require 'optparse'

class Cy
	attr_accessor :vars, :stack, :arrays
	def initialize
		@vars = {}
		@stack = []
		@arrays = []
		@mutate = true
		
		@@ops.each do |key, func|
			@vars[key] = proc do
				vals = self.pop! func.arity
				self.push instance_exec(*vals, &func)
			end
		end
		@@cmd.each do |key, func|
			@vars[key] = proc do
				vals = self.pop! func.arity
				instance_exec(*vals, &func)
			end
		end
	end

	
	@@ops = {
		'+' => ->(x,y){ x + y },
		'-' => ->(x,y){ x - y },
		'*' => ->(x,y){ x * y },
		'/' => ->(x,y){ Float(x) / Float(y) },
		'^' => ->(x,y){ x ** y },
		'!!' => ->(x,y){ x[y] },
		'>' => ->(x,y){ x > y },
		'<' => ->(x,y){ x < y },
		'>=' => ->(x,y){ x >= y },
		'<=' => ->(x,y){ x <= y }
	}
	
	@@cmd = {
		'!' => proc do |cmd|
			instance_exec(&cmd)
		end,
		'while' => proc do |body, con|
			while Cy.bool(self.call con)
				self.call body
			end
		end,
		'do_while' => proc do |body|
			body.call
			while Cy.bool(self.pop!)
				body.call
			end
		end,
		'if' => proc do |t, f, con|
			if Cy.bool(self.pop!)
				self.call t
			else
				self.call f
			end
		end,
		'[' => proc do 
			@arrays << []
		end,
		',' => proc do
			@arrays[-1] << self.pop!
		end,
		']' => proc do
			array = @arrays.pop
			array << self.pop!
			self.push(array)
		end,
		
		'pop' => proc do
			self.pop!
		end,
		
		'swap' => proc do
			self.push self.pop!, self.pop!
		end,
		
		'rev' => proc do
			@stack.reverse!
		end,
		
		'<<' => proc do
			@stack.push @stack.shift
		end,
		
		'>>' => proc do
			@stack.unshift @stack.pop
		end,

		'print' => proc do
			puts self.pop!
		end,
		
		'&print' => proc do
			puts self.pop
		end,

		'++' => proc do |x|
			@vars[x.to_s] += 1
		end,

		'&++' => proc do |x|
			self.push @vars[x.to_s]
			@vars[x.to_s] += 1
		end,

		'++&' => proc do |x|
			@vars[x.to_s] += 1
			self.push @vars[x.to_s]
		end,
		
		'--' => proc do |x|
			@vars[x.to_s] -= 1
		end,

		'&--' => proc do |x|
			self.push @vars[x.to_s]
			@vars[x.to_s] += 1
		end,

		'--&' => proc do |x|
			@vars[x.to_s] -= 1
			self.push @vars[x.to_s]
		end,
		
		'+=' => proc do |var, val|
			@vars[var.to_s] += val
		end,
		
		'+&=' => proc do |var, val|
			self.push(@vars[var.to_s] += val)
		end,

		'-=' => proc do |var, val|
			@vars[var.to_s] -= val
		end,
		
		'-&=' => proc do |var, val|
			self.push(@vars[var.to_s] -= val)
		end,

		'*=' => proc do |var, val|
			@vars[var.to_s] *= val
		end,
		
		'*&=' => proc do |var, val|
			self.push(@vars[var.to_s] *= val)
		end,

		'/=' => proc do |var, val|
			@vars[var.to_s] /= val
		end,
		
		'/&=' => proc do |var, val|
			self.push(@vars[var.to_s] /= val)
		end,

		
	}
	
	def Cy.bool (val)
		not [false, 0, nil, [], '', {}].include? (val)
	end
	
	def call(func)
		instance_exec(&func)
		self.pop!
	end
	
	def pop (n=nil)
		if n
			@stack.slice(-n, n)
		else
			@stack[-1]
		end
	end
	
	def pop! (n=nil)
		if n
			@stack.slice!(-n, n)
		else
			@stack.pop
		end
	end
	
	def push (*vals)
		@stack.push(*vals)
	end
	
	def func (s)
		case s
			when /^=(\w+)$/	
				self.setVar $1
			
			when /^&=(\w+)$/
				self.setVar $1, false

			when /^\$(\w+)$/
				self.getVar $1
			
			when /^(&?[a-zA-Z_]+)$/
				self.runMeth $1
			
			when /^"(.*)"$/
				self.string $1
			
			when /\{\s*(.*?)\s*\}/
				self.block $1
			
			when /^\.(\w+)/
				self.symbol $1
			
			
			else
				cmd = @vars[s]
				if cmd
					cmd
				else
					proc do
						self.push (eval s)
					end
				end
		
		end
	end
	
	def getVar (var)
		proc do
				self.push @vars[var]
		end
	end
	
	def setVar (var, mutate=true)
		proc do
			if mutate
				@vars[var] = self.pop!
			else
				@vars[var] = self.pop
			end
		end
	end
	
	def runMeth (var)
		proc do
			@vars[var].call
		end
	end
	
	def symbol (s)
		proc do
			self.push s.to_sym
		end
	end
	
	def string (s)
		proc do
			escape = false
			out = ''
			s.split('').each do |ch|
				if escape
					if ch == '%'
						out += '%'
					elsif ch == '\\'
						out += '\\'
					else
						out += eval('"\\' + ch + '"')
					end
					escape = false
				elsif ch == '\\'
					escape = true
				elsif ch == '%'
					out += "#{pop}"
				else
					out += ch
				end
			end
			self.push out
		end
	end
	
	def block (code)
		proc do
			self.push(proc do
				self.exec code
			end)
	
		end
	end
	
	def Cy.tokens (code)
		tokens = ['']
		level = 0
		code.gsub!(/ ?([\[\],!]) ?/,' \1 ')
		code.gsub(/\s+/, ' ').split('').each do |x|		
			if x == '{'
				level += 1
			elsif x == '}'
				level -= 1
			end
			
			if x == ' ' and level == 0
				tokens << ''
			else
				tokens[-1] += x
			end
		end
		tokens
	end
	
	def exec(line)
		tokens = Cy.tokens(line)
		tokens.each do |token|
			next if token == ""
			func = self.func token
			func.call
		end
	end
end


parser = OptionParser.new do |args|
	args.on('-f [file]') do |file|
		cy = Cy.new
		cy.exec File.read(file)
	end

	args.on('-i [file]') do |file|
		cy = Cy.new
		File.open(file, 'r') do |f|
			f.each_line do |line|
				length = cy.stack.size
				puts line
				cy.exec line
				puts "=> #{cy.stack[length..-1].join(', ')} #{cy.stack.to_s}"
			end
		end
	end
end

parser.parse! ARGV

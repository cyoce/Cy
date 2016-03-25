#!/usr/bin/env ruby
require 'optparse'

class Cy
	attr_accessor :vars, :stack, :arrays
	def initialize
		@vars = {}
		@codes = {}

		stack = []
		@readers = [stack]
		@writers = [stack]

		@active = []
		@mutate = true

		@@ops.each do |key, func|
			@vars['&' + key] = proc do
				vals = self.pop func.arity
				self.push instance_exec(*vals, &func)
			end
		end
		
		def reader
			@readers[-1]
		end

		def writer
			@writers[-1]
		end

		@@ops.each do |key, func|
			@vars[key] = proc do
				vals = self.pop! func.arity
				self.push instance_exec(*vals, &func)
			end
		end
		@@cmd.each do |key, func|
			@vars['&' + key] = proc do
				vals = self.pop func.arity
				instance_exec(*vals, &func)
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
		'+' 	=> ->(x,y){ x + y },
		'*' 	=> ->(x,y){ x * y },
		'-' 	=> ->(x,y){ x - y },
		'/' 	=> ->(x,y){ Float(x) / Float(y) },
		'%' 	=> ->(x,y){ x % y },
		'<<'    => ->(x,y){ x << y },
		'>>' 	=> ->(x,y){ x >> y },
		'^' 	=> ->(x,y){ x ** y },
		'::'	=> ->(x,y){ x[y] },
		'>' 	=> ->(x,y){ x > y },
		'<' 	=> ->(x,y){ x < y },
		'>=' 	=> ->(x,y){ x >= y },
		'<=' 	=> ->(x,y){ x <= y },
		'=='	=> ->(x,y){ x == y },
		'!='	=> ->(x,y){ x != y },
		'..'	=> ->(x,y){ Array x .. y },
		'...'	=> ->(x,y){ x .. y },
		'zip'	=> ->(x,y){ x.each_with_index.map { |i,j| [i, y[j]] } },
		'len'	=> ->(x){ x.size },
		'not'	=> ->(x){ not Cy.bool(x) },
		'stack'	=> ->(){ self.pop! reader.size },
		'&stack'=> ->(){ reader },
		'array' => ->(){ [*x]},
		':>i' 	=> ->(){ Integer STDIN.gets },
		':>f'	=> ->(){ Float STDIN.gets },
		':>s'	=> ->(){ String(STDIN.gets).chomp },
		':>' 	=> ->(){ STDIN.gets && $_.chomp },
		':i' 	=> ->(x){ Integer x },
		':f' 	=> ->(x){ Float x },
		':s'	=> ->(x){ String x },
		':r' 	=> ->(x){ x.inspect },
		}
	@@cmd = {
		'!' => proc do |cmd|
			instance_exec(&cmd)
		end,

		':<' => proc do |x|
			puts x
		end,

		'while' => proc do |body, con|
			while Cy.bool(self.call con)
				body.call
			end
		end,

		'&while' => proc do |body, con|
			while true
				con.call
				break unless Cy.bool(self.pop)
				body.call
			end
		end,

		'do' => proc do |body|
			body.call
			while Cy.bool(self.pop!)
				body.call
			end
		end,

		'&do' => proc do |body|
			body.call
			while Cy.bool(self.pop)
				body.call
			end
		end,

		'?' => proc do |con, t, f|
			if Cy.bool(con)
				t.call
			else
				f.call
			end
		end,

		'&?' => proc do |t, f|
			con = self.pop
			if Cy.bool(con)
				t.call
			else
				f.call
			end
		end,

		'if' => proc do |con, body|
			if Cy.bool(con)
				body.call
			end
		end,

		'&if' => proc do |body|
			con = self.pop
			if Cy.bool(con)
				body.call
			end
		end,

		'each' => proc do |iter, body|
			iter.each do |x|
				self.push x
				body.call
			end
		end,

		'times' => proc do |x, y|
			x,y = y,x if x.class == Proc
			x.times(&y)
		end,

		'zipwith' => proc do |x, y, func|
			out = []
			(0...x.size).each do |i|
				self.push x[i], y[i]
				func.call
				out << self.pop!
			end
			self.push out
		end,

		'fold' => proc do |iter, func|
			iter = Array iter
			while iter.size > 1
				self.push(*iter.slice!(-2, 2))
				func.call
				iter.push self.pop!
			end
			self.push iter.pop
		end,

		'[' => proc do
			@active << []
		end,

		',' => proc do |item|
			@active[-1] << item
		end,

		']' => proc do |item|
			array = @active.pop
			array << item
			self.push(array)
		end,

		'(' => proc do
			@active << {}
		end,

		':' => proc do |key, value|
			@active[-1][key] = value
		end,

		')' => proc do
			hash = @active.pop
			self.push hash
		end,

		'::=' => proc do |iter, index, value|
			iter[index] = value
		end,

		'&::=' => proc do |index, value|
			(self.pop)[index] = value
		end,

		'pop' => proc do |x|

		end,

		'swap' => proc do |x, y|
			self.push y, x
		end,

		'dupe' => proc do
			self.push self.pop
		end,

		'rev' => proc do

		end,

		'expand' => proc do |iter|
			self.push(*iter)
		end,

		'<-' => proc do
			writer.push reader.shift unless reader == []
		end,

		'<--' => proc do |x|
			x.times do
				writer.push reader.shift
			end unless reader == []
		end,

		'->' => proc do
			writer.unshift reader.pop unless reader == []
		end,

		'-->' => proc do |x|
			x.times do
				writer.unshift reader.pop
			end unless reader == []
		end,

		'print' => proc do |x|
			puts x
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

		'%=' => proc do |var, val|
			@vars[var.to_s] %= val
		end,

		'%&=' => proc do |var, val|
			self.push(@vars[var.to_s] %= val)
		end,

		'=' => proc do |var, val|
			@vars[var.to_s] = val
		end,

		'&=' => proc do |var, val|
			@vars[var.to_s] = val
		end,

		'exit' => proc do
			exit
		end
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
			reader.slice(-n, n)
		else
			reader[-1]
		end
	end

	def pop! (n=nil)
		if n
			reader.slice!(-n, n)
		else
			reader.pop
		end
	end

	def push (*vals)
		writer.push(*vals)
		vals.each do |val|
			puts val unless val.class == Proc
		end if $I
	end
	
	def func (s)
		case s
		when /^\.(\w+)/
			self.symbol $1

		when /^\{\s*(.*?)\s*\}$/
			self.block $1

		when /^"(.*)"$/
			self.string $1

		when /^=(\w+)$/
			self.setVar $1

		when /^&=(.+)$/
			self.setVar $1, false

		when /^\$(.+)$/
			self.getVar $1

		when /^(&?[.]+)$/
			self.runMeth $1

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
			self.push eval('"' + s + '"')
		end
	end

	def block (code)
		p = proc do
			self.exec code
		end
		@codes[p] = code
		proc do
			self.push p
		end
	end

	def Cy.tokens (code)
		tokens = ['']
		level = 0
		quote = escape = comment = false
		i=0
		iter = code.gsub(/\s+/, ' ').split('')
		iter.each do |x|
			if quote or comment
			elsif x == '{'
				level += 1
			elsif x == '}'
				level -= 1
			end
			
			if level > 0
			elsif quote
				quote = not(quote) if x == '"'
			elsif comment
				comment = not(comment) if x == '#'
			else
				comment = not(comment) if x == '#'
				quote = not(quote) if x == '"'
			end

			if quote and not escape and x == '%'
				tokens[-1] += '#{self.pop!}'
			elsif quote and not escape and x == '&'
				tokens[-1] += '#{self.pop}'
			elsif quote or comment
				tokens[-1] += x
			elsif x == ' ' and level == 0
				tokens << ''
			elsif '[],!()'.include? x
				tokens << x << ''
			else
				tokens[-1] += x
			end
			i+=1
		end
		tokens.pop if tokens[-1] == ''
		tokens
	end
	
	def exec(line)
		tokens = Cy.tokens(line)
		tokens.each do |token|
			next if token == ''
			func = self.func token
			func.call
		end
		sleep(Float($int)/1000) if $int
	end

	def prompt
		print "\e[37m>> \e[0m\e[1m\t "
	end

	def repl_line(file, disp=true)
		length = writer.size
		self.prompt unless disp
		return false unless file.gets
		self.prompt if disp
		print "#{$_.chomp + "\n"}" if disp
		print "\e[0m"
		self.exec $_
		print "\e[32m=> "
		puts self.inspect_it(writer), "\e[0m"
		true
	end

	def repl(file=nil)
		while file
			break unless self.repl_line(file)
		end

		while true
			break unless self.repl_line(STDIN, false)
		end
	end

	def inspect_it(item)
		if item.class == Array
			out = []
			item.each do |x|
				out << self.inspect_it(x)
			end
			"[#{out.join(', ')}]"
		elsif item.class == Proc
			"{ #{@codes[item]} }"
		else
			item.inspect
		end
	end
end
$action = nil
parser = OptionParser.new do |args|
	cy = Cy.new
	args.on('-f [file]') do |file|
		$action = proc do
			cy.exec File.read(file)
		end
	end

	args.on('-r [file]') do |file=nil|
		if file
			$action = proc do
				File.open(file) do |f|
					cy.repl f
				end
			end
		else
			$action = proc do
				cy.repl
			end
		end
	end

	args.on('-m [file]') do |file|
		$action = proc do
			File.open(file, 'r') do |f|
				puts "# [Cy](https://github.com/cyoce/Cy), #{f.size} bytes"
				puts ""
				f.each_line do |line|
					puts "    #{line}"
				end
			end
		end
	end

	args.on('-i [INTERVAL]') do |int|
		$int = Integer int
	end

	args.on('-p') do
		$I = true
	end

	args.on('-e [code]') do |code|
		$action = proc do
			cy.exec code
		end
	end
	cy.push(*args.order(*ARGV))
end
$I = false
$implicit = false
$int=nil
parser.parse! ARGV
$action.call

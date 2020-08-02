#!/usr/bin/env ruby
String.define_method(:bold) { "\e[1m#{self}" }

String.define_method(:spaces_to_tabs) do
	each_line.map do |x|
		match = x.match(/^([^\S\t\n\r]*)/)[0]
		m_len = match.length
		(m_len > 0 && m_len % 2 == 0) ? ?\t * (m_len / 2) + x[m_len .. -1] : x
	end.join
end

GREEN = "\e[38;2;85;160;10m".freeze
BLUE = "\e[38;2;0;125;255m".freeze
TURQUOISE = "\e[38;2;60;230;180m".freeze
RESET = "\e[0m".freeze
BLINK = "\e[5m".freeze

dry_test = ARGV.any? { |x| x[/^\-(\-dry\-test|d)$/] }
puts "#{TURQUOISE.bold}:: Info:#{RESET}#{TURQUOISE} Running in Dry Test mode. Files will not be changed.#{RESET}\n\n" if dry_test

Dir.glob("{app,config,db,lib,public}/**/**.{rb,erb,js,css,scss,html}").map do |y|
	if File.file?(y) && File.readable?(y)
		read = IO.read(y)
		converted = read.spaces_to_tabs

		unless read == converted
			puts "#{BLINK}#{BLUE.bold}:: Converting#{RESET}#{GREEN} indentation to tabs of #{y}#{RESET}"
			IO.write(y, converted) unless dry_test
		end
	end
end

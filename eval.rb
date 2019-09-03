#!/usr/bin/env ruby
STDOUT.sync = STDERR.sync = $VERBOSE = true
require 'io/console'

Kernel.tap { |x| x.undef_method(:p) }.define_method(:p) { |*args| args.length > 1 ? args : args[0] }

ARGV.each_with_index do |a, i|
	print "\e[1;34;4m" << "Code: #{i.next}".center(STDOUT.winsize[1]) << "\e[0m\n"
	d, __b__ = IO.readlines(a).map { |x| x.gsub(?\t, ?\s * 4) }, Kernel.binding
	max = d.map(&:length).max + 4
	print d.map { |x| x.then { |v| v.strip.empty?.|(v.start_with?(?#)) ? v : "#{v.chomp}#{?\s * (max - v.chomp.length)}# => #{__b__.eval(v).inspect}\n" } }.join
end

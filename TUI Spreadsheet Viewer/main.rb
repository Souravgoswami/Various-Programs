require 'rubygems'
require 'bundler'
Bundler.require(:default)
# require 'spreadsheet'

abort 'No file given as argument' unless ARGV[0]
book, all = Spreadsheet.open(File.expand_path(ARGV[0])), []
book.worksheets.each { |sht| sht.each { |r| r.map(&:to_s).then { |x| all << x unless x.all?(&:empty?) } } }

max, cols = all.map(&:length).max, (?a..'zzz').to_enum
all.each_with_index { |x, i| x.concat([?\s] * (max - x.length)) if x.length < max }
len = all.map { |x| x.map(&:length) }.transpose.map(&:max)
splitter = "\342\224\200" * (len.sum + len.length + all.size.to_s.length * 2)

puts "\e[1m\u250C#{splitter}\u2510\n\342\224\202#{?\s * (all.size.to_s.length + 1)} \342\224\202" +
"#{all[0].length.times.map { |i| cols.next.center(len[i]) }.join("\342\224\202")} \342\224\202\e[0m"

all.each_with_index do |x, i|
	puts "\342\224\202#{sprintf("\e[1m#%#{all.size.to_s.length}d\e[0m ", i + 1)}\342\224\202" +
	x.map.with_index { |y, i| y.send(y.to_i.to_s == y ? :rjust : :ljust, len[i]) }
	.join("\342\224\202") + " \342\224\202"
end
puts "\u2514" + splitter + "\u2518"

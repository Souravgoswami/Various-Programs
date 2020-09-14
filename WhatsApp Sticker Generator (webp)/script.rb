#!/usr/bin/ruby -w


# ---- User Modifable Values ---- #

# Width and Height of the stickers. Whatsapp uses 512x512 max
W, H = 432, 432

# Quality of the generated webp images
WEBP_QUALITY = 60

# Margin around stickers
MARGIN = 54

# Maximum task to give to each CPU core
require 'etc'
MAX_TASKS = Etc.nprocessors * 2


# ---- Main Code ---- #
$forks, $success = [], []

manage_pid = ->(x) do
	Process.wait(x)
	$forks.delete(x)

	if $?.exitstatus == 0
		puts "\e[1;38;2;130;201;30m:: Process #{x} Succeeded\e[0m"
		$success << true
	else
		puts "\e[1;38;2;255;80;104m!! Process #{x} failed\e[0m"
		$success << false
	end
end

Dir.glob("#{__dir__}/set-[0-9]*/").each do |x|
	dir = "#{File.dirname(x)}/webp-#{File.basename(x)}"
	Dir.mkdir(dir) unless Dir.exist?(dir)

	Dir.children(x).each do |y|
		f, converted_file = File.join(x, y), File.join(dir, y.split(?.).tap(&:pop).join(?.))

		$forks.dup.each { |frk| manage_pid === frk if IO.read("/proc/#{frk}/stat").split[2] == ?Z } if $forks.length > MAX_TASKS - 1
		manage_pid === $forks[0] if $forks.length > MAX_TASKS - 1

		$forks << Process.fork do
			stats = []

			stats.concat([
				system(%Q`inkscape --export-margin=#{MARGIN} "#{f}" --export-filename "#{converted_file}.svg" &>/dev/null`),
				system(%Q`inkscape -w #{W} -h #{H} "#{converted_file}.svg" --export-filename "#{converted_file}.png" &>/dev/null`),
				system(%Q`convert -quality "#{WEBP_QUALITY}" "#{converted_file}.png" "#{converted_file}.webp" &>/dev/null`)
			])

			raise RuntimeError unless stats.all?(&:itself)
			File.delete(converted_file + '.svg'.freeze)
			File.delete(converted_file + '.png'.freeze)
		end
	end
end

$forks.dup.each { |x| manage_pid === x }

if $success.all?(&:itself)
	puts "\e[1;38;2;130;201;30m:: #{$success.count} stickers were successfully generated!\e[0m"
else
	puts "\e[1;38;2;255;80;104m!! There was error generating #{$success.reject(&:itself).count} stickers\e[0m"
end

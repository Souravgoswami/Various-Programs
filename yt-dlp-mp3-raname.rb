require 'fileutils'

files = Dir
	.glob('*.mp3')
	.sort_by { |f| File.ctime(f) }

files.each do |file|
	FileUtils.touch(file)
	stripped = file.partition(/\[[^\[]+\]\.mp3/)

	if stripped[1].empty?
		puts "\e[1;33m:: Skipping target #{file}\e[0m"
	else
		filename = stripped[0]
		filename.strip!

		filename.concat('.mp3')

		puts ":: Renaming \e[1;31m#{file}\e[0m to \e[1;34m#{filename}\e[0m"
		FileUtils.mv(file, filename)
	end
end

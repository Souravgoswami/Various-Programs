#!/usr/bin/ruby -w
require 'open3'
GC.start(full_mark: true, immediate_sweep: true)
STDOUT.sync = STDERR.sync = true
VERSION = 1.0


class Notify
	USER = ENV['USER']
	@@notify_interval = 0
	@@last_notified = Time.new - @@notify_interval

	define_singleton_method(:notify_interval=) { |interval| tap { @@notify_interval, @@last_notified = interval, Time.new - interval } }

	def self.send(message = '', icon = 'state-warning', urgency = 'low')
		if @@last_notified + @@notify_interval <= Time.new
			@@last_notified = Time.new
			Open3.pipeline_start(%Q(su #{USER} -c "notify-send '#{message}' --icon='#{icon}' --urgency='#{urgency}'") )
		end
		self
	end

	define_singleton_method(:save_to_log) do |message, file = "/tmp/#{File.basename(__FILE__)}.log"|
		# From kernel 4.19 the new sysctl fs.protected regular flag can lock the file from writing if the file is created by another user on file systems like /tmp
		# Even though File.writable?('/tmp/filename') returns true, it's not always writable.
		# In such case, we have to implement an exception handling block to make sure that the program doesn't crash while having such permission errors!
		begin
			truncate_log(1)
			tap { File.open(file, 'a+') { |f| f.puts(message + "\n" + '-' * (message.each_line.map(&:length).max)) } }
		rescue Errno::EACCES
				STDERR.puts ":: Can't write to #{file}!"
			unless File.owned?(file)
				STDERR.puts ":: Permission denied. The file is owned by another user"
				STDERR.puts ":: Trying to change the ownership of #{file} to 0..."
				File.chown(0, 0, file)
				STDERR.puts ":: Changed the #{file} permission to 0... Retrying"
			else
				STDERR.puts ":: Reason Unknown."
			end
		end
	end

	def self.truncate_log(lines = 1, file = "/tmp/#{File.basename(__FILE__)}.log")
		begin
			File.write(file, File.read(file).split(/\n*\-+\n*/)[lines..-1].to_a.map { |x| x + ?\n + ?- * x.each_line.map(&:length).max }.join(?\n)) if !File.zero?(file) & File.writable?(file) & !lines.zero?
		rescue Errno::EACCES
			STDERR.puts "Can't write to #{file}. Permission denied. Please make sure that the file owner is root! Or delete the file and run #{$0} again..."
		end
		self
	end
end

def main(logging = true, notification_interval = 5, sleep = 1)
	notification = ''
	action = 'swapoff $dev && swapon $dev'

	# Stop spamming
	Notify.send("#{Time.new.ctime}\nStarted Monitoring System Memory Usage")
	Notify.notify_interval = notification_interval

	loop do
		swap_details = IO.readlines('/proc/swaps')[1..-1].map(&:split)

		swap_details.each_with_index do |sd, i|
			mem_total, mem_available = IO.readlines('/proc/meminfo').then { |x| [x[0], x[2]] }.map { |x| x.split[1].to_f }
			swap_total, swap_used = sd[2].to_f, sd[3].to_f
			swap_free = swap_total - swap_used

			if swap_free < swap_total
				dev = sd[0]
				notification.replace("#{Time.new.ctime}\nWarning! Swap Device#{dev} on #{swap_used./(1024).round(2)} MiB Swap.\n")

				if mem_available > swap_used * 2
					act = action.gsub('$dev', dev)
					Notify.send(notification.concat("Available RAM: #{mem_available./(1024).round(2)} MiB\nTaking action: #{act}"))

					if Kernel.system(action.gsub('$dev', dev))
						Notify.send(notification.concat("Successful #{act}"))
						Notify.save_to_log(notification) if logging
					else
						Notify.send(notification.concat("Cannot run #{act}"))
						Notify.save_to_log(notification) if logging
					end
				else
					notification.concat("System is running low on RAM: #{mem_total.-(mem_available)./(1024).round(2)} MiB used "\
 						"/ #{mem_total./(1024).round(2)} MiB\nUnable to apply default action on #{dev}")
					Notify.send(notification)
					Notify.save_to_log(notification) if logging
				end
			end

			Kernel.sleep(sleep)
		end
	end
end

def help
	STDOUT.puts <<~EOF
		This program can be used to move the pages from swap device automatically
		if there's enough available RAM.

		Details:
			If you are running Linux, and copy files to some directory or even open up
			some application, and you see that you are running on swap even if the
			swappiness is very low, well that could reduce your workflow.
			In such case, you can `swapoff /dev/swap_dev && sudo swapon /dev/swap_dev`.
 			That's exactly what this program is for. Everytime you run this program, it will
			detect if any of your swap devices is currently being used or not in an infinite loop.

			If you any of your swap devices are used, it will then detect if you have 1.5x available
			RAM memory that of swap used. If yes, it will try to swapoff off the particular swap
			device and then turn back on teh swap device thus moving your swap pages to the RAM.
			This should speed up your system.

			This program shows you notification using the "notify-send" command.
			This program can work with multiple swap devices.

		Arguments:
			#{File.basename($0)} --help          Show this help section.
			#{File.basename($0)} --truncate=n    Truncate the log by n lines from the beginning.
			#{File.basename($0)} --version       Show version of this program.
		EOF
end

if ARGV[0].to_s[/^\-\-help$/]
	help

elsif ARGV[0].to_s[/^\-\-truncate=\d+$/]
	Notify.truncate_log(ARGV[0].strip.split(?=)[-1].to_i.then { |x| x < 0 ? 0 : x })

elsif ARGV[0].to_s[/^\-\-version$/]
	STDOUT.puts ":: #{File.basename($0).split('.rb').join(?\s).capitalize} Version: #{VERSION}"

elsif ARGV.empty?
	begin
		main
	rescue SignalException, Interrupt, SystemExit
		puts
		exit 0
	rescue Exception => e
		STDERR.puts "Uh oh! An unexpected error occurred: #{e}."
		STDERR.puts "Details:\n#{e.full_message.each_line.map { |x| ?\t + x }.join }"
		exit! 127
	end
else
	STDERR.puts "Invalid argument #{ARGV[0]}. Please run #{File.basename($0)} --help for usage..."
end

#!/usr/bin/env ruby
puts "This is #{RUBY_PLATFORM}. Which is an unsupported platform. A GNU/Linux system is needed" unless /linux/ === RUBY_PLATFORM
puts "The Ruby Version is too old for #{File.basename(__FILE__)} to work. Make sure you have at lease Ruby 2.5.0+" if (RUBY_VERSION.split('.').first(2).join.to_i < 25)

GC.start(full_mark: true, immediate_sweep: true)
require 'io/console'

STDOUT.sync = true
COLOUR1 = 40
COLOUR2 = 63
COLOUR3 = 196
COLOUR_TITLE = "\e[1;33m"
SWAP_LABEL = "\e[1;38;5;165m"
ROUND = ARGV.select { |x| x.start_with?(/--round=|-r=/) }[-1].to_s.split('=')[-1].to_i.then { |x| x > 0 ? x.to_i : 2 }
TIME_FORMAT = ARGV.select { |x| x.start_with?(/(-f|--format)=/) }[0].to_s.split('=')[-1].then { |x| x ? x : "%I:%M:%S:%2N %p" }

String.define_method(:colourize) do |colour = [154, 184, 208, 203, 198, 164, 129, 92]|
	clr, return_val = colour.dup.concat(colour.reverse), ''
	colour_size = clr.size - 1

	str_len, i, index = length - 1, -1, 0
	div = delete("\s").length./(colour_size.next).then { |x| x == 0 ? 1 : x }

	while i < str_len do
		s = slice(i += 1)
		index += 1 if ((i) % div == 0 && index < colour_size) && i > 1 && s != "\s"
		return_val.concat("\e[38;5;#{clr[index]}m#{s}")
	end

	return_val + "\e[0m"
end

Float.define_method(:pad) { round(::ROUND).to_s.then { |x| x.split('.')[1].to_s.length.then { |y| y < ROUND && y != 0 ? x + '0'.*(ROUND - y)  : x } } }
Float.define_method(:percent) { |arg| fdiv(100).*(arg) }

def help
	split_colour = [203, 198, 199, 164, 129, 93, 63, 33, 39, 44, 49, 48, 83, 118, 184, 214, 208]

	STDOUT.puts <<~EOF.each_line.map { |x| x.rstrip.colourize(split_colour.rotate!) }
		#{$PROGRAM_NAME} is a lighweight and simple resource monitoring program for
		the Raspberry Pi.
		It can measure memory usage, swap usage, CPU usage, and display time and uptime.
		Usage:
			#{$PROGRAM_NAME} [arguments]
		Arguments:
			1. --format= / -f=		The format of the time. [Default: %I:%M:%S:%#{ROUND}N %p ]
			2. --help / -h			Show this help message.
			3. --round= / -r=		Precision of the decimal places. [Default: 2]
			4. --sleep= / -s= / -d=		Delay while measuring the CPU usage. [Default: 0.125]
							[Will affect the refresh time of the overall program]
	EOF
	exit! 0
end

help if ARGV.include?('-h') | ARGV.include?('--help')

ARGV.find { |x| x.to_s !~ /-(r|f|s|d)=|--(round|format|sleep)=/ }.to_s
	.tap { |x| (STDOUT.puts("Invalid Argument `#{x}'. Run #{$PROGRAM_NAME} --help for a manual.".colourize) || exit!(0)) unless x.empty? }

def main(sleep = 0.05)
	split_colour = [203, 198, 199, 164, 129, 93, 63, 33, 39, 44, 49, 48, 83, 118, 184, 214, 208]
	swap, cpu_usage, cpu_bar = '', '', ''

	bars = %W(\xE2\x96\x81 \xE2\x96\x83 \xE2\x96\x85 \xE2\x9A\xA0)
	clocks = %W(\xF0\x9F\x95\x9B \xF0\x9F\x95\x90 \xF0\x9F\x95\x91 \xF0\x9F\x95\x92 \xF0\x9F\x95\x93 \xF0\x9F\x95\x94 \xF0\x9F\x95\x95 \xF0\x9F\x95\x96
					\xF0\x9F\x95\x97 \xF0\x9F\x95\x98 \xF0\x9F\x95\x99 \xF0\x9F\x95\x9A)

	loop do
		width = STDOUT.winsize[1]

		# calculate memory usage
		mem_total, mem_available = IO.readlines('/proc/meminfo').then { |x| [x[0], x[2]] }.map(&:split).then { |x| [x[0][1], x[1][1]] }.map { |x| x.to_i./(1024.0) }
		mem_used = mem_total.-(mem_available)

		# calculate swap usage
		swap_devs = IO.readlines('/proc/swaps')[1..-1].map(&:split).map { |x| [x[0], x[2], x[3]] }

		# calculate CPU usage
		prev_file = IO.readlines('/proc/stat').select { |line| line.start_with?('cpu') }
		Kernel.sleep(sleep)
		file = IO.readlines('/proc/stat').select { |line| line.start_with?('cpu') }

		cpu_usage.replace(
			file.size.times.map do |i|
				data, prev_data = file[i].split.map(&:to_f), prev_file[i].split.map(&:to_f)

				%w(user nice sys idle iowait irq softirq steal).each_with_index { |e, i| binding.eval "@#{e}, @prev_#{e} = #{data[i += 1]}, #{prev_data[i]}" }

				previdle, idle = @prev_idle + @prev_iowait, @idle + @iowait
				totald = idle + (@user + @nice + @sys + @irq + @softirq + @steal) -
				(previdle + (@prev_user + @prev_nice + @prev_sys + @prev_irq + @prev_softirq + @prev_steal))

				cpu_percentage = ((totald - (idle - previdle)) / totald * 100.0)
				cpu_bar.replace(cpu_percentage < 33 ? bars[0] : cpu_percentage < 66 ? bars[1] : cpu_percentage.nan? ? bars[3] : bars[2])
				"\e[38;5;"+ (cpu_percentage < 33 ? COLOUR1 : cpu_percentage < 66 ? COLOUR2 : COLOUR3).to_s + 'm' +
					"#{cpu_bar} CPU #{i == 0 ? 'Total' : i}: #{cpu_percentage.pad} %"
			end.join("\e[0m\n") + "\n"
		)

		# String formatting and colourizing
		tot = "Total: #{mem_total.pad} MiB"
		used = " \xf0\x9f\x93\x89Used: #{mem_used.pad} MiB".center(width - tot.length * 2).rstrip
		mem_colour = "\e[38;5;#{mem_used < mem_total.percent(33) ? COLOUR1 : mem_used < mem_total.percent(66) ? COLOUR2 : COLOUR3}m"

		swap.clear
		swap.concat('Swap'.center(width - 2).colourize(split_colour) + "\n" + '-'.*(width).colourize +
			swap_devs.size.times.map do |sd|
				dev = swap_devs[sd]
				al, av = dev[1].to_f./(1024), dev[2].to_f./(1024)

				swap_colour = "\e[38;5;#{av < al.percent(33) ? COLOUR1 : av < al.percent(66) ? COLOUR2 : COLOUR3}m"

				allocated = "Total: #{al.pad} MiB"
				usage = " \xF0\x9F\x93\x8AUsed: #{av.pad} MiB".center(width - allocated.length * 2 - 1).rstrip
				available = swap_colour + " \xF0\x9F\x93\x8AAvailable: #{dev[1].to_f.-(dev[2].to_f)./(1024).pad} MiB".rjust(width - allocated.length - usage.length - 2) + "\e[0m"

		 		"#{SWAP_LABEL}\xE2\x80\xA3 #{dev[0]} \xF0\x9F\xA2\x90\e[0m\n" + swap_colour + allocated + usage + available + "\n\n"
			end.join
		) unless swap_devs.empty?

		# time
		hr, min, sec = IO.read('/proc/uptime').to_i.then do
			|x| [(x./(3600).to_s.then { |x| x.length == 1 ? '0' + x : x }), (x.%(3600)./(60).to_s.then { |x| x.length == 1 ? '0' + x : x }), (x.%(60).to_s.then { |x| x.length == 1 ? '0' + x : x })]
		end

		current_time = "#{Time.new.strftime(TIME_FORMAT)}"

		STDOUT.print(
			"\e[3J\e[H\e[2J"+ 'System Memory'.center(width).colourize(split_colour.rotate!) +
			('-' * width).colourize(split_colour) +
			mem_colour + tot + "\e[0m" + mem_colour + used + "\e[0m" + mem_colour +
			" \xf0\x9f\x93\x89Available: #{mem_available.pad} MiB".rjust(width - tot.length - used.length - 2) + "\e[0m\n\n" +
			swap +
			'CPU Usage'.center(width).colourize(split_colour) + "\n" + '-'.*(width).colourize + cpu_usage + "\n" +
			'Frequencies: '.colourize + "\n" +

			Dir['/sys/devices/system/cpu/cpu[0-9]'].map.with_index do |i, index|
				"CPU#{index.next}: #{IO.read("#{i}/cpufreq/cpuinfo_cur_freq").to_f./(1000.0).pad} MHz"
				.colourize(split_colour)
			end.join("\n") + "\n\n" +

			'Temperature: '.colourize(split_colour) +

			IO.read('/sys/class/thermal/thermal_zone0/temp').to_i./(1000.0).then{ |c| "#{c.pad}\xC2\xB0C | #{c.*(1.8).+(32).pad}\xC2\xB0F" }
				.colourize(split_colour) + "\n" +

			'Time'.center(width).colourize(split_colour) + '-'.*(width).colourize +
			(clocks.rotate![0] + ' ' + current_time +
			"\xE2\xAC\x86\xEF\xB8\x8F Uptime: #{hr}:#{min}:#{sec}".rjust(width - current_time.length - 2)).colourize(split_colour)
		)
	end
end

begin
	sleep = ARGV.select { |x| x.start_with?(/(-s|--sleep|-d)=/) }[-1].to_s.split('=')[-1].to_f.then { |x| x <= 0 ? 0.125 : x }
	main(sleep)

rescue Interrupt, SignalException, SystemExit
	puts

rescue Errno::ENOTTY
	puts 'No terminal found!'.colourize

rescue Errno::ENOENT => e
	puts ((/linux/ === RbConfig::CONFIG['arch'] ? "System detected: #{RbConfig::CONFIG['arch']}. But" : "This is not a GNU/Linux.") +
		 	" #{e.to_s.split('-')[1..-1].join.strip} is missing.").colourize

rescue Errno::EACCES => e
	puts "Permission denied while trying to read #{e.to_s.split('-')[1..-1].join.strip}".colourize

rescue Exception => e
	Kernel.warn("Oh no! \t#{e}")
	STDOUT.flush
	puts e.backtrace.map { |x| "\t#{x}".colourize }
end

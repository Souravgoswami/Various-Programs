#!/usr/bin/ruby -w
#Frozen_String_Literal: true

module Calculate
	define_singleton_method(:get_cpu_usage) do
		data = IO.foreach('/proc/stat').first.split.map!(&:to_f)
		Kernel.sleep(0.03)
		prev_data = IO.foreach('/proc/stat').first.split.map!(&:to_f)

		%w(user nice sys idle iowait irq softirq steal).each_with_index { |el, ind| binding.eval("@#{el}, @prev_#{el} = #{data[ind + 1]}, #{prev_data[ind + 1]}") }

		previdle, idle = @prev_idle + @prev_iowait, @idle + @iowait

		totald = idle + (@user + @nice + @sys + @irq + @softirq + @steal) -
			(previdle + (@prev_user + @prev_nice + @prev_sys + @prev_irq + @prev_softirq + @prev_steal))

			totald.-(idle - previdle)./(totald).*(100).abs.round(2)
	end
	
	define_singleton_method(:get_swap_usage) do
		IO.readlines('/proc/swaps').drop(1).map!(&:split).map { |x| x[3].to_i }.sum.fdiv(1024).round(2)
	end
	
	define_singleton_method(:get_disk_status) do
		IO.readlines('/proc/diskstats').map!(&:split).count { |x| x[11].to_i > 0 if x[2][/(mmcblk\d*p)|(sd[a-z]*)\d*/] } > 0
	end
end

def main(sleep: 0.05, clear: false)
	n, cp = Dir['/sys/class/leds/input[0-9]::numlock/brightness'].tap(&:sort!), File.readable?('/proc/cpuinfo')
	c, sw = Dir['/sys/class/leds/input[0-9]::capslock/brightness'].tap(&:sort!), File.readable?('/proc/swaps')
	s, st = Dir['/sys/class/leds/input[0-9]::scrolllock/brightness'].tap(&:sort!), File.readable?('/proc/stat')
	fail Errno::EACCES unless File.owned?('/sys/')

	puts "\e[1;31mUnreadable /proc/cpuinfo\e[0m" unless cp
	puts "\e[1;31mUnreadable /proc/swaps\e[0m" unless sw
	puts "\e[1;31mUnreadable /proc/stat.\e[0m" unless st
	
	if (cp || sw || st)
		unless clear		
			puts ((
				"\e[38;5;33mStarted Monitoring" +
				"#{"CPU Usage [ \e[38;5;70mNumlock\e[38;5;33m ], " if cp}" +
				"#{"Swap Usage [ \e[38;5;70mCaps Lock\e[38;5;33m ], " if sw}" +
				"#{"Disk IO [ \e[38;5;70mScroll Lock\e[38;5;33m ]\e[0m" if st}"
			).delete_suffix(', '))

			while true
				Calculate.get_cpu_usage > 50 ? n.each { |x| IO.write(x, 1) } : n.each { |x| IO.write(x, 0) } if cp
				Calculate.get_swap_usage > 0 ? c.each { |x| IO.write(x, 1) } : c.each { |x| IO.write(x, 0) } if sw
				Calculate.get_disk_status ? s.each { |x| IO.write(x, 1) } : s.each { |x| IO.write(x, 0) } if st
				sleep sleep
			end
		else
			n.each { |x| IO.write(x, 0) } if cp
			c.each { |x| IO.write(x, 0) } if sw
			s.each { |x| IO.write(x, 0) } if st
		end
	end
	nil
end

begin
	main(sleep: 0.005)
rescue Interrupt, SignalException, SystemExit
	puts "\n\e[38;5;45mBye!\e[0m"
rescue Errno::EACCES
	puts "\n\e[1;31mPermission Denied. Try Running #{$0} as Root.\e[0m"
rescue Exception
	puts $!
ensure
	main(clear: true) rescue nil
end

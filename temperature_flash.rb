#!/usr/bin/ruby -w
if ARGV.any? { |x| x.start_with?(/-(-help|h)/i) }
	puts <<~EOF
		This is a Raspberry Pi program to blink light connected to GPIO (default pin 7).
		Please make sure the connected light is LED.

		Blink Patterns:
			:: >= 90% CPU Usage: 32 times.
			:: >= 80% CPU Usage: 16 times.
			:: >= 70% CPU Usage:  8 times.
			:: >= 60% CPU Usage:  4 times.
			:: <  60% CPU Usage:  1 times.

		Arguments:
			--help / -h			Print this help message and exit.
			--delay=value / -d=value	Specify the delay time. Where value is the time. [default: 1]
			--duty=value / -dt=value	Specify the duty cycle. Where value is the duty cycle. [default: 50]
			--max=value / -m=value		Specify the max percentage.
			--pin=value / -p=value		Specify the output pin. Where the value is the pin number. [default: 7]
	EOF
	exit 0
end

abort(':: Need access to /dev/mem. Please run this as root.') unless File.readable?('/dev/mem')

begin
	require 'rpi_gpio'
rescue LoadError
	Warning.warn(":: rpi_gpio is not installed. Would you like me to install it? (Y/n): ")
	exit! 1 if STDIN.gets.to_s.strip.downcase.start_with? 'n'

	Warning.warn ":: Attempting to run `gem install rpi_gpio`. Is that Ok? (Y/n): "
	abort(':: Please manually install rpi_gpio') if STDIN.gets.to_s.strip.downcase == 'n'

	Kernel.warn system('gem install rpi_gpio') ? 'Successfully Installed rpi_gpio' : 'Failed to install dependency'
end

RPi::GPIO.set_warnings(false)

def monitor(pin:, sleep:, duty:, max:)
	max *= 10

	RPi::GPIO.set_numbering(:board)
	RPi::GPIO.setup(pin, as: :output)
	pwm = RPi::GPIO::PWM.new(pin, 1).tap { |x| x.start(duty) }

	loop do
		temp = IO.read('/sys/class/thermal/thermal_zone0/temp').to_i./(max).then { |x| x > 99 ? 100 : x }
		pwm.frequency = if temp >= 90 then 32
			elsif temp >= 80 then 16
			elsif temp >= 70 then 8
			elsif temp >= 60 then 4
			else 1
		end

		sleep sleep
	end
end

query = -> (pattern, default_value) { ARGV.select { |x| x.start_with?(pattern) }[-1].to_s.split('=')[-1].then { |x| x ? x.to_i : default_value } }
PIN = query.(/-(-pin|p)=\d+/, 7)

begin
	monitor(pin: PIN, duty: query.(/-(-duty|dt)=\d+/, 50), sleep: query.(/-(-delay|d)=\d+/, 1), max: query.call(/-(-max|m)=\d+/, 85))

rescue Interrupt, SignalException, SystemExit
	RPi::GPIO.clean_up(PIN.tap { |x| puts "\n:: Cleaning up pin #{x}" })
	puts
	exit 0
rescue Exception => e
	puts e
end

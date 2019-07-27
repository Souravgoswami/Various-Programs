#!/usr/bin/ruby -w
if ARGV.any? { |x| x.start_with?(/-(-help|h)/i) }
	puts <<~EOF
		This is a Raspberry Pi program to control lights connected to GPIO.
		This program dims all the lights sequentially.
		Please make sure the connected light is dimmable.
		LED lights are recommended.

		Arguments:
			--help / -h			Print this help message and exit.
			--delay=value / -d=value	Specify the delay time. Where value is the time. [default: 0.005]
			--frequency=value / -freq=value	Specify the frequency. Where value is the frequency. [default: 500]
			--step=value / -s=value		Specify the step. Where value is the step. [default: 0.25]
			--pins=value / -p=value		Specify the output pins. Where the values are the pin numbers
							separated with ','. Example: --pins=3,7,8. Default: 7,8.
	EOF
	exit 0
end

abort(':: This is not a GNU/Linux. A Raspberry Pi is required to run the script.') unless /linux/ === RUBY_PLATFORM
abort(":: Need access to /dev/mem.\n:: Please run #{__dir__}/#{$PROGRAM_NAME} as root.") unless File.readable?('/dev/mem')

begin
	require 'rpi_gpio'
rescue LoadError
	Warning.warn(':: rpi_gpio is not installed. Would you like me to install it? (Y/n): ')
	abort(":: If you want to run #{$PROGRAM_NAME}, please make sure rpi_gpio is installed!") if STDIN.gets.to_s.strip.downcase.start_with? ?n

	Warning.warn ':: Attempting to run `gem install rpi_gpio`. Is that Ok? (Y/n): '
	abort(':: Please manually install rpi_gpio') if STDIN.gets.to_s.strip.downcase == ?n

	Kernel.warn system('gem install rpi_gpio') ? ':: Successfully Installed rpi_gpio' : ':: Failed to install dependency'
end

Object.prepend(RPi::GPIO)
set_numbering(:board)
set_warnings(false)

def flash(pins: [7, 8], sleep: 0.005, step: 0.25, freq: 500 )
	pins.each do |pin|
		setup(pin, as: :output)
		binding.eval "@pwm#{pin} = PWM.new(pin, freq).tap { |p| p.start(100) } "
	end

	pins.each do |pin|
		i, val = 100, -1

		loop do
			val = 1 if i <= 0
			binding.eval "@pwm#{pin}.duty_cycle = i"
			Kernel.sleep sleep
			break if (i += val) >= 101
		end
	end while true
end

PINS = ARGV.select { |x| x.start_with?(/-(-pins|p)=(\d+,?)*/) }[-1].to_s.split('=')[-1].then { |x| x ? x.to_s.split(',').map(&:to_i) : [7, 8] }

query = ->(p, v) { ARGV.select { |x| x.start_with?(p) }[-1].to_s.split('=')[-1].then { |x| x ? x.to_i : v } }

DELAY = query.(/-(-delay|d)=\d+/, 0.005)
FREQUENCY = query.(/-(-frequency|f)=\d+/, 500)
STEP = query.(/-(step|s)=\d+/, 0.25)

begin
	flash(pins: PINS, sleep: DELAY, step: STEP, freq: FREQUENCY)
rescue Interrupt, SignalException, SystemExit
	puts
	PINS.each(&method(:clean_up))
	exit 0
end

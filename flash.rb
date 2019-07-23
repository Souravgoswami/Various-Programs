#!/usr/bin/ruby -w

if ARGV.any? { |x| x.start_with?(/-(-help|h)/i) }
	puts <<~EOF
		This is a Raspberry Pi program to control lights connected to GPIO.
		This program flashes all the lights (at given pins) sequentially.
		Please make sure the connected light is dimmable.
		LED lights are recommended.
		This program depends on rpi_gpio gem.

		Arguments:
			--help / -h			Print this help message and exit.
			--delay=value / -d=value	Specify the delay time. Where value is the time. [default: 0.005]
			--pins=values / -p=values	Specify the output pins. Where the values are the pin numbers
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

def flash(pins: [7, 8], sleep: 0.5 )
	pins.each { |pin| setup(pin, as: :output) }

	pins.each do |pin|
		setup(pin, as: :output, initialize: :low)
		Kernel.sleep(sleep)
		setup(pin, as: :output, initialize: :high)
	end while true
end

PINS = ARGV.select { |x| x.start_with?(/-(-pins|p)=(\d+,?)*/) }[-1].to_s.split('=')[-1].then { |x| x ? x.to_s.split(',').map(&:to_i) : [7, 8] }

begin
	flash(pins: PINS, sleep: ARGV.select { |x| x.start_with?(/-(-delay|d)=\d+/) }[-1].to_s.split('=')[-1].then { |x| x ? x.to_i : 0.075 })
rescue Interrupt, SignalException, SystemExit
	puts
	PINS.each { |pin| clean_up pin.tap { |p| puts ":: Clearing Pin: #{p}" } }
	exit 0
end

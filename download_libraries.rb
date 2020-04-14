x = <<~EOF
 	libEGL.so 	firmware: Updates for Pi4
	libEGL_static.a 	kernel: Bump to 4.19.114
	libGLESv1_CM.so 	firmware: revert: cmake: mark GLESv2 as so version 2 for consistency ?
	libGLESv2.so 	firmware: Updates for Pi4
	libGLESv2_static.a 	kernel: Bump to 4.19.114
	libOpenVG.so 	kernel: Bump to 4.14.83
	libWFC.so 	firmware: Updates for Pi4
	libbcm_host.so 	kernel: Bump to 4.19.113
	libbrcmEGL.so 	firmware: Updates for Pi4
	libbrcmGLESv2.so 	firmware: Updates for Pi4
	libbrcmOpenVG.so 	kernel: Bump to 4.14.83
	libbrcmWFC.so 	firmware: Updates for Pi4
	libcontainers.so 	kernel: Bump to 4.14.83
	libdebug_sym.so 	kernel: Bump to 4.19.89
	libdebug_sym_static.a 	kernel: Bump to 4.19.114
	libdtovl.so 	kernel: Bump to 4.19.114
	libelftoolchain.so 	kernel: Bump to 4.14.83
	libkhrn_client.a 	kernel: Bump to 4.19.114
	libkhrn_static.a 	kernel: Bump to 4.19.114
	libmmal.so 	kernel: Bump to 4.19.113
	libmmal_components.so 	kernel: Bump to 4.19.113
	libmmal_core.so 	kernel: Bump to 4.19.113
	libmmal_util.so 	kernel: Bump to 4.19.113
	libmmal_vc_client.so 	kernel: Bump to 4.19.113
	libopenmaxil.so 	kernel: Bump to 4.19.113
	libvchiq_arm.so 	kernel: Bump to 4.14.83
	libvchostif.a 	kernel: Bump to 4.19.114
	libvcilcs.a 	kernel: Bump to 4.19.114
	libvcos.so 	kernel: Bump to 4.14.94
	libvcsm.so 	kernel: Bump to 4.19.86
EOF

require 'net/https'
x.each_line do |u|
	x = u.strip.split[0]
	path = File.join(%W(/ usr lib #{x}))
	puts "Writing #{x} to #{path}"
	IO.write(path, Net::HTTP.get(URI("https://raw.githubusercontent.com/raspberrypi/firmware/master/hardfp/opt/vc/lib/#{x}")))
	puts "Changing permission and ownership of #{path} to 0644 and 0"
	File.chmod(0644, path)
	File.new(path).chown(0, 0)
end

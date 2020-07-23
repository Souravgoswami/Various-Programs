#!/usr/bin/ruby -w
require 'chunky_png'
current_time = Time.now

W, H = 1920, 50
PARTICLE_SIZE = proc { rand(1..2) }
PARTICLES = 1500
BG_COLOUR = proc { [0, 0, 0, 0] }
COLOUR = proc { [rand(255), rand(255), rand(255)] }
OUTPUT = File.join(__dir__, 'panel.png')
ANIM_CHARS = ["\xF0\x9F\x95\x90", "\xF0\x9F\x95\x91", "\xF0\x9F\x95\x92", "\xF0\x9F\x95\x93", "\xF0\x9F\x95\x94", "\xF0\x9F\x95\x95", "\xF0\x9F\x95\x96", "\xF0\x9F\x95\x97", "\xF0\x9F\x95\x98", "\xF0\x9F\x95\x99", "\xF0\x9F\x95\x9A", "\xF0\x9F\x95\x9B"]

png = ChunkyPNG::Image.new(W, H, ChunkyPNG::Color::TRANSPARENT)
i, t = -1, Time.now

while (i += 1) < W
	j = -1
	png[i, j] = ChunkyPNG::Color.rgba(*BG_COLOUR.call(i, j)) while (j += 1) < H

	if i % 100 == 0
		el = Time.now.-(t).to_i
		rem = W.*(el)./(i + 1).-(el)
		print " \e[2K#{ANIM_CHARS.rotate![0]} Creating Image | #{i + 1}/#{W} | Elapsed: #{el}s | Rem: #{rem}s\r"
	end
end
print "\e[2K\r"

w_1, h_1 = W - 1, H - 1
t = Time.now

PARTICLES.times do |x|
	particle_size, i = PARTICLE_SIZE.call, -1
	rand_w, rand_h = rand(0..W - 1), rand(0..H - 1)
	colours = COLOUR.call
	transparency = x

	while (i += 1) < particle_size
		j = -1
		w, h = rand_w.-(i).clamp(0, w_1), rand_h.-(j).clamp(0, h_1)

		transparency = h < H.fdiv(3) ? h.fdiv(H).*(340).to_i.clamp(0, 255) : 255
		png[w, h] = ChunkyPNG::Color.rgba(*colours, transparency) while (j += 1) < particle_size
	end

	if x % 10000 == 0
		el = Time.now.-(t).to_i
		rem = PARTICLES.*(el)./(x + 1).-(el)
		print " \e[2K#{ANIM_CHARS.rotate![0]} Adding Particles | #{x + 1}/#{PARTICLES} | Elapsed: #{el}s | Rem: #{rem}s\r"
	end
end

print " \e[2K\xF0\x9F\x92\xBE Saving Image: #{OUTPUT}\r"
png.save(OUTPUT, :interlace => true)

puts "\e[2KTotal Time Taken: #{Time.now.-(current_time).round(3)}s"

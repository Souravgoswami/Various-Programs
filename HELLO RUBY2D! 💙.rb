#!/usr/bin/ruby -w
# Frozen_String_Literal: true
require 'ruby2d'

W, H = 640, 480
set width: W, height: H, fps_cap: 120

pixel_size = 6
y_offset = 200
x_offset = 40
no_of_stars = 500

a = <<~'EOF'
.   . ...... .       .      ......    ......  .    . ......  .     . ...... ......  .     .   .
.   . .      .       .      .    .    .     . .    . .     .  .   .       . .     . .   .   .   .
..... ....   .       .      .    .    ......  .    . ......    . .   ...... .     . .   .       .
.   . .      .       .      .    .    .     . .    . .     .    .    .      .     .       .   .
.   . ...... ......  ...... ......    .     . ...... ......     .    ...... ......  .       .
EOF

m, squares = a.lines.map(&:length).max, []

Ruby2D::Square.attr_accessor :state

a.each_line.with_index do |y, yi|
	y.each_char.with_index do |x, xi|
		squares << Square.new(size: pixel_size, x: rand(W), y: rand(H), color: [1 - xi.to_f / (m * 2), 1 - xi.to_f / m, xi.to_f / m, 1]) if x == ?.
	end
end

stars = no_of_stars.times.map { Square.new(size: 1, x: rand(W), y: rand(H), color: [rand, rand, rand, 1]) }
speeds = stars.map.with_index { |_, i| i / (no_of_stars / 2.0) }

t, flag = Time.now, false

update do
	i = -1
	stars.each { |x| x.y = x.y > 0 - x.size ? x.y - speeds[i += 1] : H }

	i = -1
	if a.lines.map.with_index do |y, yi|
		y.chars.map.with_index { |x, xi| squares[i += 1].then { |s| s.x == x_offset + xi * pixel_size && s.y == y_offset + yi * pixel_size } if x == ?. }.compact
	end.flatten.all?(&:itself)

		tt = Time.now.-(t)

		if tt > 4
			squares.each { |x| x.x, x.y, x.opacity, x.state = x.x + 10, x.y + 10, 1, false }
		elsif tt > 3
			flag ||= true
			squares.each { |x| x.opacity = rand }
		elsif tt > 1
			r = rand
			squares.each { |x| x.opacity = r }
		end
	elsif !flag
		i = -1
		t = Time.now

		a.each_line.with_index do |y, yi|
			y.each_char.with_index do |x, xi|
				if x == ?.
					s = squares[i += 1]

					if s.x > x_offset + xi * pixel_size
						s.x -= 1
					elsif s.x < x_offset + xi * pixel_size
						s.x += 1
					end

					if s.y > y_offset + yi * pixel_size
						s.y -= 1
					elsif s.y < y_offset + yi * pixel_size
						s.y += 1
					end

					s.color = [1 - xi.to_f / (m * 2), 1 - xi.to_f / m, xi.to_f / m, s.opacity]
					s.opacity += 0.01 if s.opacity < 1
				end
			end
		end
	else
		squares.each_with_index do |x, i|
			x.x, x.y, x.opacity = x.x + Math.tan(i) * Math.cos(i), x.y + Math.tan(i) * Math.sin(i), x.opacity - 0.005

			if x.opacity < 0
				x.x = x.x.to_i.then { |z| (z < 0 || z > W) ? rand(W) : z }
				x.y = x.y.to_i.then { |z| (z < 0 || z > H) ? rand(H) : z }
				x.opacity = 0
				x.state ||= true
			end
		end

		flag = false if squares.all?(&:state)
	end
end

Window.show

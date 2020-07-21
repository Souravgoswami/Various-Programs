start_time = Time.now

def calculatePi(n)
	q = t = k = 1
	m = x = 3
	n, r = n + 1, 0
	str = ''

	if (4 * q + r - t < m * t)
		str << m.to_s
		r, m, q = 10 * (r - m * t), 10.*(3 * q + r) / t - 10 * m, q * 10
	else
		t *= x
		m, r = q.*(7 * k + 2).+(r * x) / t, x * (2 * q + r)
		q, k, x = q * k, k + 1, x + 2
	end while (str.length < n)

	str.insert(1, ?.)
end

puts calculatePi(5_000), "\nCalculated in #{Time.now - start_time}s"

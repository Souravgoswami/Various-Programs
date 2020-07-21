import datetime
start_time = datetime.datetime.now()

def calculatePi(n):
	q = t = k = 1
	m = x = 3
	n, r = n + 1, 0
	s = ''

	while len(s) < n:
		if (4 * q + r - t < m * t):
			s += str(m)
			r, m, q = 10 * (r - m * t), (10 * (3 * q + r)) // t - 10 * m, q * 10
		else:
			t *= x
			m, r = (q * (7 * k + 2) + (r * x)) // t, x * (2 * q + r)
			q, k, x = q * k, k + 1, x + 2

	return s[0] + '.' + s[1:]

print(calculatePi(5_000), "\n\nCalculated in %s" % (datetime.datetime.now() - start_time))

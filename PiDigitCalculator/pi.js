function calculatePi(n) {
	var one = BigInt(1), two = BigInt(2), three = BigInt(3), four = BigInt(4)
	var seven = BigInt(7), ten = BigInt(10)
	var q = t = k = one
	var m = x = three
	var n = BigInt(n) + one
	var r = BigInt(0)
	var str = ''

	while (str.length < n) {
		if (four * q + r - t < m * t) {
			str += m

			var rr = r
			r = ten * (r - m * t)
			m = (ten * (three * q + rr)) / t - ten * m
			q *= ten
		}

		else {
			t *= x
			m = (q * (seven * k + two) + (r * x)) / t
			r = ((two * q) + r) * x
			q *= k
			k += one
			x += two
		}
	}

	return(str.slice(0, 1) + '.' + str.slice(1))
}

time = Date.now()
console.log(calculatePi(5000))
console.log(`Calculated in ${(Date.now() - time) / 1000}s`)

# define GB 3

#include <stdio.h>
#include <stdlib.h>

int main() {
	unsigned int n = GB * (1000000000 / 4), *a ;
	long size = sizeof(n) * n ;
	printf(":: This program will create %ld bytes of data to memory\n", size) ;

	for(unsigned int count = 0 ; count < 10 ; ++count) {
		printf(":: %d: Creating Array of length %d", count + 1, n) ;
		fflush(stdout) ;

		a = malloc(n * sizeof(int)) ;

		for(unsigned int i = 0 ; i < n ; ++i) a[i] = i ;

		free(a) ;
		printf("\e[2K\r") ;
	}
}

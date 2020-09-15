/*
	Compilation:
		GCC:
			gcc memory_increase.c -Wall -march=native -mtune=native -finline-functions -funswitch-loops -fno-plt -O3 -o memory_increase
		Clang:
			clang memory_increase.c -Wall -march=native -mtune=native -finline-functions -fno-plt -O3 -o memory_increase

	Execute:
		./memory_increase

	Modify the value of GB to whatever you want to create on system
	Modify ITERATION to change the number of times the GB is created on memory
*/

# define GB 3
# define ITERATION 5

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/sysinfo.h>

int main() {
	struct sysinfo info ;
	sysinfo(&info) ;

	printf(":: Total Memory (RAM): %lu GB\n", info.totalram / 1000000) ;

	if (info.totalram / 1000000 < GB * 1000) {
		printf("\e[1;5;38;2;253;80;104m!! Total System Memory (RAM): %.2lu MB, but the program is said to raise %.2LF MB memory\e[0m\n", info.totalram / 1000000, (long double)GB * 1000) ;
		puts("Press enter to continue, SIGKILL to exit") ;

		if(getc(stdin) != 0x0A) {
			puts("Exiting") ;
			return 0 ;
		}
	}

	unsigned int n = GB * (1000000000 / sizeof(int)) ;
	static unsigned int count, *a, i ;
	long size = sizeof(n) * n ;

	struct timespec tstart = {0, 0}, tend = {0, 0} ;
	static float elap, total_elap ;

	clock_gettime(CLOCK_MONOTONIC, &tstart) ;

	printf("\e[1;5;38;2;253;80;104m:: This program will create %ld bytes of data to memory\e[0m\n", size) ;

	for(count = 0 ; count < ITERATION ; ++count) {
		printf(":: %d: Creating Array of length %d\n", count + 1, n) ;
		fflush(stdout) ;

		a = malloc(n * sizeof(int)) ;

		clock_gettime(CLOCK_MONOTONIC, &tend) ;
		elap = ((double)tend.tv_sec + 1.0e-9 * tend.tv_nsec) - ((double)tstart.tv_sec + 1.0e-9 * tstart.tv_nsec) ;

		for(i = 0 ; i < n ; ++i) a[i] = i ;

		clock_gettime(CLOCK_MONOTONIC, &tend) ;
		total_elap = ((double)tend.tv_sec + 1.0e-9 * tend.tv_nsec) - ((double)tstart.tv_sec + 1.0e-9 * tstart.tv_nsec) ;

		printf("\e[2KTime: %.12fs | Total Time Elapsed: %.12fs %f\n\n", total_elap - elap, total_elap, elap) ;
		fflush(stdout) ;

		free(a) ;
	}
}

#pragma GCC optimize("Ofast")

#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
	char *arg ;
	unsigned int nArg = 1 ;

	#pragma GCC unroll 2
	while((arg = argv[nArg++])) {
		unsigned char counter = 0 ;
		char *str ;

		char *token1 = strtok(arg, ".") ;
		printf("%s", token1) ;
		token1 = strtok(NULL, ".") ;

		#pragma GCC unroll 2
		while(1) {
			str = token1 ;
			token1 = strtok(NULL, ".") ;

			if (!token1) break ;
			printf(".%s", str) ;
			counter++ ;
		}

		puts("") ;
	} ;
}

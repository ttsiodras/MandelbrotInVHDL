#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

#include "mandelVHDL.h"

const unsigned WIDTH = 320;
const unsigned HEIGHT = 240;

int main()
{
    mandelVHDL_init();
    unsigned char *Buffer = (unsigned char *)malloc(WIDTH*HEIGHT);
    for (int i=0; i<3; i++) {
        // Send the window coordinates
        // top-left x,y, and stepx,stepy
        struct timeval Start;
        gettimeofday(&Start, NULL);
        mandelVHDL(Buffer, -2.2 + 0.3*i, -1.1, 1.1, 1.1);
        struct timeval End;
        gettimeofday(&End, NULL);

        // Helper function used to report time taken to execute.
        auto timeTakenInMS = [&Start, &End]() {
            unsigned long long uSecStart =
                (unsigned long long)Start.tv_sec*1000000ull +
                (unsigned long long)Start.tv_usec;
            unsigned long long uSecEnd =
                (unsigned long long)End.tv_sec*1000000ull +
                (unsigned long long)End.tv_usec;
            return (uSecEnd - uSecStart)/1000;
        };
        printf("[-] Frame computed and transferred over (took %lld ms)\n", timeTakenInMS());
    }

    FILE *fp = fopen("mandel.pgm", "w");
    fprintf(fp, "P5\n%u %u\n255\n", WIDTH, HEIGHT);
    fwrite(Buffer, 1, WIDTH*HEIGHT, fp);
    fclose(fp);
    free(Buffer);

    puts("[-] Releasing FPGA resources...");
    mandelVHDL_shutdown();

    puts("[-] Done.");
    return 0;
}

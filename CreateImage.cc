#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

#include "ZestSC1.h"

const unsigned WIDTH = 640;
const unsigned HEIGHT = 480;
const unsigned FRACTIONAL_PART = 27;

const double SCALE_FACTOR = ((double)(1<<FRACTIONAL_PART));

double to_double(int x)
{
    return ((double)x)/SCALE_FACTOR;
}

void ErrorHandler(const char *Function, ZESTSC1_HANDLE Handle,
                  ZESTSC1_STATUS Status, const char *Msg)
{
    printf(
        "**** FPGAMandel - Function %s returned an error\n        \"%s\"\n\n",
        Function, Msg);
    exit(1);
}

int main(int argc, char **argv)
{
    unsigned long Count;
    unsigned long NumCards;
    unsigned long CardIDs[256];
    unsigned long SerialNumbers[256];
    ZESTSC1_FPGA_TYPE FPGATypes[256];
    ZESTSC1_HANDLE Handle;
    unsigned char Result;

    ZestSC1RegisterErrorHandler(ErrorHandler);
    ZestSC1CountCards(&NumCards, CardIDs, SerialNumbers, FPGATypes);
    printf("[-] %d available FPGA board detected\n", NumCards);
    if (NumCards==0) {
        printf("[*] No FPGA boards in the system\n");
        exit(1);
    }
    for (Count=0; Count<NumCards; Count++) {
        printf("[-] Card %d : CardID = 0x%08lx, SerialNum = 0x%08lx\n",
            Count, CardIDs[Count], SerialNumbers[Count]);
    }
    ZestSC1OpenCard(CardIDs[0], &Handle);
    ZestSC1ConfigureFromFile(Handle, (char *)"FPGA-VHDL/Example3.bit");

    auto WriteDouble = [&Handle](
            double input, unsigned offset, bool debugPrint=false)
    {
        int inputFixed = (int)(input*SCALE_FACTOR);
        if (debugPrint)
            printf("0x%04x: %08x\n", offset, inputFixed);
        ZestSC1WriteRegister(Handle, offset,   (inputFixed>>0)  & 0xFF);
        ZestSC1WriteRegister(Handle, offset+1, (inputFixed>>8)  & 0xFF);
        ZestSC1WriteRegister(Handle, offset+2, (inputFixed>>16) & 0xFF);
        ZestSC1WriteRegister(Handle, offset+3, (inputFixed>>24) & 0xFF);
    };

    auto ReadNBytes = [&Handle](
            unsigned offset, unsigned bytes, bool debugPrint=false)
    {
        unsigned result = 0;
        for(; bytes!=0; bytes--) {
            unsigned char ub;
            ZestSC1ReadRegister(Handle, offset+bytes-1, &ub);
            result <<= 8; result |= ub;
            if (debugPrint)
                printf("0x%04x: %02x\n", offset+bytes-1, (unsigned)ub);
        }
        return result;
    };

    auto WriteU8 = [&Handle](
            unsigned offset, unsigned char data, bool debugPrint=false)
    {
        ZestSC1WriteRegister(Handle, offset, data);
        if (debugPrint)
            printf("W:0x%04x: %02x\n", offset, (unsigned)data);
    };

    for (int i=0; i<3; i++) {
        FILE *fp = fopen("mandel.pgm", "w");
        fprintf(fp, "P5\n%u %u\n255\n", WIDTH, HEIGHT);

        double inputX = -2.2 + 0.3*i;
        double inputY = 1.1;

        WriteDouble(inputX, 0x2060);
        WriteDouble(inputY, 0x2064);
        WriteDouble(3.3/WIDTH, 0x2068);
        WriteDouble(2.2/HEIGHT, 0x206C);

        struct timeval Start;
        unsigned output = 1, oldOutput = 0xFFFFFFFF;
        printf("[-] Remaining scanlines:         ");
        gettimeofday(&Start, NULL);
        while(1) {
            output = ReadNBytes(0x2004, 4);
            if (output == 0x55555555)
                break;
            if (oldOutput > output) {
                oldOutput = output;
                printf("\b\b\b\b\b\b\b%03d/%u", output, HEIGHT);
                fflush(stdout);
            }
        }
        struct timeval End;
        gettimeofday(&End, NULL);
        printf("\b\b\b\b\b\b\b%03d/%u", 0, HEIGHT);

        auto timeTakenInMS = [&Start, &End]() {
            unsigned long long uSecStart =
                (unsigned long long)Start.tv_sec*1000000ull +
                (unsigned long long)Start.tv_usec;
            unsigned long long uSecEnd =
                (unsigned long long)End.tv_sec*1000000ull +
                (unsigned long long)End.tv_usec;
            return (uSecEnd - uSecStart)/1000;
        };
        printf("\n[-] Frame computed (took %lld ms)\n", timeTakenInMS());

        // output = ReadNBytes(0x2000, 4, false);
        // cout << "input_x: " << to_double(output) << "\n\n";
        // auto debug1 = [&ReadNBytes]() { printf("debug1: 0x%08x\n", ReadNBytes(0x2000, 4)); };
        // auto debug2 = [&ReadNBytes]() { printf("debug2: 0x%08x\n", ReadNBytes(0x2004, 4)); };

        puts("[-] Dumping frame over USB...");
        void *Buffer = malloc(WIDTH*HEIGHT);
        WriteU8(0x2080, 1);
        gettimeofday(&Start, NULL);
        ZestSC1ReadData(Handle, Buffer, WIDTH*HEIGHT);
        gettimeofday(&End, NULL);
        printf("[-] Frame sent over USB (took %lld ms)\n", timeTakenInMS());
        fwrite(Buffer, 1, WIDTH*HEIGHT, fp);
        fclose(fp);
        free(Buffer);
    }

    puts("[-] Releasing FPGA resources...");
    ZestSC1CloseCard(Handle);

    puts("[-] Done.");
    return 0;
}

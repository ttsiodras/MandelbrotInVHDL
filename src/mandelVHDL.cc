#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ZestSC1.h"

const unsigned WIDTH = 320;
const unsigned HEIGHT = 240;
const unsigned FRACTIONAL_PART = 27;

const double SCALE_FACTOR = ((double)(1<<FRACTIONAL_PART));

ZESTSC1_HANDLE Handle;

// A few helper functions

// Provide fixed-point inputs
void WriteDouble(double input, unsigned offset, bool debugPrint=false)
{
    int inputFixed = (int)(input*SCALE_FACTOR);
    if (debugPrint)
        printf("0x%04x: %08x\n", offset, inputFixed);
    ZestSC1WriteRegister(Handle, offset,   (inputFixed>>0)  & 0xFF);
    ZestSC1WriteRegister(Handle, offset+1, (inputFixed>>8)  & 0xFF);
    ZestSC1WriteRegister(Handle, offset+2, (inputFixed>>16) & 0xFF);
    ZestSC1WriteRegister(Handle, offset+3, (inputFixed>>24) & 0xFF);
}

// Read 32-bit outputs
unsigned ReadNBytes(unsigned offset, unsigned bytes, bool debugPrint=false)
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
}

// Write 8-bit input (used to trigger the DMA-reading of the framebuffer)
void WriteU8(unsigned offset, unsigned char data, bool debugPrint=false)
{
    ZestSC1WriteRegister(Handle, offset, data);
    if (debugPrint)
        printf("W:0x%04x: %02x\n", offset, (unsigned)data);
}

double to_double(int x)
{
    return ((double)x)/SCALE_FACTOR;
}

void ErrorHandler(const char *Function, ZESTSC1_HANDLE, ZESTSC1_STATUS, const char *Msg)
{
    printf(
        "**** FPGAMandel - Function %s returned an error\n        \"%s\"\n\n",
        Function, Msg);
    exit(1);
}

void mandelVHDL_init()
{
    unsigned long Count;
    unsigned long NumCards;
    unsigned long CardIDs[256];
    unsigned long SerialNumbers[256];
    ZESTSC1_FPGA_TYPE FPGATypes[256];

    ZestSC1RegisterErrorHandler(ErrorHandler);
    ZestSC1CountCards(&NumCards, CardIDs, SerialNumbers, FPGATypes);
    printf("[-] %ld available FPGA board detected\n", NumCards);
    if (NumCards==0) {
        printf("[*] No FPGA boards in the system\n");
        exit(1);
    }
    for (Count=0; Count<NumCards; Count++) {
        printf("[-] Card %ld : CardID = 0x%08lx, SerialNum = 0x%08lx\n",
            Count, CardIDs[Count], SerialNumbers[Count]);
    }
    ZestSC1OpenCard(CardIDs[0], &Handle);
    ZestSC1ConfigureFromFile(Handle, (char *)"../FPGA-VHDL/Example3.bit");
}

void mandelVHDL(unsigned char *framebuffer, double xld, double yld, double xru, double yru)
{
    // Send the window coordinates
    // top-left x,y, and stepx,stepy
    WriteDouble(xld, 0x2060);
    WriteDouble(yru, 0x2064);
    WriteDouble((xru-xld)/WIDTH,  0x2068);
    WriteDouble((yru-yld)/HEIGHT, 0x206C);

    // Wait until the FPGA reports all scanlines computed
    while(ReadNBytes(0x2004, 4) != 0x55555555);

    // Get the frame data
    WriteU8(0x2080, 1);
    ZestSC1ReadData(Handle, framebuffer, WIDTH*HEIGHT);
}

void mandelVHDL_shutdown()
{
    ZestSC1CloseCard(Handle);
}

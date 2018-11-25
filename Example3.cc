//////////////////////////////////////////////////////////////////////
//
// File:      Example3.c
//
// Purpose:
//    ZestSC1 Example Programs
//    Low speed data transfer example
//  
// Copyright (c) 2004-2006 Orange Tree Technologies.
// May not be reproduced without permission.
//
//////////////////////////////////////////////////////////////////////

#include <iostream>
#include <iomanip>

#include <unistd.h>

#include "ZestSC1.h"

using std::cout, std::endl, std::setw;

const unsigned FRACTIONAL_PART = 27;
const double SCALE_FACTOR = ((double)(1<<FRACTIONAL_PART));

double to_double(int x)
{
    return ((double)x)/SCALE_FACTOR;
}

//
// Error handler function
//
void ErrorHandler(const char *Function, 
                  ZESTSC1_HANDLE Handle,
                  ZESTSC1_STATUS Status,
                  const char *Msg)
{
    printf("**** Example3 - Function %s returned an error\n        \"%s\"\n\n", Function, Msg);
    exit(1);
}

//
// Main program
//

ZESTSC1_HANDLE Handle;
unsigned char Result;

int main(int argc, char **argv)
{
    unsigned long Count;
    unsigned long NumCards;
    unsigned long CardIDs[256];
    unsigned long SerialNumbers[256];
    ZESTSC1_FPGA_TYPE FPGATypes[256];

    //
    // Install an error handler
    //
    ZestSC1RegisterErrorHandler(ErrorHandler);

    //
    // Request information about the system
    //
    ZestSC1CountCards(&NumCards, CardIDs, SerialNumbers, FPGATypes);
    printf("[-] %d available cards in the system\n", NumCards);
    if (NumCards==0)
    {
        printf("[*] No cards in the system\n");
        exit(1);
    }

    for (Count=0; Count<NumCards; Count++)
    {
        printf("[-] Card %d : CardID = 0x%08lx, SerialNum = 0x%08lx, FPGAType = %d\n",
            Count, CardIDs[Count], SerialNumbers[Count], FPGATypes[Count]);
    }

    //
    // Open the first card
    // Then set 4 signals as outputs and 4 signals as inputs
    //
    ZestSC1OpenCard(CardIDs[0], &Handle);

    //
    // Configure the FPGA
    //
    ZestSC1ConfigureFromFile(Handle, (char *)"FPGA-VHDL/Example3.bit");
    ZestSC1SetSignalDirection(Handle, 0xf);

    // Helper functions
    auto SendParam = [](double input, unsigned offset, bool debugPrint=false) {
        unsigned inputFixed = (unsigned)(input*SCALE_FACTOR);
        if (debugPrint)
            printf("0x%04x: %08x\n", offset, inputFixed);
        ZestSC1WriteRegister(Handle, offset,   (inputFixed>>0)  & 0xFF);
        ZestSC1WriteRegister(Handle, offset+1, (inputFixed>>8)  & 0xFF);
        ZestSC1WriteRegister(Handle, offset+2, (inputFixed>>16) & 0xFF);
        ZestSC1WriteRegister(Handle, offset+3, (inputFixed>>24) & 0xFF);
    };

    auto GetResult = [](unsigned offset, unsigned bytes, bool debugPrint=false) {
        unsigned result = 0;
        for(; bytes!=0; bytes--) {
            unsigned char ub;
            ZestSC1ReadRegister(Handle, 0x2000+offset+bytes-1, &ub);
            result <<= 8; result |= ub;
            if (debugPrint)
                printf("0x%04x: %02x\n", 0x2000+offset+bytes-1, (unsigned)ub);
        }
        return result;
    };

    auto Read = [](unsigned offset, bool debugPrint=false) {
        unsigned char ub;
        ZestSC1ReadRegister(Handle, offset, &ub);
        if (debugPrint)
            printf("R:0x%08x: %02x\n", offset, (unsigned)ub);
        return ub;
    };
    auto Write = [](unsigned offset, unsigned char data, bool debugPrint=false) {
        ZestSC1WriteRegister(Handle, offset, data);
        if (debugPrint)
            printf("W:0x%04x: %02x\n", offset, (unsigned)data);
    };

    double inputX = 0.4099999999999997;
    double inputY = -0.21500000000000008; // => 112

    // double inputX = 0.4399999999999995;
    // double inputY = 0.24999999999999978; // => 16

    GetResult(4, 4, true);
    SendParam(inputX, 0x2060);
    GetResult(4, 4, true);
    SendParam(inputY, 0x2064);
    GetResult(4, 4, true);

    puts("[-] Waiting for pixel line to be computed...");
    unsigned output = 1;
    do {
        output = GetResult(4, 4, true);
    } while(output != 0x99999999);

    output = GetResult(0, 4, false);
    cout << "input_x: " << to_double(output) << "\n\n";

    auto debug1 = [&GetResult]() { printf("debug1: 0x%08x\n", GetResult(0, 4)); };
    auto debug2 = [&GetResult]() { printf("debug2: 0x%08x\n", GetResult(4, 4)); };

    for(int i=0; i<64; i++) {
        Write(0x207E, (unsigned char)i);
        printf("At SRAM[%d]: %04x\n", i, GetResult(0x10, 4));
    }

    //
    // Close the card
    //
    ZestSC1CloseCard(Handle);

    return 0;
}

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
    printf("%d available cards in the system\n\n\n", NumCards);
    if (NumCards==0)
    {
        printf("No cards in the system\n");
        exit(1);
    }

    for (Count=0; Count<NumCards; Count++)
    {
        printf("%d : CardID = 0x%08lx, SerialNum = 0x%08lx, FPGAType = %d\n",
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
            printf("0x%04x: %08x\n", 0x207B+offset, inputFixed);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>24) & 0xFF);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>16) & 0xFF);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>8) & 0xFF);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>0) & 0xFF);
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
            printf("W:0x%08x: %02x\n", offset, (unsigned)data);
    };

    if (argc > 1) {
        double inputX = 0.4099999999999997;
        double inputY = -0.21500000000000008; // => 111

        for(int i=0; i<100; i++) {
            if (i&1) {
                inputX = 0.4099999999999997;
                inputY = -0.21500000000000008; // => 111
            } else {
                inputX = 0.4399999999999995;
                inputY = 0.24999999999999978; // => 15
            }
            SendParam(inputX, 0);
            SendParam(inputY, 1);
            unsigned output = GetResult(0x7c, 1);
            printf("%d\n", output);

            // unsigned magnitude = GetResult(8, 4, true);
            // cout << "Magnitude: " << to_double(magnitude) << "\n\n";
        }
    } else {
        puts("Verifying 256 write/reads...");
        for(int i=0; i<100; i++) {
            putchar('.');
            //Write(0x2080, 0x00);
            //Read(0x2004);
            Write(0x207D, i);
            //Read(0x2004);
            Write(0x207E, 0xFF);
            auto rd = Read(0x207D);
            if (rd != i) {
                puts("\nFailed...");
            }
        }
    }

    //
    // Close the card
    //
    ZestSC1CloseCard(Handle);

    return 0;
}

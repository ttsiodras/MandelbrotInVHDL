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
    auto SendParam = [](double input, unsigned offset) {
        unsigned inputFixed = (unsigned)(input*SCALE_FACTOR);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>24) & 0xFF);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>16) & 0xFF);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>8) & 0xFF);
        ZestSC1WriteRegister(Handle, 0x207B+offset, (inputFixed>>0) & 0xFF);
    };

    auto GetResult = [](unsigned offset, bool debugPrint=false) {
        unsigned result = 0;
        for(auto byteIdx=3; byteIdx!=-1; byteIdx--) {
            unsigned char ub;
            ZestSC1ReadRegister(Handle, 0x207c+offset+byteIdx, &ub);
            result <<= 8; result |= ub;
            if (debugPrint)
                printf("0x%04x: %02x\n", 0x207c+(unsigned)byteIdx, (unsigned)ub);
        }
        return result;
    };

    for(int i=0; i<25; i++) {
        double input = 0.1 * i;
        SendParam(input, 0);
        SendParam(input, 1);
        unsigned output = GetResult(0);

        cout << "Sent in: " << setw(10) << input;
        cout << ", got out: " << setw(10) << to_double(output);
        cout << " (expected: " << setw(10) << 3.14159*input*input;
        cout << ")" << endl;
    }

    //
    // Close the card
    //
    ZestSC1CloseCard(Handle);

    return 0;
}

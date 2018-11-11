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

#include <stdio.h>
#include <stdlib.h>
#include "ZestSC1.h"

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

void printByteAt(unsigned byteIdx)
{
    unsigned char res;
    ZestSC1ReadRegister(Handle, 0x2000+0x7c+byteIdx, &res);
    printf("0x%04x: %02x\n", 0x207c+(unsigned)byteIdx, (unsigned)res);
}

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
    ZestSC1ConfigureFromFile(Handle, "FPGA-VHDL/Example3.bit");
    ZestSC1SetSignalDirection(Handle, 0xf);

    //for(int i=0; i<10; i++) {
        ZestSC1WriteRegister(Handle, 0x2000+123, 0x01);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0x23);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0x45);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0x67);
        printByteAt(3);
        printByteAt(2);
        printByteAt(1);
        printByteAt(0);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0x89);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0xAB);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0xCD);
        ZestSC1WriteRegister(Handle, 0x2000+123, 0xEF);
        printByteAt(3);
        printByteAt(2);
        printByteAt(1);
        printByteAt(0);

        // printf("...and computed: 0x%08x\n", res);
    //}

    //
    // Close the card
    //
    ZestSC1CloseCard(Handle);

    return 0;
}

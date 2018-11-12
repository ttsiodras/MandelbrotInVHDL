
TARGET = ../example3
LDFLAGS = -L../../Lib
LIBS = -lusb -lZestSC1
OBJS = Example3.o
CC = gcc
CFLAGS = -O2 -I../../Inc
LD = gcc
BITFILE := FPGA-VHDL/Example3.bit

all: $(TARGET)

clean:
	rm $(TARGET)
	rm $(OBJS)
	
$(TARGET): $(OBJS) ../../Lib/libZestSC1.a $(BITFILE)
	$(LD) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LIBS)

${BITFILE}:	FPGA-VHDL/Example3.vhd
	cd FPGA-VHDL/ && xtclsh Example3.tcl   rebuild_project

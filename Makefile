TARGET = ../example3
LDFLAGS = -L../../Lib
LIBS = -lusb -lZestSC1
OBJS = Example3.o
CXXFLAGS = -g -I../../Inc -std=c++17
BITFILE := FPGA-VHDL/Example3.bit

all: $(TARGET) $(BITFILE)

clean:
	rm $(TARGET)
	rm $(OBJS)
	
$(TARGET): $(OBJS) ../../Lib/libZestSC1.a
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LIBS) -lstdc++

${BITFILE}:	FPGA-VHDL/Example3.vhd FPGA-VHDL/MyTypes.vhd FPGA-VHDL/Example3.tcl
	cd FPGA-VHDL/ && xtclsh Example3.tcl   rebuild_project

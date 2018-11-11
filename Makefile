
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
	cd FPGA-VHDL/ && xst -intstyle ise -ifn "/home/ttsiod/Xilinx/ZestSC1/Examples/Primes/FPGA-VHDL/Example3.xst" -ofn "/home/ttsiod/Xilinx/ZestSC1/Examples/Primes/FPGA-VHDL/Example3.syr" || exit 1
	cd FPGA-VHDL/ && ngdbuild -intstyle ise -dd _ngo -sd ipcore_dir -aul -nt timestamp -uc /home/ttsiod/Xilinx/ZestSC1/UCF/ZestSC1.ucf -p xc3s1000-ft256-5 Example3.ngc Example3.ngd  || exit 1
	cd FPGA-VHDL/ && map -intstyle ise -p xc3s1000-ft256-5 -cm area -ir off -pr b -c 100 -o Example3_map.ncd Example3.ngd Example3.pcf || exit 1
	cd FPGA-VHDL/ && par -w -intstyle ise -ol high -t 1 Example3_map.ncd Example3.ncd Example3.pcf || exit 1
	cd FPGA-VHDL/ && trce -intstyle ise -e 3 -s 5 -n 3 -xml Example3.twx Example3.ncd -o Example3.twr Example3.pcf || exit 1
	cd FPGA-VHDL/ && bitgen -intstyle ise -f Example3.ut Example3.ncd || exit 1


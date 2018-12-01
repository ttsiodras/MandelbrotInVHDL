LDFLAGS = -L../../Lib -m32 -L ../../linux/Lib/ -lZestSC1 /usr/lib32/libusb-0.1.so.4.4.4 -lSDL
OBJS = CreateImage.o GUI.o mandelVHDL.o
CXXFLAGS = -g -I../../Inc -I /usr/include/SDL -std=c++17 -m32 -Wall -Wextra
BITFILE := FPGA-VHDL/Example3.bit

all: ${BITFILE}

%.o:	%.cc
	${CC} -c ${CXXFLAGS} -o $@ $<

CreateImage: CreateImage.o mandelVHDL.o
	${CXX} -o $@ $^ ${LDFLAGS}

Zoomer:	GUI.o mandelVHDL.o
	${CXX} -o $@ $^ ${LDFLAGS}

${BITFILE}:	FPGA-VHDL/Example3.vhd FPGA-VHDL/MyTypes.vhd FPGA-VHDL/Example3.tcl
	cd FPGA-VHDL/ && xtclsh Example3.tcl rebuild_project
	@grep met FPGA-VHDL/Example3.par
	@grep "All constraints were met." FPGA-VHDL/Example3.twr >/dev/null || exit 1
	@grep "All constraints were met." FPGA-VHDL/Example3.par >/dev/null || exit 1

test:	CreateImage ${BITFILE}
	@sudo ./CreateImage && feh mandel.pgm

clean:
	rm -f CreateImage Zoomer *.o mandel.pgm

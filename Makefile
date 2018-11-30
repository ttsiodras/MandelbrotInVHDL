TARGET = CreateImage
LDFLAGS = -L../../Lib -m32 -L ../../linux/Lib/ -lZestSC1 /usr/lib32/libusb-0.1.so.4.4.4
OBJS = CreateImage.o
CXXFLAGS = -g -O2 -I../../Inc -std=c++17 -m32
BITFILE := FPGA-VHDL/Example3.bit

all: ${TARGET} ${BITFILE}

%.o:	%.cc
	${CC} -c ${CXXFLAGS} -o $@ $<

${TARGET}: ${OBJS}
	${CXX} -o $@ $^ ${LDFLAGS}

${BITFILE}:	FPGA-VHDL/Example3.vhd FPGA-VHDL/MyTypes.vhd FPGA-VHDL/Example3.tcl
	cd FPGA-VHDL/ && xtclsh Example3.tcl rebuild_project
	@grep met FPGA-VHDL/Example3.par
	@grep "All constraints were met." FPGA-VHDL/Example3.twr >/dev/null || exit 1
	@grep "All constraints were met." FPGA-VHDL/Example3.par >/dev/null || exit 1

test:	${TARGET} ${BITFILE}
	@sudo ./${TARGET} && feh mandel.pgm

clean:
	rm -f ${TARGET} ${OBJS}

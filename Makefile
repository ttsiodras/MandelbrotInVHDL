TARGET = ../example3
LDFLAGS = -L../../Lib
LIBS = -lusb -lZestSC1
OBJS = Example3.o
CXXFLAGS = -g -O2 -I../../Inc -std=c++17
BITFILE := FPGA-VHDL/Example3.bit

all: ${TARGET} ${BITFILE}

clean:
	rm ${TARGET}
	rm ${OBJS}

%.o:	%.cc
	${CC} -c -o $@ ${CXXFLAGS} $^

${TARGET}: ${OBJS} ../../Lib/libZestSC1.a
	${CC} ${LDFLAGS} -o $@ $^ ${LIBS} -lstdc++

CreateImage: CreateImage.o ../../Lib/libZestSC1.a
	${CC} ${LDFLAGS} -o $@ $^ ${LIBS} -lstdc++

${BITFILE}:	FPGA-VHDL/Example3.vhd FPGA-VHDL/MyTypes.vhd FPGA-VHDL/Example3.tcl
	cd FPGA-VHDL/ && xtclsh Example3.tcl   rebuild_project
	@grep met FPGA-VHDL/Example3.par
	@grep "All constraints were met." FPGA-VHDL/Example3.twr >/dev/null || exit 1
	@grep "All constraints were met." FPGA-VHDL/Example3.par >/dev/null || exit 1

test:	${BITFILE} ${TARGET}
	@echo
	@sudo ${TARGET}
	@echo
	@sudo ${TARGET} fractal

picture:	CreateImage
	@sudo ./$<
	@feh mandel.pgm

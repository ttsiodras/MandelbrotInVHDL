PRJ_ROOT:=$(abspath $(lastword $(MAKEFILE_LIST)))
ZESTSC1:=${HOME}/Xilinx/ZestSC1

CC:=gcc
LDFLAGS = -m32 -L${ZESTSC1}/Lib -m32 -L${ZESTSC1}/linux/Lib/ -lZestSC1 /usr/lib32/libusb-0.1.so.4.4.4 -lSDL /usr/lib32/libSDL_gfx.so.5
OBJS = CreateImage.o GUI.o mandelVHDL.o
CXXFLAGS = -g -I ${ZESTSC1}/Inc/ -I /usr/include/SDL -std=c++17 -m32 -Wall -Wextra

all:	CreateImage Zoomer

%.o:	%.cc
	${CC} -c ${CXXFLAGS} -o $@ $<

CreateImage: CreateImage.o mandelVHDL.o
	${CXX} -o $@ $^ ${LDFLAGS}

Zoomer:	GUI.o mandelVHDL.o
	${CXX} -o $@ $^ ${LDFLAGS}

test:	CreateImage
	$(MAKE) -C ../FPGA-VHDL
	@sudo ./CreateImage && feh mandel.pgm

clean:
	rm -f CreateImage Zoomer *.o mandel.pgm

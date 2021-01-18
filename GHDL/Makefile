.PHONY:	all compile test waves

export GHDL_BACKEND=llvm

SRC:=                 \
    src/mytypes.vhdl  \
    src/mandel.vhdl   \
    tb/mandel_tb.vhdl
TB:=mandel_tb
GHDL_COMPILE_OPTIONS=--ieee=synopsys --workdir=work --std=08
GHDL_RUN_OPTIONS=--stop-time=5ms

V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif

all:	compile

compile:	.built

.built:	${SRC}
	$(Q)mkdir -p work
	@echo "[-] Analysing files... "
	@bash -c 'for i in ${SRC} ; do echo -e "\t$$i" ; done'
	$(Q)ghdl -a ${GHDL_COMPILE_OPTIONS} ${SRC}
	@echo "[-] Elaborating test bench..."
	$(Q)ghdl -e ${GHDL_COMPILE_OPTIONS} ${TB}
	@touch $@

test:	compile
	@echo "[-] Running ${TB} unit..."
	$(Q)ghdl -r ${GHDL_COMPILE_OPTIONS} ${TB} ${GHDL_RUN_OPTIONS} || { \
	    echo "[x] Failure. Aborting..." ; \
	    exit 1 ; \
	}
	$(Q)echo "[-] All tests passed."
	$(Q)echo "[-] To do GTKWAVE plotting, \"make waves\""

waves:	compile
	$(Q)mkdir -p simulation
	$(Q)ghdl -r ${GHDL_COMPILE_OPTIONS} ${TB} ${GHDL_RUN_OPTIONS} --vcdgz=simulation/mandel.vcd.gz || { \
	    echo "[x] Failure. Aborting..." ; \
	    exit 1 ; \
       	}
	$(Q)zcat simulation/mandel.vcd.gz | gtkwave --vcd

clean:
	$(Q)rm -rf work-obj93.cf work/ *.o ${TB} simulation/ .built

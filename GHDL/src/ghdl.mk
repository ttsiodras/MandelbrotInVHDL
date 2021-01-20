export GHDL_BACKEND=llvm

TB:=mandel_tb
SRC:=                            \
    ${ROOT_DIR}src/mytypes.vhdl  \
    ${ROOT_DIR}src/mandel.vhdl   \
    ${ROOT_DIR}tb/mandel_tb.vhdl

GHDL_COMPILE_OPTIONS=--ieee=synopsys --workdir=work --std=08
GHDL_RUN_OPTIONS=--stop-time=5ms

compile:	.built

.built:	${SRC}
	$(Q)mkdir -p work
	@echo "[GHDL] Analysing files... "
	@bash -c 'for i in ${SRC} ; do echo -e "\t$$i" ; done'
	$(Q)ghdl -a ${GHDL_COMPILE_OPTIONS} ${SRC}
	@echo "[GHDL] Elaborating test bench..."
	$(Q)ghdl -e ${GHDL_COMPILE_OPTIONS} ${TB}
	@touch $@
	@echo "[-] Now issue 'make test' to run the testbench."

test:	compile
	@echo "[GHDL] Running ${TB} unit..."
	$(Q)ghdl -r ${GHDL_COMPILE_OPTIONS} ${TB} ${GHDL_RUN_OPTIONS} || { \
	    echo "[x] Failure. Aborting..." ; \
	    exit 1 ; \
	}
	$(Q)echo "[GHDL] All tests passed."
	$(Q)echo "[-] To do GTKWAVE plotting, \"make waves\""

waves:	compile
	$(Q)mkdir -p simulation
	$(Q)ghdl -r ${GHDL_COMPILE_OPTIONS} ${TB} ${GHDL_RUN_OPTIONS} --vcdgz=simulation/mandel.vcd.gz || { \
	    echo "[GHDL] Failure. Aborting..." ; \
	    exit 1 ; \
       	}
	$(Q)zcat simulation/mandel.vcd.gz | gtkwave --vcd

CLEAN+=work-obj93.cf work/ *.o ${TB} simulation/ .built

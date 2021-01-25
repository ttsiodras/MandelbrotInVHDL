export GHDL_BACKEND=llvm

TB:=mandel_tb
AUTOGEN:=${ROOT_DIR}tb/test_data.vhdl
# SRC_TB=${AUTOGEN} ${ROOT_DIR}tb/mandel_tb.vhdl
SRC_TB=${ROOT_DIR}tb/mandel_tb.vhdl

${AUTOGEN}:	${ROOT_DIR}tb/test_data.vhdl.template  ${ROOT_DIR}tb/paste.py ${MANDEL_RESULTS}
	$(Q)rm -f $@
	@echo "[MERGING SAMPLES IN TB] ${AUTOGEN}"
	$(Q)cd tb ; ./paste.py
	$(Q)chmod 444 ${AUTOGEN}

compileTB:	.builtTB

.builtTB:	${SRC_TB} .built
	$(Q)mkdir -p work
	@echo "[GHDL] Analysing TB files... "
	@bash -c 'for i in ${SRC_TB} ; do echo -e "\t$$i" ; done'
	$(Q)ghdl -a ${GHDL_COMPILE_OPTIONS} ${SRC_TB}
	@echo "[GHDL] Elaborating test bench..."
	$(Q)ghdl -e ${GHDL_COMPILE_OPTIONS} ${TB}
	@touch $@

test:	compileTB
	@echo "[GHDL] Running ${TB} unit..."
	$(Q)ghdl -r ${GHDL_COMPILE_OPTIONS} ${TB} ${GHDL_RUN_OPTIONS} || { \
	    echo "[x] Failure. Aborting..." ; \
	    exit 1 ; \
	}
	$(Q)echo "[GHDL] All tests passed."
	$(Q)echo "[-] To do GTKWAVE plotting, \"make waves\""

waves:	compileTB
	$(Q)mkdir -p simulation
	$(Q)ghdl -r ${GHDL_COMPILE_OPTIONS} ${TB} ${GHDL_RUN_OPTIONS} --vcdgz=simulation/mandel.vcd.gz || exit 0
	$(Q)test -f simulation/mandel.vcd.gz && ( zcat simulation/mandel.vcd.gz | gtkwave --vcd )

CLEAN+=${AUTOGEN} ${TB} simulation/ .builtTB

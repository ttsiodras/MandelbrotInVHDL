export GHDL_BACKEND=llvm

SRC=\
    ${ROOT_DIR}src/custom_fixed_point_types.vhdl \
    ${ROOT_DIR}src/pipeline_types.vhdl \
    ${ROOT_DIR}tb/test_data.vhdl \
    ${ROOT_DIR}src/mandelbrot.vhdl

compile:	.built

.built:	${SRC}
	$(Q)mkdir -p work
	@echo "[GHDL] Analysing files... "
	@bash -c 'for i in ${SRC} ; do echo -e "\t$$i" ; done'
	$(Q)ghdl -a ${GHDL_COMPILE_OPTIONS} ${SRC}
	@touch $@
	@echo "[-] Now issue 'make test' to run the testbench."

CLEAN+=work-obj93.cf work/ *.o .built

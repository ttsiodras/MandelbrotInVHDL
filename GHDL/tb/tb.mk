AUTOGEN:=${ROOT_DIR}tb/${TB}.vhdl

${AUTOGEN}:	${ROOT_DIR}tb/mandel_tb.vhdl.template  ${ROOT_DIR}tb/paste.py ${MANDEL_RESULTS}
	$(Q)rm -f $@
	@echo "[MERGING SAMPLES IN TB] ${AUTOGEN}"
	$(Q)cd tb ; ./paste.py
	$(Q)chmod 444 ${AUTOGEN}

CLEAN+=${AUTOGEN}

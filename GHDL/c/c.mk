GENEXE:=${ROOT_DIR}c/mandel
MANDEL_RESULTS:=${ROOT_DIR}c/tests.adb

${GENEXE}:	${ROOT_DIR}c/mandel.c ${ROOT_DIR}c/c.mk
	@echo "[CC] $<"
	$(Q)gcc -o $@ $<

${MANDEL_RESULTS}:	${GENEXE}
	@echo "[MANDELBROT SAMPLES] Generating into $@ ..."
	$(Q)${GENEXE} > $@ 2>/dev/null

CLEAN+=${GENEXE} ${MANDEL_RESULTS}

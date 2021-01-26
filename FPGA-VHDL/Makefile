BITFILE := Example3.bit

all: ${BITFILE}

${BITFILE}:	Example3.vhd MyTypes.vhd pipeline_types.vhd Mandelbrot.vhd Example3.tcl
	xtclsh Example3.tcl rebuild_project
	@grep met Example3.par
	@grep "All constraints were met." Example3.twr >/dev/null || exit 1
	@grep "All constraints were met." Example3.par >/dev/null || exit 1

clean:
	rm -rf ${BITFILE} $$(cat .gitignore)

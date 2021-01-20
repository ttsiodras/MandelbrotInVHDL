.PHONY:	all compile test waves clean

include setup.mk

all:	compile  # in ghdl.mk

include c/c.mk
include src/ghdl.mk
include tb/tb.mk

clean:
	@echo "[CLEAN]"
	$(Q)rm -rf ${CLEAN}

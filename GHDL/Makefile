.PHONY:	all compile test waves clean

include setup.mk
include config.mk

all:	compile

include c/c.mk
include src/src.mk
include tb/tb.mk

clean:
	@echo "[CLEAN]"
	$(Q)rm -rf ${CLEAN}

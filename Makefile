all:
	$(MAKE) -C FPGA-VHDL/
	$(MAKE) -C src/

clean:
	$(MAKE) -C FPGA-VHDL/ clean
	$(MAKE) -C src/ clean


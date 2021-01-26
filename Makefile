all:
	$(MAKE) -C FPGA-VHDL/
	$(MAKE) -C src/

simulation:
	$(MAKE) -C GHDL/ test

clean:
	$(MAKE) -C FPGA-VHDL/ clean
	$(MAKE) -C src/ clean
	$(MAKE) -C GHDL/ clean


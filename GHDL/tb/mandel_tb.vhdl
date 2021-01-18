--  A testbench has no ports.
library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.fixed_pkg.all;

use work.custom_fixed_point_types.all;

entity mandel_tb is
end mandel_tb;

architecture behav of mandel_tb is
  --  Declaration of the component that will be instantiated.
  component MandelBrot
    port (
      clk              : in std_logic;
      rst              : in std_logic;

      -- These are the input coordinates on the complex plane
      -- for which the computation will take place.
      input_x, input_y : in std_logic_vector(31 downto 0);

      -- When this is pulsed once (0->1->0) the engine "wakes up" and
      -- starts computing the output color.
      startWorking     : in std_logic;

      --  When it concludes computing, it stores the result here...
      OutputNumber     : out std_logic_vector(7 downto 0);

      -- ...and raises this ; to signal completion.
      finishedWorking  : out std_logic
    );
  end component;

  -- for mandel_0: MandelBrot use entity work.MandelBrot;


  -- 50 MHz clock
  constant half_period : time  := 10 ns;
  constant cycle_period : time  := 20 ns;

  signal clk : std_logic := '0'; -- make sure you initialise!
  signal rst : std_logic := '1'; -- make sure you initialise!
  signal input_x, input_y : std_logic_vector(31 downto 0);
  signal startWorking : std_logic := '0';
  signal finishedWorking : std_logic := '1';
  signal OutputNumber : std_logic_vector(7 downto 0);

begin
  clk <= not clk after half_period;

  --  Component instantiation.
  mandel_0: MandelBrot port map (
    clk => clk,
    rst => rst,
    input_x => input_x,
    input_y => input_y,
    startWorking => startWorking,
    finishedWorking => finishedWorking,
    OutputNumber => OutputNumber
  );

  --  This process does the real job.
  process
    type pattern_type is record
      ix, iy, o : std_logic_vector(31 downto 0);
    end record;

    --  The numbers to check. as computed in ../c/mandel.c
    type pattern_array is array (natural range <>) of pattern_type;
    constant patterns : pattern_array :=
      ((X"f7333334", X"fc666667", X"00000001"),
       (X"f8666667", X"fc666667", X"00000001"),
       (X"f999999a", X"fc666667", X"00000003"),
       (X"facccccd", X"fc666667", X"00000003"),
       (X"fc000000", X"fc666667", X"00000003"),
       (X"fd333334", X"fc666667", X"00000004"),
       (X"fe666667", X"fc666667", X"00000005"),
       (X"ff99999a", X"fc666667", X"00000018"));

    function to_hex(i : std_logic_vector(31 downto 0)) return string is
    begin
      return "0x" & to_hstring(i);
    end;

    variable l : line;
  begin
    -- Reset for 100 cycles
    rst <= '1';
    wait for 2*cycle_period;
    rst <= '0';
    wait for 5*cycle_period;

    --  Check each one of our sample tests..
    for i in patterns'range loop
      --  Set the inputs.
      input_x <= patterns(i).ix;
      input_y <= patterns(i).iy;
      startWorking <= '1';
      wait for cycle_period;
      startWorking <= '0';
      writeline(OUTPUT, l);
      write(l, string'("Testing for input X:"));
      write(l, to_hex(input_x));
      write(l, string'(" and input Y:"));
      write(l, to_hex(input_y));
      writeline(OUTPUT, l);

      --  Wait for the results.
      write(l, string'("Waiting for circuit to indicate completeness..."));
      writeline(OUTPUT, l);
      wait until finishedWorking = '1';
      wait until finishedWorking = '0';

      write(l, string'("Got result:   "));
      write(l, to_hex(X"000000" & OutputNumber));
      writeline(OUTPUT, l);
      write(l, string'("Was expecting:"));
      write(l, to_hex(patterns(i).o));
      writeline(OUTPUT, l);
      --  Check the outputs.
      assert OutputNumber = patterns(i).o
        report "bad mandelbrot result value" severity error;
    end loop;
    -- assert false report "end of test" severity note;
    --  Wait forever; this will finish the simulation.
    wait;
  end process;


end behav;

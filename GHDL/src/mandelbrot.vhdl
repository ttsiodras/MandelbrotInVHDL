------------------------------------------------------------------
-- This is my simple "direct-to-VHDL" translation
-- of a Mandelbrot fractal computing engine.
------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.fixed_pkg.all;
use work.custom_fixed_point_types.all;
use work.pipeline_types.all;

use std.textio.all;
use work.test_data.all;

entity Mandelbrot is
  port (
    CLK               : in std_logic;
    RST               : in std_logic;

    -- These are the input coordinates on the complex plane
    -- for which the computation will take place.
    input_x, input_y  : in std_logic_vector(31 downto 0);
    -- And this is the screen offset where the returned
    -- color result will be written into:
    input_offset      : in unsigned(31 downto 0);
    -- When this is pulsed once (0->1->0) the engine "wakes up" and
    -- starts trying to store the inputs (x,y,ofs) in the pipeline
    new_input_arrived : in std_logic;
    -- as soon as it manages to do this, it pulses this:
    new_input_ack     : out std_logic;
    -- ...and starts processing.

    --  When it concludes computing, it stores the result here...
    output_number     : out unsigned(7 downto 0);
    output_offset     : out unsigned(31 downto 0);
    -- ...so the outer circuit can take this result and plot it.
    -- To wake it up, we pulse this, to signal completion.
    new_output_made   : out std_logic
    -- No ACK is needed, because we expect someone to be
    -- constantly waiting for this new_output signal, and 
    -- immediately store the output in some single-cycle buffer.
  );
end Mandelbrot;


architecture arch of Mandelbrot is

  signal is_used_slot   : std_logic_vector(1 to depth) := (others => '0');
  signal Xc_pipe_reg    : coord_array_type(1 to depth) := (others => (others => '0'));
  signal Yc_pipe_reg    : coord_array_type(1 to depth) := (others => (others => '0'));
  signal X_pipe_reg     : coord_array_type(1 to depth) := (others => (others => '0'));
  signal Y_pipe_reg     : coord_array_type(1 to depth) := (others => (others => '0'));
  signal offst_pipe_reg : offst_array_type(1 to depth) := (others => (others => '0'));
  signal iter_pipe_reg  : iterations_array(1 to depth) := (others => (others => '0'));
  signal iter_pipe_delta : iterations_array(1 to depth) := (others => (others => '0'));

  signal X_reg : custom_fixed_point_type;
  signal Y_reg : custom_fixed_point_type;

  signal XX_reg : custom_fixed_point_type;
  signal YY_reg : custom_fixed_point_type;
  signal XY_reg : custom_fixed_point_type;

  signal XXpYY_reg : custom_fixed_point_type;
  signal XXmYY_reg : custom_fixed_point_type;
  signal XYpXY_reg : custom_fixed_point_type;

  -- iteration
  signal overflow  : std_logic := '0';

  signal input_slot_empty : std_logic := '0';

  procedure debug_log(msg: string) is 
    variable l : line;
  begin
    writeline(OUTPUT, l);

    write(l, msg);
    writeline(OUTPUT, l);

    write(l, string'("new_input_arrived:"));
    write(l, new_input_arrived);
    writeline(OUTPUT, l);

    write(l, string'("input_slot_empty:"));
    write(l, input_slot_empty);
    writeline(OUTPUT, l);

    write(l, string'("new_input_ack:"));
    write(l, new_input_ack);
    writeline(OUTPUT, l);

    write(l, string'("overflow:"));
    write(l, overflow);
    writeline(OUTPUT, l);

    write(l, string'("is_used_slot:"));
    writeline(OUTPUT, l);
    for i in is_used_slot'range loop
      write(l, is_used_slot(i));
      write(l, string'(","));
    end loop;
    writeline(OUTPUT, l);

    write(l, string'("Xc_pipe_reg:"));
    writeline(OUTPUT, l);
    for i in Xc_pipe_reg'range loop
      write(l, to_hex(to_slv(Xc_pipe_reg(i))));
      write(l, string'(","));
    end loop;
    writeline(OUTPUT, l);

    write(l, string'("offst_pipe_reg:"));
    writeline(OUTPUT, l);
    for i in offst_pipe_reg'range loop
      write(l, to_hex(offst_pipe_reg(i)));
      write(l, string'(","));
    end loop;
    writeline(OUTPUT, l);

    write(l, string'("iter_pipe_reg:"));
    writeline(OUTPUT, l);
    for i in iter_pipe_reg'range loop
      write(l, to_hex(iter_pipe_reg(i)));
      write(l, string'(","));
    end loop;
    writeline(OUTPUT, l);

    write(l, string'("iter_pipe_delta:"));
    writeline(OUTPUT, l);
    for i in iter_pipe_delta'range loop
      write(l, to_hex(iter_pipe_delta(i)));
      write(l, string'(","));
    end loop;
    writeline(OUTPUT, l);

    writeline(OUTPUT, l);
  end procedure;

begin

-------------------------------------------------------------------------------
-- STAGE 0 (INPUT)
-------------------------------------------------------------------------------

  -------------------------------------------------------------
  -- register inputs and move things up the pipeline
  -------------------------------------------------------------

  process(clk, rst,
          is_used_slot, Xc_pipe_reg, Yc_pipe_reg,
          X_pipe_reg, Y_pipe_reg, offst_pipe_reg, XXmYY_reg,
          iter_pipe_reg, new_input_arrived, overflow,
          input_slot_empty)
  begin
    if (rst='1') then
      is_used_slot   <= (others => '0');
      Xc_pipe_reg    <= (others => (others => '0'));
      Yc_pipe_reg    <= (others => (others => '0'));
      X_pipe_reg     <= (others => (others => '0'));
      Y_pipe_reg     <= (others => (others => '0'));
      offst_pipe_reg <= (others => (others => '0'));
      iter_pipe_reg  <= (others => (others => '0'));
      X_reg <= (others => '0');
      Y_reg <= (others => '0');
      new_input_ack <= '0';
    elsif rising_edge(clk) then
      -- debug_log("CLOCKED");
      if new_input_arrived = '1' and input_slot_empty = '1' and new_input_ack = '0' then
        new_input_ack <= '1';
        is_used_slot(1) <= '1';
        Xc_pipe_reg(1) <= to_sfixed_custom(input_x);
        Yc_pipe_reg(1) <= to_sfixed_custom(input_y);
        X_pipe_reg(1) <= to_sfixed_custom(input_x);
        Y_pipe_reg(1) <= to_sfixed_custom(input_y);
        X_reg <= to_sfixed_custom(input_x);
        Y_reg <= to_sfixed_custom(input_y);
        offst_pipe_reg(1) <= input_offset;
        iter_pipe_reg(1) <= X"00";
        iter_pipe_delta(1) <= X"01";
      else
        new_input_ack <= '0';
        is_used_slot(1) <= is_used_slot(depth);
        Xc_pipe_reg(1) <= Xc_pipe_reg(depth);
        Yc_pipe_reg(1) <= Yc_pipe_reg(depth);
        X_pipe_reg(1) <= X_pipe_reg(depth);
        Y_pipe_reg(1) <= Y_pipe_reg(depth);
        X_reg <= X_pipe_reg(depth);
        Y_reg <= Y_pipe_reg(depth);
        offst_pipe_reg(1) <= offst_pipe_reg(depth);
        iter_pipe_reg(1) <= iter_pipe_reg(depth);
        iter_pipe_delta(1) <= iter_pipe_delta(depth);
      end if;
      Xc_pipe_reg(2 to depth) <= Xc_pipe_reg(1 to depth-1);
      Yc_pipe_reg(2 to depth) <= Yc_pipe_reg(1 to depth-1);

      X_pipe_reg(2 to depth) <= X_pipe_reg(1 to depth-1);
      Y_pipe_reg(2 to depth) <= Y_pipe_reg(1 to depth-1);
      -- x^2 - y^2 + xC
      X_pipe_reg(4) <= resize(XXmYY_reg + Xc_pipe_reg(3), X_pipe_reg(3));
      -- 2*x*y + yC
      Y_pipe_reg(4) <= resize(XYpXY_reg + Yc_pipe_reg(3), Y_pipe_reg(3));

      offst_pipe_reg(2 to depth) <= offst_pipe_reg(1 to depth-1);
      for i in 2 to depth loop
        iter_pipe_reg(i) <= iter_pipe_reg(i-1);
      end loop;
      iter_pipe_reg(depth) <= iter_pipe_reg(depth-1) + iter_pipe_delta(depth-1);
      iter_pipe_delta(2 to depth) <= iter_pipe_delta(1 to depth-1);
      is_used_slot(2 to depth) <= is_used_slot(1 to depth-1);
      if overflow = '0' then
        is_used_slot(5) <= is_used_slot(4);
        iter_pipe_delta(5) <= iter_pipe_delta(4);
      else
        is_used_slot(5) <= '0';
        iter_pipe_delta(5) <= X"00";
        Xc_pipe_reg(5) <= (others => '0');
        debug_log("JUST MARKED SLOT 5 AS UNUSED");
      end if;
    end if;
  end process;

  process(rst, clk, is_used_slot, iter_pipe_reg)
  begin
    if (rst='1') then
      input_slot_empty <= '1';
    elsif rising_edge(clk) then
      if is_used_slot(depth-1) = '0' then
        input_slot_empty <= '1';
      else
        input_slot_empty <= '0';
      end if;
    end if;
  end process;

  -------------------------------------------------------------
  -- assigned after one cycle (input currently in slot 2)
  -------------------------------------------------------------

  process(clk, rst, X_reg)
  begin
    if (rst='1') then
       XX_reg <= (others => '0');
    elsif rising_edge(clk) then
       XX_reg <= resize(X_reg*X_reg, XX_reg);
    end if;
  end process;

  process(clk, rst, Y_reg)
  begin
    if (rst='1') then
       YY_reg <= (others => '0');
    elsif rising_edge(clk) then
       YY_reg <= resize(Y_reg*Y_reg, YY_reg);
    end if;
  end process;

  process(clk, rst, X_reg, Y_reg)
  begin
    if (rst='1') then
       XY_reg <= (others => '0');
    elsif rising_edge(clk) then
       XY_reg <= resize(X_reg*Y_reg, XY_reg);
    end if;
  end process;

  -------------------------------------------------------------
  -- assigned after two cycles (input is currently in slot 3)
  -------------------------------------------------------------

  process(clk, rst, XX_reg, YY_reg, XY_reg)
    variable l : line;
  begin
    if (rst='1') then
      XXpYY_reg <= (others => '0'); 
      XXmYY_reg <= (others => '0');
      XYpXY_reg <= (others => '0');
    elsif rising_edge(clk) then
      -- (x^2 + y^2)
      XXpYY_reg <= resize((XX_reg + YY_reg), XXpYY_reg);
      -- (x^2 - y^2)
      XXmYY_reg <= resize(XX_reg - YY_reg, XXmYY_reg);
      -- (2xy)
      XYpXY_reg <= resize(scalb(XY_reg, 1), XYpXY_reg);

      if is_used_slot(2) = '1' then
        write(l, string'("XX_reg:"));
        write(l, to_hex(to_slv(XX_reg)));
        write(l, string'(",YY_reg:"));
        write(l, to_hex(to_slv(YY_reg)));
        write(l, string'(" => XXpYY_reg: "));
        write(l, to_hex(to_slv(XX_reg + YY_reg)));
        write(l, string'(" for "));
        write(l, to_hex(to_slv(Xc_pipe_reg(2))));
        writeline(OUTPUT, l);
      end if;
    end if;
  end process;

  -------------------------------------------------------------
  -- assigned after three cycles (input is currently in slot 4)
  -------------------------------------------------------------

  process(clk, rst, XXpYY_reg, is_used_slot)
    variable l : line;
  begin
    if (rst='1') then
      overflow <= '0';
    elsif rising_edge(clk) then
      -- detect overflow of (x^2 + y^2) by checking top 4 bits
      overflow <= '0';
      if is_used_slot(3) = '1' then
        if  to_slv(XXpYY_reg)(31) or
            to_slv(XXpYY_reg)(30) or
            to_slv(XXpYY_reg)(29) or
            to_slv(XXpYY_reg)(28) then
          overflow <= '1';
          writeline(OUTPUT, l);
          write(l, string'("DETECTED OVERLOW! "));
          write(l, string'("XXpYY_reg: "));
          write(l, to_hex(to_slv(XXpYY_reg)));
          writeline(OUTPUT, l);
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------
  -- assigned after four cycles (input is currently in slot 5)
  -------------------------------------------------------------

  process(clk, rst,
          overflow, iter_pipe_reg, offst_pipe_reg, 
          XXmYY_reg, XYpXY_reg,
          Xc_pipe_reg, Yc_pipe_reg)
    variable l : line;
  begin
    if (rst='1') then
      new_output_made <= '0';
      output_offset <= (others => '0');
      output_number <= X"00";
    elsif rising_edge(clk) then
      if overflow = '0' then -- must check 240, too
        new_output_made <= '0';
      else
        output_number <= iter_pipe_reg(4);
        output_offset <= offst_pipe_reg(4);
        new_output_made <= '1';
        writeline(OUTPUT, l);
        write(l, string'("Outputing pixel "));
        write(l, to_hex(iter_pipe_reg(4)));
        write(l, string'(" for offset "));
        write(l, to_hex(offst_pipe_reg(4)));
        debug_log("PIXEL OUT...");
        writeline(OUTPUT, l);
      end if;
    end if;
  end process;

end arch;

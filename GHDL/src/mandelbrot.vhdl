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
        output_number     : out std_logic_vector(7 downto 0);
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

--     -- The simple state machine:
--     type state_type is (
--     receiving_input, -- waiting for input_x and input_y to arrive
--         comp_stage1, -- calculating x^2, y^2 and x*y
--         comp_stage2, -- calculating 2*x*y and x^2+y^2
--         comp_stage3, -- checking if magnitute > 4.0
--         comp_stage4, -- newx = x^2 - y^2 + input_x, newy = 2*x*y + input_y
--         computed
--     );
--     signal state : state_type;
-- 
--     -- the local variables needed for the algorithm
--     signal input_x_sfixed, input_y_sfixed : custom_fixed_point_type;
--     signal x_mandel, y_mandel : custom_fixed_point_type;
--     signal x_mandel_sq, y_mandel_sq : custom_fixed_point_type;
--     signal x_mandel_times_y_mandel, magnitude : custom_fixed_point_type;
--     signal pixel_color : unsigned(7 downto 0);
begin

    process (RST, CLK)
    begin
        if (RST='1') then
            new_input_ack <= '0';
            output_number <= X"00";
            output_offset <= X"00000000";
            new_output_made <= '0';
 
--         elsif rising_edge(CLK) then
-- 
--             case state is
--                 when receiving_input =>
--                     finishedWorking <= '0';
--                     if startWorking = '1' then
--                         input_x_sfixed <= to_sfixed_custom(input_x);
--                         input_y_sfixed <= to_sfixed_custom(input_y);
--                         x_mandel <= to_sfixed_custom(0.0);
--                         y_mandel <= to_sfixed_custom(0.0);
--                         pixel_color <= X"00";
--                         state <= comp_stage1;
--                     else
--                         state <= receiving_input;
--                     end if;
-- 
--                 when comp_stage1 =>
--                     if pixel_color(7) /= '0' then
--                         state <= computed;
--                     else
--                         x_mandel_times_y_mandel <= resize(
--                             x_mandel*y_mandel, x_mandel_times_y_mandel);
--                         x_mandel_sq <= resize(x_mandel*x_mandel, x_mandel_sq);
--                         y_mandel_sq <= resize(y_mandel*y_mandel, y_mandel_sq);
--                         state <= comp_stage2;
--                     end if;
-- 
--                 when comp_stage2 =>
--                     magnitude <= resize(x_mandel_sq + y_mandel_sq, magnitude);
--                     x_mandel_times_y_mandel <= x_mandel_times_y_mandel sll 1;
--                     state <= comp_stage3;
-- 
--                 when comp_stage3 =>
--                     if to_slv(magnitude)(31 downto 28) /= "0000" then
--                         state <= computed;
--                     else
--                         state <= comp_stage4;
--                     end if;
-- 
--                 when comp_stage4 =>
--                     pixel_color <= pixel_color + 1;
--                     x_mandel <= resize(
--                         x_mandel_sq - y_mandel_sq + input_x_sfixed, x_mandel);
--                     y_mandel <= resize(
--                         x_mandel_times_y_mandel + input_y_sfixed, y_mandel);
--                     state <= comp_stage1;
-- 
--                 when computed =>
--                    OutputNumber <= std_logic_vector(pixel_color);
--                    finishedWorking <= '1';
--                    state <= receiving_input;
--             end case; -- case state is ...
-- 
        end if; -- if rising_edge(CLK) ...
    end process;

end arch;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

use work.custom_fixed_point_types.all;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mandelbrot is
    port (
        CLK              : in std_logic;
        RST              : in std_logic;
        input_x, input_y : in std_logic_vector(31 downto 0);
        startWorking     : in std_logic;
        OutputNumber     : out std_logic_vector(7 downto 0);
        finishedWorking  : out std_logic
    );
end Mandelbrot;

architecture arch of Mandelbrot is

    -- My types
    type state_type is (
        receiving_input,
        comp_stage1,
        comp_stage2,
        comp_stage3,
        comp_stage4,
        computed
    );
    signal state : state_type;

    -- Inner logic
    signal input_x_sfixed, input_y_sfixed : custom_fixed_point_type;
    signal x_mandel, y_mandel : custom_fixed_point_type;
    signal x_mandel_sq, y_mandel_sq, x_mandel_times_y_mandel, magnitude : custom_fixed_point_type;
    signal pixel_color : unsigned(7 downto 0);
begin

    process (RST, CLK)
    begin
        if (RST='1') then
            OutputNumber <= X"00";
            finishedWorking <= '0';
            state <= receiving_input;

        elsif rising_edge(CLK) then

            case state is
                when receiving_input =>
                    if startWorking = '1' then
                        finishedWorking <= '0';
                        input_x_sfixed <= to_sfixed_custom(input_x);
                        input_y_sfixed <= to_sfixed_custom(input_y);
                        x_mandel <= to_sfixed_custom(0.0);
                        y_mandel <= to_sfixed_custom(0.0);
                        pixel_color <= X"00";
                        state <= comp_stage1;
                    else
                        state <= receiving_input;
                    end if;
                
                when comp_stage1 =>
                    if pixel_color(7) /= '0' then
                        state <= computed;
                    else
                        x_mandel_times_y_mandel <= resize(x_mandel*y_mandel, x_mandel_times_y_mandel);
                        x_mandel_sq <= resize(x_mandel*x_mandel, x_mandel_sq);
                        y_mandel_sq <= resize(y_mandel*y_mandel, y_mandel_sq);
                        state <= comp_stage2;
                    end if;

                when comp_stage2 =>
                    magnitude <= resize(x_mandel_sq + y_mandel_sq, magnitude);
                    x_mandel_times_y_mandel <= x_mandel_times_y_mandel sll 1;
                    state <= comp_stage3;

                when comp_stage3 =>
                    if to_slv(magnitude)(31 downto 29) /= "000" then
                        state <= computed;
                    else
                        state <= comp_stage4;
                    end if;

                when comp_stage4 =>
                    pixel_color <= pixel_color + 1;
                    x_mandel <= resize(x_mandel_sq - y_mandel_sq + input_x_sfixed, x_mandel);
                    y_mandel <= resize(x_mandel_times_y_mandel + input_y_sfixed, y_mandel);
                    state <= comp_stage1;

                when computed =>
                   OutputNumber <= std_logic_vector(pixel_color);
                   finishedWorking <= '1';
                   state <= receiving_input;
            end case; -- case state is ...
            
        end if; -- if rising_edge(CLK) ...
    end process;

end arch;

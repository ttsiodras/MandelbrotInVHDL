-- ZestSC1 Example 3
-- File name: Example3.vhd
-- Version: 1.10
-- Date: 6/2/2006

--
-- ZestSC1 Example 3
-- Register implementation, loopback of signals and interrupt generation
--

-- Copyright (C) 2005-2006 Orange Tree Technologies Ltd. All rights reserved.
-- Orange Tree Technologies grants the purchaser of a ZestSC1 the right to use and 
-- modify this logic core in any form such as VHDL source code or EDIF netlist in 
-- FPGA designs that target the ZestSC1.
-- Orange Tree Technologies prohibits the use of this logic core in any form such 
-- as VHDL source code or EDIF netlist in FPGA designs that target any other
-- hardware unless the purchaser of the ZestSC1 has purchased the appropriate 
-- licence from Orange Tree Technologies. Contact Orange Tree Technologies if you 
-- want to purchase such a licence.

--*****************************************************************************************
--**
--**  Disclaimer: LIMITED WARRANTY AND DISCLAIMER. These designs are
--**              provided to you "as is". Orange Tree Technologies and its licensors 
--**              make and you receive no warranties or conditions, express, implied, 
--**              statutory or otherwise, and Orange Tree Technologies specifically 
--**              disclaims any implied warranties of merchantability, non-infringement,
--**              or fitness for a particular purpose. Orange Tree Technologies does not
--**              warrant that the functions contained in these designs will meet your 
--**              requirements, or that the operation of these designs will be 
--**              uninterrupted or error free, or that defects in the Designs will be 
--**              corrected. Furthermore, Orange Tree Technologies does not warrant or 
--**              make any representations regarding use or the results of the use of the 
--**              designs in terms of correctness, accuracy, reliability, or otherwise.                                               
--**
--**              LIMITATION OF LIABILITY. In no event will Orange Tree Technologies 
--**              or its licensors be liable for any loss of data, lost profits, cost or 
--**              procurement of substitute goods or services, or for any special, 
--**              incidental, consequential, or indirect damages arising from the use or 
--**              operation of the designs or accompanying documentation, however caused 
--**              and on any theory of liability. This limitation will apply even if 
--**              Orange Tree Technologies has been advised of the possibility of such 
--**              damage. This limitation shall apply notwithstanding the failure of the 
--**              essential purpose of any limited remedies herein.
--**
--*****************************************************************************************

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

entity Example3 is
    port (
        USB_StreamCLK : in std_logic;
        USB_StreamFIFOADDR : out std_logic_vector(1 downto 0);
        USB_StreamPKTEND_n : out std_logic;
        USB_StreamFlags_n : in std_logic_vector(2 downto 0);
        USB_StreamSLOE_n : out std_logic;
        USB_StreamSLRD_n : out std_logic;
        USB_StreamSLWR_n : out std_logic;
        USB_StreamData : inout std_logic_vector(15 downto 0);
        USB_StreamFX2Rdy : in std_logic;

        USB_RegCLK : in std_logic;
        USB_RegAddr : in std_logic_vector(15 downto 0);
        USB_RegData : inout std_logic_vector(7 downto 0);
        USB_RegOE_n : in std_logic;
        USB_RegRD_n : in std_logic;
        USB_RegWR_n : in std_logic;
        USB_RegCS_n : in std_logic;

        USB_Interrupt : out std_logic;

        User_Signals : inout std_logic_vector(7 downto 0);

        S_CLK : out std_logic;
        S_A : out std_logic_vector(22 downto 0);
        S_DA : inout std_logic_vector(8 downto 0);
        S_DB : inout std_logic_vector(8 downto 0);
        S_ADV_LD_N : out std_logic;
        S_BWA_N : out std_logic;
        S_BWB_N : out std_logic;
        S_OE_N : out std_logic;
        S_WE_N : out std_logic;

        IO_CLK_N : inout std_logic;
        IO_CLK_P : inout std_logic;
        IO : inout std_logic_vector(46 downto 0)
    );
end Example3;

architecture arch of Example3 is

    -- Declare interfaces component
    component ZestSC1_Interfaces
        port (
            -- FPGA pin connections
            USB_StreamCLK : in std_logic;
            USB_StreamFIFOADDR : out std_logic_vector(1 downto 0);
            USB_StreamPKTEND_n : out std_logic;
            USB_StreamFlags_n : in std_logic_vector(2 downto 0);
            USB_StreamSLOE_n : out std_logic;
            USB_StreamSLRD_n : out std_logic;
            USB_StreamSLWR_n : out std_logic;
            USB_StreamData : inout std_logic_vector(15 downto 0);
            USB_StreamFX2Rdy : in std_logic;

            USB_RegCLK : in std_logic;
            USB_RegAddr : in std_logic_vector(15 downto 0);
            USB_RegData : inout std_logic_vector(7 downto 0);
            USB_RegOE_n : in std_logic;
            USB_RegRD_n : in std_logic;
            USB_RegWR_n : in std_logic;
            USB_RegCS_n : in std_logic;

            USB_Interrupt : out std_logic;

            S_CLK: out std_logic;
            S_A: out std_logic_vector(22 downto 0);
            S_ADV_LD_N: out std_logic;
            S_BWA_N: out std_logic;
            S_BWB_N: out std_logic;
            S_DA: inout std_logic_vector(8 downto 0);
            S_DB: inout std_logic_vector(8 downto 0);
            S_OE_N: out std_logic;
            S_WE_N: out std_logic;

            -- User connections
            -- Streaming interface
            User_CLK : out std_logic;
            User_RST : out std_logic;

            User_StreamBusGrantLength : in std_logic_vector(11 downto 0);

            User_StreamDataIn : out std_logic_vector(15 downto 0);
            User_StreamDataInWE : out std_logic;
            User_StreamDataInBusy : in std_logic;

            User_StreamDataOut : in std_logic_vector(15 downto 0);
            User_StreamDataOutWE : in std_logic;
            User_StreamDataOutBusy : out std_logic;

            -- Register interface
            User_RegAddr : out std_logic_vector(15 downto 0);
            User_RegDataIn : out std_logic_vector(7 downto 0);
            User_RegDataOut : in std_logic_vector(7 downto 0);
            User_RegWE : out std_logic;
            User_RegRE : out std_logic;

            -- Signals and interrupts
            User_Interrupt : in std_logic;

            -- SRAM interface
            User_SRAM_A: in std_logic_vector(22 downto 0);
            User_SRAM_W: in std_logic;
            User_SRAM_R: in std_logic;
            User_SRAM_DR_VALID: out std_logic;
            User_SRAM_DW: in std_logic_vector(17 downto 0);
            User_SRAM_DR: out std_logic_vector(17 downto 0)
        );
    end component;

    -- Declare signals
    signal CLK : std_logic;
    signal RST : std_logic;
    signal LEDs : std_logic_vector(7 downto 0);

    -- Register interface
    signal Addr : std_logic_vector(15 downto 0);
    signal DataIn : std_logic_vector(7 downto 0);
    signal DataOut : std_logic_vector(7 downto 0);
    signal WE : std_logic;
    signal RE : std_logic;

    -- Interrupt signal
    signal Interrupt : std_logic;

    -- Registers
    signal input_x, input_y : std_logic_vector(31 downto 0);
    signal input_x_given, input_y_given : std_logic;
    signal OutputNumber : std_logic_vector(7 downto 0);
 
    -- My types
    type state_type is (
        receiving_input,
        comp_stage1,
        comp_stage2,
        comp_stage3,
        comp_stage4,
        computed);
    signal state : state_type;

    -- Signals
    signal bits_sent_so_far_for_X, bits_sent_so_far_for_Y : std_logic_vector(2 downto 0);
    signal WE_old : std_logic;

    -- Inner logic
    signal input_x_sfixed, input_y_sfixed : custom_fixed_point_type;
    signal x_mandel, y_mandel : custom_fixed_point_type;
    signal x_mandel_sq, y_mandel_sq, x_mandel_times_y_mandel, magnitude : custom_fixed_point_type;
    signal output_xy_sfixed : custom_fixed_point_type;
    constant borderValue : custom_fixed_point_type := to_sfixed_custom(4.0);
    signal pixel_color : unsigned(7 downto 0);
    signal debug1 : std_logic_vector(31 downto 0);
    signal debug2 : std_logic_vector(31 downto 0);
begin

    -- Tie unused signals
    User_Signals <= "ZZZZZZZZ";
    LEDs <= "11111111";
    IO_CLK_N <= 'Z';
    IO_CLK_P <= 'Z';
    IO <= (0=>LEDs(0), 1=>LEDs(1), 41=>LEDs(2), 42=>LEDs(3), 43=>LEDs(4),
           44=>LEDs(5), 45=>LEDs(6), 46=>LEDs(7), others => 'Z');

    -- Implement register write
    -- Note that for compatibility with FX2LP devices only addresses
    -- above 2000 Hex are used
    process (RST, CLK)
    begin
        if (RST='1') then
            bits_sent_so_far_for_X <= "000";
            bits_sent_so_far_for_Y <= "000";
            input_x <= X"00000000";
            input_y <= X"00000000";
            input_x_given <= '0';
            input_y_given <= '0';
            OutputNumber <= X"00";
            state <= receiving_input;
            WE_old <= '0';
        elsif (CLK'event and CLK='1') then
            WE_old <= WE;

            -- Was the WE signal just raised?
            if (WE='1' and WE_old = '0') then
                case Addr is
                    when X"207B" => 
                        input_x <= input_x(23 downto 0) & DataIn;
                        if bits_sent_so_far_for_X = "011" then
                            input_x_given <= '1';
                            bits_sent_so_far_for_X <= "000";
                        else 
                            input_x_given <= '0';
                            bits_sent_so_far_for_X <= bits_sent_so_far_for_X + 1;
                        end if;
                    when X"207C" => 
                        input_y <= input_y(23 downto 0) & DataIn;
                        if bits_sent_so_far_for_Y = "011" then
                            input_y_given <= '1';
                            bits_sent_so_far_for_Y <= "000";
                        else 
                            input_y_given <= '0';
                            bits_sent_so_far_for_Y <= bits_sent_so_far_for_Y + 1;
                        end if;
                    when others =>
                end case;
            end if; -- WE='1'

            case state is
                when receiving_input =>
                    if input_x_given = '1' and input_y_given = '1' then
                        input_x_sfixed <= to_sfixed_custom(input_x);
                        input_y_sfixed <= to_sfixed_custom(input_y);
                        x_mandel <= to_sfixed_custom(0.0);
                        y_mandel <= to_sfixed_custom(0.0);
                        pixel_color <= X"00";
                        state <= comp_stage1;
                        input_x_given <= '0';
                        input_y_given <= '0';
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
                    debug1 <= to_slv(x_mandel);
                    debug2 <= to_slv(y_mandel);
                    state <= comp_stage1;

                when computed =>
                   OutputNumber <= std_logic_vector(pixel_color);
                   state <= receiving_input;
            end case; -- case state is ...
            
        end if; -- if CLK'event and CLK = '1' ...
    end process;

    process (Addr, debug1, OutputNumber)
    begin
        case Addr is
            when X"207C" => DataOut <= OutputNumber(7 downto 0);
            when X"2000" => DataOut <= debug1(7 downto 0);
            when X"2001" => DataOut <= debug1(15 downto 8);
            when X"2002" => DataOut <= debug1(23 downto 16);
            when X"2003" => DataOut <= debug1(31 downto 24);

            when X"2004" => DataOut <= debug2(7 downto 0);
            when X"2005" => DataOut <= debug2(15 downto 8);
            when X"2006" => DataOut <= debug2(23 downto 16);
            when X"2007" => DataOut <= debug2(31 downto 24);

            when others => DataOut <= X"AA";
        end case;
    end process;

    -- Instantiate interfaces component
    Interfaces : ZestSC1_Interfaces
        port map (
            USB_StreamCLK => USB_StreamCLK,
            USB_StreamFIFOADDR => USB_StreamFIFOADDR,
            USB_StreamPKTEND_n => USB_StreamPKTEND_n,
            USB_StreamFlags_n => USB_StreamFlags_n,
            USB_StreamSLOE_n => USB_StreamSLOE_n,
            USB_StreamSLRD_n => USB_StreamSLRD_n,
            USB_StreamSLWR_n => USB_StreamSLWR_n,
            USB_StreamData => USB_StreamData,
            USB_StreamFX2Rdy => USB_StreamFX2Rdy,
    
            USB_RegCLK => USB_RegCLK,
            USB_RegAddr => USB_RegAddr,
            USB_RegData => USB_RegData,
            USB_RegOE_n => USB_RegOE_n,
            USB_RegRD_n => USB_RegRD_n,
            USB_RegWR_n => USB_RegWR_n,
            USB_RegCS_n => USB_RegCS_n,

            USB_Interrupt => USB_Interrupt,

            S_CLK => S_CLK,
            S_A => S_A,
            S_ADV_LD_N => S_ADV_LD_N,
            S_BWA_N => S_BWA_N,
            S_BWB_N => S_BWB_N,
            S_DA => S_DA,
            S_DB => S_DB,
            S_OE_N => S_OE_N,
            S_WE_N => S_WE_N,

            -- User connections
            -- Streaming interface
            User_CLK => CLK,
            User_RST => RST,

            User_StreamBusGrantLength => X"002",

            User_StreamDataIn => open,
            User_StreamDataInWE => open,
            User_StreamDataInBusy => '1',

            User_StreamDataOut => "0000000000000000", 
            User_StreamDataOutWE => '0',
            User_StreamDataOutBusy => open,

            -- Register interface
            User_RegAddr => Addr,
            User_RegDataIn => DataIn,
            User_RegDataOut => DataOut,
            User_RegWE => WE,
            User_RegRE => RE,

            -- Interrupts
            User_Interrupt => Interrupt,

            -- SRAM interface
            User_SRAM_A => "00000000000000000000000",
            User_SRAM_W => '0',
            User_SRAM_R => '0',
            User_SRAM_DR_VALID => open,
            User_SRAM_DW => "000000000000000000",
            User_SRAM_DR => open
        );

end arch;

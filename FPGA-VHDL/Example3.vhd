library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.to_sfixed_custom;

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

    -- Declare components
    component Mandelbrot
        port (
            CLK              : in std_logic;
            RST              : in std_logic;
            input_x, input_y : in std_logic_vector(31 downto 0);
            startWorking     : in std_logic;
            OutputNumber     : out std_logic_vector(7 downto 0);
            finishedWorking  : out std_logic
        );
    end component;

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

    signal CLK : std_logic;
    signal RST : std_logic;
    signal LEDs : std_logic_vector(7 downto 0);

    -- Register interface
    signal Addr : std_logic_vector(15 downto 0);
    signal DataIn : std_logic_vector(7 downto 0);
    signal DataOut : std_logic_vector(7 downto 0);
    signal WE : std_logic;
    signal RE : std_logic;

    -- SRAM interface
    signal SRAMAddr : std_logic_vector(22 downto 0);
    signal SRAMDataOut : std_logic_vector(17 downto 0);
    signal SRAMDataIn : std_logic_vector(17 downto 0);
    signal SRAMWE : std_logic;
    signal SRAMRE : std_logic;
    signal SRAMValid : std_logic;

    -- Interrupt signal
    signal Interrupt : std_logic;

    -- My types
    type state_type is (
        reading,
        receiving_input,
        drawPixels,
        drawPixelsWaitForWrite,
        waitForMandelbrot
    );
    signal state : state_type;

    -- Signals
    signal bits_sent_so_far_for_X, bits_sent_so_far_for_Y : natural range 0 to 7;
    signal WE_old : std_logic;

    -- Inner logic
    signal input_x_sfixed, input_y_sfixed : custom_fixed_point_type;
    signal x_mandel, y_mandel : custom_fixed_point_type;
    signal x_mandel_sq, y_mandel_sq, x_mandel_times_y_mandel, magnitude : custom_fixed_point_type;
    signal output_xy_sfixed : custom_fixed_point_type;
    constant borderValue : custom_fixed_point_type := to_sfixed_custom(4.0);
    signal debug1 : std_logic_vector(31 downto 0);
    signal debug2 : std_logic_vector(31 downto 0);

    signal startReading : std_logic := '0';
    signal input_x_given, input_y_given : std_logic;
    signal TestByteRead : std_logic_vector(17 downto 0);

    signal PixelsToCompute : natural range 0 to 1023;
    signal PixelAddrInSRAM : unsigned(22 downto 0);

    -- Signals used to interface with Mandelbrot engine
    signal input_x, input_y : std_logic_vector(31 downto 0);
    signal startWorking     : std_logic;
    signal OutputNumber     : std_logic_vector(7 downto 0);
    signal finishedWorking  : std_logic;
begin

    -- Tie unused signals
    User_Signals <= "ZZZZZZZZ";
    LEDs <= "11111111";
    IO_CLK_N <= 'Z';
    IO_CLK_P <= 'Z';
    Interrupt <= '0';

    IO <= (0=>LEDs(0), 1=>LEDs(1), 41=>LEDs(2), 42=>LEDs(3), 43=>LEDs(4),
           44=>LEDs(5), 45=>LEDs(6), 46=>LEDs(7), others => 'Z');

    process (RST, CLK)
    begin
        if (RST='1') then
            bits_sent_so_far_for_X <= 0;
            bits_sent_so_far_for_Y <= 0;
            input_x <= X"00000000";
            input_y <= X"00000000";
            input_x_given <= '0';
            input_y_given <= '0';
            state <= receiving_input;
            WE_old <= '0';
            SRAMDataOut <= (others => '0');
            debug1 <= (others => '0');
            debug2 <= (others => '0');

        elsif rising_edge(CLK) then
            WE_old <= WE;

            -- Was the WE signal just raised?
            if (WE='1' and WE_old = '0') then
                case Addr is

                    when X"207B" => 
                        debug2 <= X"00000000";
                        input_x <= input_x(23 downto 0) & DataIn;
                        if bits_sent_so_far_for_X = 3 then
                            input_x_given <= '1';
                            bits_sent_so_far_for_X <= 0;
                        else 
                            input_x_given <= '0';
                            bits_sent_so_far_for_X <= bits_sent_so_far_for_X + 1;
                        end if;

                    when X"207C" => 
                        debug2 <= X"00000000";
                        input_y <= input_y(23 downto 0) & DataIn;
                        if bits_sent_so_far_for_Y = 3 then
                            input_y_given <= '1';
                            bits_sent_so_far_for_Y <= 0;
                        else 
                            input_y_given <= '0';
                            bits_sent_so_far_for_Y <= bits_sent_so_far_for_Y + 1;
                        end if;

                    when X"207E" =>
                        startReading <= '1';
                        SRAMAddr <= "000000000000000" & DataIn;

                    when others =>
                end case;
            end if; -- WE='1'

            case state is
                when reading =>
                    SRAMRE <= '0';
                    if SRAMValid = '1' then
                        TestByteRead <= SRAMDataIn;
                        state <= receiving_input;
                    else
                        state <= reading;
                    end if;

                when receiving_input =>
                    if startReading = '1' then
                        startReading <= '0';
                        SRAMRE <= '1';
                        state <= reading;
                    elsif input_x_given = '1' and input_y_given = '1' then
                        PixelsToCompute <= 320;
                        PixelAddrInSRAM <= (others => '0');
                        input_x_given <= '0';
                        input_y_given <= '0';
                        state <= drawPixels;
                    end if;

                when drawPixels =>
                    SRAMWE <= '0';
                    if PixelsToCompute /= 0 then
                        SRAMAddr <= std_logic_vector(PixelAddrInSRAM);
                        PixelAddrInSRAM <= PixelAddrInSRAM + 1;
                        PixelsToCompute <= PixelsToCompute - 1;
                        debug1 <= std_logic_vector(to_unsigned(PixelsToCompute, debug1'length));
                        startWorking <= '1';
                        state <= waitForMandelbrot;
                    else
                        state <= receiving_input;
                    end if;

                when waitForMandelbrot =>
                    startWorking <= '0'; -- finish pulse
                    if finishedWorking = '0' then
                        state <= waitForMandelbrot;
                    else
                        SRAMDataOut <= "0000000000" & OutputNumber;
                        -- Go right by 3.3/320.0
                        input_x <= std_logic_vector(unsigned(input_x) + 1384120);
                        state <= drawPixelsWaitForWrite;
                    end if;

                when drawPixelsWaitForWrite =>
                    SRAMWE <= '1';
                    state <= drawPixels;

            end case; -- case state is ...
        end if; -- if rising_edge(CLK) ...
    end process;

    process (Addr, debug1, debug2, TestByteRead)
    begin
        case Addr is
            when X"2010" => DataOut <= TestByteRead(7 downto 0);

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

    -- Instantiate components

    FractalEngine : Mandelbrot
        port map (
            CLK => CLK,
            RST => RST,
            input_x => input_x,
            input_y => input_y,
            startWorking => startWorking,
            OutputNumber => OutputNumber,
            finishedWorking => finishedWorking
        );

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
            User_SRAM_A => SRAMAddr,
            User_SRAM_W => SRAMWE,
            User_SRAM_R => SRAMRE,
            User_SRAM_DR_VALID => SRAMValid,
            User_SRAM_DW => SRAMDataOut,
            User_SRAM_DR => SRAMDataIn
        );

end arch;

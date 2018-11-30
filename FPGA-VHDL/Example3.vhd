------------------------------------------------------------------
-- This is the top-level of my simple "direct-to-VHDL" translation
-- of a Mandelbrot fractal computing engine.
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- The top-level needs to hook up with ZestSC1 connections:
entity Example3 is
    port (
        USB_StreamCLK : in std_logic;
        USB_StreamFIFOADDR : out std_logic_vector(1 downto 0);
        USB_StreamPKTEND_n : out std_logic;
        USB_StreamFlags_n : in std_logic_vector(2 downto 0);
        USB_StreamSLOE_n : out std_logic;
        USB_StreamSLRD_n : out std_logic;
        USB_StreamSLWR_n : out std_logic;
        USB_StreamFX2Rdy : in std_logic;
        USB_StreamData : inout std_logic_vector(15 downto 0);

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

    -- This is the actual fractal computing engine.
    -- Details about it are in "Mandelbrot.vhd";
    component Mandelbrot
        port (
            CLK              : in std_logic;
            RST              : in std_logic;

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

    -- In addition to a single instance of the computing engine
    -- (for now, no pipelining - yet) we also instantiate the ZestSC1 stuff.
    component ZestSC1_Interfaces
        port (
            -----------------------------------------------
            -- The deep dark magic of the ZestSC1 design.
            --     Don't mess with any of these.
            -----------------------------------------------
            USB_StreamCLK : in std_logic;
            USB_StreamFIFOADDR : out std_logic_vector(1 downto 0);
            USB_StreamPKTEND_n : out std_logic;
            USB_StreamFlags_n : in std_logic_vector(2 downto 0);
            USB_StreamSLOE_n : out std_logic;
            USB_StreamSLRD_n : out std_logic;
            USB_StreamSLWR_n : out std_logic;
            USB_StreamFX2Rdy : in std_logic;
            USB_StreamData : inout std_logic_vector(15 downto 0);

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

            -------------------------------------------------------
            -- The foundations of life, the universe and everything
            -------------------------------------------------------
            User_CLK : out std_logic;
            User_RST : out std_logic;

            ----------------------
            -- Streaming interface
            ----------------------

            -- size of USB transactions
            -- (bigger ==> faster speed, worse latency)
            User_StreamBusGrantLength : in std_logic_vector(11 downto 0);

            -- from the PC to the board
            User_StreamDataIn : out std_logic_vector(15 downto 0);
            User_StreamDataInWE : out std_logic;
            User_StreamDataInBusy : in std_logic;

            -- from the board to the PC.
            -- (actually used - to send the framebuffer data back)
            User_StreamDataOut : in std_logic_vector(15 downto 0);
            User_StreamDataOutWE : in std_logic;
            User_StreamDataOutBusy : out std_logic;

            ---------------------
            -- Register interface
            ---------------------

            -- This is used to send:
            --
            --  the topx, topy (in complex plane, so fixed point coordinates)
            --  the stepx, stepy (to move for each pixel - also fixed point)
            User_RegAddr : out std_logic_vector(15 downto 0);
            User_RegDataIn : out std_logic_vector(7 downto 0);
            User_RegDataOut : in std_logic_vector(7 downto 0);
            User_RegWE : out std_logic;
            User_RegRE : out std_logic;

            -------------------------
            -- Signals and interrupts
            -------------------------

            -- This is unused. The Linux implementation of ZestSC1's library
            -- doesn't deliver the interrupt.
            User_Interrupt : in std_logic;

            -----------------
            -- SRAM interface
            -----------------

            -- This is used to store the computed colors,
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

    -- signals connected to the FPGA's USB inputs (coming from PC)
    signal USB_DataIn : std_logic_vector(15 downto 0);
    signal USB_DataInBusy : std_logic;
    signal USB_DataInWE : std_logic;

    -- signals connected to the FPGA's USB outputs (going to PC)
    signal USB_DataOut : std_logic_vector(15 downto 0);
    signal USB_DataOutBusy : std_logic;
    signal USB_DataOutWE : std_logic := '0';

    -- SRAM interface
    signal SRAMAddr : std_logic_vector(22 downto 0);
    signal SRAMDataOut : std_logic_vector(17 downto 0);
    signal SRAMDataIn : std_logic_vector(17 downto 0);
    signal SRAMWE : std_logic;
    signal SRAMRE : std_logic;
    signal SRAMValid : std_logic;

    -- Interrupt signal
    signal Interrupt : std_logic;

    -- The State Machine (TM)
    type state_type is (
        receiving_input,         -- waiting for X,Y of upper left corner
        drawRows,                -- outer loop (per row)
        drawPixels,              -- inner loop (per pixel)
        waitForMandelbrot,       -- wait for engine to compute color
        drawPixelsWaitForWrite,  -- engine finished, write to SRAM

        waitForDMAtoPC,          -- wait for PC to initiate USB burst read
        DMAing,                  -- ...and read from memory
        DMAwaitingSRAM,
        DMAwaitingSRAM2,         -- ...read two pixels, in fact
        DMAwaitingSRAM3,         -- since our USB bus is 16-bit big
        DMAwaitingForUSB,        -- wait for USB to say it's ready
        DMAwaitingForUSB2        -- and send the data.
    );
    signal state : state_type;

    -- When debugging what is happening, these store additional info.
    signal debug1 : std_logic_vector(31 downto 0);
    signal debug2 : std_logic_vector(31 downto 0);

    -- Flag signalling we received all inputs and should start processing.
    signal startComputing : std_logic := '0';

    -- The size of the window (in pixels) that we are computing
    constant spanx : integer := 640;
    constant spany : integer := 480;

    -- The two loop counters - outer (Y)
    signal RowsToCompute : natural range 0 to spany;

    -- ...and inner (X)
    signal PixelsToCompute : natural range 0 to spanx;


    signal PixelAddrInSRAM : unsigned(22 downto 0);

    -- Data back to PC...
    signal ReadCount : natural;
    signal ReadingActive : std_logic := '0';

    -- Signals used to interface with Mandelbrot engine
    signal input_x, input_y     : std_logic_vector(31 downto 0);
    signal input_x_orig         : std_logic_vector(31 downto 0);
    signal startMandelEngine    : std_logic;
    signal OutputNumber         : std_logic_vector(7 downto 0);
    signal mandelEngineFinished : std_logic;

    signal USB_DataOutStaging : std_logic_vector(7 downto 0);
begin

    -- Tie unused signals
    User_Signals <= "ZZZZZZZZ";
    LEDs(7 downto 1) <= "1111111";
    IO_CLK_N <= 'Z';
    IO_CLK_P <= 'Z';
    Interrupt <= '0';

    IO <= (0=>LEDs(0), 1=>LEDs(1), 41=>LEDs(2), 42=>LEDs(3), 43=>LEDs(4),
           44=>LEDs(5), 45=>LEDs(6), 46=>LEDs(7), others => 'Z');

    process (RST, CLK)
    begin
        if (RST='1') then
            input_x <= X"00000000";
            input_y <= X"00000000";
            state <= receiving_input;
            SRAMDataOut <= (others => '0');
            debug1 <= (others => '0');
            debug2 <= (others => '0');
            ReadingActive <= '0';
            USB_DataOutWE <= '0';
            USB_DataOut <= (others => '0');
            USB_DataInBusy <= '0';

        elsif rising_edge(CLK) then
            SRAMWE <= '0';
            SRAMRE <= '0';
            USB_DataInBusy <= '0';
            startComputing <= '0';
            startMandelEngine <= '0';
            ReadingActive <= '0';
            USB_DataOutWE <= '0';

            -- Is the PC calling ZestSC1WriteRegister?
            if WE = '1' then

                -- He is! What address is he writing in?
                case Addr is

                    -- Ah. He is giving the X coordinate.
                    when X"2060" => input_x(7 downto 0) <= DataIn;
                    when X"2061" => input_x(15 downto 8) <= DataIn;
                    when X"2062" => input_x(23 downto 16) <= DataIn;
                    when X"2063" => input_x(31 downto 24) <= DataIn;
                                    debug2 <= X"AAAAAAAA";

                    -- Ah. He is giving the Y coordinate.
                    when X"2064" => input_y(7 downto 0) <= DataIn;
                    when X"2065" => input_y(15 downto 8) <= DataIn;
                    when X"2066" => input_y(23 downto 16) <= DataIn;
                    when X"2067" => input_y(31 downto 24) <= DataIn;
                                    debug2 <= X"55555555";
                                    RowsToCompute <= spany;
                                    PixelAddrInSRAM <= (others => '0');
                                    startComputing <= '1';

                    when X"2080" => ReadingActive <= '1';
                                    ReadCount <= spanx*spany;
                                    SRAMAddr <= (others => '0');

                    when others =>
                end case;

            end if; -- WE='1'

            case state is
                when receiving_input =>
                    debug2 <= X"22222222";
                    if startComputing = '1' then
                        input_x_orig <= input_x;
                        state <= drawRows;
                    end if;

                when drawRows =>
                    if RowsToCompute /= 0 then
                        RowsToCompute <= RowsToCompute - 1;
                        debug2 <= std_logic_vector(to_unsigned(RowsToCompute, debug2'length));
                        PixelsToCompute <= spanx;
                        state <= drawPixels;
                    else
                        state <= waitForDMAtoPC;
                        SRAMAddr <= (others => '0');
                    end if;

                when drawPixels =>
                    if PixelsToCompute /= 0 then
                        PixelsToCompute <= PixelsToCompute - 1;
                        debug1 <= std_logic_vector(to_unsigned(PixelsToCompute, debug1'length));
                        startMandelEngine <= '1';
                        state <= waitForMandelbrot;
                    else
                        input_x <= input_x_orig;
                        -- Go down by 2.2/480
                        input_y <= std_logic_vector(unsigned(input_y) - 615164);
                        state <= drawRows;
                    end if;

                when waitForMandelbrot =>
                    if mandelEngineFinished = '0' then
                        state <= waitForMandelbrot;
                    else
                        SRAMDataOut <= "0000000000" & OutputNumber;
                        -- Go right by 3.3/640.0
                        input_x <= std_logic_vector(unsigned(input_x) + 692060);
                        SRAMAddr <= std_logic_vector(PixelAddrInSRAM);
                        PixelAddrInSRAM <= PixelAddrInSRAM + 1;
                        state <= drawPixelsWaitForWrite;
                    end if;

                when drawPixelsWaitForWrite =>
                    SRAMWE <= '1';
                    state <= drawPixels;

                when waitForDMAtoPC =>
                    debug2 <= X"99999999";
                    if ReadingActive = '1' then
                        state <= DMAing;
                    else
                        state <= waitForDMAtoPC;
                    end if;

                when DMAing =>
                    debug2 <= std_logic_vector(to_unsigned(ReadCount, debug2'length));
                    if ReadCount /= 0 then
                        SRAMRE <= '1';
                        state <= DMAwaitingSRAM;
                    else
                        state <= receiving_input;
                    end if;

                when DMAwaitingSRAM =>
                    if SRAMValid = '1' then
                        USB_DataOutStaging <= SRAMDataIn(7 downto 0);
                        ReadCount <= ReadCount - 1;
                        SRAMAddr <= std_logic_vector(unsigned(SRAMAddr) + 1);
                        state <= DMAwaitingSRAM2;
                    else
                        state <= DMAwaitingSRAM;
                    end if;

                when DMAwaitingSRAM2 =>
                    SRAMRE <= '1';
                    state <= DMAwaitingSRAM3;

                when DMAwaitingSRAM3 =>
                    if SRAMValid = '1' then
                        USB_DataOut <= SRAMDataIn(7 downto 0) & USB_DataOutStaging;
                        ReadCount <= ReadCount - 1;
                        SRAMAddr <= std_logic_vector(unsigned(SRAMAddr) + 1);
                        state <= DMAwaitingForUSB;
                    else
                        state <= DMAwaitingSRAM2;
                    end if;

                when DMAwaitingForUSB =>
                    if USB_DataOutBusy = '1' then
                        state <= DMAwaitingForUSB;
                    else
                        state <= DMAwaitingForUSB2;
                    end if;

                when DMAwaitingForUSB2 =>
                    if USB_DataOutBusy = '1' then
                        state <= DMAwaitingForUSB;
                    else
                        USB_DataOutWE <= '1';
                        state <= DMAing;
                    end if;

            end case; -- case state is ...

        end if; -- if rising_edge(CLK) ...
    end process;

    process (Addr, debug1, debug2)
    begin
        case Addr is
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
            startWorking => startMandelEngine,
            OutputNumber => OutputNumber,
            finishedWorking => mandelEngineFinished
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

            User_StreamDataIn => USB_DataIn,
            User_StreamDataInWE => USB_DataInWE,
            User_StreamDataInBusy => USB_DataInBusy,

            User_StreamDataOut => USB_DataOut,
            User_StreamDataOutWE => USB_DataOutWE,
            User_StreamDataOutBusy => USB_DataOutBusy,

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

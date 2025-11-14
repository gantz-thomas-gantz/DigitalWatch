-- Clock Divider Module
-- This VHDL module divides the incoming system clock into slower pulses.
-- It produces single-cycle pulses for:
--   - clk_1hz  : 1 pulse per second   (used for timekeeping)
--   - clk_1khz : 1000 pulses per second (used for display multiplexing)
--   - clk_10hz : 10 pulses per second  (used for button sampling)
--
-- Notes:
-- - Each output is a one-system-clock-cycle-wide pulse generated when the
--   corresponding counter reaches its target value.
-- - Reset is synchronous (checked inside rising_edge(clk)) in this implementation.
--
-- To change the produced frequencies, modify the generic CLK_FREQ or change the
-- divisors.
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    generic (
        CLK_FREQ : natural := 100_000_000  -- Input clock frequency in Hz
    );
    port (
        clk      : in  std_logic;    -- System clock input
        rst      : in  std_logic;    -- Synchronous reset (active high)

        -- Output single-cycle pulses (high for exactly one clk cycle)
        clk_1hz  : out std_logic;    -- 1 Hz pulse
        clk_1khz : out std_logic;    -- 1 kHz pulse
        clk_10hz : out std_logic     -- 10 Hz pulse
    );
end clock_divider;

architecture behavioral of clock_divider is

    -- We allocate 32-bit counters (safe for >100 MHz clocks).
    -- If desired, you can reduce the width to save resources.
    signal counter_1hz  : unsigned(31 downto 0) := (others => '0');
    signal counter_1khz : unsigned(31 downto 0) := (others => '0');
    signal counter_10hz : unsigned(31 downto 0) := (others => '0');

    -- Internal registers that hold the pulse outputs (one-cycle wide)
    signal clk_1hz_reg  : std_logic := '0';
    signal clk_1khz_reg : std_logic := '0';
    signal clk_10hz_reg : std_logic := '0';

    -- Target counts (number of system clocks per period minus 1)
    -- Example: for 1 Hz at CLK_FREQ = 100_000_000, MAX_COUNT_1HZ = 100_000_000 - 1
    constant MAX_COUNT_1HZ  : natural := CLK_FREQ - 1;
    constant MAX_COUNT_1KHZ : natural := (CLK_FREQ / 1000) - 1;
    constant MAX_COUNT_10HZ : natural := (CLK_FREQ / 10) - 1;

begin

    ----------------------------------------------------------------------------
    -- 1 Hz generator (single-clock-cycle pulse)
    -- Behaviour:
    --  - On reset: counter and pulse cleared.
    --  - On each rising edge: increment counter
    --  - When counter reaches MAX_COUNT_1HZ: generate a single-cycle pulse
    --    by setting clk_1hz_reg to '1' and resetting the counter to 0.
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter_1hz  <= (others => '0');
                clk_1hz_reg  <= '0';
            else
                if counter_1hz = to_unsigned(MAX_COUNT_1HZ, counter_1hz'length) then
                    -- reached one second: emit one-cycle pulse and reset counter
                    counter_1hz <= (others => '0');
                    clk_1hz_reg <= '1';
                else
                    -- keep counting; ensure pulse is only one cycle long
                    counter_1hz <= counter_1hz + 1;
                    clk_1hz_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 1 kHz generator (single-clock-cycle pulse)
    -- Same structure as 1Hz but targets 1 kHz pulses (every millisecond)
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter_1khz  <= (others => '0');
                clk_1khz_reg  <= '0';
            else
                if counter_1khz = to_unsigned(MAX_COUNT_1KHZ, counter_1khz'length) then
                    counter_1khz <= (others => '0');
                    clk_1khz_reg <= '1';
                else
                    counter_1khz <= counter_1khz + 1;
                    clk_1khz_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 10 Hz generator (single-clock-cycle pulse)
    -- Targets a 10 Hz pulse (every 100 ms) for button sampling, etc.
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter_10hz  <= (others => '0');
                clk_10hz_reg  <= '0';
            else
                if counter_10hz = to_unsigned(MAX_COUNT_10HZ, counter_10hz'length) then
                    counter_10hz <= (others => '0');
                    clk_10hz_reg <= '1';
                else
                    counter_10hz <= counter_10hz + 1;
                    clk_10hz_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Assign internal registers to outputs
    clk_1hz  <= clk_1hz_reg;
    clk_1khz <= clk_1khz_reg;
    clk_10hz <= clk_10hz_reg;

end behavioral;

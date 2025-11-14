-- Clock Divider Module
-- This VHDL module is used to divide the clock frequency.
-- The main purpose of this module is to produce a slower clock signal
-- which can be used for various timing-related functions in digital
-- systems, such as debouncing switches, controlling timing for
-- operations, or generating different timing signals required by
-- other components in the system.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock_divider is
    Port ( CLK_IN       : in  STD_LOGIC;  -- Incoming clock signal
           CLK_OUT      : out STD_LOGIC;  -- Divided clock signal
           RESET        : in  STD_LOGIC   -- Asynchronous reset signal
           );
end clock_divider;

architecture Behavioral of clock_divider is
    signal counter : INTEGER := 0;  -- Counter to track clock cycles
    signal temp_clk : STD_LOGIC := '0';  -- Intermediate clock signal
    constant DIVISOR : INTEGER := 1000000; -- Change this value to set the division factor
begin

    process(CLK_IN, RESET) 
    begin
        if RESET = '1' then
            counter <= 0;
            temp_clk <= '0';
        elsif rising_edge(CLK_IN) then
            counter <= counter + 1;
            if counter = DIVISOR/2 then
                temp_clk <= not temp_clk;  -- Toggle intermediate clock signal
            end if;
            if counter = DIVISOR then
                counter <= 0;  -- Reset counter after reaching divisor
            end if;
        end if;
    end process;

    CLK_OUT <= temp_clk;  -- Assign intermediate clock signal to output

end Behavioral;
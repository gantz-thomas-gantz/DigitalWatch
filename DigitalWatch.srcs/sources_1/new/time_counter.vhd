--------------------------------------------------------------------------------
-- Module: time_counter
-- Purpose: Keep track of current time (HH:MM:SS)
--
-- WHAT THIS MODULE DOES:
-- 1. Count seconds, minutes, and hours
-- 2. Handle overflow (59 sec -> 0 sec + increment minute, etc.)
-- 3. Allow external setting of time (for SET_TIME mode)
-- 4. Provide current time as output
--
-- - Automatic increment every second (using clk_1hz from the clock divider module)
-- - Manual time setting (enable/disable via control signals)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity time_counter is
    port (
        clk      : in  std_logic;                    -- Global system clock
        rst      : in  std_logic;                    -- Synchronous reset (active high)
        clk_1hz  : in  std_logic;                    -- 1 Hz pulse for timekeeping
        
        -- Control signals (from FSM)
        count_enable : in  std_logic;                -- '1' = count time, '0' = hold (e.g., when editing)
        set_enable   : in  std_logic;                -- '1' = manual set mode, '0' = normal
        set_hh       : in  unsigned(4 downto 0);     -- Manual hour input (0..23)
        set_mm       : in  unsigned(5 downto 0);     -- Manual minute input (0..59)
        set_ss       : in  unsigned(5 downto 0);     -- Manual second input (0..59)
        
        -- Outputs
        hh           : out unsigned(4 downto 0);     -- Current hour (0-23)
        mm           : out unsigned(5 downto 0);     -- Current minute (0-59)
        ss           : out unsigned(5 downto 0)      -- Current second (0-59)
    );
end time_counter;

architecture behavioral of time_counter is
    
    -- Internal registers to store time
    signal hh_reg : unsigned(4 downto 0) := (others => '0');
    signal mm_reg : unsigned(5 downto 0) := (others => '0');
    signal ss_reg : unsigned(5 downto 0) := (others => '0');
    
begin

    -- Connect internal registers to outputs
    hh <= hh_reg;
    mm <= mm_reg;
    ss <= ss_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset: set time to 00:00:00
                hh_reg <= (others => '0');
                mm_reg <= (others => '0');
                ss_reg <= (others => '0');

            elsif set_enable = '1' then
                -- Manual set mode:
                -- Load values provided by FSM (atomic update on this clock edge).
                hh_reg <= set_hh;
                mm_reg <= set_mm;
                ss_reg <= set_ss;

            elsif count_enable = '1' and clk_1hz = '1' then
                -- Automatic 1 Hz increment with cascading overflow
                -- STEP 1: Seconds
                if ss_reg = to_unsigned(59, ss_reg'length) then
                    ss_reg <= (others => '0'); 

                    -- STEP 2: Minutes 
                    if mm_reg = to_unsigned(59, mm_reg'length) then
                        mm_reg <= (others => '0');  

                        -- STEP 3: Hours
                        if hh_reg = to_unsigned(23, hh_reg'length) then
                            hh_reg <= (others => '0');  -- wrap hours to 0 (midnight)
                        else
                            hh_reg <= hh_reg + 1;      
                        end if;

                    else
                        mm_reg <= mm_reg + 1;  
                    end if;

                else
                    ss_reg <= ss_reg + 1; 
                end if;

            else
                -- Hold current values (no change)
                hh_reg <= hh_reg;
                mm_reg <= mm_reg;
                ss_reg <= ss_reg;
            end if;
        end if;
    end process;

end behavioral;

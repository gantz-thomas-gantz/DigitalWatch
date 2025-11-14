library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_level is
end entity;

architecture bench of tb_top_level is

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';

    signal btn_mode   : std_logic := '0';
    signal btn_select : std_logic := '0';
    signal btn_inc    : std_logic := '0';
    signal btn_reset  : std_logic := '0';

    signal hh : unsigned(4 downto 0);
    signal mm : unsigned(5 downto 0);
    signal ss : unsigned(5 downto 0);

    signal current_state : std_logic_vector(3 downto 0);
    
    -- Simulation clock period (change as needed)
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock (20 ns period)


begin

    -- Instantiate DUT with a small clock divisor for fast simulation (50)
    DUT: entity work.top_level
        generic map (
            CLK_FREQ => 50   -- small value to make the clock divider produce frequent 1Hz pulses in simulation
        )
        port map (
            clk           => clk,
            rst           => rst,
            btn_mode      => btn_mode,
            btn_select    => btn_select,
            btn_inc       => btn_inc,
            btn_reset     => btn_reset,
            hh_out        => hh,
            mm_out        => mm,
            ss_out        => ss,
            current_state => current_state
        );
    
    -- Clock Process
    clk_proc: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_proc;

    ----------------------------------------------------------------------------
    -- Manual test stimulus
    ----------------------------------------------------------------------------
    stim_proc: process
    begin
        -- Hold reset for a short time (synchronous reset in design)
        rst <= '1';
        wait for 100 ns;
        rst <= '0';

        -- Let the clock run for a short while to observe time increments
        wait for 1 us;

        -- Wait and observe more increments
        wait for 2 us;

        -- Simulate a button press: enter SET_TIME_HH (mode), then return to idle
        btn_mode <= '1';
        wait for 20 ns;    -- one clk period (pulse width of one clock)
        btn_mode <= '0';

        wait for 200 ns;

        -- Press increment a few times to change hour (btn_inc pulses)
        btn_inc <= '1';
        wait for 20 ns;
        btn_inc <= '0';
        wait for 40 ns;
        btn_inc <= '1';
        wait for 20 ns;
        btn_inc <= '0';


        -- Press mode repeatedly to cycle to alarm (and back to idle)
        btn_mode <= '1';
        wait for 20 ns; btn_mode <= '0';
        wait for 40 ns;
        btn_mode <= '1';
        wait for 20 ns; btn_mode <= '0';

        wait for 200 ns;

        -- Finish simulation
        wait for 1 ms;

        wait;
    end process stim_proc;

end architecture bench;
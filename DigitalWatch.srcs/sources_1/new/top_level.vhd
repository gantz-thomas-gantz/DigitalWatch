library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    generic (
        CLK_FREQ : natural := 100_000_000  -- input clock frequency in Hz (adjust for target board)
    );
    port (
        -- Physical interface (minimal)
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Button inputs (for now we expect these to be already debounced/pulsed
        -- by the testbench or external logic; we connect them directly to the FSM)
        btn_mode   : in  std_logic;
        btn_select : in  std_logic;
        btn_inc    : in  std_logic;
        btn_reset  : in  std_logic;

        -- Expose current time for testbench / debug
        hh_out     : out unsigned(4 downto 0);
        mm_out     : out unsigned(5 downto 0);
        ss_out     : out unsigned(5 downto 0);

        -- Expose FSM state for debugging (optional)
        current_state : out std_logic_vector(3 downto 0)
    );
end entity;

architecture structural of top_level is

    -- Clock divider outputs
    signal clk_1hz  : std_logic;
    signal clk_1khz : std_logic;
    signal clk_10hz : std_logic;

    -- FSM <-> time_counter control signals
    signal time_count_en_sig : std_logic;
    signal time_set_en_sig   : std_logic;
    signal alarm_set_en_sig  : std_logic;
    signal alarm_arm_sig     : std_logic;
    signal alarm_ack_sig     : std_logic;

    -- Edited values from FSM (to time_counter)
    signal set_hh_sig : unsigned(4 downto 0);
    signal set_mm_sig : unsigned(5 downto 0);
    signal set_ss_sig : unsigned(5 downto 0);

    -- Alarm-related signals (not used yet, tied low)
    signal alarm_triggered_sig : std_logic := '0';
    signal alarm_armed_in_sig  : std_logic := '0';

begin

    -------------------------------------------------------------------------
    -- Instantiate clock_divider
    -------------------------------------------------------------------------
    U_CLOCK_DIV: entity work.clock_divider
        generic map (
            CLK_FREQ => CLK_FREQ
        )
        port map (
            clk      => clk,
            rst      => rst,
            clk_1hz  => clk_1hz,
            clk_1khz => clk_1khz,
            clk_10hz => clk_10hz
        );

    -------------------------------------------------------------------------
    -- Instantiate FSM controller
    -- NOTE: We expect the top-level button ports to be pulses (testbench provides)
    -------------------------------------------------------------------------
    U_FSM: entity work.fsm_controller
        port map (
            clk               => clk,
            rst               => rst,
            btn_mode_pulse    => btn_mode,       -- testbench must provide single-cycle pulses
            btn_select_pulse  => btn_select,
            btn_inc_pulse     => btn_inc,
            btn_reset_pulse   => btn_reset,

            alarm_triggered   => alarm_triggered_sig,
            alarm_armed_in    => alarm_armed_in_sig,

            time_count_en     => time_count_en_sig,
            time_set_en       => time_set_en_sig,
            alarm_set_en      => alarm_set_en_sig,
            alarm_arm         => alarm_arm_sig,
            alarm_ack         => alarm_ack_sig,

            set_hh_out        => set_hh_sig,
            set_mm_out        => set_mm_sig,
            set_ss_out        => set_ss_sig,

            alarm_hh_out      => open, --does not connect to anything for now
            alarm_mm_out      => open,

            edit_mode         => open,
            edit_field        => open,

            current_state     => current_state
        );

    -------------------------------------------------------------------------
    -- Instantiate time_counter
    -------------------------------------------------------------------------
    U_TIME_COUNTER: entity work.time_counter
        port map (
            clk          => clk,
            rst          => rst,
            clk_1hz      => clk_1hz,
            count_enable => time_count_en_sig,
            set_enable   => time_set_en_sig,
            set_hh       => set_hh_sig,
            set_mm       => set_mm_sig,
            set_ss       => set_ss_sig,
            hh           => hh_out,
            mm           => mm_out,
            ss           => ss_out
        );

end architecture;

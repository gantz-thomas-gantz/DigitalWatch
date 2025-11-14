--------------------------------------------------------------------------------
-- Module: fsm_controller
-- Purpose: Main control logic - implements the state machine
--
-- WHAT THIS MODULE DOES:
-- 1. Implements all states from the FSM diagram
-- 2. Handles button inputs and state transitions
-- 3. Generates control signals for other modules
-- 4. Manages which digit is being edited in set modes
--
-- STATES:
-- - IDLE: Normal operation, clock running
-- - SET_TIME_HH / SET_TIME_MM / SET_TIME_SS: Editing current time (hours, minutes, seconds)
-- - SET_ALARM_HH / SET_ALARM_MM: Editing alarm time (hours, minutes)
-- - ACTIVATE_ALARM: Toggle alarm on/off
-- - ALARM_ACTIVE: Alarm is ringing
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_controller is
    port (
        clk              : in  std_logic;               -- System clock
        rst              : in  std_logic;               -- Synchronous reset (active high)

        -- Debounced button pulses (one-cycle wide)
        btn_mode_pulse   : in  std_logic;               -- Cycle modes / confirm
        btn_select_pulse : in  std_logic;               -- Select field in set modes
        btn_inc_pulse    : in  std_logic;               -- Increment selected field
        btn_reset_pulse  : in  std_logic;               -- Reset/clear

        -- Status inputs
        alarm_triggered  : in  std_logic;               -- Alarm module signals ringing
        alarm_armed_in   : in  std_logic;               -- Current armed status (optional input; use for consistency)

        -- Control outputs to other modules
        time_count_en    : out std_logic;               -- '1' = enable time counting
        time_set_en      : out std_logic;               -- '1' = manual time set active
        alarm_set_en     : out std_logic;               -- '1' = manual alarm set active
        alarm_arm        : out std_logic;               -- '1' = arm alarm; '0' = disarm
        alarm_ack        : out std_logic;               -- pulse to acknowledge alarm (stays '1' one cycle when ack'd)

        -- Edited values (to be connected to time_counter / alarm_module)
        set_hh_out       : out unsigned(4 downto 0);    -- edited hour (0-23)
        set_mm_out       : out unsigned(5 downto 0);    -- edited minute (0-59)
        set_ss_out       : out unsigned(5 downto 0);    -- edited seconds (0-59)

        alarm_hh_out     : out unsigned(4 downto 0);    -- edited alarm hour (0-23)
        alarm_mm_out     : out unsigned(5 downto 0);    -- edited alarm minute (0-59)

        -- Edit/display helpers
        edit_mode        : out std_logic;               -- '1' = some digit is flashing
        edit_field       : out std_logic_vector(1 downto 0); -- 00=HH, 01=MM, 10=SS (encodes which of these fields to edit)

        -- Debug / state output (for checking our current state in the simulation results)
        current_state    : out std_logic_vector(3 downto 0)
    );
end entity;

architecture behavioral of fsm_controller is

    -- State type (meta-states removed: SET_TIME and SET_ALARM)
    type state_t is (
        IDLE,
        SET_TIME_HH,
        SET_TIME_MM,
        SET_TIME_SS,
        SET_ALARM_HH,
        SET_ALARM_MM,
        ACTIVATE_ALARM,
        ALARM_ACTIVE
    );

    signal state : state_t := IDLE;

    -- Internal registers for edited time/alarm
    signal set_hh_reg    : unsigned(4 downto 0) := (others => '0');
    signal set_mm_reg    : unsigned(5 downto 0) := (others => '0');
    signal set_ss_reg    : unsigned(5 downto 0) := (others => '0');

    signal alarm_hh_reg  : unsigned(4 downto 0) := (others => '0');
    signal alarm_mm_reg  : unsigned(5 downto 0) := (others => '0');

    -- Internal alarm arm register and ack pulse generator
    signal alarm_arm_reg : std_logic := '0';
    signal alarm_ack_reg : std_logic := '0';

begin

    -- Drive outputs from internal registers
    set_hh_out    <= set_hh_reg;
    set_mm_out    <= set_mm_reg;
    set_ss_out    <= set_ss_reg;

    alarm_hh_out  <= alarm_hh_reg;
    alarm_mm_out  <= alarm_mm_reg;

    alarm_arm     <= alarm_arm_reg;
    alarm_ack     <= alarm_ack_reg;

    -- State machine: controls modes and edited values
    process(clk)
    begin
        if rising_edge(clk) then
            -- Default: clear single-cycle outputs and set safe defaults
            alarm_ack_reg <= '0';

            if rst = '1' or btn_reset_pulse = '1' then
                -- Reset all registers and return to IDLE
                state <= IDLE;

                -- Reset edited time to 00:00:00
                set_hh_reg    <= (others => '0'); -- sets every element of the array (or every bit of vector) to 0
                set_mm_reg    <= (others => '0');
                set_ss_reg    <= (others => '0');

                -- Reset alarm edit values and disarm
                alarm_hh_reg  <= (others => '0');
                alarm_mm_reg  <= (others => '0');
                alarm_arm_reg <= '0';

                -- Defaults for control outputs
                time_count_en <= '1'; -- A signal assignment (<=) inside a process is legal whether the target is an internal signal or an output port.
                time_set_en   <= '0'; -- If assignment happens only inside a rising_edge(clk) branch (a clocked process), the synth will infer a register (flipflop) for that signal/port.
                alarm_set_en  <= '0';
                edit_mode     <= '0';
                edit_field    <= "00";

            else
                -- Default outputs (overridden in states)
                time_count_en <= '0';
                time_set_en   <= '0';
                alarm_set_en  <= '0';
                edit_mode     <= '0';
                edit_field    <= "00"; 

                -- State transitions and behavior
                case state is

                    when IDLE =>
                        -- Normal operation: enable time counting, no edit
                        time_count_en <= '1';
                        edit_mode <= '0';
                        edit_field <= "00";

                        -- Enter set-time mode on mode button -> go directly to SET_TIME_HH
                        if btn_mode_pulse = '1' then
                            state <= SET_TIME_HH;
                        -- If alarm module asserts alarm_triggered, go to ALARM_ACTIVE
                        elsif alarm_triggered = '1' then
                            state <= ALARM_ACTIVE;
                        end if;

                    when SET_TIME_HH =>
                        -- Editing hours
                        time_count_en <= '0';
                        time_set_en   <= '1';
                        edit_mode     <= '1';
                        edit_field    <= "00";  -- HH

                        -- Increment hours on inc pulse (wrap 0..23)
                        if btn_inc_pulse = '1' then
                            if set_hh_reg = to_unsigned(23, set_hh_reg'length) then
                                set_hh_reg <= (others => '0');
                            else
                                set_hh_reg <= set_hh_reg + 1;
                            end if;
                        end if;

                        -- Select moves to minutes
                        if btn_select_pulse = '1' then
                            state <= SET_TIME_MM;
                        -- Mode moves directly to alarm-setting hours 
                        elsif btn_mode_pulse = '1' then
                            state <= SET_ALARM_HH;
                        end if;

                    when SET_TIME_MM =>
                        -- Editing minutes
                        time_count_en <= '0';
                        time_set_en   <= '1';
                        edit_mode     <= '1';
                        edit_field    <= "01";  -- MM

                        if btn_inc_pulse = '1' then
                            if set_mm_reg = to_unsigned(59, set_mm_reg'length) then
                                set_mm_reg <= (others => '0');
                            else
                                set_mm_reg <= set_mm_reg + 1;
                            end if;
                        end if;

                        if btn_select_pulse = '1' then
                            state <= SET_TIME_SS;
                        elsif btn_mode_pulse = '1' then
                            state <= SET_ALARM_HH;
                        end if;

                    when SET_TIME_SS =>
                        -- Editing seconds
                        time_count_en <= '0';
                        time_set_en   <= '1';
                        edit_mode     <= '1';
                        edit_field    <= "10";  -- SS

                        if btn_inc_pulse = '1' then
                            if set_ss_reg = to_unsigned(59, set_ss_reg'length) then --set_ss_reg'length returns the number of elements (bits) in set_ss_reg
                                set_ss_reg <= (others => '0');
                            else
                                set_ss_reg <= set_ss_reg + 1;
                            end if;
                        end if;

                        if btn_select_pulse = '1' then
                            -- Wrap back to hours
                            state <= SET_TIME_HH;
                        elsif btn_mode_pulse = '1' then
                            state <= SET_ALARM_HH;
                        end if;

                    when SET_ALARM_HH =>
                        -- Edit alarm hours
                        time_count_en <= '0';
                        alarm_set_en  <= '1';
                        edit_mode     <= '1';
                        edit_field    <= "00";  -- use same coding for display

                        if btn_inc_pulse = '1' then
                            if alarm_hh_reg = to_unsigned(23, alarm_hh_reg'length) then
                                alarm_hh_reg <= (others => '0');
                            else
                                alarm_hh_reg <= alarm_hh_reg + 1;
                            end if;
                        end if;

                        if btn_select_pulse = '1' then
                            state <= SET_ALARM_MM;
                        elsif btn_mode_pulse = '1' then
                            -- Move to activation/toggle state to arm/disarm
                            state <= ACTIVATE_ALARM;
                        end if;

                    when SET_ALARM_MM =>
                        -- Edit alarm minutes
                        time_count_en <= '0';
                        alarm_set_en  <= '1';
                        edit_mode     <= '1';
                        edit_field    <= "01";

                        if btn_inc_pulse = '1' then
                            if alarm_mm_reg = to_unsigned(59, alarm_mm_reg'length) then
                                alarm_mm_reg <= (others => '0');
                            else
                                alarm_mm_reg <= alarm_mm_reg + 1;
                            end if;
                        end if;

                        if btn_select_pulse = '1' then
                            -- wrap back to hours
                            state <= SET_ALARM_HH;
                        elsif btn_mode_pulse = '1' then
                            state <= ACTIVATE_ALARM;
                        end if;

                    when ACTIVATE_ALARM =>
                        -- Toggle armed state, then return to IDLE on mode
                        time_count_en <= '1';  -- allow clock to run while toggling
                        edit_mode <= '0';
                        edit_field <= "00";

                        if btn_inc_pulse = '1' then
                            -- toggle
                            if alarm_arm_reg = '1' then
                                alarm_arm_reg <= '0';
                            else
                                alarm_arm_reg <= '1';
                            end if;
                        end if;

                        if btn_mode_pulse = '1' then
                            state <= IDLE;
                        end if;

                    when ALARM_ACTIVE =>
                        -- Alarm is ringing: wait for acknowledge (mode) or reset
                        time_count_en <= '0';  -- pause time counting while alarm active (optional)
                        edit_mode <= '0';

                        if btn_mode_pulse = '1' then
                            -- Acknowledge alarm and return to IDLE
                            alarm_ack_reg <= '1';
                            state <= IDLE;
                        elsif btn_reset_pulse = '1' then
                            -- Reset also acknowledges & returns to IDLE
                            alarm_ack_reg <= '1';
                            state <= IDLE;
                        end if;

                    when others =>
                        state <= IDLE;

                end case; -- case state
            end if;
        end if;
    end process;

    -- Provide a small combinational mapping from state to current_state vector
    process(state)
    begin
        case state is
            when IDLE             => current_state <= "0000";
            when SET_TIME_HH      => current_state <= "0010";
            when SET_TIME_MM      => current_state <= "0011";
            when SET_TIME_SS      => current_state <= "0100";
            when SET_ALARM_HH     => current_state <= "0110";
            when SET_ALARM_MM     => current_state <= "0111";
            when ACTIVATE_ALARM   => current_state <= "1000";
            when ALARM_ACTIVE     => current_state <= "1001";
            when others           => current_state <= "1111";
        end case;
    end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_watch is
  generic (
    clk_freq : natural := 50000000  -- e.g. 50 MHz; match the type/value expected by the testbench
  );
  port (
    clk        : in  std_logic;     -- system clock
    rst        : in  std_logic;
    btn_reset  : in  std_logic;
    btn_mode   : in  std_logic;
    btn_select : in  std_logic;
    btn_inc    : in  std_logic;

    HH : out unsigned(4 downto 0);
    MM : out unsigned(5 downto 0);
    SS : out unsigned(5 downto 0);

    alarm_active : out std_logic
  );
end entity;

architecture rtl of top_watch is

  --------------------------------------------------------------------
  -- State machine definition
  --------------------------------------------------------------------
  type state_t is (
    IDLE,
    SET_TIME,
    SET_ALARM,
    ACTIVATE_ALARM,
    SET_TIME_HH,
    SET_TIME_MM,
    SET_TIME_SS,
    SET_ALARM_HH,
    SET_ALARM_MM
  );

  signal state : state_t := IDLE;

  signal hh_reg : unsigned(4 downto 0) := (others => '0');
  signal mm_reg : unsigned(5 downto 0) := (others => '0');
  signal ss_reg : unsigned(5 downto 0) := (others => '0');
  signal alarm_active_reg : std_logic := '0';

  -- 1 Hz tick generator
  signal tick_cnt   : unsigned(25 downto 0) := (others => '0');
  signal tick_1s    : std_logic := '0';

begin

  HH <= hh_reg;
  MM <= mm_reg;
  SS <= ss_reg;
  alarm_active <= alarm_active_reg;

  --------------------------------------------------------------------
  -- 1 Hz tick generator
  --------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      tick_cnt <= (others => '0');
      tick_1s  <= '0';
    elsif rising_edge(clk) then
      if tick_cnt = to_unsigned(clk_freq - 1, tick_cnt'length) then
        tick_cnt <= (others => '0');
        tick_1s  <= '1';
      else
        tick_cnt <= tick_cnt + 1;
        tick_1s  <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Timekeeping mechanism
  --------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      ss_reg <= (others => '0');
      mm_reg <= (others => '0');
      hh_reg <= (others => '0');
    elsif rising_edge(clk) then
      if tick_1s = '1' then
        -- increment time ALWAYS
        if ss_reg = to_unsigned(59, ss_reg'length) then
          ss_reg <= (others => '0');
          if mm_reg = to_unsigned(59, mm_reg'length) then
            mm_reg <= (others => '0');
            if hh_reg = to_unsigned(23, hh_reg'length) then
              hh_reg <= (others => '0');
            else
              hh_reg <= hh_reg + to_unsigned(1, hh_reg'length);
            end if;
          else
            mm_reg <= mm_reg + to_unsigned(1, mm_reg'length);
          end if;
        else
          ss_reg <= ss_reg + to_unsigned(1, ss_reg'length);
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Main FSM for mode and user interaction
  --------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      state <= IDLE;
      alarm_active_reg <= '0';
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          if btn_mode = '1' then
            state <= SET_TIME;
          end if;

        when SET_TIME =>
          if btn_mode = '1' then
            state <= SET_ALARM;
          elsif btn_select = '1' then
            state <= SET_TIME_HH;
          end if;

        when SET_TIME_HH =>
          if btn_select = '1' then
            state <= SET_TIME_MM;
          elsif btn_inc = '1' then
            if hh_reg = to_unsigned(23, hh_reg'length) then
              hh_reg <= (others => '0');
            else
              hh_reg <= hh_reg + to_unsigned(1, hh_reg'length);
            end if;
          end if;

        when SET_TIME_MM =>
          if btn_select = '1' then
            state <= SET_TIME_SS;
          elsif btn_inc = '1' then
            if mm_reg = to_unsigned(59, mm_reg'length) then
              mm_reg <= (others => '0');
            else
              mm_reg <= mm_reg + to_unsigned(1, mm_reg'length);
            end if;
          end if;

        when SET_TIME_SS =>
          if btn_select = '1' then
            state <= SET_TIME;
          elsif btn_inc = '1' then
            if ss_reg = to_unsigned(59, ss_reg'length) then
              ss_reg <= (others => '0');
            else
              ss_reg <= ss_reg + to_unsigned(1, ss_reg'length);
            end if;
          end if;

        when SET_ALARM =>
          if btn_mode = '1' then
            state <= ACTIVATE_ALARM;
          elsif btn_select = '1' then
            state <= SET_ALARM_HH;
          end if;

        when SET_ALARM_HH =>
          if btn_mode = '1' then
            state <= SET_ALARM_MM;
          end if;

        when SET_ALARM_MM =>
          if btn_mode = '1' then
            state <= SET_ALARM;
          end if;

        when ACTIVATE_ALARM =>
          if btn_mode = '1' then
            state <= IDLE;
          elsif btn_inc = '1' then
            alarm_active_reg <= not alarm_active_reg;
          end if;

        when others =>
          state <= IDLE;
      end case;
    end if;
  end process;

end architecture;




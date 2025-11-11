library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_watch is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    btn_reset  : in  std_logic;
    btn_mode   : in  std_logic;
    btn_select : in std_logic;
    btn_inc    : in  std_logic;

    HH : out unsigned(4 downto 0);
    MM : out unsigned(5 downto 0);
    SS : out unsigned(5 downto 0);

    alarm_active : out std_logic
  );
end entity top_watch;

architecture top_watch_architecture of top_watch is

  --------------------------------------------------------------------
  -- State machine definition
  --------------------------------------------------------------------
  type state_t is (
    IDLE,
    SET_HOURS,
    SET_MINUTES,
    SET_SECONDS,
    SET_ALARM_H,
    SET_ALARM_M,
    ALARM_ACTIVE
  );

  signal cur_state : state_t := IDLE;

begin

  --------------------------------------------------------------------
  -- MAIN FSM
  --------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      cur_state <= IDLE;

    elsif rising_edge(clk) then
      case cur_state is

        when IDLE =>
          null;

        when SET_HOURS =>
          null;

        when SET_MINUTES =>
          null;

        when SET_SECONDS =>
          null;

        when SET_ALARM_H =>
          null;

        when SET_ALARM_M =>
          null;

        when ALARM_ACTIVE =>
          null;

      end case;
    end if;
  end process;

end architecture top_watch_architecture;



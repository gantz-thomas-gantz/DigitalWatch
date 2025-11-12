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
    SET_TIME,
    SET_ALARM,
    ACTIVATE_ALARM,
    SET_TIME_HH,
    SET_TIME_MM,
    SET_TIME_SS,
    SET_ALARM_HH,
    SET_ALARM_MM,
  );

  signal state : state_t := IDLE;

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
          if btn_mode = '1' then 
            state <= SET_TIME;

        when SET_TIME =>
          if btn_mode = '1' then 
            state <= SET_ALARM;
          if btn_select = '1' then 
            state <= SET_TIME_HH;

        when SET_ALARM =>
          if btn_mode = '1' then 
            state <= ACTIVATE_ALARM;
          if btn_select = '1' then 
            state <= SET_ALARM_HH;

        when SET_TIME_HH =>
          if btn_select = '1' then 
            state <= SET_TIME_MM;
          if btn_inc = '1' then 
            state <= SET_TIME_HH;

        when SET_TIME_MM =>
          if btn_select = '1' then 
            state <= SET_TIME_SS;
          if btn_inc = '1' then 
            state <= SET_TIME_MM;

        when SET_TIME_SS =>
          if btn_select = '1' then 
            state <= SET_TIME;
          if btn_inc = '1' then 
            state <= SET_TIME_SS;
          
        when SET_ALARM_HH =>
          if btn_mode = '1' then 
            state <= SET_ALARM_MM;
          if btn_inc = '1' then 
            state <= SET_ALARM_HH;

        when SET_ALARM_MM =>
          if btn_mode = '1' then 
            state <= SET_ALARM;
          if btn_inc = '1' then 
            state <= SET_ALARM_MM;

        when ACTIVATE_ALARM =>
          if btn_mode = '1' then 
            state <= IDLE;

      end case;
    end if;
  end process;

end architecture top_watch_architecture;



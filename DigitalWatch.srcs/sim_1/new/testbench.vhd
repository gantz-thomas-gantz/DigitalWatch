library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity test is
end test;

architecture a of test is

  -- Signals for the DUT
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '0';
  signal btn_reset  : std_logic := '0';
  signal btn_mode   : std_logic := '0';
  signal btn_select : std_logic := '0';
  signal btn_inc    : std_logic := '0';

  signal HH : unsigned(4 downto 0);
  signal MM : unsigned(5 downto 0);
  signal SS : unsigned(5 downto 0);
  signal alarm_active : std_logic;

  -- Component declaration
component top_watch is
  generic (CLK_FREQ : natural := 50_000_000);
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    btn_reset  : in  std_logic;
    btn_mode   : in  std_logic;
    btn_select : in  std_logic;
    btn_inc    : in  std_logic;
    HH         : out unsigned(4 downto 0);
    MM         : out unsigned(5 downto 0);
    SS         : out unsigned(5 downto 0);
    alarm_active : out std_logic
  );
end component;

begin

    -- Clock generation (50 MHz -> 20 ns period)
    clk <= not clk after 10 ns;
    rst <= '1', '0' after 100 ns;  
    btn_mode <= '0',        -- initial value
                '1' after 100 ns,  -- press
                '0' after 200 ns;  -- release

    

    c: top_watch
      generic map (CLK_FREQ => 50)  -- fast simulation
      port map (
        clk => clk,
        rst => rst,
        btn_reset => btn_reset,
        btn_mode => btn_mode,
        btn_select => btn_select,
        btn_inc => btn_inc,
        HH => HH,
        MM => MM,
        SS => SS,
        alarm_active => alarm_active
      );

end a;



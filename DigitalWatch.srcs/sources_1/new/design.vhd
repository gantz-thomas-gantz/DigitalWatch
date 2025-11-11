library ieee;;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_watch is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    btn_inc   : in  std_logic;
    seg       : out std_logic_vector(6 downto 0);
    dp        : out std_logic;
    digit_en  : out std_logic_vector(5 downto 0)
  );
end entity;

architecture rtl of top_watch is

  signal rst       : std_logic;
  signal clk_1hz   : std_logic;
  signal mux_tick  : std_logic;
  signal btn_db    : std_logic;
  signal inc_pulse : std_logic;

  signal sec_count : unsigned(5 downto 0) := (others => '0');

  subtype nibble is unsigned(3 downto 0);
  signal digits : nibble vector(0 to 5);

begin

  rst <= not rst_n;

  -- Clock divider: 50 MHz -> 1 Hz and mux
  clkdiv: entity work.clk_div
    generic map (
      CLOCK_FREQ => 50000000,
      MUX_FREQ   => 1000
    )
    port map (
      clk_in  => clk,
      rst     => rst,
      clk_1hz => clk_1hz,
      clk_2hz => open,
      mux_tick=> mux_tick
    );

  -- Debounce increment button
  deb: entity work.debounce
    port map (
      clk     => clk,
      rst     => rst,
      btn_in  => btn_inc,
      btn_out => btn_db
    );

  -- Edge detect in 1 Hz domain
  process(clk_1hz, rst)
    variable prev : std_logic := '0';
  begin
    if rst = '1' then
      inc_pulse <= '0';
      prev := '0';
    elsif rising_edge(clk_1hz) then
      inc_pulse <= '0';
      if btn_db = '1' and prev = '0' then
        inc_pulse <= '1';
      end if;
      prev := btn_db;
    end if;
  end process;

  -- Simple counter
  process(clk_1hz, rst)
  begin
    if rst = '1' then
      sec_count <= (others => '0');
    elsif rising_edge(clk_1hz) then
      if inc_pulse = '1' then
        if sec_count = 59 then
          sec_count <= (others => '0');
        else
          sec_count <= sec_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Display 00:00:SS
  digits(5) <= "0000";
  digits(4) <= "0000";
  digits(3) <= "0000";
  digits(2) <= "0000";
  digits(1) <= to_unsigned(to_integer(sec_count) / 10, 4);
  digits(0) <= to_unsigned(to_integer(sec_count) mod 10, 4);

  mux: entity work.sevenseg_mux
    generic map ( DIGITS => 6 )
    port map (
      clk_mux     => mux_tick,
      rst         => rst,
      digits      => digits,
      dp_on       => (others => '0'),
      active_flash=> (others => '0'),
      flash_mask  => '1',
      seg_out     => seg,
      dp_out      => dp,
      digit_en    => digit_en
    );

end architecture;


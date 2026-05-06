library ieee;
use ieee.std_logic_1164.all;

entity tb_clk_en is
end tb_clk_en;

architecture tb of tb_clk_en is
    --component "clk_en" declaration--
    component clk_en
    generic ( G_MAX : positive := 5 );
        port (clk : in std_logic;
              rst : in std_logic;
              ce  : out std_logic);
    end component;

    signal sig_clk : std_logic;
    signal sig_rst : std_logic;
    signal sig_ce  : std_logic;

    constant TbPeriod : time := 10 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : clk_en --device under test--
    generic map ( G_MAX => 86400 )
    port map (clk => sig_clk,
              rst => sig_rst,
              ce  => sig_ce);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    sig_clk <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed

        -- Reset generation
        -- ***EDIT*** Check that rst is really your reset signal
        sig_rst <= '1';
        wait for 50 ns;
        sig_rst <= '0';
        wait for 100 ns;

        -- ***EDIT*** Add stimuli here
        wait for 200 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;
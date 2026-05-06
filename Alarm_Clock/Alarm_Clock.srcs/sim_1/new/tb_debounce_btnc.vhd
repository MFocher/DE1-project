library ieee;
use ieee.std_logic_1164.all;

entity tb_debounce_btnc is
end tb_debounce_btnc;

architecture tb of tb_debounce_btnc is

    component debounce_btnc
        port (clk          : in std_logic;
              rst          : in std_logic;
              btnc_in      : in std_logic;
              btnc_state   : out std_logic;
              btnc_release : out std_logic;
              btnc_press   : out std_logic);
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal btnc_in      : std_logic;
    signal btnc_state   : std_logic;
    signal btnc_release : std_logic;
    signal btnc_press   : std_logic;

    constant TbPeriod : time := 10 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : debounce_btnc
    port map (clk          => clk,
              rst          => rst,
              btnc_in      => btnc_in,
              btnc_state   => btnc_state,
              btnc_release => btnc_release,
              btnc_press   => btnc_press);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

        stimuli : process
    begin
        btnc_in <= '0';

        -- Reset generation
        rst <= '1';
        wait for 50 ns;
        rst <= '0';

        -- Simulate button bounce on press
        report "Simulating button press with bounce";

        wait for 100 ns;
        btnc_in <= '1';
        wait for 50 ns;
        btnc_in <= '0';
        wait for 50 ns;
        btnc_in <= '1';
        wait for 250 ns;
        btnc_in <= '0';  -- Final stable press

        -- Simulate button bounce on release
        report "Simulating button release with bounce";

        wait for 20 ns;
        btnc_in <= '1';
        wait for 60 ns;
        btnc_in <= '0';
        wait for 30 ns;
        btnc_in <= '1';
        wait for 50 ns;
        btnc_in <= '0';  -- Final release
        wait for 300 ns;

        -- Stop the clock and hence terminate the simulation
        report "Simulation finished";
        TbSimEnded <= '1';
        wait;

    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_debounce_btnc of tb_debounce_btnc is
    for tb
    end for;
end cfg_tb_debounce_btnc;
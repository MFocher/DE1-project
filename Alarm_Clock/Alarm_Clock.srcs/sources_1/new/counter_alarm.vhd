library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;  

entity counter_alarm is
        port (
        clk     : in  std_logic;                             
        rst     : in  std_logic;                           

        sw_0 : in std_logic;
        btnc_press : in std_logic;
        btnu_press : in std_logic;
        btnr_press : in std_logic;
        
        alarm_on : out std_logic;        ---1 => aktivní budík
                                
        total_alarm_seconds : out std_logic_vector(16 downto 0);    ---2 na 17 = az 131072 abychom meli dost mista na až 86400 sekund
        
        alr_minutes_x0 : out std_logic_vector(3 downto 0);      ---2 na 4 = az 16 abychom meli 0,1,2,...,9 = na 10 cisel
        alr_minutes_0x : out std_logic_vector(3 downto 0);      ---2 na 4 = az 16 abychom meli 0,1,2,...,9 = na 10 cisel
        alr_hours_x0   : out std_logic_vector(3 downto 0);      ---2 na 4 = az 16 abychom meli 0,1,2,...,9 = na 10 cisel
        alr_hours_0x   : out std_logic_vector(3 downto 0);       ---2 na 4 = az 16 abychom meli 0,1,2,...,9 = na 10 cisel
        
        alr_dp_out : out std_logic_vector(7 downto 0)   --!!!
    );
end entity counter_alarm;

-------------------------------------------------

architecture Behavioral of counter_alarm is
 
    signal sig_alarm_on : std_logic := '0';     ---zapnutí/vypnutí budíku
    signal sig_time_unit : integer range 0 to 3 := 3;     ---jaký zrovna řád chceme (0-> 0-9, 1-> 0-5, 2-> 0-9, 3-> 0-2)
    
    signal sig_m_0x : integer range 0 to 9 := 0;
    signal sig_m_x0 : integer range 0 to 5 := 0;
    signal sig_h_0x : integer range 0 to 9 := 0;
    signal sig_h_x0 : integer range 0 to 2 := 0;
    
    signal sig_total_alarm_seconds : integer := 0;
begin

   
    p_alarm_activate : process (clk) is     ---zapnutí a vypnutí pomocí BTNC
    begin
        if rising_edge(clk) then
            if rst = '1' then    
                sig_alarm_on <= '0';

            elsif (btnc_press = '1') then       
                sig_alarm_on <= not sig_alarm_on;       ---překlopeni zap/vyp       
            end if;
        end if;
    end process p_alarm_activate;
    
    p_time_unit_edit : process (clk) is     ---prepinani mezi rady budiku
    begin
        if rising_edge(clk) then
            if (rst = '1' and sw_0 = '0') then         ---při startu cloku řád bude na 3
                sig_time_unit <= 3;
            elsif (btnr_press = '1' and sw_0 = '0') then       ---při potvrzeni se řád zase přepne na 0 pokud byl na 3
                if (sig_time_unit = 0) then     
                    sig_time_unit <= 3;
                else sig_time_unit <= sig_time_unit - 1;        ---jinak se posune o další výše
                end if;
            end if;
        end if;
    end process p_time_unit_edit;
    
    p_alarm_setting : process (clk) is 
    begin   
        if rising_edge(clk) then
            if (rst = '1') then
                sig_m_0x <= 0;
                sig_m_x0 <= 0;
                sig_h_0x <= 0;
                sig_h_x0 <= 0;
                elsif (btnu_press = '1' and sw_0 = '0') then
                    case sig_time_unit is
                        when 0 =>
                            if (sig_m_0x = 9) then
                                sig_m_0x <= 0;
                            else sig_m_0x <= sig_m_0x + 1;
                            end if;
                        when 1 =>
                            if (sig_m_x0 = 5) then
                                sig_m_x0 <= 0;
                            else sig_m_x0 <= sig_m_x0 + 1;
                            end if;
                        when 2 =>
                            if (sig_h_x0 = 2) then
                                if (sig_h_0x = 3) then
                                    sig_h_0x <= 0;
                                else sig_h_0x <= sig_h_0x + 1; 
                                end if;
                            else 
                                if (sig_h_0x = 9) then
                                    sig_h_0x <= 0;
                                else sig_h_0x <= sig_h_0x + 1;
                                end if;
                            end if;
                        when 3 =>
                            if (sig_h_x0 = 2) then
                                sig_h_x0 <= 0;
                            else sig_h_x0 <= sig_h_x0 + 1;
                                if sig_h_x0 = 1 and sig_h_0x > 3 then
                                    sig_h_0x <= 3;
                                end if;
                            end if;
                end case;
            end if;
        end if;
    end process p_alarm_setting;
    
    p_dp_out : process (sig_time_unit) is
    begin
        alr_dp_out <= "11111111";
        
        case sig_time_unit is
            when 0 => alr_dp_out(0) <= '0'; 
            when 1 => alr_dp_out(1) <= '0';
            when 2 => alr_dp_out(2) <= '0';
            when 3 => alr_dp_out(3) <= '0';
            when others => null;
        end case;
    end process p_dp_out;
    
    sig_total_alarm_seconds <= ((sig_m_0x * 60) + (sig_m_x0 * 600) + (sig_h_0x * 3600) + (sig_h_x0 * 36000));
    
    alarm_on <= sig_alarm_on;
    total_alarm_seconds <= std_logic_vector(to_unsigned(sig_total_alarm_seconds, 17)); ---vystup celkových sekund
    
    alr_minutes_x0 <= std_logic_vector(to_unsigned(sig_m_x0, 4)); ---prevedeny sekundy na minuty a jejich vystup-x0
    alr_minutes_0x <= std_logic_vector(to_unsigned(sig_m_0x, 4)); ---prevedeny sekundy na minuty a jejich vystup-0x

    alr_hours_x0 <= std_logic_vector(to_unsigned(sig_h_x0, 4)); ---prevedeny sekundy na minuty, pak hodiny a jejich vystup-x0
    alr_hours_0x <= std_logic_vector(to_unsigned(sig_h_0x, 4)); ---prevedeny sekundy na minuty, pak hodiny a jejich vystup-0x

end Behavioral;
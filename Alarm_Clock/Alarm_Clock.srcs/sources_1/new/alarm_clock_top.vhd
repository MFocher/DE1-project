library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alarm_clock_top is
    Port (  clk : in std_logic;
            
            btnu : in std_logic;
            btnc : in std_logic;
            btnr : in std_logic;
            btnd : in std_logic;
            sw : in std_logic_vector (15 downto 0);
            
            seg : out std_logic_vector (6 downto 0);
            an : out std_logic_vector (7 downto 0);
            led16_r : out std_logic;

            dp : out std_logic
            
            --neimplementovane prvky k audio vystupu:
            --aud_pwm : out std_logic;
            --aud_sd : out std_logic
            );
end alarm_clock_top;

architecture Behavioral of alarm_clock_top is
    
    component clk_en is
    generic ( G_max : positive); 
    Port (  clk : in std_logic;
            rst : in std_logic;
            ce : out std_logic
            );
    end component clk_en;
    
    component debounce is
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            btn_in : in STD_LOGIC;
            btn_state : out STD_LOGIC;
            btn_press : out STD_LOGIC
            );
    end component debounce;
    
    
    
    component counter_clock is
    port (  clk     : in  std_logic;                             
            rst     : in  std_logic;                           
            en      : in  std_logic; 
        
            sw_0 : in std_logic;
            btnc_press : in std_logic;
            btnu_press : in std_logic;
            btnr_press : in std_logic;
                            
            total_clock_seconds : out std_logic_vector(16 downto 0);    
        
            clk_minutes_x0 : out std_logic_vector(3 downto 0);     
            clk_minutes_0x : out std_logic_vector(3 downto 0);      
            clk_hours_x0   : out std_logic_vector(3 downto 0);      
            clk_hours_0x   : out std_logic_vector(3 downto 0);
            
            clk_dp_out : out std_logic_vector(7 downto 0)       
            );
    end component counter_clock;
    
    component counter_alarm is
    port (  clk     : in  std_logic;                             
            rst     : in  std_logic;                           

            sw_0 : in std_logic;
            btnc_press : in std_logic;
            btnu_press : in std_logic;
            btnr_press : in std_logic;
        
            alarm_on : out std_logic;        
                                
            total_alarm_seconds : out std_logic_vector(16 downto 0);    
        
            alr_minutes_x0 : out std_logic_vector(3 downto 0);      
            alr_minutes_0x : out std_logic_vector(3 downto 0);      
            alr_hours_x0   : out std_logic_vector(3 downto 0);      
            alr_hours_0x   : out std_logic_vector(3 downto 0);
            
            alr_dp_out : out std_logic_vector(7 downto 0)       
            );
    end component counter_alarm;
    
    component seconds_compare is
    Port (  rst             : in STD_LOGIC;
            clk             : in STD_LOGIC;
            ce              : in STD_LOGIC; 
            alarm_en        : in std_logic;
            buzzer_off      : in STD_LOGIC; 
            s_clock         : in STD_LOGIC_vector (16 downto 0); 
            s_alarm         : in STD_LOGIC_vector (16 downto 0); 
            buzzer_interval : out STD_LOGIC
            ); 
    end component seconds_compare;
    
    component clock_display is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           clk_minutes_x0 : in std_logic_vector(3 downto 0);       
           clk_minutes_0x : in std_logic_vector(3 downto 0);       
           clk_hours_x0   : in std_logic_vector(3 downto 0);       
           clk_hours_0x   : in std_logic_vector(3 downto 0);       
           
           alr_minutes_x0 : in std_logic_vector(3 downto 0);       
           alr_minutes_0x : in std_logic_vector(3 downto 0);       
           alr_hours_x0   : in std_logic_vector(3 downto 0);       
           alr_hours_0x   : in std_logic_vector(3 downto 0);       
           
           seg : out STD_LOGIC_VECTOR (6 downto 0);
           an : out STD_LOGIC_VECTOR (7 downto 0);
           
           dp_in : in std_logic_vector(7 downto 0);         --!!
           dp : out std_logic                               --!!
           );
    end component clock_display;        
    
    -- Internal signal(s)
    signal sig_cnt_en : std_logic;
    signal sig_btnu_press : std_logic;
    signal sig_btnc_press : std_logic;
    signal sig_btnr_press : std_logic;
    
    signal sig_s_clock : std_logic_vector (16 downto 0);
    signal sig_clk_m0x : std_logic_vector (3 downto 0);
    signal sig_clk_mx0 : std_logic_vector (3 downto 0);
    signal sig_clk_h0x : std_logic_vector (3 downto 0);
    signal sig_clk_hx0 : std_logic_vector (3 downto 0);
    
    signal sig_s_alarm : std_logic_vector (16 downto 0);
    signal sig_alr_m0x : std_logic_vector (3 downto 0);
    signal sig_alr_mx0 : std_logic_vector (3 downto 0);
    signal sig_alr_h0x : std_logic_vector (3 downto 0);
    signal sig_alr_hx0 : std_logic_vector (3 downto 0);
    
    signal sig_buzz_off : std_logic;
    
    signal sig_clk_dp_out : std_logic_vector(7 downto 0);
    signal sig_alr_dp_out : std_logic_vector(7 downto 0);
    signal sig_dp_out     : std_logic_vector(7 downto 0);
    
    signal sig_unused_sw : std_logic_vector(12 downto 0);
    attribute dont_touch : string;
    attribute dont_touch of sig_unused_sw : signal is "true";
    
begin
    sig_unused_sw <= sw(14 downto 2);

    sig_dp_out <= "11111111" when sw(1) = '1' else
                         sig_clk_dp_out when sw(0) = '1' else
                         sig_alr_dp_out;
    
    gen_Hz : clk_en
        generic map (G_max => 100_000_000)  --- pro desku 100_000_000, pro sim 20
        port map (
            clk => clk,
            rst => sw(15),
            ce => sig_cnt_en
        );
    
    debounce_btnu_0 : debounce
        port map (
            clk       => clk,
            rst       => sw(15),
            btn_in    => btnu,
            btn_press => sig_btnu_press,
            btn_state => open
        );
        
    debounce_btnc_0 : debounce
        port map (
            clk       => clk,
            rst       => sw(15),
            btn_in    => btnc,
            btn_press => sig_btnc_press,
            btn_state => open
        );
        
    debounce_btnr_0 : debounce
        port map (
            clk       => clk,
            rst       => sw(15),
            btn_in    => btnr,
            btn_press => sig_btnr_press,
            btn_state => open
        );
        
    debounce_btnd_0 : debounce
        port map (
            clk       => clk,
            rst       => sw(15),
            btn_in    => btnd,
            btn_press => sig_buzz_off,
            btn_state => open
        );
        
    counter_clock_0 : counter_clock
        port map (
            clk     => clk,
            rst     => sw(15),
            en => sig_cnt_en,
            btnu_press => sig_btnu_press,
            btnc_press => sig_btnc_press,
            btnr_press => sig_btnr_press,
            sw_0 => sw(0),
            
            total_clock_seconds => sig_s_clock,
            clk_minutes_0x => sig_clk_m0x,
            clk_minutes_x0 => sig_clk_mx0,
            clk_hours_0x => sig_clk_h0x,
            clk_hours_x0 => sig_clk_hx0,
            
            clk_dp_out => sig_clk_dp_out
        );
    counter_alarm_0 : counter_alarm
        port map (
            clk     => clk,
            rst     => sw(15),

            btnu_press => sig_btnu_press,
            btnc_press => sig_btnc_press,
            btnr_press => sig_btnr_press,
            sw_0 => sw(0),
            
            total_alarm_seconds => sig_s_alarm,
            alr_minutes_0x => sig_alr_m0x,
            alr_minutes_x0 => sig_alr_mx0,
            alr_hours_0x => sig_alr_h0x,
            alr_hours_x0 => sig_alr_hx0,
            
            alr_dp_out => sig_alr_dp_out
        );
        
    compare : seconds_compare
        port map (
            clk => clk,
            rst => sw(15),
            ce => sig_cnt_en,
            buzzer_off => sig_buzz_off,
            alarm_en => sw(1),
            
            s_clock => sig_s_clock,
            s_alarm => sig_s_alarm,
            
            buzzer_interval => led16_r
            
            --neimplementovane prvky k audio vystupu:
            --buzzer_interval => aud_pwm,
            --aud_sd <= '1'
        );
    
    display : clock_display
        port map (
            clk => clk,
            rst => sw(15),
            
            clk_minutes_0x => sig_clk_m0x,
            clk_minutes_x0 => sig_clk_mx0,
            clk_hours_0x => sig_clk_h0x,
            clk_hours_x0 => sig_clk_hx0,
            
            alr_minutes_0x => sig_alr_m0x,
            alr_minutes_x0 => sig_alr_mx0,
            alr_hours_0x => sig_alr_h0x,
            alr_hours_x0 => sig_alr_hx0,
            
            seg => seg,
            an => an,
            
            dp_in => sig_dp_out,
            dp => dp
        );
    
    
end Behavioral;
----------------------------------------------------------------------------------
-- Company: Myway Plus Corporation 
-- Module Name: pwm_if
-- Target Devices: Kintex-7 xc7k70t
-- Tool Versions: Vivado 2016.4
-- Create Date: 2017/01/10
-- Revision: 1.0
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity pwm_if is
    port (
        CLK_IN           : in std_logic;
        RESET_IN        : in std_logic;
        nPWM_UP_OUT    : out std_logic; --nUSER_OPT_OUT(0)
        nPWM_UN_OUT    : out std_logic; --nUSER_OPT_OUT(1)
        nPWM_VP_OUT    : out std_logic; --nUSER_OPT_OUT(2)
        nPWM_VN_OUT    : out std_logic; --nUSER_OPT_OUT(3)
        nPWM_WP_OUT    : out std_logic; --nUSER_OPT_OUT(4)
        nPWM_WN_OUT    : out std_logic; --nUSER_OPT_OUT(5)
        nUSER_OPT_OUT : out std_logic_vector (23 downto 6);

        UPDATE    : in std_logic;
        CARRIER   : in std_logic_vector (15 downto 0);
        CNT_REF_RECT : in std_logic_vector (15 downto 0);
        CNT_REF_PWMC : in std_logic_vector (15 downto 0);
        U_REF    : in std_logic_vector (15 downto 0);
        V_REF    : in std_logic_vector (15 downto 0);
        W_REF    : in std_logic_vector (15 downto 0);
        DEADTIME : in std_logic_vector (12 downto 0);
        GATE_EN_RECT  : in std_logic;
        GATE_EN_PWMC  : in std_logic;
        SYNC_IN  : in std_logic
    );
end pwm_if;

architecture Behavioral of pwm_if is

    component deadtime_if is
        Port (
            CLK_IN     : in std_logic;
            RESET_IN : in std_logic;
            DT           : in std_logic_vector(12 downto 0);
            G_IN        : in std_logic;
            G_OUT      : out std_logic
        );
    end component;

    signal carrier_cnt_max_b : std_logic_vector (15 downto 0);
    signal carrier_cnt_max_bb : std_logic_vector (15 downto 0);
    signal carrier_cnt_rect   : std_logic_vector (15 downto 0);
    signal carrier_cnt_pwmc   : std_logic_vector (15 downto 0);
    signal carrier_up_down_rect : std_logic;
    signal carrier_up_down_pwmc : std_logic;
    signal cnt_ref_rect_b : std_logic_vector (15 downto 0);
    signal cnt_ref_pwmc_b : std_logic_vector (15 downto 0);
    signal cnt_rst_rect : std_logic;
    signal cnt_rst_pwmc : std_logic;
    signal sync_in_prvs : std_logic;
    signal sync_in_crnt : std_logic;
    signal sync_in_r : std_logic;
    signal sync_cnt  : std_logic_vector (15 downto 0);
    signal u_ref_b : std_logic_vector (15 downto 0);
    signal v_ref_b : std_logic_vector (15 downto 0);
    signal w_ref_b : std_logic_vector (15 downto 0);
    signal u_ref_bb : std_logic_vector (15 downto 0);
    signal v_ref_bb : std_logic_vector (15 downto 0);
    signal w_ref_bb : std_logic_vector (15 downto 0);
    signal pwm_up : std_logic;
    signal pwm_un : std_logic;
    signal pwm_vp : std_logic;
    signal pwm_vn : std_logic;
    signal pwm_wp : std_logic;
    signal pwm_wn : std_logic;
    signal pwm_up_dt : std_logic := '0';
    signal pwm_un_dt : std_logic := '0';
    signal pwm_vp_dt : std_logic := '0';
    signal pwm_vn_dt : std_logic := '0';
--    signal pwm_wp_dt : std_logic := '0';
--    signal pwm_wn_dt : std_logic := '0';
    signal dt_b : std_logic_vector (12 downto 0);
    signal dt_bb : std_logic_vector (12 downto 0);
    signal gate_en_rect_b : std_logic := '0';
    signal gate_en_pwmc_b : std_logic := '0';
    
    attribute mark_debug : string;
    attribute mark_debug of sync_in_crnt: signal is "true";
    attribute mark_debug of sync_in_r: signal is "true";
    attribute mark_debug of sync_cnt: signal is "true";
    attribute mark_debug of cnt_rst_pwmc: signal is "true";
    attribute mark_debug of carrier_cnt_pwmc: signal is "true";
    attribute mark_debug of pwm_wp: signal is "true";

begin

    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                gate_en_rect_b <= '0';
                gate_en_pwmc_b <= '0';
            else
                gate_en_rect_b <= GATE_EN_RECT;
                gate_en_pwmc_b <= GATE_EN_PWMC;
            end if;

            if RESET_IN = '1' then
                carrier_cnt_max_b  <= X"024C"; -- 85kHz
                carrier_cnt_rect   <= X"0000";
                carrier_cnt_pwmc   <= X"0000";
                cnt_ref_rect_b     <= X"024C"; -- 85kHz
                cnt_ref_pwmc_b     <= X"0126"; -- 85kHz
                u_ref_b <= X"0126"; -- m = 0.5
                v_ref_b <= X"0126"; -- m = 0.5
                w_ref_b <= X"0126"; -- m = 0.5
                dt_b <= '0' & X"00A"; -- 100ns
            elsif UPDATE = '1' then
                carrier_cnt_max_b <= CARRIER;
                cnt_ref_rect_b    <= CNT_REF_RECT;
                cnt_ref_pwmc_b    <= CNT_REF_PWMC;
                u_ref_b <= U_REF;
                v_ref_b <= V_REF;
                w_ref_b <= W_REF;
                dt_b <= DEADTIME;
            end if;       

            if RESET_IN = '1' then
                carrier_up_down_rect <= '1';
                carrier_up_down_pwmc <= '1';
                carrier_cnt_max_bb <= X"024C";
            elsif cnt_rst_rect = '1' then
                carrier_up_down_rect <= '1';
            elsif cnt_rst_pwmc = '1' then
                carrier_up_down_pwmc <= '1';
            elsif carrier_cnt_rect >= (carrier_cnt_max_bb -1) and carrier_up_down_rect = '1' then
                carrier_up_down_rect <= '0';
                carrier_cnt_max_bb <= carrier_cnt_max_b;
            elsif carrier_cnt_pwmc >= (carrier_cnt_max_bb -1) and carrier_up_down_pwmc = '1' then
                carrier_up_down_pwmc <= '0';
            end if;

            if RESET_IN = '1' then
                carrier_cnt_rect <= X"0000";
            elsif cnt_rst_rect = '1' then
                carrier_cnt_rect <= X"0000";
            elsif carrier_up_down_rect = '1' then
                carrier_cnt_rect <= carrier_cnt_rect + 1;
            elsif carrier_up_down_rect = '0' and carrier_cnt_rect > X"0000" then
                carrier_cnt_rect <= carrier_cnt_rect - 1;
            end if;
            
            if RESET_IN = '1' then
                carrier_cnt_pwmc <= X"0000";
            elsif cnt_rst_pwmc = '1' then
                carrier_cnt_pwmc <= X"0000";
            elsif carrier_up_down_pwmc = '1' then
                carrier_cnt_pwmc <= carrier_cnt_pwmc + 1;
            elsif carrier_up_down_pwmc = '0' and carrier_cnt_pwmc > X"0000" then
                carrier_cnt_pwmc <= carrier_cnt_pwmc - 1;
            end if;
            
            if RESET_IN = '1' then
                sync_in_prvs <= '0'; sync_in_crnt <= '0';
            else
                sync_in_crnt <= SYNC_IN;
                sync_in_prvs <= sync_in_crnt;
            end if;
            
            if RESET_IN = '1' then
                sync_in_r <= '0';
            elsif sync_in_prvs = '0' and sync_in_crnt = '1' then
                sync_in_r <= '1';
            else
                sync_in_r <= '0';
            end if;
            
            if RESET_IN = '1' then
                sync_cnt <= X"0000";
            elsif sync_in_r = '1' and sync_cnt > X"0320" then
                sync_cnt <= X"0000";
            else
                sync_cnt <= sync_cnt + 1;
            end if;
            
            if RESET_IN = '1' then
                cnt_rst_rect <= '0';
                cnt_rst_pwmc <= '0';
            elsif sync_cnt = cnt_ref_rect_b then
                cnt_rst_rect <= '1';
            elsif sync_cnt = cnt_ref_pwmc_b then
                cnt_rst_pwmc <= '1';
            else
                cnt_rst_rect <= '0';
                cnt_rst_pwmc <= '0';
            end if;

        end if;
    end process;

    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                u_ref_bb <= X"0126"; -- m = 0.5
                v_ref_bb <= X"0126"; -- m = 0.5
                w_ref_bb <= X"0126"; -- m = 0.5
            elsif carrier_cnt_rect = (carrier_cnt_max_bb -1) and carrier_up_down_rect = '1' then
                u_ref_bb <= u_ref_b;
                v_ref_bb <= v_ref_b;
                w_ref_bb <= w_ref_b;
            end if;

            if RESET_IN = '1' then
                pwm_up <= '0';
                pwm_un <= '0';
            elsif carrier_cnt_rect >= u_ref_bb then
                pwm_up <= '0';
                pwm_un <= '1';
            else
                pwm_up <= '1';
                pwm_un <= '0';
            end if;

            if RESET_IN = '1' then
                pwm_vp <= '0';
                pwm_vn <= '0';
            elsif carrier_cnt_rect >= v_ref_bb then
                pwm_vp <= '1';
                pwm_vn <= '0';
            else
                pwm_vp <= '0';
                pwm_vn <= '1';
            end if;

            if RESET_IN = '1' then
                pwm_wp <= '0';
                pwm_wn <= '0';
            elsif carrier_cnt_pwmc >= w_ref_bb then
                pwm_wp <= '0';
                pwm_wn <= '0';
            else
                pwm_wp <= '1';
                pwm_wn <= '0';
            end if;

        end if;
    end process;

    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                dt_bb <= '0' & X"00A"; -- 100ns
            elsif carrier_cnt_rect = (carrier_cnt_max_bb -1) then
                dt_bb <= dt_b;
            end if;
        end if;
    end process;

    dt_up : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_up, G_OUT => pwm_up_dt);
    dt_un : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_un, G_OUT => pwm_un_dt);
    dt_vp : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_vp, G_OUT => pwm_vp_dt);
    dt_vn : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_vn, G_OUT => pwm_vn_dt);
--    dt_wp : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_wp, G_OUT => pwm_wp_dt);
--    dt_wn : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_wn, G_OUT => pwm_wn_dt);

    nPWM_UP_OUT <= not (pwm_up_dt and gate_en_rect_b);
    nPWM_UN_OUT <= not (pwm_un_dt and gate_en_rect_b);
    nPWM_VP_OUT <= not (pwm_vp_dt and gate_en_rect_b);
    nPWM_VN_OUT <= not (pwm_vn_dt and gate_en_rect_b);
    nPWM_WP_OUT <= not (pwm_wp and gate_en_pwmc_b);
    nPWM_WN_OUT <= not (pwm_wn and gate_en_pwmc_b);

    nUSER_OPT_OUT(6) <= not (pwm_up_dt and gate_en_rect_b);
    nUSER_OPT_OUT(7) <= not (pwm_un_dt and gate_en_rect_b);
    nUSER_OPT_OUT(8) <= not (pwm_vp_dt and gate_en_rect_b);
    nUSER_OPT_OUT(9) <= not (pwm_vn_dt and gate_en_rect_b);
    nUSER_OPT_OUT(10) <= not (pwm_wp and gate_en_pwmc_b);
    nUSER_OPT_OUT(11) <= not (pwm_wn and gate_en_pwmc_b);
    nUSER_OPT_OUT(12) <= not (pwm_up_dt and gate_en_rect_b);
    nUSER_OPT_OUT(13) <= not (pwm_un_dt and gate_en_rect_b);
    nUSER_OPT_OUT(14) <= not (pwm_vp_dt and gate_en_rect_b);
    nUSER_OPT_OUT(15) <= not (pwm_vn_dt and gate_en_rect_b);
    nUSER_OPT_OUT(16) <= not (pwm_wp and gate_en_pwmc_b);
    nUSER_OPT_OUT(17) <= not (pwm_wn and gate_en_pwmc_b);
    nUSER_OPT_OUT(18) <= not (pwm_up_dt and gate_en_rect_b);
    nUSER_OPT_OUT(19) <= not (pwm_un_dt and gate_en_rect_b);
    nUSER_OPT_OUT(20) <= not (pwm_vp_dt and gate_en_rect_b);
    nUSER_OPT_OUT(21) <= not (pwm_vn_dt and gate_en_rect_b);
    nUSER_OPT_OUT(22) <= not (pwm_wp and gate_en_rect_b);
    nUSER_OPT_OUT(23) <= not (pwm_wn and gate_en_rect_b);

end Behavioral;


----------------------------------------------------------------------------------
--Deadtime module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity deadtime_if is
    Port (
        CLK_IN     : in std_logic;
        RESET_IN : in std_logic;
        DT           : in std_logic_vector(12 downto 0);
        G_IN        : in std_logic;
        G_OUT      : out std_logic
        );
end deadtime_if;

architecture behavioral of deadtime_if is
signal d_g_in: std_logic;
signal cnt: std_logic_vector(12 downto 0);
signal gate: std_logic;

begin

    process(CLK_IN)
    begin
        if (CLK_IN'event and CLK_IN='1') then
            if RESET_IN = '1' then
                d_g_in <= '0';
            else
                d_g_in <= G_IN;
            end if;

            if RESET_IN = '1' then
                cnt   <= "0000000000001";
                gate <= '0';
            elsif (d_g_in = '0' and G_IN = '1') then
                cnt   <= "0000000000001";
                gate <= '0';
            elsif (cnt >= DT) then
                cnt   <= "1111111111111";
                gate <= d_g_in;
            elsif (cnt /= "1111111111111") then
                cnt   <= cnt + 1;
                gate <= '0';
            else
                gate <= d_g_in;
            end if;
        end if;
    end process;

    G_OUT <= gate;

end behavioral;

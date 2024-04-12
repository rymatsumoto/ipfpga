----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/04/06 16:14:01
-- Design Name: 
-- Module Name: fcs_mpc_if - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
-- use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity fcs_mpc_if is
    port (
        CLK_IN : in std_logic;
        RESET_IN : in std_logic;
        STATE_PRESENT : in std_logic;
        STATE_NEXT : out std_logic;
        PWM_SYNCH_FLAG : in std_logic;
        I1 : in std_logic_vector (15 downto 0); -- integer 16 bit
        I2 : in std_logic_vector (15 downto 0); -- integer 16 bit
        PEAK_COUNT_I1 : in std_logic_vector (15 downto 0);
        PEAK_COUNT_I2 : in std_logic_vector (15 downto 0);
        MPC_A : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        MPC_B : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        MPC_C : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        LPF_A : in std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
        LPF_B : in std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
        V1d : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        P1ref : in std_logic_vector(31 downto 0) -- integer 32 bit
    );
end fcs_mpc_if;

architecture Behavioral of fcs_mpc_if is

    signal counter : std_logic_vector (15 downto 0);
    signal pwm_synch_flag_prvs : std_logic := '0';
    signal state_next_b : std_logic := '1';
    
    signal i1_peak : std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
    signal i2_peak : std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
    signal i1_next_ON : std_logic_vector (15 downto 0); -- integer 16 bit
    signal i1_peak_debug : std_logic_vector (15 downto 0); -- integer 16 bit
    signal i2_peak_debug : std_logic_vector (15 downto 0); -- integer 16 bit
    
    signal p1_present : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
    signal p1_present_debug : std_logic_vector (31 downto 0); -- integer 32 bit
    signal p1_next_ON : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
    signal p1_next_ON_debug : std_logic_vector (31 downto 0); -- integer 32 bit
    
    signal p1_present_lpf : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
    signal p1_present_lpf_debug : std_logic_vector (31 downto 0); -- integer 32 bit
    signal p1_next_ON_lpf : std_logic_vector (31 downto 0); -- integer 32 bit
    signal p1_next_OFF_lpf : std_logic_vector (31 downto 0); -- integer 32 bit
    
    attribute mark_debug : string;
    -- attribute mark_debug of counter : signal is "true";
    -- attribute mark_debug of i1_peak_debug : signal is "true";
    -- attribute mark_debug of i2_peak_debug : signal is "true";
    -- attribute mark_debug of i1_next_ON : signal is "true";
    -- attribute mark_debug of p1_present_debug : signal is "true";
    -- attribute mark_debug of p1_next_ON_debug : signal is "true";
    -- attribute mark_debug of p1_present_lpf_debug : signal is "true";
    attribute mark_debug of p1_next_ON_lpf : signal is "true";
    attribute mark_debug of p1_next_OFF_lpf : signal is "true";
    attribute mark_debug of P1ref : signal is "true";
    attribute mark_debug of state_next_b : signal is "true";

begin

    STATE_NEXT <= state_next_b;
    
    i1_peak_debug <= i1_peak(31 downto 16);
    i2_peak_debug <= i2_peak(31 downto 16);
    
    p1_present_debug <= p1_present(47 downto 16);
    p1_next_ON_debug <= p1_next_ON(47 downto 16);
    
    p1_present_lpf_debug <= p1_present_lpf(47 downto 16);
    
    -- ===================================================================================
    -- create counter
    -- ===================================================================================
    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                pwm_synch_flag_prvs <= '0';
            else
                pwm_synch_flag_prvs <= PWM_SYNCH_FLAG;
            end if;
        end if;
        
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                counter <= X"0000";
            elsif PWM_SYNCH_FLAG /= pwm_synch_flag_prvs then
                counter <= X"0000";
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- ===================================================================================
    -- capture current peak
    -- ===================================================================================
    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                i1_peak <= X"0000" & X"0000";
                i2_peak <= X"0000" & X"0000";
            else
                if counter = PEAK_COUNT_I1 then
                    i1_peak <= abs(I1) & X"0000";
                elsif counter = PEAK_COUNT_I2 then
                    i2_peak <= abs(I2) & X"0000";
                end if;
            end if;
        end if;
    end process;

    -- ===================================================================================
    -- calculate input power of present sample
    -- ===================================================================================
    process(CLK_IN)
    variable p1_present_32_tmp : std_logic_vector (31 downto 0); -- integer 32 bit
    variable p1_present_32 : std_logic_vector (31 downto 0); -- integer 32 bit
    
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                p1_present_32_tmp := X"0000" & X"0000";
                p1_present_32 := X"0000" & X"0000";
                p1_present <= X"0000" & X"0000" & X"0000";
            else
                if counter = PEAK_COUNT_I1 + 1 then
                    if STATE_PRESENT = '1' then
                        p1_present_32_tmp := i1_peak(31 downto 16) * V1d(31 downto 16);
                        p1_present_32 := '0' & p1_present_32_tmp(31 downto 1); -- divide by 2
                        p1_present <= p1_present_32 & X"0000"; -- add fractional bit
                    elsif STATE_PRESENT = '0' then
                        p1_present <= X"0000" & X"0000" & X"0000";
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- ===================================================================================
    -- predict 1 sample ahead primary current peak
    -- ===================================================================================
    process(CLK_IN)
    variable i1_next_ON_64 : std_logic_vector (63 downto 0); -- integer 32 bit, fractional 32 bit
    variable i1_next_ON_16 : std_logic_vector (15 downto 0); -- integer 16 bit
    
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                i1_next_ON_64 := X"0000" & X"0000" & X"0000" & X"0000";
                i1_next_ON_16 := X"0000";                               
                i1_next_ON <= X"0000";
            else
                if counter = PEAK_COUNT_I1 + 2 then
                    i1_next_ON_64 := MPC_A * i1_peak - MPC_B * i2_peak + MPC_C * V1d;
                    i1_next_ON_16 := i1_next_ON_64(47 downto 32);
                    i1_next_ON <= i1_next_ON_16;
                end if;
            end if;
        end if;
    end process;
    
    -- ===================================================================================
    -- predict 1 sample ahead input power
    -- ===================================================================================
    process(CLK_IN)
    variable p1_next_ON_32_tmp : std_logic_vector (31 downto 0); -- integer 32 bit
    variable p1_next_ON_32 : std_logic_vector (31 downto 0); -- integer 32 bit
    
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                p1_next_ON_32_tmp := X"0000" & X"0000";
                p1_next_ON_32 := X"0000" & X"0000";
                p1_next_ON <= X"0000" & X"0000" & X"0000";
            else
                if counter = PEAK_COUNT_I1 + 3 then
                    if i1_next_ON(15) = '0' then
                        p1_next_ON_32_tmp := i1_next_ON * V1d(31 downto 16);
                        p1_next_ON_32 := '0' & p1_next_ON_32_tmp(31 downto 1); -- divide by 2
                    elsif i1_next_ON(15) = '1' then
                        p1_next_ON_32_tmp := i1_next_ON * V1d(31 downto 16);
                        p1_next_ON_32 := '1' & p1_next_ON_32_tmp(31 downto 1); -- divide by 2
                    end if;
                    p1_next_ON <= p1_next_ON_32 & X"0000"; -- add fractional bit
                end if;
            end if;
        end if;
    end process;
    
    -- ===================================================================================
    -- apply low pass filter to present input power
    -- ===================================================================================
    process(CLK_IN)
    variable p1_present_lpf_96 : std_logic_vector (95 downto 0); -- integer 64 bit, fractional 32 bit
    variable p1_last : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
    variable p1_last_lpf : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
    
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                p1_present_lpf_96 := X"0000" & X"0000" & X"0000" & X"0000" & X"0000" & X"0000";
                p1_last := X"0000" & X"0000" & X"0000";
                p1_last_lpf := X"0000" & X"0000" & X"0000";
                p1_present_lpf <= X"0000" & X"0000" & X"0000";
            else
                if counter = PEAK_COUNT_I1 + 4 then
                    p1_present_lpf_96 := LPF_A * p1_present + LPF_A * p1_last + LPF_B * p1_last_lpf;
                    p1_last := p1_present;
                    p1_last_lpf := p1_present_lpf_96(63 downto 16);
                    p1_present_lpf <= p1_present_lpf_96(63 downto 16);
                end if;
            end if;
        end if;
    end process;
    
    -- ===================================================================================
    -- apply low pass filter to 1 sample ahead input power
    -- ===================================================================================
    process(CLK_IN)
    variable p1_next_ON_lpf_96 : std_logic_vector (95 downto 0); -- integer 64 bit, fractional 32 bit
    variable p1_next_OFF_lpf_96 : std_logic_vector (95 downto 0); -- integer 64 bit, fractional 32 bit
    
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                p1_next_ON_lpf_96 := X"0000" & X"0000" & X"0000" & X"0000" & X"0000" & X"0000";
                p1_next_OFF_lpf_96 := X"0000" & X"0000" & X"0000" & X"0000" & X"0000" & X"0000";
                p1_next_ON_lpf <= X"0000" & X"0000";
                p1_next_OFF_lpf <= X"0000" & X"0000";
            else
                if counter = PEAK_COUNT_I1 + 5 then
                    p1_next_ON_lpf_96 := LPF_A * p1_next_ON + LPF_A * p1_present + LPF_B * p1_present_lpf;
                    p1_next_OFF_lpf_96 := LPF_A * p1_present + LPF_B * p1_present_lpf;
                    p1_next_ON_lpf <= p1_next_ON_lpf_96(63 downto 32);
                    p1_next_OFF_lpf <= p1_next_OFF_lpf_96(63 downto 32);
                end if;
            end if;
        end if;
    end process;
    
    -- ===================================================================================
    -- determine inverter state of next half cycle
    -- ===================================================================================
    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                state_next_b <= '1';
            else
                if counter = PEAK_COUNT_I1 + 6 then
                    if abs(P1ref - p1_next_ON_lpf) > abs(P1ref - p1_next_OFF_lpf) then
                        state_next_b <= '0';
                    else
                        state_next_b <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
            
end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/06/09 16:11:46
-- Design Name: 
-- Module Name: lpf_if - Behavioral
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
use ieee.std_logic_signed.all;

entity lpf_if is
    port (
        CLK_IN : in std_logic;
        RESET_IN : in std_logic;
        STATE_PRESENT : in std_logic;
        PWM_SYNCH_FLAG : in std_logic;
        I1 : in std_logic_vector (15 downto 0); -- integer 16 bit
        PEAK_COUNT_I1 : in std_logic_vector (15 downto 0);
        LPF_A : in std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
        LPF_B : in std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
        V1d : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        P1_LPF : out std_logic_vector (31 downto 0) -- integer 32 bit
    );
end lpf_if;

architecture Behavioral of lpf_if is

    signal counter : std_logic_vector (15 downto 0);
    signal pwm_synch_flag_prvs : std_logic := '0';
    
    signal i1_peak : std_logic_vector (31 downto 0);
    signal p1_present : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit
    signal p1_present_lpf : std_logic_vector (47 downto 0); -- integer 32 bit, fractional 16 bit

begin

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
            else
                if counter = PEAK_COUNT_I1 then
                    i1_peak <= abs(I1) & X"0000";
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
                if counter = PEAK_COUNT_I1 + 2 then
                    p1_present_lpf_96 := LPF_A * p1_present + LPF_A * p1_last + LPF_B * p1_last_lpf;
                    p1_last := p1_present;
                    p1_last_lpf := p1_present_lpf_96(63 downto 16);
                    p1_present_lpf <= p1_present_lpf_96(63 downto 16);
                end if;
            end if;
        end if;
    end process;
    
    P1_LPF <= p1_present_lpf(47 downto 16);

end Behavioral;

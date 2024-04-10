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
        PWM_SYNCH_FLAG : in std_logic;
        I1 : in std_logic_vector (15 downto 0); -- integer 16 bit
        I2 : in std_logic_vector (15 downto 0); -- integer 16 bit
        PEAK_COUNT_I1 : in std_logic_vector (15 downto 0);
        PEAK_COUNT_I2 : in std_logic_vector (15 downto 0);
        MPC_A : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        MPC_B : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        MPC_C : in std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
        V1d : in std_logic_vector (31 downto 0) -- integer 16 bit, fractional 16 bit
    );
end fcs_mpc_if;

architecture Behavioral of fcs_mpc_if is

    signal counter : std_logic_vector (15 downto 0);
    signal pwm_synch_flag_prvs : std_logic := '0';
    signal i1_peak : std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
    signal i2_peak : std_logic_vector (31 downto 0); -- integer 16 bit, fractional 16 bit
    signal i1_next : std_logic_vector (15 downto 0); -- integer 16 bit
    signal i1_peak_debug : std_logic_vector (15 downto 0); -- integer 16 bit
    signal i2_peak_debug : std_logic_vector (15 downto 0); -- integer 16 bit
--    signal v1d_debug : std_logic_vector (15 downto 0); -- integer 16 bit
--    signal mpc_debug_a_64 : std_logic_vector (63 downto 0);
--    signal mpc_debug_b_64 : std_logic_vector (63 downto 0);
--    signal mpc_debug_c_64 : std_logic_vector (63 downto 0);
--    signal mpc_debug_a_16 : std_logic_vector (15 downto 0);
--    signal mpc_debug_b_16 : std_logic_vector (15 downto 0);
--    signal mpc_debug_c_16 : std_logic_vector (15 downto 0);
    
    attribute mark_debug : string;
    attribute mark_debug of counter : signal is "true";
    attribute mark_debug of i1_peak_debug : signal is "true";
    attribute mark_debug of i2_peak_debug : signal is "true";
    attribute mark_debug of i1_next : signal is "true";
--    attribute mark_debug of v1d_debug : signal is "true";
--    attribute mark_debug of mpc_debug_a_16 : signal is "true";
--    attribute mark_debug of mpc_debug_b_16 : signal is "true";
--    attribute mark_debug of mpc_debug_c_16 : signal is "true";

begin

    i1_peak_debug <= i1_peak(31 downto 16);
    i2_peak_debug <= i2_peak(31 downto 16);
--    v1d_debug <= V1d(31 downto 16);
--    mpc_debug_a_16 <= mpc_debug_a_64(47 downto 32);
--    mpc_debug_b_16 <= mpc_debug_b_64(47 downto 32);
--    mpc_debug_c_16 <= mpc_debug_c_64(47 downto 32);
    
--    process(CLK_IN)
--    begin
--        if CLK_IN'event and CLK_IN = '1' then
--            if RESET_IN = '1' then
--                mpc_debug_a_64 <= X"0000" & X"0000" & X"0000" & X"0000";
--                mpc_debug_b_64 <= X"0000" & X"0000" & X"0000" & X"0000";
--                mpc_debug_c_64 <= X"0000" & X"0000" & X"0000" & X"0000";
--            else
--                if counter = PEAK_COUNT_I1 + 1 then
--                    mpc_debug_a_64 <= MPC_A * i1_peak;
--                    mpc_debug_b_64 <= MPC_B * i2_peak;
--                    mpc_debug_c_64 <= MPC_C * V1d;
--                end if;
--            end if;
--        end if;
--    end process;

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
    
    process(CLK_IN)
    variable i1_next_64 : std_logic_vector (63 downto 0);
    variable i1_next_16 : std_logic_vector (15 downto 0);
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                i1_next_64 := X"0000" & X"0000" & X"0000" & X"0000";
                i1_next_16 := X"0000";
                i1_next <= X"0000";
            else
                if counter = PEAK_COUNT_I1 + 1 then
                    i1_next_64 := MPC_A * i1_peak - MPC_B * i2_peak + MPC_C * V1d;
                    i1_next_16 := i1_next_64(47 downto 32);
                    i1_next <= i1_next_16;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

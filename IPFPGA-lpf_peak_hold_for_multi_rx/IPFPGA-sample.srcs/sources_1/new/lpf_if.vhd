library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity lpf_if is
    port (
        CLK_IN         : in std_logic;
        RESET_IN       : in std_logic;
        AD_DATA_CRNT   : in std_logic_vector(31 downto 0);
        LPF_A_FP       : in std_logic_vector(31 downto 0);
        LPF_B_FP       : in std_logic_vector(31 downto 0);
        AD_DATA_LPF_CRNT : out std_logic_vector(31 downto 0)
    );
end lpf_if;

architecture Behavioral of lpf_if is
    
begin

    -- Low Pass Filter
    process(CLK_IN)
    
    variable ad_data_crnt_fp     : std_logic_vector(31 downto 0);
    variable ad_data_prvs_fp     : std_logic_vector(31 downto 0);
    variable ad_data_lpf_crnt_fp_64 : std_logic_vector(63 downto 0);
    variable ad_data_lpf_prvs_fp_32 : std_logic_vector(31 downto 0);
    
    begin
        
        if (CLK_IN' event and CLK_IN = '1') then
            if RESET_IN = '1' then
                ad_data_crnt_fp := X"0000" & X"0000";
                ad_data_prvs_fp := X"0000" & X"0000";
                ad_data_lpf_crnt_fp_64 := X"0000" & X"0000" & X"0000" & X"0000";
                ad_data_lpf_prvs_fp_32 := X"0000" & X"0000";
                ad_data_lpf_crnt <= X"0000" & X"0000";
            else  
                ad_data_crnt_fp := AD_DATA_CRNT(15 downto 0) & X"0000";
                ad_data_lpf_crnt_fp_64 := LPF_A_FP * ad_data_crnt_fp + LPF_A_FP * ad_data_prvs_fp + LPF_B_FP * ad_data_lpf_prvs_fp_32;
                ad_data_prvs_fp := ad_data_crnt_fp;
                ad_data_lpf_prvs_fp_32 := ad_data_lpf_crnt_fp_64(47 downto 16);
                AD_DATA_LPF_CRNT <= ad_data_lpf_crnt_fp_64(63 downto 32);
            end if;
        end if;
    end process;

end Behavioral;

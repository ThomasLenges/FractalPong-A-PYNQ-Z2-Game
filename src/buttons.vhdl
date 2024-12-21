-- Group AD
-- Renuka Singh Virk & Thomas Lenges

-- The buttons component detects rising edges of input signals (LeftxSI and RightxSI) 
-- and outputs corresponding signals (LRisingEdgexSO and RRisingEdgexSO) 
-- that pulse high ('1') for one clock cycle when a rising edge occurs.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity buttons is
    Port (
    
    -- Clock and reset inputs
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Controls from push buttons
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;
    
    -- rising edge detection 
    LRisingEdgexSO : out std_logic; 
    RRisingEdgexSO : out std_logic
 );
end buttons;

architecture rtl of buttons is

    signal LeftxDP, LeftxDN, RightxDP, RightxDN : std_logic;
       
begin

    process(CLKxCI,RSTxRI)
    begin
        if(RSTxRI = '1') then
            LeftxDP <= '0';
            RightxDP <= '0';
        elsif(CLKxCI'event and CLKxCI = '1') then
            LeftxDP <= LeftxDN;
            RightxDP <= RightxDN;
        end if;
    end process;

LeftxDN <= LeftxSI;
RightxDN <= RightxSI;

-- Rising edges detecttion
LRisingEdgexSO <= '1' when (LeftxDP = '0' and LeftxDN = '1') else
                  '0';
RRisingEdgexSO <= '1' when (RightxDP = '0' and RightxDN = '1') else
                  '0';

end rtl;

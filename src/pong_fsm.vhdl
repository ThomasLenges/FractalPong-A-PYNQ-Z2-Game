-- Group AD
-- Renuka Singh Virk & Thomas Lenges

--=============================================================================
-- @file pong_fsm.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Controls from push buttons
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Coordinate from VGA
    VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
    VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
    VSEdgexSI : in std_logic;

    -- Ball and plate coordinates
    BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
    BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0) -- No need to include PlateYxDO as the plate does only evolve horizontally
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is
    type PongFSM_Type is (OutGame, InGame); -- 'OutGame' when idle. 'InGame' game is ongoing.
    
    signal StatexDP, StatexDN : PongFSM_Type; -- Game state signal
    
    signal CNTXxDP, CNTXxDN, CNTYxDP, CNTYxDN, PlateXxDP, PlateXxDN : unsigned(COORD_BW - 1 downto 0); -- Counters and coordinates (same dimensions)
    
    signal IncrementXxSP, IncrementXxSN,IncrementYxSP, IncrementYxSN, GameOverxS, LRisingxS, RRisingxS: std_logic;
    
    component buttons is
      Port (
        CLKxCI : in std_logic;
        RSTxRI : in std_logic;
        LeftxSI  : in std_logic; -- Left button
        RightxSI : in std_logic; -- Right button
        LRisingEdgexSO : out std_logic; -- Rising edge detections
        RRisingEdgexSO : out std_logic 
      );
     end component;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
    i_rising_edge: buttons
      port map (
        CLKxCI => CLKxCI,
        RSTxRI => RSTxRI,
        LeftxSI => LeftxSI,
        RightxSI => RightxSI,
        LRisingEdgexSO => LRisingxS,
        RRisingEdgexSO => RRisingxS
      );
    
    process(CLKxCI,RSTxRI)
    begin
        if(RSTxRI = '1') then
            StatexDP <= OutGame;
            CNTXxDP <= (others => '0');
            CNTYxDP <= (others => '0');
            PlateXxDP <= (others => '0');
            IncrementXxSP <= '0';
            IncrementYxSP <= '0';
        elsif(CLKxCI'event and CLKxCI = '1') then
            StatexDP <= StatexDN;  
            CNTXxDP <= CNTXxDN;
            CNTYxDP <= CNTYxDN;
            PlateXxDP <= PlateXxDN; 
            IncrementXxSP <= IncrementXxSN;
            IncrementYxSP <= IncrementYxSN;
        end if;
    end process;
    
    p_FSMPong : process(LeftxSI, RightxSI, StatexDP, GameOverxS) is
    begin
        StatexDN <= StatexDP;
        case StatexDP is
            when OutGame =>
                if(LeftxSI = '1' and RightxSI = '1') then -- Get into state InGame only when the two buttons are pressed
                    StatexDN <= InGame;
                end if;
                
            when InGame =>
                if(GameOverxS = '1') then -- When GameOver don't forget to set correct state
                    StatexDN <= OutGame;
                end if;
                
        end case;
        
    end process p_FSMPong;
    
    -- Increment authorisations for ball (not within counters for clarity)
    IncrementXxSN <= '1' when CNTXxDP <= 0 else -- Ball moves right when hit left 
                    '0' when CNTXxDP >= HS_DISPLAY - 1 - BALL_WIDTH else -- Ball moves right when hit right
                    IncrementXxSP;
 
    IncrementYxSN <= '1' when CNTYxDP <= 0 else -- Ball moves down when hit up
                    '0' when (CNTYxDP >= VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT - 1) and (CNTXxDP >= PlateXxDP and CNTXxDP <= PlateXxDP + PLATE_WIDTH) else 
                    -- Ball moves up WHEN HIT PLATE
                    IncrementYxSP;
    
    CNTXxDN <= to_unsigned(BALL_XSTART, CNTXxDN'length) when StatexDP = OutGame else -- Assign value to counter before game starts
               CNTXxDP + BALL_STEP_X when (IncrementXxSP = '1'and VSEdgexSI = '1') else -- Increment the counter by the step (ONLY WHEN VSEdgexSI is '1')
               CNTXxDP - BALL_STEP_X when (IncrementXxSP = '0'and VSEdgexSI = '1') else -- Decrement the counter by the step (ONLY WHEN VSEdgexSI is '1')
               CNTXxDP; -- Else required to keep counter value unchanged
               
    CNTYxDN <= to_unsigned(BALL_YSTART, CNTYxDN'length) when StatexDP = OutGame else -- Repeat for the Y coordinate
               CNTYxDP + BALL_STEP_Y when (IncrementYxSP = '1'and VSEdgexSI = '1') else
               CNTYxDP - BALL_STEP_Y when (IncrementYxSP = '0'and VSEdgexSI = '1') else
               CNTYxDP;
               
    PlateXxDN <= to_unsigned(PLATE_XSTART - PLATE_WIDTH/2, PlateXxDN'length) when StatexDP = OutGame else
                 PlateXxDP - PLATE_STEP_X when (LRisingxS = '1' and PlateXxDP > PLATE_STEP_X)  else -- We don't want plate to exit screen on left side
                 PlateXxDP + PLATE_STEP_X when (RRisingxS = '1' and PlateXxDP + PLATE_WIDTH <= HS_DISPLAY) else -- We don't want plate to exit screen on right side
                 (others => '0') when (LRisingxS = '1' and PlateXxDP <= PLATE_STEP_X) else -- We still move the plate but get it against the left hand side of screen
                 to_unsigned(HS_DISPLAY - 1 - PLATE_WIDTH, PlateXxDN'length) when PLATEXxDP >= HS_DISPLAY - PLATE_WIDTH - 1 else  -- Same but for right side
                 PlateXxDP; -- Else required to keep counter value unchanged
    

                    
    GameOverxS <= '1' when (CNTYxDP >= VS_DISPLAY - BALL_HEIGHT - 1) else -- GameOver once the bottom of the ball touches the bottom of screen
                  '0';               
    
    -- Update positions
    BallXxDO <= CNTXxDP; 
    BallYxDO <= CNTYxDP;
    PlateXxDO <= PlateXxDP;
    
end rtl;
--=================================================================
-- ARCHITECTURE END
--=============================================================================

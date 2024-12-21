-- Group AD
-- Renuka Singh Virk & Thomas Lenges

--=============================================================================
-- @file vga_controller.vhdl
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
-- vga_controller
--
-- @brief This file specifies a VGA controller circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity vga_controller is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Data/color input
    RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0); -- 4 bits per color see constant file
    GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

    -- Coordinate output
    XCoordxDO : out unsigned(COORD_BW - 1 downto 0); -- 12 bits so screen width up to 4096 pixels. Actually is 1024.
    YCoordxDO : out unsigned(COORD_BW - 1 downto 0); -- 12 bits so screen height up to 4096 pixels. Actually is 768.

    -- Timing output
    HSxSO : out std_logic; -- See lecture 9 refers to Horizontal sync (reset beam to start of next row)
    VSxSO : out std_logic; -- See lecture 9 refers to Vertical sync (reset beam to start of new frame)
    
    VSEdgexSO : out std_logic; -- Added for lab7 (to implement) 

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0); -- Same as above but this is output
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller is

signal RedxSP, RedxSN, GreenxSP, GreenxSN, BluexSP, BluexSN : std_logic_vector(COLOR_BW - 1 downto 0); -- Color signals
signal HRGBxS, VRGBxS : std_logic; -- RGB enable signals

signal CNT_HSxDP, CNT_HSxDN, CNT_VSxDP, CNT_VSxDN : unsigned(COORD_BW - 1 downto 0); -- Counters for the synchronisation
signal HSxSP, HSxSN, VSxSP, VSxSN : std_logic;  -- Synchronisation signals (!= counters)
signal XCoordxD, YCoordxD : unsigned(COORD_BW - 1 downto 0); -- X and Y coordinates signals
constant HPixels : integer := HS_DISPLAY + HS_FRONT_PORCH + HS_PULSE + HS_BACK_PORCH; -- Nb. horizontal pixels (width)
-- 1024 + 24 + 136 + 144
-- HS_FRONT_PROCH: brief blanking period after the active display area and before the sync pulse.
-- HS_PULSE: horizontal sync pulse used to reset the horizontal beam to the start of the next line.
-- HS_BACK_PORCH: other blanking period after the sync pulse and before the active display area. Ensures the horizontal beam is stable before starting the next line of display.
constant VLines : integer := VS_DISPLAY + VS_FRONT_PORCH + VS_PULSE + VS_BACK_PORCH; -- Nb. vertical pixels (height)
-- 768 + 3 + 6 + 29
-- See above for explnation of each term
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

process(CLKxCI,RSTxRI) -- Initialisation and clock rising edge
    begin
        if(RSTxRI = '1') then
            CNT_HSxDP <= (others => '0'); -- Set count to zero <==> origin of screen (top left) 
            CNT_VSxDP <= (others => '0');
            HSxSP <= '1'; -- Required for proper initialisation
            VSxSP <= '1'; -- Required for proper initialisation
            RedxSP <= (others => '0'); -- Start with black screen
            GreenxSP <= (others => '0');
            BluexSP <= (others => '0');
        elsif(CLKxCI'event and CLKxCI = '1') then -- Update all registers with their new value
            CNT_HSxDP <= CNT_HSxDN; 
            CNT_VSxDP <= CNT_VSxDN; 
            HSxSP <= HSxSN; 
            VSxSP <= VSxSN;  
            RedxSP <= RedxSN; 
            GreenxSP <= GreenxSN; 
            BluexSP <= BluexSN;  
        end if;
    end process;            
       
-- Increment horizontal sync counter unless it reaches the end of the horizontal line (= HPixels)
CNT_HSxDN <= CNT_HSxDP + "1" when CNT_HSxDP < HPixels - 1 -- Don't forget for rest of project as the indexation starts with zero
               else (others => '0');

-- Set HSxSN to '0' during the sync pulse region (start of signal)
-- Set HSxSN to '1' for the rest of the horizontal line (back porch, display, front porch)
HSxSN <= '0' when CNT_HSxDP < HS_PULSE
             else '1';

-- Increment vertical sync counter unless it reaches the end of frame (Height = VPixels)
-- If we are not at the end of the frame or the end of a line don't forgert to save the actual line position (doesn't apply to columns as it changes every cycle)
CNT_VSxDN <= CNT_VSxDP + "1" when (CNT_HSxDP >= HPixels - 1 and CNT_VSxDP < VLines - 1) 
              else (others => '0') when (CNT_HSxDP >= HPixels - 1 and CNT_VSxDP >= VLines - 1)
              else CNT_VSxDP;

-- Set VSxSN to '0' during the sync pulse region (start of signal)
-- Set VSxSN to '1' for the rest of the horizontal line (back porch, display, front porch)
VSxSN <= '0' when CNT_VSxDP < VS_PULSE
             else '1';
             
-- Enable horizontal RGB display only in 'display' section:
HRGBxS <= '1' when (CNT_HSxDP >= HS_PULSE + HS_BACK_PORCH and CNT_HSxDP < HS_PULSE + HS_BACK_PORCH + HS_DISPLAY)
              else '0';

-- Enable vertical RGB display only in 'display' section:
VRGBxS <= '1' when (CNT_VSxDP >= VS_BACK_PORCH + VS_PULSE and CNT_VSxDP < VS_PULSE + VS_BACK_PORCH + VS_DISPLAY)
              else '0';  

-- Input Red color value to the next state if the pixel is in the active display area (otherwise black = all bits set to '0')
RedxSN <= RedxSI when (HRGBxS = '1' and VRGBxS = '1')
                 else (others => '0');   

-- Input Green color value to the next state if the pixel is in the active display area
GreenxSN <= GreenxSI when (HRGBxS = '1' and VRGBxS = '1')
                 else (others => '0');

-- Input Blue color value to the next state if the pixel is in the active display area
BluexSN <= BluexSI when (HRGBxS = '1' and VRGBxS = '1')
                 else (others => '0');      

-- Don't forget pulse and porch offsets also propose a else 
XCoordxD <= CNT_HSxDP - HS_PULSE - HS_BACK_PORCH when (CNT_HSxDP >= HS_PULSE + HS_BACK_PORCH and CNT_HSxDP < HS_PULSE + HS_BACK_PORCH + HS_DISPLAY)
            else (others => '-'); -- Don't care bits 

YCoordxD <= CNT_VSxDP - VS_PULSE - VS_BACK_PORCH when (CNT_VSxDP >= VS_PULSE + VS_BACK_PORCH and CNT_VSxDP < VS_PULSE + VS_BACK_PORCH + VS_DISPLAY)
            else (others => '-');
            
VSEdgexSO <= '1' when (CNT_HSxDP = HS_PULSE + HS_BACK_PORCH + HS_DISPLAY and CNT_VSxDP = VS_PULSE + VS_BACK_PORCH + VS_DISPLAY) 
            else '0'; -- We decide to update sprites once everything has been displayed on screen

-- Output values
XCoordxDO <= XCoordxD;
YCoordxDO <= YCoordxD;
RedxSO <= RedxSP;
GreenxSO <= GreenxSP; 
BluexSO <= BluexSP;                 
HSxSO <= HSxSP;
VSxSO <= VSxSP;


end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================

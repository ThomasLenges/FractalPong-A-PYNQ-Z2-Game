-- Group AD
-- Renuka Singh Virk & Thomas Lenges

--=============================================================================
-- @file dsd_prj_pkg.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- dsd_prj_pkg
--
-- @brief This file specifies the parameters used for the VGA controller, pong and mandelbrot circuits
--
-- The parameters are given here http://tinyvga.com/vga-timing/1024x768@70Hz
-- with a more elaborate explanation at https://projectf.io/posts/video-timings-vga-720p-1080p/
--=============================================================================

package dsd_prj_pkg is

  -- Bitwidths for screen coordinate and colors
  constant COLOR_BW : natural := 4;  -- Each colour LED is 4 bits
  constant COORD_BW : natural := 12; -- 12 bits should accommodate any screen size we can consider

  -- Horizontal timing parameters
  constant HS_DISPLAY     : natural   := 1024; -- Display width in pixels
  constant HS_FRONT_PORCH : natural   := 24;   -- Horizontal sync front porch length in number of pixels (clock-cycles)
  constant HS_PULSE       : natural   := 136;  -- Horizontal sync pulse length in number of pixels (clock-cycles)
  constant HS_BACK_PORCH  : natural   := 144;  -- Horizontal sync back porch length in number of pixels (clock-cycles)
  constant HS_POLARITY    : std_logic := '0';  -- Polarity indicates value of sync signal in sync period
                                               -- with negative polarity meaning active LOW.

  -- Vertical timing parameters
  constant VS_DISPLAY     : natural   := 768; -- Display height in pixels
  constant VS_FRONT_PORCH : natural   := 3;   -- Vertical sync front porch length in number of horizontal lines
  constant VS_PULSE       : natural   := 6;   -- Vertical sync pulse length in number of horizontal lines
  constant VS_BACK_PORCH  : natural   := 29;  -- Vertical sync back porch length in number of horizontal lines
  constant VS_POLARITY    : std_logic := '0'; -- Vertical sync polarity

  -- Memory parameters
  constant MEM_ADDR_BW : natural := 16; -- We save up to 256*192 pixels (49152) so need at least 16 bits to save them all (2^16 = 65536, 2^15=32768)
  constant MEM_DATA_BW : natural := 12; -- 3 (RGB) and 4 bits per color

  -- Pong parameters (in pixels)
  constant BALL_WIDTH   : natural := 10;
  constant BALL_HEIGHT  : natural := 10;
  constant BALL_STEP_X  : natural := 2;
  constant BALL_STEP_Y  : natural := 2;
  constant PLATE_WIDTH  : natural := 70;
  constant PLATE_HEIGHT : natural := 10;
  constant PLATE_STEP_X : natural := 40;
  constant PLATE_XSTART : natural := HS_DISPLAY/2; -- We want plate to start at the bottom middle of screen (no need to initialise the Y coordinate to a value (see 'pong_top.vhdl' as we use VS_DISPLAY - 10)
  constant BALL_XSTART : natural := HS_DISPLAY/2; -- We want the ball to start at the middle of screen
  constant BALL_YSTART : natural := VS_DISPLAY/2;
  
  -- Mandelbrot parameters
  -- Use QNi.Nf notation, with Ni being number of integer bits WITH sign and Nf number of fractional bits
  -- Use UQNi.Nf notation for unsigned, with Ni being just the number of integer bits WITHOUT sign
  constant N_INT  : natural := 3;   -- # Integer bits (plus sign-bit)
  constant N_FRAC : natural := 15;  -- # Fractional bits
  constant N_BITS : natural := N_INT + N_FRAC;

  constant ITER_LIM : natural := 2**(2 + N_FRAC); -- Represents 2^2 in UQ3.15 (100.000000000000000)
  constant MAX_ITER : natural := 100;             -- Maximum iteration bumber before stopping

  -- Start at (-2, -1) = (0b110, 0b111) on the complex plane. As the Mandelbrot fractal is symmetric
  -- along the real axis, this can be used to draw the Mandelbrot fractal similar to starting at (-2, 1).
  -- The benefit of starting at (-2, -1) is that we only have to ADD the increments to C_RE_0 and C_IM_0
  -- instead of having to subtract the increment C_IM_INC from C_IM_0 to go down the imaginary axis
  constant C_RE_0 : signed(N_BITS - 1 downto 0) := to_signed(-2 * (2**N_FRAC), N_BITS); -- Q3.15
  constant C_IM_0 : signed(N_BITS - 1 downto 0) := to_signed(-1 * (2**N_FRAC), N_BITS); -- Q3.15

  -- Increment by 3*2^(-10) and 5*2^(-11) for real and imaginary, respectively.
  -- For real (X), starting at -2 with 1024 = 2^10 pixels, we end at -2 + 2^10 * 3 * 2^(-10) = -2 + 3 = 1
  -- For imaginary (Y), starting at -1 with 768 pixels, we end at -1 + 768*5*2^(-11) = 0.875
  constant C_RE_INC : signed(N_BITS - 1 downto 0) := to_signed(3 * 2**(-10 + N_FRAC), N_BITS); -- Q3.15
  constant C_IM_INC : signed(N_BITS - 1 downto 0) := to_signed(5 * 2**(-11 + N_FRAC), N_BITS); -- Q3.15


end package dsd_prj_pkg;

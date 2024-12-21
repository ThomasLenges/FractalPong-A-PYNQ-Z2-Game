-- Group AD
-- Renuka Singh Virk & Thomas Lenges

--=============================================================================
-- @file mandelbrot.vhdl
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
-- mandelbrot
--
-- @brief This file specifies a basic circuit for mandelbrot
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT
--=============================================================================
entity mandelbrot is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    WExSO   : out std_logic;
    XxDO    : out unsigned(COORD_BW - 1 downto 0);
    YxDO    : out unsigned(COORD_BW - 1 downto 0);
    ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
  );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

    signal CNT_XxDP, CNT_XxDN, CNT_YxDP, CNT_YxDN : unsigned(COORD_BW-1 downto 0); -- Counters for x and y coordinates
    
    signal CNT_ReCxDP, CNT_ReCxDN, CNT_ImCxDP, CNT_ImCxDN : signed(N_BITS - 1 downto 0); -- Real and imaginary counters for complex number computations
    
    signal NITERxDP, NITERxDN : unsigned(MEM_DATA_BW - 1 downto 0); -- Iteration counter
    
    signal Z_RxD, Z_IxD : signed(N_BITS - 1 downto 0);  -- Real and Imaginary parts of z
    signal C_RxD, C_IxD : signed(N_BITS - 1 downto 0);  -- Real and Imaginary parts of c
    signal Z_RxDP, Z_RxDN, Z_IxDP, Z_IxDN : signed(N_BITS - 1 downto 0);  -- Next states for z

    signal Z_R2convertxD, Z_I2convertxD, Z_RIconvertxD : signed(N_BITS - 1 downto 0); -- Converted values for multiplication
    
    signal Z_R2xD, Z_I2xD,Z_RIxD : signed(2*(N_BITS)- 1 downto 0);
    signal WhileCondxS: std_logic; -- Indicates whether to continue iterations



--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
    process(CLKxCI, RSTxRI)
    begin
        if (RSTxRI = '1') then -- Initialize counters and signals
            CNT_XxDP <= (others => '1');  -- This ensures that the first update to X starts at zero 
            CNT_YxDP <= (others => '0');  
            CNT_ReCxDP <= C_RE_0;         
            CNT_ImCxDP <= C_IM_0;         
            Z_RxDP <= (others => '0');    
            Z_IxDP <= (others => '0');    
            NITERxDP <= to_unsigned(0, MEM_DATA_BW);
        elsif (CLKxCI'event and CLKxCI = '1') then -- Update signals
            CNT_XxDP <= CNT_XxDN;       
            CNT_YxDP <= CNT_YxDN;      
            CNT_ReCxDP <= CNT_ReCxDN;    
            CNT_ImCxDP <= CNT_ImCxDN;   
            Z_RxDP <= Z_RxDN;            
            Z_IxDP <= Z_IxDN;           
            NITERxDP <= NITERxDN;       
        end if;
    end process;
    

    CNT_XxDN <= CNT_XxDP when WhileCondxS = '0' else -- Keep counter to same value as long as we are computing this pixel value
                CNT_XxDP + 1 when CNT_XxDP < HS_DISPLAY - 1 else
                (others => '0');  -- Reset X counter when display limit is reached
    
    CNT_YxDN <= CNT_YxDP when WhileCondxS = '0' or CNT_XxDP < HS_DISPLAY - 1 else -- Keep counter to same value as long as we are computing the same line pixel values
                CNT_YxDP + 1 when WhileCondxS = '1' and CNT_XxDP = HS_DISPLAY - 1 -- Don't forget second condition otherwise will increment counter every pixel (even on same line)
                                and CNT_YxDP < VS_DISPLAY - 1 else
                (others => '0');  -- Reset Y counter when display limit is reached
    

    CNT_ReCxDN <= CNT_ReCxDP when WhileCondxS = '0' else
                  CNT_ReCxDP + C_RE_INC when CNT_XxDP < HS_DISPLAY - 1 else
                  C_RE_0;  -- Reset real c counter to initial value once line finished
    
    CNT_ImCxDN <= CNT_ImCxDP when WhileCondxS = '0' or CNT_XxDP < HS_DISPLAY - 1 else -- Complex axis explains why we need to do this (Im = Y-axis)
                  CNT_ImCxDP + C_IM_INC when WhileCondxS = '1' and CNT_XxDP = HS_DISPLAY - 1 
                                         and CNT_YxDP < VS_DISPLAY - 1 else
                  C_IM_0;  -- Reset imaginary c counter to initial value
    
 
    -- Start of algo
    C_RxD <= CNT_ReCxDP;
    C_IxD <= CNT_ImCxDP;
    
    -- If we are at iteration zero then z_r = c_r and z_i = c_i otherwise use last values computed for z_r and z_i
    Z_RxD <= CNT_ReCxDP when NITERxDP = to_unsigned(0, MEM_DATA_BW) else 
             Z_RxDP;
    Z_IxD <= CNT_ImCxDP when NITERxDP = to_unsigned(0, MEM_DATA_BW) else 
             Z_IxDP;
    
    Z_R2xD <= Z_RxD * Z_RxD; 
    Z_I2xD <= Z_IxD * Z_IxD;   
    Z_RIxD <= Z_RxD * Z_IxD + Z_RxD * Z_IxD;  -- Can't simply shift left because & '0' assumes unsigned
    -- Safer to use explicit addition
    
    -- Gives mandelbrot but blurred
    -- If two numbers are N (18) bits wide then the multiplication will be 2N (36) bits wide. Need to adjust this!
    Z_R2convertxD <= Z_R2xD(2*(N_BITS)-1) & Z_R2xD(2*(N_BITS)-2-N_INT downto 0 + N_FRAC); -- Extract sign bit '2*(N_BITS)-1' value is 35
    Z_I2convertxD <= Z_I2xD(2*(N_BITS)-1) & Z_I2xD(2*(N_BITS)-2-N_INT downto 0 + N_FRAC); -- Extract most significant bits of same size 
    Z_RIconvertxD <= Z_RIxD(2*(N_BITS)-1) & Z_RIxD(2*(N_BITS)-2-N_INT downto 0 + N_FRAC); -- Lower bits may be truncated because they represent very small precision
    
    -- Gives black bg
    -- Z_R2convertxD <= Z_R2xD(35) & Z_R2xD(34 downto 33) & Z_R2xD(32 downto 18);
    -- Z_I2convertxD <= Z_I2xD(35) & Z_I2xD(34 downto 33) & Z_I2xD(32 downto 18);
    -- Z_RIconvertxD <= Z_RIxD(35) & Z_RIxD(34 downto 33) & Z_RIxD(32 downto 18);
    
    --Z_R2convertxD <= Z_R2xD(35) & Z_R2xD(34 downto 33) & Z_R2xD(29 downto 15);
    --Z_I2convertxD <= Z_I2xD(35) & Z_I2xD(34 downto 33) & Z_I2xD(29 downto 15);
    --Z_RIconvertxD <= Z_RIxD(35) & Z_RIxD(34 downto 33) & Z_RIxD(29 downto 15);

    --Z_R2convertxD <= Z_R2xD(35) & Z_R2xD(31 downto 30) & Z_R2xD(29 downto 15);
    --Z_I2convertxD <= Z_I2xD(35) & Z_I2xD(31 downto 30) & Z_I2xD(29 downto 15);
    --Z_RIconvertxD <= Z_RIxD(35) & Z_RIxD(31 downto 30) & Z_RIxD(29 downto 15);

    
    -- Compute next iteration z real and imaginary values (Don't forget to provide iteration zero situation)
    Z_RxDN <= CNT_ReCxDP when NITERxDP = to_unsigned(0, MEM_DATA_BW) else
              Z_R2convertxD - Z_I2convertxD + C_RxD;
    
    Z_IxDN <= CNT_ImCxDP when NITERxDP = to_unsigned(0, MEM_DATA_BW) else
              Z_RIconvertxD + C_IxD;
    
    WhileCondxS <=  '0' when (Z_R2xD(2*(N_BITS)-2 downto N_FRAC) + Z_I2xD(2*(N_BITS)-2 downto N_FRAC) < ITER_LIM and NITERxDP<MAX_ITER) else
                    '1';  -- Terminate when max iterations or escape condition is met
    
    -- Iteration counter
    NITERxDN <= NITERxDP + 1 when WhileCondxS = '0' else
                to_unsigned(0, MEM_DATA_BW); 
    
    
    -- Outputs 
    WExSO <= WhileCondxS;     
    ITERxDO <= NITERxDP;        
    XxDO <= CNT_XxDP;        
    YxDO <= CNT_YxDP;           
     
    
end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================

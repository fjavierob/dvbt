--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:09:02 06/06/2018
-- Design Name:   
-- Module Name:   C:/Users/Javi/Dropbox/Master/Electronica/Proyecto/Ecualizador/tb_interpolador.vhd
-- Project Name:  Proyecto
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Intelpoladol
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.ALL;
use work.DEF.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_interpolador IS
END tb_interpolador;
 
ARCHITECTURE behavior OF tb_interpolador IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Intelpoladol
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         inf : IN  complex10;
         sup : IN  complex10;
         enable : IN   std_logic;
         estim  : OUT  complex10;
         estim_valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
	signal inf : complex10 := (re => "0000000000", im => "0000000000");
	signal sup : complex10 := (re => "0000000000", im => "0000000000");
   signal enable : std_logic := '0';

 	--Outputs
   signal estim : complex10;
   signal estim_valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Intelpoladol PORT MAP (
          clk => clk,
          rst => rst,
          inf => inf,
          sup => sup,
          enable => enable,
          estim => estim,
          estim_valid => estim_valid
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for clk_period;
		
		rst <= '1';
		
		wait for clk_period;
		
		rst <= '0';
		
		wait for clk_period;
		
		enable <= '1';
		
		inf.re <= "0000001100"; -- 12
		inf.im <= "0000000110"; -- 6
		sup.re <= "0000011000"; -- 24
		sup.im <= "1111111010"; -- -6
		
		wait for clk_period*12*2;
		
		enable <= '0';
		
		wait for clk_period*5;


   end process;

END;

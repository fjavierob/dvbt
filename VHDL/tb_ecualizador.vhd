--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:31:09 05/31/2018
-- Design Name:   
-- Module Name:   C:/Users/Javi/Desktop/Estimador3/tb_ecualizador.vhd
-- Project Name:  Proyecto
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Ecualizador
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
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_ecualizador IS
END tb_ecualizador;
 
ARCHITECTURE behavior OF tb_ecualizador IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Ecualizador
    PORT(
         reset : IN  std_logic;
         clk : IN  std_logic;
         start : IN  std_logic;
         endsim : IN  std_logic;
         dato : OUT  std_logic_vector(15 downto 0);
         valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal reset : std_logic := '0';
   signal clk : std_logic := '0';
   signal start : std_logic := '0';
   signal endsim : std_logic := '0';

 	--Outputs
   signal dato : std_logic_vector(15 downto 0);
   signal valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Ecualizador PORT MAP (
          reset => reset,
          clk => clk,
          start => start,
          endsim => endsim,
          dato => dato,
          valid => valid
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
      wait for clk_period*2;
		
		reset <= '1';
		
		wait for clk_period;
		
		reset <= '0';
		
		wait for clk_period*5;
		
		start <= '1';
		
		wait for clk_period*5;
		
		start <= '0';
		
		wait for 1200 us;
		
		endsim <= '1';
		
		wait for clk_period*5;
		
		endsim <= '0';

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;

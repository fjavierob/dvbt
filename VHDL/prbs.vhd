----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:18:08 05/08/2018 
-- Design Name: 
-- Module Name:    prbs - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity prbs is
	 Generic (ESPACIADO_PILOTOS : integer := 12);
    Port ( clk 		 : in  STD_LOGIC;
           rst    	 : in  STD_LOGIC;
			  enable 	 : in  STD_LOGIC;
			  ready		 : out STD_LOGIC;
			  signo  	 : out STD_LOGIC);
end prbs;

architecture Behavioral of prbs is

type estado is (reposo, iterando);

signal estado_actual, nuevo_estado : estado;
signal cuenta, p_cuenta : unsigned(3 downto 0);
signal secuencia, p_secuencia : STD_LOGIC_VECTOR(1 to 11);
signal signo_aux, p_signo_aux : STD_LOGIC;

signal ready_aux, p_ready_aux : STD_LOGIC;

begin

signo <= signo_aux;
ready <= ready_aux;

sinc : process (rst, clk)
begin
	if (rst = '1') then
		secuencia 		<= (others => '1');
		estado_actual 	<= reposo;
		cuenta	 		<= (others => '0');
		signo_aux      <= '1';
		ready_aux		<= '1';
	elsif (rising_edge(clk)) then
		secuencia 		<= p_secuencia;
		estado_actual 	<= nuevo_estado;
		cuenta 			<= p_cuenta;
		signo_aux 		<= p_signo_aux;
		ready_aux		<= p_ready_aux;
	end if;
end process;

comb : process (enable, estado_actual, cuenta, secuencia, signo_aux)
begin

	p_cuenta 	 <= (others => '0');
	nuevo_estado <= reposo;
	p_secuencia  <= secuencia;
	p_signo_aux  <= signo_aux;
	
	p_ready_aux <= '1';

	case estado_actual is

			when reposo =>	
				if (enable = '1') then
					nuevo_estado <= iterando;
					p_signo_aux  <= secuencia(11);
					p_ready_aux  <= '0';
				end if;
				p_signo_aux <= secuencia(11);
				
			when iterando =>
				p_ready_aux 			<= '0';
				p_secuencia(1) 	   <= secuencia(9) xor secuencia(11);
				p_secuencia(2 to 11) <= secuencia(1 to 10);			
				if (cuenta /= ESPACIADO_PILOTOS-1) then
					nuevo_estado <= iterando;
					p_cuenta 	 <= cuenta + 1;
					p_ready_aux  <= '0';
				end if;
		
		end case;

end process;

end Behavioral;


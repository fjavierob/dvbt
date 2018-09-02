----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:02:30 05/08/2018 
-- Design Name: 
-- Module Name:    Intelpoladol - Behavioral 
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
library work;
use IEEE.STD_LOGIC_1164.ALL;
use work.DEF.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Intelpoladol is
	 Generic (ESPACIADO_PILOTOS: SIGNED(4 DOWNTO 0) := "01100");
    Port ( clk 			: in   STD_LOGIC;
           rst 			: in   STD_LOGIC;
           inf 			: in   complex10;
           sup 		  	: in   complex10;
           enable		  	: in   STD_LOGIC;
           estim 		  	: out  complex10;
           estim_valid 	: out  STD_LOGIC);
end Intelpoladol;

architecture Behavioral of Intelpoladol is

type estado is (reposo, interpolando, espera);

signal estado_actual, nuevo_estado : estado;
signal i, p_i : signed(4 downto 0);
signal a, p_a, b, p_b : complex10;
signal estim_aux,  p_estim_aux  : complex15;
signal estimv_aux, p_estimv_aux : STD_LOGIC;

begin

-- Dividir por 12 y por 4/3 => Dividir por 16 = Quitar últimos 4 bits (pierdo el resto de la división).
-- Los dos primerps bits (más significativos) siempre tiene el mismo valor
-- debido a la multiplicación -> Se puede descartar 1 de ellos
estim.re 	<= estim_aux.re(13 downto 4);
estim.im 	<= estim_aux.im(13 downto 4);
estim_valid <= estimv_aux;

sinc : process (rst, clk) 
begin
	if (rst = '1') then
		estado_actual <= reposo;
		i <= (others => '0');
		estimv_aux   <= '0';
	elsif (rising_edge(clk)) then
		estado_actual <= nuevo_estado;
		estim_aux.re  <= p_estim_aux.re;
		estim_aux.im  <= p_estim_aux.im;
		estimv_aux    <= p_estimv_aux;
		i <= p_i;
		a <= p_a;
		b <= p_b;
	end if;
end process;

comb : process (enable, i, a, b, estim_aux, estado_actual, inf, sup)
begin

	p_estimv_aux    <= '0';
	p_estim_aux.re  <= estim_aux.re;
	p_estim_aux.im  <= estim_aux.im;

	p_i <= i;
	p_a <= a;
	p_b <= b;

	nuevo_estado <= estado_actual;

	case estado_actual is

		when reposo =>
			if (enable = '1') then
				nuevo_estado  <= interpolando;
				p_a 			  <= inf;
				p_b 			  <= sup;		
			end if;
			
		when interpolando =>
			p_estim_aux.re <= std_logic_vector(signed(b.re)*i+signed(a.re)*(ESPACIADO_PILOTOS-i));
			p_estim_aux.im <= std_logic_vector(signed(b.im)*i+signed(a.im)*(ESPACIADO_PILOTOS-i));
			p_estimv_aux 	<= '1';
			if (i = ESPACIADO_PILOTOS-1) then
				nuevo_estado  <= reposo;
				p_i 			  <= (others => '0');
			else
				p_i <= i + 1;
				nuevo_estado <= espera;
			end if;
		
		when espera =>
			if (enable = '1') then
				nuevo_estado <= interpolando;
			end if;
			
		
	end case;

end process;


end Behavioral;


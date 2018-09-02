----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:45:11 05/23/2018 
-- Design Name: 
-- Module Name:    FSM - Behavioral 
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

entity FSM is
	 Generic (ESPACIADO_PILOTOS : integer := 12;
				 NUM_INTERVALOS	 : integer := 142;
				 BITS_INTERVALOS 	 : integer := 8);
	 
    Port ( clk 				: in  STD_LOGIC;
           rst 				: in  STD_LOGIC;
			  start				: in 	STD_LOGIC;
           datoMemoria    	: in	STD_LOGIC_VECTOR(23 downto 0);
			  signo 				: in 	STD_LOGIC;
			  prbs_ok	   	: in	STD_LOGIC;
			  int_valid			: in  STD_LOGIC;
			  int_dato			: in 	complex10;
			  div_rfd			: in	STD_LOGIC;
			  div_rdy			: in	STD_LOGIC;
			  div_q				: in 	STD_LOGIC_VECTOR(19 downto 0);
			  div_f				: in 	STD_LOGIC_VECTOR(19 downto 0);
			  div_nd			   : out STD_LOGIC;
			  div_dividend		: out	STD_LOGIC_VECTOR(19 downto 0);
			  div_divisor		: out STD_LOGIC_VECTOR(19 downto 0);
			  enablePRBS		: out STD_LOGIC;
			  dir 				: out STD_LOGIC_VECTOR(10 downto 0);
           interpola	  		: out	STD_LOGIC;
			  piloto_sup		: out complex10;
			  piloto_inf		: out	complex10;
			  dato_valid		: out STD_LOGIC;
			  dato_ecualizado : out STD_LOGIC_VECTOR(15 downto 0));
end FSM;

architecture Behavioral of FSM is

type estado is (reposo, leerPiloto, estimando, esperaMemoriaPiloto, esperaPRBS, ecualizando, esperaMemoriaDato, ecualizaDato, esperaDivisor);

signal interpola_aux,  		p_interpola_aux 	 : STD_LOGIC;
signal prbs,		  	  		p_prbs 				 : STD_LOGIC;
signal dir_aux, 		  		p_dir_aux 			 : unsigned (10 downto 0);
signal sup_re,   sup_im,	inf_re,   inf_im 	 : std_logic_vector(9 downto 0);
signal p_sup_re, p_sup_im, p_inf_re, p_inf_im : std_logic_vector(9 downto 0);

signal i, 			 p_i 			 : unsigned (BITS_INTERVALOS-1 downto 0);
signal espera, 	 p_espera 	 : unsigned(1 downto 0);
signal sup, p_sup, inf, p_inf  : STD_LOGIC_VECTOR (23 downto 0);
signal signo_sup,  p_signo_sup : STD_LOGIC;
signal signo_inf,  p_signo_inf : STD_LOGIC;

signal estado_actual, nuevo_estado : estado;

signal dato_valid_aux, p_dato_valid_aux 	: STD_LOGIC;
signal dato_ec_aux,    p_dato_ec_aux 		: complex10;

signal divisor_aux, 	 p_divisor_aux	  : STD_LOGIC_VECTOR(19 downto 0);
signal dividendo_aux, p_dividendo_aux : STD_LOGIC_VECTOR(19 downto 0);

signal h_re, p_h_re,   h_im, p_h_im 	 : STD_LOGIC_VECTOR(9 downto 0);
signal dato_re,	     p_dato_re    	 : STD_LOGIC_VECTOR(9 downto 0);
signal dato_im,	     p_dato_im    	 : STD_LOGIC_VECTOR(9 downto 0);
signal resultado_div,  p_resultado_div	 : STD_LOGIC_VECTOR(7 downto 0);
signal dato_ec_re, 	  p_dato_ec_re		 : STD_LOGIC_VECTOR(7 downto 0);
signal dato_ec_im, 	  p_dato_ec_im		 : STD_LOGIC_VECTOR(7 downto 0);
signal parte, 			  p_parte			 : unsigned(1 downto 0);
signal nd, 				  p_nd     	 		 : STD_LOGIC;

signal e, p_e : unsigned(3 downto 0);

begin

dir 				 <= std_logic_vector(dir_aux);
interpola 		 <= interpola_aux;
enablePRBS  	 <= prbs;
dato_ecualizado <= dato_ec_re & dato_ec_im;
dato_valid		 <= dato_valid_aux;

div_dividend    <= divisor_aux;
div_divisor		 <= dividendo_aux;

piloto_sup.re  <= sup_re;
piloto_sup.im  <= sup_im;
piloto_inf.re  <= inf_re;
piloto_inf.im  <= inf_im;

div_nd <= nd;

sinc : process (rst, clk) 
begin
	if (rst = '1') then
		estado_actual 	<= reposo;
		dir_aux 		  	<= (others => '0');
		i 				  	<= (others => '0');
		espera 		  	<= (others => '0');
		e					<= (others => '0');
		parte				<= (others => '0');
		interpola_aux 	<= '0';
		prbs				<= '0';
		dato_valid_aux <= '0';
		nd					<= '0';
	elsif (rising_edge(clk)) then
		dir_aux		  		<= p_dir_aux;
		i 				  		<= p_i;
		estado_actual 		<= nuevo_estado;
		espera 		  		<= p_espera;
		
		sup 					<= p_sup;
		inf					<= p_inf;
		
		signo_sup			<= p_signo_sup;
		signo_inf			<= p_signo_inf;
		
		interpola_aux 		<= p_interpola_aux;
			
		prbs 					<= p_prbs;
		
		sup_re				<= p_sup_re;
		sup_im				<= p_sup_im;
		inf_im				<= p_inf_im;
		inf_re				<= p_inf_re;
		
		h_re					<= p_h_re;
		h_im					<= p_h_im;
		
		divisor_aux			<= p_divisor_aux;
		dividendo_aux 		<= p_dividendo_aux;
		resultado_div		<= p_resultado_div;
		
		dato_re  			<= p_dato_re;
		dato_im				<= p_dato_im;
		parte					<= p_parte;
		nd						<= p_nd;
		dato_valid_aux  	<= p_dato_valid_aux;
		dato_ec_re   		<= p_dato_ec_re;
		dato_ec_im			<= p_dato_ec_im;
		
		e						<= p_e;
	end if;
end process;

comb : process (start, dir_aux, i, estado_actual, espera, sup, inf, datoMemoria, signo, signo_sup, prbs_ok, signo_inf, sup_re, sup_im, inf_im, inf_re, 
					 signo_inf, h_re, h_im, divisor_aux, dividendo_aux, resultado_div, dato_re, dato_im, parte, dato_ec_re, dato_ec_im, e, int_valid, int_dato,
					 div_rfd, div_rdy, div_q, div_f)
begin
	
	p_dir_aux 			<= dir_aux;
	p_i 		 			<= i;
	nuevo_estado 		<= estado_actual;
	p_espera 			<= espera;
	
	p_sup 				<= sup;
	p_inf 				<= inf;
	
	p_signo_sup			<= signo_sup;
	p_signo_inf			<= signo_inf;
	
	p_interpola_aux 	<= '0';
	
	p_prbs 				<= '0';
	
	p_sup_re				<= sup_re;
	p_sup_im				<= sup_im;
	p_inf_im				<= inf_im;
	p_inf_re				<= inf_re;
	
	p_h_re				<= h_re;
	p_h_im				<= h_im;
	
	p_divisor_aux		<= divisor_aux;
	p_dividendo_aux 	<= dividendo_aux;
	p_resultado_div	<= resultado_div;
	
	p_dato_re  			<= dato_re;
	p_dato_im			<= dato_im;
	p_parte				<= parte;
	p_nd					<= '0';
	p_dato_valid_aux  <= '0';
	p_dato_ec_re   	<= dato_ec_re;
	p_dato_ec_im		<= dato_ec_im;
	
	p_e					<= e;
	
	case estado_actual is
	
		when reposo =>
			if (start = '1') then
				nuevo_estado 	<= esperaPRBS;
				p_sup				<= datoMemoria;
			end if;
			
		when esperaPRBS =>
			if (prbs_ok = '1') then
				p_signo_sup 			 	<= signo;
				p_prbs 						<= '1';
				if (i = 0) then
					nuevo_estado 		 	<= leerPiloto;
					p_i						<= i + 1;
				else
					nuevo_estado 		 	<= estimando;
					p_dir_aux				<= dir_aux - ESPACIADO_PILOTOS;
					p_interpola_aux 	 	<= '1';
					if (signo = '1') then -- Cambiar el signo del piloto superior.
						p_sup_re <= std_logic_vector(signed(not(sup(21 downto 12)))+1);
						p_sup_im <= std_logic_vector(signed(not(sup(9  downto  0)))+1);
					else
						p_sup_re <= sup(21 downto 12);
						p_sup_im <= sup(9  downto  0);
					end if;
					if (signo_inf = '1') then -- Cambiar el signo del piloto inferior.
						p_inf_re <= std_logic_vector(signed(not(inf(21 downto 12)))+1);
						p_inf_im <= std_logic_vector(signed(not(inf(9  downto  0)))+1);
					else
						p_inf_re <= inf(21 downto 12);
						p_inf_im <= inf(9  downto  0);
					end if;
				end if;
			end if;
			
		when esperaMemoriaPiloto =>
			if (espera = 3) then
				nuevo_estado  		<= esperaPRBS;
				p_sup 				<= datoMemoria;
				p_espera				<= (others => '0');
			end if;
				p_espera 			<= espera + 1;
			
		when leerPiloto =>
			p_dir_aux		<= dir_aux + ESPACIADO_PILOTOS;
			p_inf 			<= sup;
			p_signo_inf		<= signo_sup;
			nuevo_estado 	<= esperaMemoriaPiloto;
		
		when estimando =>
			if (e = ESPACIADO_PILOTOS) then
				p_e <= (others => '0');
				if (i = NUM_INTERVALOS) then
					nuevo_estado <= reposo;
				else
					nuevo_estado <= leerPiloto;
					p_i 			 <= i + 1;
				end if;
			elsif (int_valid = '1') then
				-- Ecualizar dato
				p_h_re		 <= int_dato.re;
			-- Pequeño parche. El signo de la parte imaginaria me sale siempre al revés, y no sé por qué -__-
			--	p_h_im		 <= int_dato.im;
				p_h_im 		 <= std_logic_vector((signed(not(int_dato.im)))+1);
				nuevo_estado <= ecualizando;
			end if;
			
		when ecualizando =>
			p_dir_aux 	 <= dir_aux + 1;
			nuevo_estado <= estimando;
			if (e = 0) then
			   -- El primer valor de la interpolación es un piloto, así que lo ignoro.
				nuevo_estado	 <= estimando;
				p_interpola_aux <= '1';
				p_e 				 <= e + 1;
			else
				-- Ecualizo el dato.
				nuevo_estado <= esperaMemoriaDato;
			end if;
				
		when esperaMemoriaDato =>
			-- Espero a que la memoria tenga el dato listo.
			if (espera = 3) then
				nuevo_estado <= ecualizaDato;
				p_dato_re 	 <= datoMemoria(21 downto 12);
				p_dato_im 	 <= datoMemoria(9  downto  0);
				p_espera		 <= (others => '0');
			end if;
				p_espera 	 <= espera + 1;
			
		when ecualizaDato =>
			-- Ecualizo el dato
			p_parte <= parte + 1;
			if (parte = 0) then
				-- Dividir parte real.
				if (div_rfd = '1') then
					p_nd 				 <= '1';
					p_dividendo_aux <= std_logic_vector(signed(dato_re)*signed(h_re)+signed(dato_im)*signed(h_im));
					p_divisor_aux   <= std_logic_vector(signed(h_re)*signed(h_re)+signed(h_im)*signed(h_im));
					nuevo_estado    <= esperaDivisor;
				end if;
			elsif (parte = 1) then
				-- Guardamos el valor de la división de la parte real.
				p_dato_ec_re	 <= resultado_div;
				-- Dividir parte imag.
				if (div_rfd = '1') then
					p_nd 				  <= '1';
					p_dividendo_aux  <= std_logic_vector(signed(dato_im)*signed(h_re)-signed(dato_re)*signed(h_im));
					p_divisor_aux    <= std_logic_vector(signed(h_re)*signed(h_re)+signed(h_im)*signed(h_im));
					nuevo_estado 	  <= esperaDivisor;
				end if;
			else
				-- Se han hecho las dos divisiones
				nuevo_estado		  <= estimando;
				-- Guardamos el valor de la división de la parte real.
				p_dato_ec_im 	  	  <= resultado_div;
				-- Indicamos que en el próximo ciclo de reloj el dato ecualizado es correcto.
				p_dato_valid_aux    <= '1';
				p_parte <= (others  => '0');
				p_e				     <= e + 1;
				if (e /= ESPACIADO_PILOTOS - 1) then
					p_interpola_aux  <= '1';
				end if;
			end if;
			
		when esperaDivisor =>
			if (div_rdy = '1') then
				p_resultado_div <= div_q(2 downto 0) & div_f(19 downto 15);
				nuevo_estado <= ecualizaDato;
			end if;
					
	end case;
	
end process;

end Behavioral;


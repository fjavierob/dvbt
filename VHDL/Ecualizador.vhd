----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:41:13 05/20/2018 
-- Design Name: 
-- Module Name:    Ecualizador - Behavioral 
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

entity Ecualizador is
	 Port ( reset  : in  STD_LOGIC;
           clk    : in  STD_LOGIC;
           start  : in  STD_LOGIC;
			  endsim : in  STD_LOGIC;
			  dato   : out STD_LOGIC_VECTOR(15 downto 0);
			  valid  : out STD_LOGIC
			  );
end Ecualizador;

architecture Behavioral of Ecualizador is

COMPONENT datawrite is
  generic(
    SIMULATION_LABEL    : string  := "datawrite";                    --! Allow to separate messages from different instances in SIMULATION
    VERBOSE             : boolean := false;                          --! Print more internal details
    DEBUG               : boolean := false;                          --! Print debug info (developers only)        
    OUTPUT_FILE         : string  := "./output/datawrite_test.txt";  --! File where data will be stored
    OUTPUT_NIBBLES      : integer := 2;                              --! Hex chars on each output line 
    DATA_WIDTH          : integer := 8                               --! Width of input data
    );
  PORT (
    clk    : in std_logic;                                --! Will sample input on rising_edge of this clock
    data   : in std_logic_vector (DATA_WIDTH-1 downto 0); --! Data to write to file
    valid  : in std_logic;                                --! Active high, indicates data is valid
    endsim : in std_logic                                 --! Active high, tells the process to close its open files
    );
END COMPONENT;

COMPONENT datos2k is
  PORT (
    clka  : IN  STD_LOGIC;
    addra : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(23 DOWNTO 0));
END COMPONENT;

COMPONENT divisor20
	PORT (
	clk		  : in  std_logic;
	nd			  : in  std_logic;
	rdy 		  : out std_logic;
	rfd 		  : out std_logic;
	dividend   : in  std_logic_vector(19 downto 0);
	divisor    : in  std_logic_vector(19 downto 0);
	quotient   : out std_logic_vector(19 downto 0);
	fractional : out std_logic_vector(19 downto 0));
END COMPONENT;

component Intelpoladol is
	 Generic (ESPACIADO_PILOTOS: SIGNED(4 DOWNTO 0) := "01100");
    Port ( clk 			: in   STD_LOGIC;
           rst 			: in   STD_LOGIC;
           inf 			: in   complex10;
           sup 		  	: in   complex10;
           enable		  	: in   STD_LOGIC;
           estim 		  	: out  complex10;
           estim_valid 	: out  STD_LOGIC);
end component;

component prbs is
	 Generic (ESPACIADO_PILOTOS : integer := 12);
    Port ( clk 		 : in  STD_LOGIC;
           rst    	 : in  STD_LOGIC;
			  enable 	 : in  STD_LOGIC;
			  ready		 : out STD_LOGIC;
			  signo  	 : out STD_LOGIC);
end component;

component FSM is
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
end component;

-- Señales datawrite
signal s_canal  	   : STD_LOGIC_VECTOR(23 downto 0);
signal s_ec_dato		: STD_LOGIC_VECTOR(15 downto 0);
signal s_ec_valid    : STD_LOGIC;

-- Señales memoria
signal s_addr   : STD_LOGIC_VECTOR (10 downto 0);
signal s_datoMemoria : STD_LOGIC_VECTOR (23 downto 0); 

-- Señales prbs
signal valid_prbs, enable_prbs, s_signo : STD_LOGIC;

-- Señales interpolador
signal s_sup, s_inf	 : complex10;
signal s_int_enable   : STD_LOGIC;
signal s_int_valid 	 : STD_LOGIC;
signal s_int_dato		 : complex10;

-- Señales divisor
signal s_div_rdy,  s_div_rfd, s_div_nd : STD_LOGIC;
signal s_dividend, s_divisor			   : STD_LOGIC_VECTOR(19 downto 0);
signal s_div_q,    s_div_f					: STD_LOGIC_VECTOR(19 downto 0);


begin



s_canal(23 downto 22) <= "00";
s_canal(21 downto 12) <= s_int_dato.re;
-- Pequeño parche. El signo de la parte imaginaria me sale siempre al revés, y no sé por qué -__-
-- s_canal(9  downto  0) <= s_int_dato.im;
s_canal(9  downto  0) <= std_logic_vector((signed(not(s_int_dato.im)))+1);
s_canal(11 downto 10) <= "00";

dato  <= s_ec_dato;
valid <= s_ec_valid;

writeCanal : datawrite
  GENERIC MAP (
	 OUTPUT_NIBBLES => 6,
    DATA_WIDTH  	 => 24,
	 OUTPUT_FILE 	 => "output\canal.txt"
	 )
  PORT MAP (
	 clk    => clk,
	 data   => s_canal,
	 valid  => s_int_valid,
	 endsim => endsim
	 );
	 
writeDatos : datawrite
  GENERIC MAP (
	 OUTPUT_NIBBLES => 4,
    DATA_WIDTH  	 => 16,
	 OUTPUT_FILE 	 => "output\datos.txt"
	 )
  PORT MAP (
	 clk    => clk,
	 data   => s_ec_dato,
	 valid  => s_ec_valid,
	 endsim => endsim
	 );

memoriaDatos : datos2k
  PORT MAP (
    clka  => clk,
    addra => s_addr,
    douta => s_datoMemoria
  );
  
divisor : divisor20
	port map (
		clk 		  => clk,
		nd 		  => s_div_nd,
		rdy 		  => s_div_rdy,
		rfd 		  => s_div_rfd,
		dividend   => s_dividend,
		divisor 	  => s_divisor,
		quotient   => s_div_q,
		fractional => s_div_f);

interpolador : Intelpoladol
	PORT MAP (
		clk 			=> clk,
		rst 			=> reset,
		inf 			=> s_inf,
		sup 			=> s_sup,
		enable 		=> s_int_enable,
		estim 		=> s_int_dato,
		estim_valid => s_int_valid
      );
		
random : prbs
	PORT MAP (
		clk 	 => clk,
		rst 	 => reset,
		signo  => s_signo,
		ready  => valid_prbs,
		enable => enable_prbs
		);

control : FSM
	PORT MAP (
		clk 				 => clk, 
		rst 				 => reset,
		start 			 => start,
		datoMemoria		 => s_datoMemoria,
		signo 			 => s_signo,
		prbs_ok 			 => valid_prbs,
		int_valid   	 => s_int_valid,
		int_dato    	 => s_int_dato,
		div_rfd			 => s_div_rfd,
		div_rdy			 => s_div_rdy,
		div_q				 => s_div_q,
		div_f				 => s_div_f,
		
		div_nd		 	 => s_div_nd,
		div_dividend 	 => s_dividend,
		div_divisor  	 => s_divisor,
		enablePRBS 		 => enable_prbs,
		dir 				 => s_addr,
		interpola 		 => s_int_enable,
		piloto_sup		 => s_sup,
		piloto_inf 		 => s_inf,
		dato_valid   	 => s_ec_valid,
		dato_ecualizado => s_ec_dato
		);

end Behavioral;


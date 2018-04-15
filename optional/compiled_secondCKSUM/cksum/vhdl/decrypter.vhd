----------------------------------------------------------------------------------
-- DECRYPTOR

-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:06:59 01/29/2018 
-- Design Name: 
-- Module Name:    decrypter - Behavioral 
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
-- for unsigned integer operations
use IEEE.NUMERIC_STD.ALL;

-- Entity definition for Decrypter
entity decrypter is
    Port ( clock : in  STD_LOGIC;
           K : in  STD_LOGIC_VECTOR (31 downto 0);
           C : in  STD_LOGIC_VECTOR (31 downto 0);
           P : out  STD_LOGIC_VECTOR (31 downto 0);
           done : out STD_LOGIC;
           reset : in  STD_LOGIC;
           enable : in  STD_LOGIC);
end decrypter;

-- Architecture definition for Decrypter
architecture Behavioral of decrypter is

-----------------------
-- Signal definitions --
-----------------------

signal T : STD_LOGIC_VECTOR (3 downto 0);
-- introduced to handle dynamic initialization of signals
signal first_loop : STD_LOGIC := '1';
-- introduced to handle T <= T + 15
signal second_loop : STD_LOGIC := '1';
-- stores number of ones in K
signal N1 : STD_LOGIC_VECTOR (5 downto 0);
-- signal to store output bits
signal myC : STD_LOGIC_VECTOR (31 downto 0);
-- integers to store signal values for convenient addition 
signal temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8,temp9,temp10,temp11,temp12,temp13,temp14,temp15,temp16,temp17,temp18,temp19,temp20,temp21,temp22,temp23,temp24,temp25,temp26,temp27,temp28,temp29,temp30,temp31, temp32: integer :=0;
-- integer to store number of ones in K
signal num_ones,num_zeros: integer := 0;
-- constant integer 32
signal thirty_two: integer := 32;

begin
	-- store signal values in integers
	temp1 <= 1 when (K(0) = '1') else 0;
	temp2 <= 1 when (K(1) = '1') else 0;
	temp3 <= 1 when (K(2) = '1') else 0;
	temp4 <= 1 when (K(3) = '1') else 0;
	temp5 <= 1 when (K(4) = '1') else 0;
	temp6 <= 1 when (K(5) = '1') else 0;
	temp7 <= 1 when (K(6) = '1') else 0;
	temp8 <= 1 when (K(7) = '1') else 0; 
	temp9 <= 1 when (K(8) = '1') else 0; 
	temp10 <= 1 when (K(9) = '1') else 0;
	temp11 <= 1 when (K(10) = '1') else 0; 
	temp12 <= 1 when (K(11) = '1') else 0;  
	temp13 <= 1 when (K(12) = '1') else 0; 
	temp14 <= 1 when (K(13) = '1') else 0; 
	temp15 <= 1 when (K(14) = '1') else 0;
	temp16 <= 1 when (K(15) = '1') else 0;
	temp17 <= 1 when (K(16) = '1') else 0;
	temp18 <= 1 when (K(17) = '1') else 0; 
	temp19 <= 1 when (K(18) = '1') else 0; 
	temp20 <= 1 when (K(19) = '1') else 0; 
	temp21 <= 1 when (K(20) = '1') else 0; 
	temp22 <= 1 when (K(21) = '1') else 0; 
	temp23 <= 1 when (K(22) = '1') else 0; 
	temp24 <= 1 when (K(23) = '1') else 0; 
	temp25 <= 1 when (K(24) = '1') else 0; 
	temp26 <= 1 when (K(25) = '1') else 0; 
	temp27 <= 1 when (K(26) = '1') else 0; 
	temp28 <= 1 when (K(27) = '1') else 0; 
	temp29 <= 1 when (K(28) = '1') else 0; 
	temp30 <= 1 when (K(29) = '1') else 0; 
	temp31 <= 1 when (K(30) = '1') else 0;
	temp32 <= 1 when (K(31) = '1') else 0; 
	-- count number of ones and store in num_ones
	num_ones <= temp1+temp2+temp3+temp4+temp5+temp6+temp7+temp8+temp9+temp10+temp11+temp12+temp13+temp14+temp15+temp16+temp17+temp18+temp19+temp20+temp21+temp22+temp23+temp24+temp25+temp26+temp27+temp28+temp29+temp30+temp31+ temp32;
	-- find number of zeros from num_ones
	num_zeros <= thirty_two - num_ones;
   process(clock, reset, enable)
	 begin
		if (reset = '1') then
			P <= "00000000000000000000000000000000";
			first_loop <= '1';
			second_loop <= '1';
			done <= '0';
		elsif (clock'event and clock = '1' and enable = '1') then		
			-- loop which handles initializations
			if ( first_loop = '1') then
				myC <= C;
				-- intialize T according to algorithm
				T(3) <= K(31) xor K(27) xor K(23) xor K(19) xor K(15) xor K(11) xor K(7) xor K(3);
				T(2) <= K(30) xor K(26) xor K(22) xor K(18) xor K(14) xor K(10) xor K(6) xor K(2);
				T(1) <= K(29) xor K(25) xor K(21) xor K(17) xor K(13) xor K(9) xor K(5) xor K(1);
				T(0) <= K(28) xor K(24) xor K(20) xor K(16) xor K(12) xor K(8) xor K(4) xor K(0);    
				N1 <= STD_LOGIC_VECTOR(to_unsigned(num_zeros,6));
				first_loop <= '0';	
				done <= '0';			
			else
				-- handles T <= T + 15 AFTER initialization of T
				if ( second_loop = '1' ) then
					T <= std_logic_vector(unsigned(T) + 15);
					second_loop <= '0';
					done <= '0';
				else
					-- for loop iterations, as per algorithm described
					if ( N1 /= "000000") then
						myC <= myC xor (T & T & T & T & T & T & T & T);
						T <= std_logic_vector(unsigned(T) + 15);
						N1 <= std_logic_vector(unsigned(N1) - 1);
						done <= '0';
					else
						-- send result to output port once loop terminates
						P <= myC;
						done <= '1';
					end if;
				end if;				
			end if;			
		end if;			
	 end process;
end Behavioral;

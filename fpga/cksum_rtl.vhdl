--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- state = sw_in[3]

-- channel 0 read and write 0000 on channel 0
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of swled is
	-- Flags for display on the 7-seg decimal points
	signal flags : std_logic_vector(3 downto 0);

	-- Registers implementing the channels 
	constant curr_coordinate : std_logic_vector(31 downto 0) := "00010011000100110001001100010011";
	constant my_channel_in : std_logic_vector(6 downto 0) := "0000101";
	constant my_channel_out : std_logic_vector(6 downto 0) := "0000100";
	constant ACK1: std_logic_vector(31 downto 0) := "00101010001010100010101000101011";
	constant ACK2: std_logic_vector(31 downto 0) := "10101010101010101010101010101011";
	constant WannaSent : std_logic_vector(31 downto 0) := "11001110110011101100111011001111";
	constant NotWannaSent : std_logic_vector(31 downto 0) := "00110001001100010011000100110011";
	
	signal encrypted_data1: std_logic_vector(31 downto 0);
	
	constant key:  std_logic_vector(31 downto 0):= "10100000110100111111000101011011";

	signal enable_decryptor1 : std_logic := '0';
	signal done_decrypt : std_logic := '0';
	signal decrypted_data1: std_logic_vector(31 downto 0) := (others => '0');


	signal decrypt_data_part1: std_logic_vector(31 downto 0);
	signal decrypt_data_part2: std_logic_vector(31 downto 0);

	signal uart_data_part1: std_logic_vector(31 downto 0);
	signal uart_data_part2: std_logic_vector(31 downto 0);

	
	signal encrypter_inp : std_logic_vector(31 downto 0);
	signal enable_encryption : std_logic;
	signal encrypter_out : std_logic_vector(31 downto 0);
	signal done_encrypt : std_logic;

	constant TIMER_COUNT : integer :=  48000000;--value
	signal timer : integer;
	signal second_counter: integer;
	signal cntr : integer;
	signal cntrdecrypt: integer; -- This will count from 0 to 15 and at each count add recieved data to encrypted_data_signal
	signal decrypter_reset : std_logic;
	signal encrypter_reset : std_logic;

signal uart_rx_data: std_logic_vector(7 downto 0);
signal uart_rx_enable: std_logic;
signal uart_tx_data: std_logic_vector(7 downto 0);
signal uart_tx_enable: std_logic;
signal uart_tx_ready: std_logic;
signal uart_buffer : std_logic_vector(7 downto 0);

	signal f2hValid_out2 : std_logic;
	signal f2hData_out2 :std_logic_vector(7 downto 0);
	signal train_direction : std_logic_vector(7 downto 0);

	signal stage : integer := 0;
begin                                                                     
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				decrypter_reset <= '1';
				encrypter_reset <= '1';
				cntrdecrypt <= 0;
				cntr <= 0;
				timer <= 3*TIMER_COUNT;
				enable_encryption <= '0';
				encrypter_inp <= "00000000000000000000000000000000";
				decrypt_data_part1 <= "00000000000000000000000000000000";
				decrypt_data_part2 <= "00000000000000000000000000000000";
				uart_data_part1 <= "11000001110010011101000111011001";
				uart_data_part2 <= "11100001111010011111000111111001";
				enable_decryptor1 <= '0';
				encrypted_data1 <= "00000000000000000000000000000000";
				stage <= 0;
				uart_buffer <= "00011001";
				f2hValid_out2 <= '1';
				f2hData_out2 <= "00000000";
				second_counter <= 0;
				led_out <= "00000000";
				uart_tx_enable <= '0';
			else
				if ( stage = 0) then
					decrypter_reset <= '0';
					encrypter_reset <= '0';
					cntrdecrypt <= 0;
					cntr <= 0;
					if (timer = 0) then
						second_counter <= 0;
						decrypt_data_part1 <= "00000000000000000000000000000000";
						decrypt_data_part2 <= "00000000000000000000000000000000";
						enable_decryptor1 <= '0';
						encrypted_data1 <= "00000000000000000000000000000000";
						f2hData_out2 <= "00000000";
						enable_encryption <= '1';
						f2hValid_out2 <= '1';
						encrypter_inp <= curr_coordinate;
						if (done_encrypt = '1') then
							stage <= 1;--40; --CHANGE
							led_out <= "00000000";
						end if;
					else
						timer <= timer - 1;
						led_out <= "11111111";						
					end if ;
					

				end if;
-- sending message
				if (stage = 1) then
					timer <= TIMER_COUNT;
					enable_encryption <= '0';
					if (cntr = 0) then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							--stage <= 2;
							stage <= 2;
							-- led_out <= "00000010";
							encrypter_reset <= '1';			
						end if;
					end if;
				end if;
-- 256 second wait for receiving Encrypted coordinate on the channel == my_channel_in
				if (stage = 2) then
					if(second_counter < 256) then
						if(timer > 0) then
							if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then
								encrypter_reset <= '1';	
								encrypted_data1(31 downto 24) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
								encrypter_reset <= '0';						
								encrypted_data1(23 downto 16) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 2) then	
								encrypted_data1(15 downto 8) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 3) then	
								encrypted_data1(7 downto 0) <= h2fData_in;
								cntrdecrypt <= 0;
								stage <= 3;
								-- led_out <= "00000011";
								enable_decryptor1 <= '1';
							else
								timer <= timer - 1;
							end if;
						else
							timer <= TIMER_COUNT;
							second_counter <= second_counter + 1;
						end if;
					else
						second_counter <= 0;
						stage <= 0;
					end if;
				end if;

				if (stage = 3) then
					if ( done_decrypt = '1' and decrypted_data1 = curr_coordinate) then
						stage <= 4;
						-- led_out <= "00000100";
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
						timer <= TIMER_COUNT;
						second_counter <= 0;
					elsif ( done_decrypt = '1') then
						stage <= 2;
					end if;
				end if;

				if (stage = 4) then
					decrypter_reset <= '0';
					enable_encryption <= '1';
					encrypter_inp <= ACK1;
					if (done_encrypt = '1') then
						stage <= 5;
						-- led_out <= "00000101";
					end if;
				end if;

				if (stage = 5) then
					enable_encryption <= '0';
					if (cntr = 0) then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							f2hData_out2 <= encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 6;
							-- led_out <= "00000110";				
						end if;
					end if;
				end if;
-- ACK2 receiving and matching
				if (stage = 6) then
					if(second_counter < 256) then
						if(timer > 0) then
							if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then
								encrypter_reset <= '1';	
								encrypted_data1(31 downto 24) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
								encrypter_reset <= '0';						
								encrypted_data1(23 downto 16) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 2) then	
								encrypted_data1(15 downto 8) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 3) then	
								encrypted_data1(7 downto 0) <= h2fData_in;
								cntrdecrypt <= 0;
								stage <= 7;
								-- led_out <= "00000111";
								enable_decryptor1 <= '1';
							else
								timer <= timer - 1;
							end if;
						else
							timer <= TIMER_COUNT;
							second_counter <= second_counter + 1;
						end if;
					else
						second_counter <= 0;
						stage <= 0;
					end if;
				end if;

				if (stage = 7) then
					if ( done_decrypt = '1' and decrypted_data1 = ACK2) then
						stage <= 8; -- NEED TO DECIDE FOR ELSE
						-- led_out <= "00001000";
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
						timer <= TIMER_COUNT;
						second_counter <= 0;
					elsif ( done_decrypt = '1') then
						stage <= 6;
					end if;
				end if;

				-- DATA 1st part is coming
				if (stage = 8) then
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then	
						decrypter_reset <= '0';
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypted_data1(23 downto 16) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;					
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 2) then	
						encrypted_data1(15 downto 8) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;					
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 3) then	
						encrypted_data1(7 downto 0) <= h2fData_in;
						cntrdecrypt <= 0;
						stage <= 9;
						-- led_out <= "00001001";
						enable_decryptor1 <= '1';
					end if;
				end if;
				if (stage = 9) then
					if ( done_decrypt = '1') then
						stage <= 10; -- We have part 1 of data
						-- led_out <= "00001010";
						enable_decryptor1 <= '0';
						decrypt_data_part1 <= decrypted_data1;
					end if;
				end if;

				if (stage = 10) then
					decrypter_reset <= '1';
					enable_encryption <= '1';
					encrypter_inp <= ACK1;
					if (done_encrypt = '1') then
						stage <= 11;
						-- led_out <= "00001011";
					end if;	
				end if;


				-- Send ACK after encryption back to host
				if (stage = 11) then
					enable_encryption <= '0';
					decrypter_reset <= '0';
					if (cntr = 0) then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							f2hData_out2 <= encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 14;
							-- led_out <= "00001110";				
						end if;
					end if;
				end if;

				if (stage = 14) then
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then	
						decrypter_reset <= '0';
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypted_data1(23 downto 16) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;					
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 2) then	
						encrypted_data1(15 downto 8) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;					
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 3) then	
						encrypted_data1(7 downto 0) <= h2fData_in;
						cntrdecrypt <= 0;
						stage <= 15;
						-- led_out <= "00001111";
						enable_decryptor1 <= '1';
					end if;
				end if;
				if (stage = 15) then
					if ( done_decrypt = '1') then
						stage <= 16; -- We have part 1 of data
						-- led_out <= "00010000";
						enable_decryptor1 <= '0';
						decrypt_data_part2 <= decrypted_data1;
					end if;
				end if;

				if (stage = 16) then
					decrypter_reset <= '1';
					enable_encryption <= '1';
					encrypter_inp <= ACK1;
					if (done_encrypt = '1') then
						stage <= 17;
						-- led_out <= "00010001";
					end if;	
				end if;

				-- Send ACK after encryption back to host
				if (stage = 17) then
					enable_encryption <= '0';
					decrypter_reset <= '0';
					if (cntr = 0) then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							f2hData_out2 <= encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 18;
							-- led_out <= "00010010";				
						end if;
					end if;
				end if;

-- READING ACK2

				if (stage = 18) then
					if(second_counter < 256) then
						if(timer > 0) then
							if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then
								encrypter_reset <= '1';	
								encrypted_data1(31 downto 24) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
								encrypter_reset <= '0';						
								encrypted_data1(23 downto 16) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 2) then	
								encrypted_data1(15 downto 8) <= h2fData_in;
								cntrdecrypt <= cntrdecrypt + 1;
							elsif (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 3) then	
								encrypted_data1(7 downto 0) <= h2fData_in;
								cntrdecrypt <= 0;
								stage <= 19;
								-- led_out <= "00010011";
								enable_decryptor1 <= '1';
							else
								timer <= timer - 1;
							end if;
						else
							timer <= TIMER_COUNT;
							second_counter <= second_counter + 1;
						end if;
					else
						second_counter <= 0;
						stage <= 0;
					end if;
				end if;

				if (stage = 19) then
					if ( done_decrypt = '1' and decrypted_data1 = ACK2) then
						stage <= 20;
						-- led_out <= "00010100";
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
						timer <= TIMER_COUNT;
						second_counter <= 0;
					elsif ( done_decrypt = '1') then
						stage <= 18;
					end if;
				end if;

				if(stage = 20) then 
					train_direction <= sw_in;
					stage <= 21;
					timer <= 0;
				end if;

				if (stage = 21) then
					if(timer < 3*TIMER_COUNT) then 
					timer <= timer+1;
						if( decrypt_data_part1(31) = '0' or uart_data_part1(30) = '0' or decrypt_data_part1(30)='0') then
							led_out <= "00000001";
						end if;	 
						if( decrypt_data_part1(31) = '1' and uart_data_part1(30) = '1' and decrypt_data_part1(30)='1') then
							if(train_direction(0) = '0') then -- no incoming hence red
								led_out<="00000001";
							else 
								if(train_direction(4) = '0') then
									if(not(decrypt_data_part1(26 downto 24) = "001") or not(uart_data_part1(26 downto 24) = "001")) then 
										led_out<="00000100";
									else 
										led_out<="00000010";
									end if;	
								else  
									led_out <= "00000001"; -- red signal
 								end if;
							end if;	
						end if;			
					elsif(timer < 6*TIMER_COUNT) then 
					timer <= timer+1;
						if( decrypt_data_part1(23) = '0' or decrypt_data_part1(22) = '0' or uart_data_part1(22) = '0') then
							led_out <= "00100001";
						end if;	
						if( decrypt_data_part1(23) = '1' and decrypt_data_part1(22) = '1' and decrypt_data_part1(22)='1') then
							if(train_direction(1) = '0') then 
								led_out<="00100001";
							else 
								if(train_direction(5) = '0') then
									if(not(decrypt_data_part1(18 downto 16) = "001") or not(uart_data_part1(18 downto 16) = "001")) then
										led_out<="00100100";
									else 
										led_out<="00100010";
									end if; 
								else 
									led_out <= "00100001";
								end if;
							end if;	
						end if;						
					elsif(timer < 9*TIMER_COUNT) then
					timer <= timer+1;
						if( decrypt_data_part1(15) = '0' or decrypt_data_part1(14) = '0' or uart_data_part1(14) = '0') then
							led_out <= "01000001";
						end if;	 
						if( decrypt_data_part1(15) = '1' and decrypt_data_part1(14) = '1' and uart_data_part1(15)='1') then
							if(train_direction(2) = '0') then 
								led_out<="01000001";
							else 
								if(train_direction(6) = '0') then
									if(not(decrypt_data_part1(10 downto 8) = "001") or not(uart_data_part1(10 downto 8) = "001")) then
										led_out<="01000100"; -- greennnnnnn
									else
										led_out<="01000010"; --------amber
									end if;	
								else 
									led_out <= "01000001";								
								end if;
							end if;	
						end if; 
					elsif(timer < 12*TIMER_COUNT) then 
					timer <= timer+1;
						if( decrypt_data_part1(7) = '0' or decrypt_data_part1(6) = '0' or uart_data_part1(6)='0') then
							led_out <= "01100001";
						end if;	
						if( decrypt_data_part1(7) = '1' and decrypt_data_part1(6) = '1' and uart_data_part1(6)='1') then
							if(train_direction(3) = '0') then -- noincoming
								led_out<="01100001"; 
							else 
								if(train_direction(7) = '0') then
									if(not(decrypt_data_part1(2 downto 0) = "001") or not(uart_data_part1(2 downto 0) = "001")) then
										led_out <="01100100"; --green 
									else 
										led_out <="01100010"; --amber
									end if;	
								else 
									led_out <= "01100001"; --red
								end if;
							end if;	
						end if;
					elsif(timer < 15*TIMER_COUNT) then
					timer <= timer+1;
						if( decrypt_data_part2(31) = '0' or decrypt_data_part2(30) = '0' or uart_data_part2(30)='0') then
							led_out <= "10000001"; --redddddddddddddddddd
						end if;	 
						if( decrypt_data_part2(31) = '1' and decrypt_data_part2(30) = '1') then
							if(train_direction(4) = '0') then 
								led_out<="10000001"; -- red no train here
							else 
								if(train_direction(0) = '0') then
									if(not(decrypt_data_part2(26 downto 24) = "001") or not(uart_data_part2(26 downto 24) = "001")) then 
									led_out<="10000100"; -- green
									else 
									led_out <="10000010"; -- amber
									end if;
								else 
									if(timer<13*TIMER_COUNT) then 
										led_out <= "10000100";
									elsif(timer < 14*TIMER_COUNT) then 
										led_out <= "10000010";
									else 
										led_out <= "10000001";
									end if;	
								end if;		
							end if;	
						end if;
					elsif(timer < 18*TIMER_COUNT) then 
					timer <= timer+1;
						if( decrypt_data_part2(23) = '0' or decrypt_data_part2(22) = '0' or uart_data_part2(22)='0') then
							led_out <= "10100001";
						end if;	
						if( decrypt_data_part2(23) = '1' and decrypt_data_part2(22) = '1') then
							if(train_direction(5) = '0') then 
								led_out<="10100001";
							else 
								if(train_direction(1) = '0') then
									if(not(decrypt_data_part2(18 downto 16) = "001") or not(uart_data_part2(18 downto 16) = "001")) then 
									led_out<="10100100"; -- green
									else 
									led_out<="10100010"; -- amber
									end if;
								else 
									if(timer<16*TIMER_COUNT) then 
										led_out <= "10100100";
									elsif(timer < 17*TIMER_COUNT) then 
										led_out <= "10100010";
									else 
										led_out <= "10100001";
									end if;	
								end if;		
							end if;	
						end if;	
					elsif(timer < 21*TIMER_COUNT) then 
					timer <= timer+1;
						if( decrypt_data_part2(15) = '0' or decrypt_data_part2(14) = '0' or uart_data_part2(14)='0') then
							led_out <= "11000001";
						end if;	
						if( decrypt_data_part2(15) = '1' and decrypt_data_part2(14) = '1') then
							if(train_direction(6) = '0') then 
								led_out<="11000001";
							else 
								if(train_direction(2) = '0') then
									if(not(decrypt_data_part2(10 downto 8) = "001") or not(uart_data_part2(10 downto 8) = "001")) then 
									led_out<="11000100"; -- green
									else 
									led_out <="11000010"; -- amber
									end if;
								else 
									if(timer<19*TIMER_COUNT) then 
										led_out <= "11000100";
									elsif(timer < 20*TIMER_COUNT) then 
										led_out <= "11000010";
									else 
										led_out <= "11000001";
									end if;	
								end if;		
							end if;	
						end if;	
					elsif(timer < 24*TIMER_COUNT) then
					timer <= timer+1;
						if( decrypt_data_part2(7) = '0' or decrypt_data_part2(6) = '0' or uart_data_part2(6)='0') then
							led_out <= "11100001";
						end if;	 
						if( decrypt_data_part2(7) = '1' and decrypt_data_part2(6) = '1') then
							if(train_direction(7) = '0') then 
								led_out<="11100001";
							else 
								if(train_direction(3) = '0') then
									if(not(decrypt_data_part2(2 downto 0) = "001") or not(uart_data_part2(2 downto 0) = "001")) then 
									led_out<="11100100"; -- green
									else 
									led_out <="11100010"; -- amber
									end if;
								else 
									if(timer<22*TIMER_COUNT) then 
										led_out <= "11100100";
									elsif(timer < 23*TIMER_COUNT) then 
										led_out <= "11100010";
									else 
										led_out <= "11100001";
									end if;	
								end if;		
							end if;	
						end if;					
					elsif(timer < 32*TIMER_COUNT) then
					-- now is the time to send to microState S3 which in our case will be stage 30 
					stage <= 30;
					timer <= 0;
					led_out <= "00000000";
					end if;
				end if;


				if (stage = 30) then
					encrypter_reset <= '0';
					if(upsignal = '0') then

						enable_encryption <= '1';
						encrypter_inp <= NotWannaSent;
						if(done_encrypt = '1') then
							stage <= 31;
						end if;
					else
						enable_encryption <= '1';
						encrypter_inp <= WannaSent;
						if(done_encrypt = '1') then
							stage <= 32;
						end if;
					end if;
				end if;
				if (stage = 31) then
					enable_encryption <= '0';
					if (cntr = 0) then
						--if (chanAddr_in = my_channel_out  and f2hReady_in = '1') then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
						--end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 40;
							encrypter_reset <= '1';				
						end if;
					end if;
				end if;
				if (stage = 32) then
					enable_encryption <= '0';
					if (cntr = 0) then
						--if (chanAddr_in = my_channel_out  and f2hReady_in = '1') then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
						--end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 33;
							led_out <= "11111111"; --waiting for downSignal to be one
							encrypter_reset <= '1';				
						end if;
					end if;
				end if;

				if (stage = 404) then
					encrypter_inp <= "00000001001000110000000100100011";
					enable_encryption <= '1';
					if(done_encrypt = '1') then
						stage <= 405;
					end if;
				end if;

				if (stage = 405) then
					enable_encryption <= '0';
					if (cntr = 0) then
					f2hData_out2 <=	encrypter_out(31 downto 24);
					f2hValid_out2 <= '1';
					cntr <= 1;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 406;
							encrypter_reset <= '1';				
						end if;
					end if;
				end if ;

				if (stage = 406) then
					encrypter_reset <= '0';
					if(downsignal = '1') then
						encrypter_inp <= sw_in & sw_in & sw_in & sw_in;
						enable_encryption <= '1';
						if (done_encrypt = '1') then
							stage <= 34;
							led_out <= "00100011";
						end if;
					end if;
				end if ;


				if (stage = 33) then
					encrypter_reset <= '0';
					f2hValid_out2 <= '0';
					if (cntr < 60 * TIMER_COUNT) then
						if(downsignal = '1') then
							encrypter_inp <= sw_in & sw_in & sw_in & sw_in;
							enable_encryption <= '1';
							if (done_encrypt = '1') then
								stage <= 34;
								cntr <= 0;
								led_out <= "00100010";
							end if;
						else
							cntr <= cntr + 1;
						end if;
					else
						stage <= 404;
						cntr <= 0;
					end if;
				end if;




				if (stage = 34) then
					enable_encryption <= '0';
					if (cntr = 0) then
						--if (chanAddr_in = my_channel_out  and f2hReady_in = '1') then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
						f2hValid_out2 <= '1';
							cntr <= 1;
						led_out <= "00001111";
						--end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						led_out <= "00001110";
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out and f2hReady_in = '1') then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 40;
							encrypter_reset <= '1';
							led_out <= "00001100";				
						end if;
					end if;
				end if;
				if(stage = 40) then
					encrypter_reset <= '0';
					if (leftsignal = '0') then
						stage <= 50;
					else
						stage <= 41;
						--led_out <= "00101000";
					end if;
				end if;

				if (stage = 41) then
					if (rightsignal = '1') then
						uart_tx_data <= sw_in;
						stage <= 42; 
					end if ;
				end if ;


				if (stage = 42) then
					if uart_tx_ready = '1' then
						uart_tx_enable <= '1';
						stage <= 43;
					end if ;
				end if ;

				if (stage = 43) then
					if uart_tx_ready = '0' then
						uart_tx_enable <= '0';
						stage <= 50;
					end if;
				end if ;
				if (uart_rx_enable = '1') then
					uart_buffer <= uart_rx_data;
				end if;

				if (stage = 50) then
					led_out <= uart_buffer;
					stage <= 51;
				end if ;

				if (stage = 52) then
					if(timer < 10 * TIMER_COUNT) then
						timer <= timer + 1;
					else
						stage <= 0;
						timer <= 0;--15*TIMER_COUNT; --CHANGE
					end if;
				end if ;

				if (stage = 51) then
					if (uart_buffer(7 downto 5) = "000") then
						uart_data_part1(31) <=  uart_buffer(4);
						uart_data_part1(30) <= uart_buffer(3);
						uart_data_part1(26 downto 24) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "001") then
						uart_data_part1(23) <=  uart_buffer(4);
						uart_data_part1(22) <= uart_buffer(3);
						uart_data_part1(18 downto 16) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "010") then
						uart_data_part1(15) <=  uart_buffer(4);
						uart_data_part1(14) <= uart_buffer(3);
						uart_data_part1(10 downto 8) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "011") then
						uart_data_part1(7) <=  uart_buffer(4);
						uart_data_part1(6) <= uart_buffer(3);
						uart_data_part1(2 downto 0) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "100") then
						uart_data_part2(31) <=  uart_buffer(4);
						uart_data_part2(30) <= uart_buffer(3);
						uart_data_part2(26 downto 24) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "101") then
						uart_data_part2(23) <=  uart_buffer(4);
						uart_data_part2(22) <= uart_buffer(3);
						uart_data_part2(18 downto 16) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "110") then
						uart_data_part2(15) <=  uart_buffer(4);
						uart_data_part2(14) <= uart_buffer(3);
						uart_data_part2(10 downto 8) <= uart_buffer(2 downto 0);
					end if;
					if (uart_buffer(7 downto 5) = "111") then
						uart_data_part2(7) <=  uart_buffer(4);
						uart_data_part2(6) <= uart_buffer(3);
						uart_data_part2(2 downto 0) <= uart_buffer(2 downto 0);
					end if;
					stage <= 52;
				end if ;
			end if;
		end if;
	end process;


with chanAddr_in select f2hData_out <=
		f2hData_out2       when my_channel_out,
		x"00" when others;


		decrypt1 : entity work.decrypter
		port map(
		   clock => clk_in,
           K => key,
           C => encrypted_data1,
           P => decrypted_data1,
           done => done_decrypt,
           reset => decrypter_reset,
           enable => enable_decryptor1
		);
		encypt1 : entity work.encrypter
		port map(
			clock => clk_in,
			K => key,
			P => encrypter_inp,
			C => encrypter_out,
			done =>  done_encrypt,
            reset => encrypter_reset,
            enable => enable_encryption
			);
		my_uart : entity work.basic_uart
		generic map (DIVISOR => 1250)
		port map(
    clk => clk_in, -- replace
    reset => reset_in,
    rx_data => uart_rx_data,
    rx_enable => uart_rx_enable,
    tx_data => uart_tx_data, 
    tx_enable => uart_tx_enable, 
    tx_ready => uart_tx_ready,
    rx => uart_rx,
    tx => uart_tx
			);


	h2fReady_out <= '1';

	with chanAddr_in select f2hValid_out <=
		f2hValid_out2       when my_channel_out,
		'1' when others;

	-- LEDs and 7-seg display
	--led_out <= data(7 downto 0);   -- lighting should be done in a period of 1 sec in cyclic fashion
	--flags <= "00" & f2hReady_in & reset_in;
	--seven_seg : entity work.seven_seg
	--	port map(
	--		clk_in     => clk_in,
	--		data_in    => decrypt_data_part1(15 downto 0),
	--		dots_in    => flags,
	--		segs_out   => sseg_out,
	--		anodes_out => anode_out
	--	);
end architecture;
-- Compile VHDL
-- sudo "PATH=$PATH" python2 ../../../../../bin/hdlmake.py -t ../../templates/fx2all/vhdl -b atlys -p fpga
-- RUN
-- sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 --custom track_data.csv
-- I enumerate -p PROg
-- sudo "PATH=$PATH" ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -i 1443:0007
-- sudo "PATH=$PATH" ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -p J:D0D2D3D4:fpga.xsvf

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
--

-- channel 0 read and write 0000 on channel 0
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of swled is
	-- Flags for display on the 7-seg decimal points
	signal flags : std_logic_vector(3 downto 0);

	-- Registers implementing the channels 
	constant curr_coordinate : std_logic_vector(31 downto 0) := "00100011001000110010001100100011";
	constant my_channel_in : std_logic_vector(6 downto 0) := "0000101";
	constant my_channel_out : std_logic_vector(6 downto 0) := "0000100";
	constant ACK1: std_logic_vector(31 downto 0) := "11111111111111111111111111111111";
	constant ACK2: std_logic_vector(31 downto 0) := "10101010101010101010101010101010";
	signal data : std_logic_vector(63 downto 0)  := "0000010000100100010001000110010010000100101001001100010011100100";

	--signal data_next : std_logic_vector(7 downto 0) := (others => '0');
	signal stage : integer := 0;
	
	signal encrypted_data1: std_logic_vector(31 downto 0) := (others => '0');
	signal encrypted_data2: std_logic_vector(31 downto 0) := (others => '0');
	
	constant key:  std_logic_vector(31 downto 0) := (others => '1');--"10101111101011111010111111111010";
	
	signal enable_decryptor1 : std_logic := '0';
	signal enable_decryptor2 : std_logic := '0';
	signal done_decrypt : std_logic := '0';
	signal decrypted_data1: std_logic_vector(31 downto 0) := (others => '0');


	signal decrypt_data_part1: std_logic_vector(31 downto 0) := (others => '0');
	signal decrypt_data_part2: std_logic_vector(31 downto 0) := (others => '0');
	
	signal encrypter_inp : std_logic_vector(31 downto 0) := (others => '0');
	signal enable_encryption : std_logic := '0';
	signal encrypter_out : std_logic_vector(31 downto 0) := (others => '1');
	signal done_encrypt : std_logic := '0';

	constant TIMER_COUNT : integer :=  48000000;--value
	signal timer : integer := TIMER_COUNT;
	signal cntr : integer := 0;
	signal cntrdecrypt: integer := 0; -- This will count from 0 to 15 and at each count add recieved data to encrypted_data_signal
	signal decrypter_reset : std_logic := '0';
	signal encrypter_reset : std_logic := '0';

	signal f2hData_out2 :std_logic_vector(7 downto 0) := (others => '0');
begin                                                                     
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				data <= "1000000010000001100000101000001110000100100001011000011010000111";
				decrypter_reset <= '0';
				--curr_coordinate <= "00100011";
			else
				--curr_coordinate <= "00100011";
				if ( stage = 0) then
					-- f2hValid_out <= '0';
					enable_encryption <= '1';
					encrypter_inp <= curr_coordinate;
					if (done_encrypt = '1') then
						stage <= 1;
						led_out <= encrypter_out(31 downto 24);
					end if;
				end if;
-- sending message
				if (stage = 1) then
					enable_encryption <= '0';
					if (cntr = 0) then
						if (chanAddr_in = my_channel_out) then
							f2hData_out2 <=
						encrypter_out(31 downto 24);
							cntr <= 1;
						end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out) then
					f2hData_out2 <=
						encrypter_out(23 downto 16);
							cntr <= 2;
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out) then
					f2hData_out2 <=
						encrypter_out(15 downto 8);
							cntr <= 3;
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out) then
					f2hData_out2 <=
						encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 2;
							led_out <= "00000010";			
						end if;
					end if;
				end if;

				if (stage = 2) then
					---- f2hValid_out <= '0';
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then
						encrypter_reset <= '1';	
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypter_reset <= '0';						
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
						stage <= 3;
						led_out <= "00000011";
						enable_decryptor1 <= '1';
					end if;
				end if;

				if (stage = 3) then
					if ( done_decrypt = '1' and decrypted_data1 = curr_coordinate) then
						stage <= 4; -- NEED TO DECIDE FOR ELSE
						led_out <= "00000100";
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
					else
						led_out <= decrypted_data1(31 downto 24);
					end if;
				end if;

				if (stage = 4) then
					decrypter_reset <= '0';
					enable_encryption <= '1';
					encrypter_inp <= ACK1;
					if (done_encrypt = '1') then
						stage <= 5;
					end if;
				end if;

				if (stage = 5) then
					enable_encryption <= '0';
					if (cntr = 0) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(31 downto 24);
							cntr <= 1;
						--else LET THERE NO NEED TO WRITE ON OTHER CHANNELS
						--	-- f2hValid_out <= '1';
						--	f2hData_out2 <= "00000000";
						end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(23 downto 16);
							cntr <= 2;				
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(15 downto 8);
							cntr <= 3;				
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 6;				
						end if;
					end if;
				end if;

				if (stage = 6) then
					-- f2hValid_out <= '0';
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then	
						encrypter_reset <= '1';
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypter_reset <= '0';						
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
						stage <= 7;
						enable_decryptor1 <= '1';
					end if;
				end if;

				if (stage = 7) then
					if ( done_decrypt = '1' and decrypted_data1 = ACK2) then
						stage <= 8; -- NEED TO DECIDE FOR ELSE
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
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
						enable_decryptor1 <= '1';
					end if;
				end if;
				if (stage = 9) then
					if ( done_decrypt = '1') then
						stage <= 10; -- We have part 1 of data
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
					end if;	
				end if;


				-- Send ACK after encryption back to host
				if (stage = 11) then
					enable_encryption <= '0';
					decrypter_reset <= '0';
					if (cntr = 0) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(31 downto 24);
							cntr <= 1;
						end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(23 downto 16);
							cntr <= 2;				
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(15 downto 8);
							cntr <= 3;				
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 12;				
						end if;
					end if;
				end if;

-- READING ACK2

				if (stage = 12) then
					-- f2hValid_out <= '0';
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then	
						encrypter_reset <= '1';
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypter_reset <= '0';						
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
						stage <= 13;
						enable_decryptor1 <= '1';
					end if;
				end if;

				if (stage = 13) then
					if ( done_decrypt = '1' and decrypted_data1 = ACK2) then
						stage <= 14; -- NEED TO DECIDE FOR ELSE
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
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
						enable_decryptor1 <= '1';
					end if;
				end if;
				if (stage = 15) then
					if ( done_decrypt = '1') then
						stage <= 16; -- We have part 1 of data
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
					end if;	
				end if;

				-- Send ACK after encryption back to host
				if (stage = 17) then
					enable_encryption <= '0';
					decrypter_reset <= '0';
					if (cntr = 0) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(31 downto 24);
							cntr <= 1;
						end if;
					end if;
					if (cntr = 1) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(23 downto 16);
							cntr <= 2;				
						end if;
					end if;
					if (cntr = 2) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(15 downto 8);
							cntr <= 3;				
						end if;
					end if;
					if (cntr = 3) then
						if (chanAddr_in = my_channel_out) then
							-- f2hValid_out <= '1';
							f2hData_out2 <= encrypter_out(7 downto 0);
							cntr <= 0;
							stage <= 18;				
						end if;
					end if;
				end if;

-- READING ACK2

				if (stage = 18) then
					-- f2hValid_out <= '0';
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 0) then	
						encrypter_reset <= '1';
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = my_channel_in and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypter_reset <= '0';						
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
						stage <= 19;
						enable_decryptor1 <= '1';
					end if;
				end if;

				if (stage = 19) then
					if ( done_decrypt = '1' and decrypted_data1 = ACK2) then
						stage <= 20;
						enable_decryptor1 <= '0';
						decrypter_reset <= '1';
					end if;
				end if;

				if (stage = 20) then
				decrypter_reset <= '0';
						if ( decrypt_data_part1(31) = '1' and decrypt_data_part1(30) = '1') then
							if ( decrypt_data_part1(26 downto 24) = "000" or decrypt_data_part1(26 downto 24) = "001") then
								data(63 downto 56) <= decrypt_data_part1(29 downto 27) & "00" & "010";
							else
								data(63 downto 56) <= decrypt_data_part1(29 downto 27) & "00" & "100";
							end if;
						else
							data(63 downto 56) <= decrypt_data_part1(29 downto 27) & "00" & "001";
						end if;

						if ( decrypt_data_part1(23) = '1' and decrypt_data_part1(22) = '1') then
							if ( decrypt_data_part1(18 downto 16) = "000" or decrypt_data_part1(18 downto 16) = "001") then
								data(55 downto 48) <= decrypt_data_part1(21 downto 19) & "00" & "010";
							else
								data(55 downto 48) <= decrypt_data_part1(21 downto 19) & "00" & "100";
							end if;
						else
							data(55 downto 48) <= decrypt_data_part1(21 downto 19) & "00" & "001";
						end if;

						if ( decrypt_data_part1(15) = '1' and decrypt_data_part1(14) = '1') then
							if ( decrypt_data_part1(10 downto 8) = "000" or decrypt_data_part1(10 downto 8) = "001") then
								data(47 downto 40) <= decrypt_data_part1(13 downto 11) & "00" & "010";
							else
								data(47 downto 40) <= decrypt_data_part1(13 downto 11) & "00" & "100";
							end if;
						else
							data(47 downto 40) <= decrypt_data_part1(13 downto 11) & "00" & "001";
						end if;
						if ( decrypt_data_part1(7) = '1' and decrypt_data_part1(6) = '1') then
							if ( decrypt_data_part1(2 downto 0) = "000" or decrypt_data_part1(2 downto 0) = "001") then
								data(39 downto 32) <= decrypt_data_part1(5 downto 3) & "00" & "010";
							else
								data(39 downto 32) <= decrypt_data_part1(5 downto 3) & "00" & "100";
							end if;
						else
							data(39 downto 32) <= decrypt_data_part1(5 downto 3) & "00" & "001";
						end if;




						if ( decrypt_data_part2(31) = '1' and decrypt_data_part2(30) = '1') then
							if ( decrypt_data_part2(26 downto 24) = "000" or decrypt_data_part2(26 downto 24) = "001") then
								data(31 downto 24) <= decrypt_data_part2(29 downto 27) & "00" & "010";
							else
								data(31 downto 24) <= decrypt_data_part2(29 downto 27) & "00" & "100";
							end if;
						else
							data(31 downto 24) <= decrypt_data_part2(29 downto 27) & "00" & "001";
						end if;

						if ( decrypt_data_part2(23) = '1' and decrypt_data_part2(22) = '1') then
							if ( decrypt_data_part2(18 downto 16) = "000" or decrypt_data_part2(18 downto 16) = "001") then
								data(23 downto 16) <= decrypt_data_part2(21 downto 19) & "00" & "010";
							else
								data(23 downto 16) <= decrypt_data_part2(21 downto 19) & "00" & "100";
							end if;
						else
							data(23 downto 16) <= decrypt_data_part2(21 downto 19) & "00" & "001";
						end if;

						if ( decrypt_data_part2(15) = '1' and decrypt_data_part2(14) = '1') then
							if ( decrypt_data_part2(10 downto 8) = "000" or decrypt_data_part2(10 downto 8) = "001") then
								data(15 downto 8) <= decrypt_data_part2(13 downto 11) & "00" & "010";
							else
								data(15 downto 8) <= decrypt_data_part2(13 downto 11) & "00" & "100";
							end if;
						else
							data(15 downto 8) <= decrypt_data_part2(13 downto 11) & "00" & "001";
						end if;
						if ( decrypt_data_part2(7) = '1' and decrypt_data_part2(6) = '1') then
							if ( decrypt_data_part2(2 downto 0) = "000" or decrypt_data_part2(2 downto 0) = "001") then
								data(7 downto 0) <= decrypt_data_part2(5 downto 3) & "00" & "010";
							else
								data(7 downto 0) <= decrypt_data_part2(5 downto 3) & "00" & "100";
							end if;
						else
							data(7 downto 0) <= decrypt_data_part2(5 downto 3) & "00" & "001";
						end if;

						stage <= 21;
				end if;
				-- needs a check
				if ( stage = 21) then
					if ( timer = 0) then
						if ( cntr < 24) then -- 24 sec wait out of which 8 sec is display 
							if ( cntr = 0) then
								led_out <= data(63 downto 56);
							elsif ( cntr = 1) then
								led_out <= data(55 downto 48);
							elsif ( cntr = 2) then
								led_out <= data(47 downto 40);
							elsif ( cntr = 3) then
								led_out <= data(39 downto 32);
							elsif ( cntr = 4) then
								led_out <= data(31 downto 24);
							elsif ( cntr = 5) then
								led_out <= data(23 downto 16);
							elsif ( cntr = 6) then
								led_out <= data(15 downto 8);
							elsif ( cntr = 7) then
								led_out <= data(7 downto 0);
							end if;
							cntr <= cntr + 1;
							timer <= TIMER_COUNT;
						else
							cntr <= 0;
							stage <= 0;
							--f2hData_out2 <= curr_coordinate;
						end if;
					else
						timer <= timer -1;
					end if;
				end if;
			end if;
		end if;
	end process;

with chanAddr_in select f2hData_out <=
		f2hData_out2       when my_channel_out,
		x"11" when others;


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


	h2fReady_out <= '1';
	f2hValid_out <= '1';
	-- LEDs and 7-seg display
	--led_out <= data(7 downto 0);   -- lighting should be done in a period of 1 sec in cyclic fashion
	flags <= "00" & f2hReady_in & reset_in;
	seven_seg : entity work.seven_seg
		port map(
			clk_in     => clk_in,
			data_in    => data(15 downto 0),
			dots_in    => flags,
			segs_out   => sseg_out,
			anodes_out => anode_out
		);
end architecture;

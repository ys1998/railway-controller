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
	constant curr_coordinate : std_logic_vector(7 downto 0) := "00100011";
	signal data : std_logic_vector(63 downto 0)  := "0000010000100100010001000110010010000100101001001100010011100100";

	--signal data_next : std_logic_vector(7 downto 0) := (others => '0');
	signal stage : std_logic := '0';
	signal encrypted_data1: std_logic_vector(31 downto 0) := (others => '0');
	signal encrypted_data2: std_logic_vector(31 downto 0) := (others => '0');
	signal key:  std_logic_vector(31 downto 0) := (others => '1');
	signal enable_decryptor1 : std_logic := '0';
	signal enable_decryptor2 : std_logic := '0';
	signal done_decrypt : std_logic := '0';
	signal decrypted_data1: std_logic_vector(31 downto 0) := (others => '0');
	signal decrypted_data2: std_logic_vector(31 downto 0) := (others => '0');

	constant TIMER_COUNT : integer :=  48000000;--value
	signal timer : integer := TIMER_COUNT;
	signal cntr : integer := 0;
	signal cntrdecrypt: integer := 0; -- This will count from 0 to 15 and at each count add recieved data to encrypted_data_signal
	signal decrypter_reset : std_logic := '0';
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
				if ( stage = '0') then
				-- 8 cycles run NEED A COUNTER 
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 0) then	
						encrypted_data1(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 1) then	
						encrypted_data1(23 downto 16) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;					
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 2) then	
						encrypted_data1(15 downto 8) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;					
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 3) then	
						encrypted_data1(7 downto 0) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 4) then	
						encrypted_data2(31 downto 24) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 5) then	
						encrypted_data2(23 downto 16) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 6) then	
						encrypted_data2(15 downto 8) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
					end if;
					if (chanAddr_in = "0000000" and h2fValid_in = '1' and cntrdecrypt = 7) then	
						encrypted_data2(7 downto 0) <= h2fData_in;
						cntrdecrypt <= cntrdecrypt + 1;
						enable_decryptor1 <= '1';
					end if;

-- Only after done_decrypt is 1 then do parts below it
					--f2hData_out <= "00000000";
					if (done_decrypt = '1') then
						if ( decrypted_data1(31) = '1' and decrypted_data1(30) = '1') then
							if ( decrypted_data1(26 downto 24) = "000" or decrypted_data1(26 downto 24) = "001") then
								data(63 downto 56) <= decrypted_data1(29 downto 27) & "00" & "010";
							else
								data(63 downto 56) <= decrypted_data1(29 downto 27) & "00" & "100";
							end if;
						else
							data(63 downto 56) <= decrypted_data1(29 downto 27) & "00" & "001";
						end if;

						if ( decrypted_data1(23) = '1' and decrypted_data1(22) = '1') then
							if ( decrypted_data1(18 downto 16) = "000" or decrypted_data1(18 downto 16) = "001") then
								data(55 downto 48) <= decrypted_data1(21 downto 19) & "00" & "010";
							else
								data(55 downto 48) <= decrypted_data1(21 downto 19) & "00" & "100";
							end if;
						else
							data(55 downto 48) <= decrypted_data1(21 downto 19) & "00" & "001";
						end if;

						if ( decrypted_data1(15) = '1' and decrypted_data1(14) = '1') then
							if ( decrypted_data1(10 downto 8) = "000" or decrypted_data1(10 downto 8) = "001") then
								data(47 downto 40) <= decrypted_data1(13 downto 11) & "00" & "010";
							else
								data(47 downto 40) <= decrypted_data1(13 downto 11) & "00" & "100";
							end if;
						else
							data(47 downto 40) <= decrypted_data1(13 downto 11) & "00" & "001";
						end if;
						if ( decrypted_data1(7) = '1' and decrypted_data1(6) = '1') then
							if ( decrypted_data1(2 downto 0) = "000" or decrypted_data1(2 downto 0) = "001") then
								data(39 downto 32) <= decrypted_data1(5 downto 3) & "00" & "010";
							else
								data(39 downto 32) <= decrypted_data1(5 downto 3) & "00" & "100";
							end if;
						else
							data(39 downto 32) <= decrypted_data1(5 downto 3) & "00" & "001";
						end if;




						if ( decrypted_data2(31) = '1' and decrypted_data2(30) = '1') then
							if ( decrypted_data2(26 downto 24) = "000" or decrypted_data2(26 downto 24) = "001") then
								data(31 downto 24) <= decrypted_data2(29 downto 27) & "00" & "010";
							else
								data(31 downto 24) <= decrypted_data2(29 downto 27) & "00" & "100";
							end if;
						else
							data(31 downto 24) <= decrypted_data2(29 downto 27) & "00" & "001";
						end if;

						if ( decrypted_data2(23) = '1' and decrypted_data2(22) = '1') then
							if ( decrypted_data2(18 downto 16) = "000" or decrypted_data2(18 downto 16) = "001") then
								data(23 downto 16) <= decrypted_data2(21 downto 19) & "00" & "010";
							else
								data(23 downto 16) <= decrypted_data2(21 downto 19) & "00" & "100";
							end if;
						else
							data(23 downto 16) <= decrypted_data2(21 downto 19) & "00" & "001";
						end if;

						if ( decrypted_data2(15) = '1' and decrypted_data2(14) = '1') then
							if ( decrypted_data2(10 downto 8) = "000" or decrypted_data2(10 downto 8) = "001") then
								data(15 downto 8) <= decrypted_data2(13 downto 11) & "00" & "010";
							else
								data(15 downto 8) <= decrypted_data2(13 downto 11) & "00" & "100";
							end if;
						else
							data(15 downto 8) <= decrypted_data2(13 downto 11) & "00" & "001";
						end if;
						if ( decrypted_data2(7) = '1' and decrypted_data2(6) = '1') then
							if ( decrypted_data2(2 downto 0) = "000" or decrypted_data2(2 downto 0) = "001") then
								data(7 downto 0) <= decrypted_data2(5 downto 3) & "00" & "010";
							else
								data(7 downto 0) <= decrypted_data2(5 downto 3) & "00" & "100";
							end if;
						else
							data(7 downto 0) <= decrypted_data2(5 downto 3) & "00" & "001";
						end if;

						stage <= '1';
						enable_decryptor1 <= '0';
						cntrdecrypt <= 0;
						decrypter_reset <= '1';

					end if;
				else
					decrypter_reset <= '0';
					if ( timer = 0) then
						if ( cntr < 16) then
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
							stage <= '0';
							--f2hData_out <= curr_coordinate;
						end if;
					else
						timer <= timer -1;
					end if;
				end if;
			end if;
		end if;
	end process;

		decrypt1 : entity work.decrypter
		port map(
		   clock => clk_in,
           K => key,
           C => encrypted_data1,
           P => decrypted_data1,
           done => enable_decryptor2,
           reset => decrypter_reset,
           enable => enable_decryptor1
		);

		decrypt2 : entity work.decrypter
		port map(
		   clock => clk_in,
           K => key,
           C => encrypted_data2,
           P => decrypted_data2,
           done => done_decrypt,
           reset => decrypter_reset,
           enable => enable_decryptor2
		);

	-- Drive register inputs for each channel when the host is writing H2FVALID =1 once every 16 sec


	-- Select values to return for each channel when the host is reading
	with chanAddr_in select f2hData_out <=
		curr_coordinate       when "0000000",
		x"00" when others;

	-- Assert that there's always data for reading, and always room for writing
	f2hValid_out <= '1';
	h2fReady_out <= '1';                                                     --END_SNIPPET(registers)

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

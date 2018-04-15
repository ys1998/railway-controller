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
	signal curr_coordinate : std_logic_vector(7 downto 0) := "00100011";
	signal data         : std_logic_vector(63 downto 0)  := "1000000010000001100000101000001110000100100001011000011010000111";
	signal data_next : std_logic_vector(7 downto 0) := (others => '0');
	signal stage : std_logic := '0';

	constant TIMER_COUNT : integer :=  48000000;--value
	signal timer : integer := TIMER_COUNT;
	signal cntr : integer := 0;

begin                                                                     
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				data <= "1000000010000001100000101000001110000100100001011000011010000111";
				data_next <= "00000000";
				curr_coordinate <= "00100011";
			else
				curr_coordinate <= "00100011";
				if ( stage = '0') then
					if (chanAddr_in = "0000000" and h2fValid_in = '1') then	
						data_next <= h2fData_in;
					end if;
					--f2hData_out <= "00000000";
					if ( data_next(5 downto 3) = "000") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(63 downto 56) <= "010" & "00" & data_next(5 downto 3);
							else
								data(63 downto 56) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(63 downto 56) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "001") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(55 downto 48) <= "010" & "00" & data_next(5 downto 3);
							else
								data(55 downto 48) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(55 downto 48) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "010") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(47 downto 40) <= "010" & "00" & data_next(5 downto 3);
							else
								data(47 downto 40) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(47 downto 40) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "011") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(39 downto 32) <= "010" & "00" & data_next(5 downto 3);
							else
								data(39 downto 32) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(39 downto 32) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "100") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(31 downto 24) <= "010" & "00" & data_next(5 downto 3);
							else
								data(31 downto 24) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(31 downto 24) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "101") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(23 downto 16) <= "010" & "00" & data_next(5 downto 3);
							else
								data(23 downto 16) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(23 downto 16) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "110") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(15 downto 8) <= "010" & "00" & data_next(5 downto 3);
							else
								data(15 downto 8) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(15 downto 8) <= "100" & "00" & data_next(5 downto 3);
						end if;
					elsif ( data_next(5 downto 3) = "111") then
						if ( data_next(7) = '1' and data_next(6) = '1') then
							if ( data_next(2 downto 0) = "000" or data_next(2 downto 0) = "001") then
								data(7 downto 0) <= "010" & "00" & data_next(5 downto 3);
							else
								data(7 downto 0) <= "001" & "00" & data_next(5 downto 3);
							end if;
						else
							data(7 downto 0) <= "100" & "00" & data_next(5 downto 3);
						end if;
						stage <= '1';
						data_next <= "00000000";
					end if;
				else
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

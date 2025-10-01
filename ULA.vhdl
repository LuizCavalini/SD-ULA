library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ULA is
    Port ( 
        A         : in  STD_LOGIC_VECTOR (3 downto 0);
        B         : in  STD_LOGIC_VECTOR (3 downto 0);
        Operation : in  STD_LOGIC_VECTOR (2 downto 0);
        Result    : out STD_LOGIC_VECTOR (3 downto 0);
        zero, negative, carry_out, overflow : out std_logic
    );
end ULA;

architecture Behavioral of ULA is
begin
    process (A, B, Operation)
        variable A_signed, B_signed : signed(3 downto 0);
        -- Use a 5-bit temporary result to easily capture the carry bit
        variable temp_result : signed(4 downto 0);
    begin
        -- Convert inputs to signed type for arithmetic operations
        A_signed := signed(A);
        B_signed := signed(B);

        -- Initialize flags to '0' at the beginning of each execution
        zero <= '0';
        negative <= '0';
        carry_out <= '0';
        overflow <= '0';

        -- Case statement selects the operation based on the 'Operation' input
        case Operation is
            when "000" => -- Addition: A + B
                temp_result := resize(A_signed, 5) + resize(B_signed, 5);
                -- Carry out is the 5th bit of the result
                carry_out <= temp_result(4);
                -- Overflow detection for addition: occurs if signs of operands are the same
                -- but different from the sign of the result.
                overflow <= (A_signed(3) xnor B_signed(3)) and (A_signed(3) xor temp_result(3));

            when "001" => -- Subtraction: A - B
                temp_result := resize(A_signed, 5) - resize(B_signed, 5);
                -- Carry out for subtraction is inverted (borrow flag)
                carry_out <= not temp_result(4);
                -- Overflow detection for subtraction: occurs if signs of operands are different
                -- and the result's sign is different from A's sign.
                overflow <= (A_signed(3) xor B_signed(3)) and (A_signed(3) xor temp_result(3));

            when "010" => -- Bitwise AND
                -- No arithmetic flags are set for logical operations
                temp_result := resize(A_signed and B_signed, 5);

            when "011" => -- Bitwise OR
                temp_result := resize(A_signed or B_signed, 5);

            when "100" => -- Shift Left Logical on A
                -- Shifts A to the left by one position.
                temp_result := resize(signed(A(2 downto 0) & '0'), 5);
                -- The bit shifted out becomes the carry.
                carry_out <= A(3);

            when "101" => -- Shift Right Logical on A
                -- Shifts A to the right by one position.
                temp_result := resize(signed('0' & A(3 downto 1)), 5);
                -- The bit shifted out becomes the carry.
                carry_out <= A(0);

            when "110" => -- Equality Check: A == B?
                if A = B then
                    temp_result := "00001"; -- Result is 1 if true
                else
                    temp_result := "00000"; -- Result is 0 if false
                end if;

            when "111" => -- Signed Greater Than: A > B?
                if A_signed > B_signed then
                    temp_result := "00001"; -- Result is 1 if true
                else
                    temp_result := "00000"; -- Result is 0 if false
                end if;

            when others => -- Default case
                temp_result := "00000";
        end case;

        -- Set common flags based on the final result
        Result <= std_logic_vector(temp_result(3 downto 0));
        
        -- Zero flag is set if the 4-bit result is all zeros
        if temp_result(3 downto 0) = "0000" then
            zero <= '1';
        end if;
        
        -- Negative flag is the Most Significant Bit (MSB) of the result
        negative <= temp_result(3);

    end process;
end Behavioral;

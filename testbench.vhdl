library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Test_Bench is
    generic (
        DEBOUNCE_LIMIT : integer := 500000
    );
    Port (
        clk        : in  STD_LOGIC; -- Main board clock
        button0    : in  STD_LOGIC; -- Button to advance states ("Enter")
        btnClear   : in  STD_LOGIC; -- NEW: Button to reset the ULA
        switchs    : in  STD_LOGIC_VECTOR (3 downto 0);
        leds       : out STD_LOGIC_VECTOR (7 downto 0);
        leds_state : out STD_LOGIC_VECTOR (1 downto 0)
    );
end entity Test_Bench;

architecture Behavioral of Test_Bench is

    -- State machine signals (WITH WAIT STATES)
    type state_type is (GET_OPERATION, WAIT_OP_RELEASE, GET_A, WAIT_A_RELEASE, GET_B, WAIT_B_RELEASE);
    signal current_state : state_type := GET_OPERATION;

    -- Signals for operands and operation
    signal A, B      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal Operation : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');

    -- ULA signals
    signal Result    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal zero, negative, carry_out, overflow : std_logic := '0';

    -- Signals for button debouncing
    signal debounce_counter       : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal button0_debounced      : std_logic := '0';
    -- NEW SIGNALS FOR THE CLEAR BUTTON
    signal debounce_counter_clear : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal btnClear_debounced     : std_logic := '0';

begin

    -- Instantiation of the ULA (Arithmetic Logic Unit)
    ula_inst : entity work.ula
        port map (
            A         => A,
            B         => B,
            Operation => Operation,
            Result    => Result,
            zero      => zero,
            negative  => negative,
            carry_out => carry_out,
            overflow  => overflow
        );

    -- SYNCHRONOUS process to debounce BOTH buttons
    debounce_process : process (clk)
    begin
        if rising_edge(clk) then
            -- Debouncer logic for button0 (Enter)
            if button0 = '1' then
                if debounce_counter < DEBOUNCE_LIMIT then
                    debounce_counter <= debounce_counter + 1;
                else
                    button0_debounced <= '1';
                end if;
            else
                debounce_counter <= 0;
                button0_debounced <= '0';
            end if;

            -- Debouncer logic for btnClear (Reset)
            if btnClear = '1' then
                if debounce_counter_clear < DEBOUNCE_LIMIT then
                    debounce_counter_clear <= debounce_counter_clear + 1;
                else
                    btnClear_debounced <= '1';
                end if;
            else
                debounce_counter_clear <= 0;
                btnClear_debounced <= '0';
            end if;
        end if;
    end process debounce_process;

    -- State machine process WITH ASYNCHRONOUS RESET
    main_fsm : process (clk, btnClear_debounced) -- Added btnClear_debounced to the sensitivity list
        variable operation_requires_B : std_logic := '0';
    begin
        -- Reset Logic: If btnClear is pressed, zero everything immediately
        if btnClear_debounced = '1' then
            current_state <= GET_OPERATION;
            A <= (others => '0');
            B <= (others => '0');
            Operation <= (others => '0');

        -- Normal logic, only executes on the rising edge of the clock and if clear is not active
        elsif rising_edge(clk) then

            case current_state is
                when GET_OPERATION =>
                    if button0_debounced = '1' then
                        Operation <= switchs(2 downto 0);
                        if switchs(2 downto 0) = "100" or switchs(2 downto 0) = "101" then
                            operation_requires_B := '0';
                        else
                            operation_requires_B := '1';
                        end if;
                        current_state <= WAIT_OP_RELEASE;
                    end if;

                when WAIT_OP_RELEASE =>
                    if button0_debounced = '0' then
                        current_state <= GET_A;
                    end if;

                when GET_A =>
                    if button0_debounced = '1' then
                        A <= switchs;
                        current_state <= WAIT_A_RELEASE;
                    end if;

                when WAIT_A_RELEASE =>
                    if button0_debounced = '0' then
                        if operation_requires_B = '1' then
                            current_state <= GET_B;
                        else
                            current_state <= GET_OPERATION;
                        end if;
                    end if;

                when GET_B =>
                    if button0_debounced = '1' then
                        B <= switchs;
                        current_state <= WAIT_B_RELEASE;
                    end if;

                when WAIT_B_RELEASE =>
                    if button0_debounced = '0' then
                        current_state <= GET_OPERATION;
                    end if;
            end case;
        end if;
    end process main_fsm;

    -- COMBINATIONAL process to control the output LEDs (no changes)
    output_logic : process (current_state, Result, zero, negative, carry_out, overflow)
    begin
        case current_state is
            when GET_OPERATION | WAIT_B_RELEASE =>
                leds_state <= "00";
                leds <= Result & zero & negative & carry_out & overflow;

            when GET_A | WAIT_OP_RELEASE =>
                leds_state <= "01";
                leds <= (others => '0');

            when GET_B | WAIT_A_RELEASE =>
                leds_state <= "10";
                leds <= (others => '0');
        end case;
    end process output_logic;

end Behavioral;

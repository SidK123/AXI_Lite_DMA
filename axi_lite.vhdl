-- TODO: Write functionality needs to be implemented. Read functionality implemented.

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_lite_slave is
   port (
     ACLK : in std_logic;
     ARESETN : in std_logic;
	 ARADDR : in std_logic_vector(31 downto 0);
	 ARCACHE : in std_logic_vector(31 downto 0);
  	 ARPROT : in std_logic_vector(2 downto 0); -- Unused signal for protection type of memory read.
	 ARVALID : in std_logic; -- Master generates signal when the read address and control signals are valid.
     ARREADY : out std_logic; -- Asserted when slave can accept the address and other control signals.
	 -- Read data channel.
	 RDATA : out std_logic_vector(31 downto 0); -- Read data.
  	 RRESP : out std_logic; -- Read status outputted from slave device.
	 RVALID : out std_logic; -- Asserted when slave data is valid. 
  	 RREADY : in std_logic -- Master asserts this signal when it is ready to accept read data from slave.
     );
 end axi_lite_slave;

architecture participant1 of axi_lite_slave is
    type t_Memory is array (0 to 127) of std_logic_vector(31 downto 0);
    type states is (IDLE, READ_DATA);
    signal currentState, nextState : states;
    signal r_Mem : t_Memory;
    signal r_addr : std_logic_vector(31 downto 0);
    signal address_latch : std_logic;
begin
    process (r_addr, r_Mem)
    begin
        RDATA <= r_Mem(to_integer(unsigned(r_addr)));
    end process;

    process (ACLK, ARESETN)
    begin 
        if ARESETN = '1' then
            currentState <= IDLE;
        elsif rising_edge(ACLK) then
            currentState <= nextState;
        end if;
    end process;

    process (ACLK, address_latch, ARESETN)
    begin
        if ARESETN = '1' then
            r_addr <= "00000000000000000000000000000000";
        elsif (rising_edge(ACLK) and address_latch = '1') then
            r_addr <= ARADDR;
        end if;
    end process;

    process (ACLK) 
    begin
        r_Mem(3) <= "00010001000100010001000100010001";
        case currentState is
            when IDLE =>
                ARREADY <= '1'; 
                if ARVALID = '1' then
                    nextState <= READ_DATA;
                    address_latch <= '1';
                else 
                    nextState <= IDLE;
                    address_latch <= '0';
                end if;
            when READ_DATA =>
                ARREADY <= '0';
                RVALID <= '1';
                if RREADY = '1' then
                    nextState <= IDLE;
                else 
                    nextState <= READ_DATA;
                end if;
        end case;
    end process;
end participant1;

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;

entity axi_lite_master is
  port (
  	-- Global signals.
  	ACLK : in std_logic;
  	ARESETN : in std_logic;
    -- Signals to configure master to send out appropriate AXI Lite transaction to slave.
    addr : in std_logic_vector(31 downto 0);
    r_data : out std_logic_vector(31 downto 0); 
    txn_ready : in std_logic;
    -- Read address channel.
	ARADDR : out std_logic_vector(31 downto 0);
	ARCACHE : out std_logic_vector(31 downto 0);
  	ARPROT : out std_logic_vector(2 downto 0); -- Unused signal for protection type of memory read.
	ARVALID : out std_logic; -- Master generates signal when the read address and control signals are valid.
	ARREADY : in std_logic; -- Slave generated signal when it can accept the address and other control signals.
	-- Read data channel.
	RDATA : in std_logic_vector(31 downto 0);
  	RRESP : in std_logic; -- Read status from slave device.
	RVALID : in std_logic; -- Read valid from slave device, generated when the slave data is valid. 
  	RREADY : out std_logic -- Ready to accept a read; master asserts this signal when it is ready to accept read data from slave.
	);
end axi_lite_master;

architecture master1 of axi_lite_master is
	type states is (IDLE, DATA_REC, FIN); 
	signal current_state, next_state : states;
    signal read_latch, addr_latch : std_logic;
begin
	process (ACLK, ARESETN)
	begin
		if ARESETN = '1' then
			current_state <= IDLE;
		elsif rising_edge(ACLK) then
			current_state <= next_state;
		end if;
	end process;

    process (ACLK, ARESETN) 
    begin
        if ARESETN = '1' then
            r_data <= (others => '0');
        elsif rising_edge(ACLK) then
            if read_latch = '1' then
                r_data <= RDATA;
            end if;
        end if;
    end process;

	process (ACLK)
	begin
        RREADY <= '0';
        ARADDR <= addr; -- Assume address is hooked up to some register that is modified as necessary.
        ARCACHE <= (others => '0');
        ARPROT  <= (others => '0');
        ARVALID <= '0';
		case current_state is
			when IDLE => 
				if txn_ready = '1' then
				    ARVALID <= '1';
				    RREADY <= '1';
                    if ARREADY = '1' then
                        next_state <= DATA_REC;
                    else 
                        next_state <= IDLE;
                    end if; 
                else 
                    RREADY <= '0';
                    next_state <= IDLE;
                end if;
            when DATA_REC =>
                RREADY <= txn_ready;
                if (RVALID = '1') and (txn_ready = '1') then
                    read_latch <= '1';
                    next_state <= IDLE;
                elsif RVALID = '1' then
                    read_latch <= '1';
                    next_state <= FIN;
                else 
                    next_state <= DATA_REC;
                end if;
            when FIN =>
                RREADY <= txn_ready;
                if (txn_ready = '1') then
                    next_state <= IDLE;
                else next_state <= FIN;
                end if;
        end case;
	end process;
end master1;

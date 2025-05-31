library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb is
end tb;

architecture behavior of tb is
    signal aclk : std_logic;
    signal areset : std_logic;
    signal addr : std_logic_vector(31 downto 0);
    signal final_r_data : std_logic_vector(31 downto 0);
    signal txn_ready : std_logic;
    signal araddr, arcache : std_logic_vector(31 downto 0);
    signal arprot : std_logic_vector(2 downto 0);
    signal arvalid, arready : std_logic;
    signal slave_rdata : std_logic_vector(31 downto 0);
    signal rresp, rvalid, rready : std_logic;
    -- Clock generation for simulation.
    constant clk_period : time := 10 ns;
begin
    uut: entity work.axi_lite_master 
        port map (
            ACLK => aclk,
            ARESETN => areset,
            addr => addr,
            r_data => final_r_data,
            txn_ready => txn_ready,
            ARADDR => araddr,
            ARCACHE => arcache,
            ARPROT => arprot,
            ARVALID => arvalid,
            ARREADY => arready,
            RDATA => slave_rdata,
            RRESP => rresp,
            RVALID => rvalid,
            RREADY => rready
        );
    uut2: entity work.axi_lite_slave
        port map (
            ACLK => aclk,
            ARESETN => areset,
            ARADDR => araddr,
            ARCACHE => arcache,
            ARPROT => arprot,
            ARVALID => arvalid,
            ARREADY => arready,
            RDATA => slave_rdata,
            RRESP => rresp,
            RVALID => rvalid,
            RREADY => rready
        );
    clk_process : process 
    begin
        while now < 200 ns loop
            aclk <= '0'; wait for clk_period/2;
            aclk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    stim_process : process
    begin
        addr <= "00000000000000000000000000000011";
        areset <= '1';
        wait until rising_edge(aclk);
        wait until rising_edge(aclk);
        areset <= '0';
        wait until rising_edge(aclk);
        wait until rising_edge(aclk);
        wait until rising_edge(aclk); -- Should indicate that the address is valid, and that the master is ready to receive data (ARVALID & RREADY, respectively.)
        txn_ready <= '1';
        wait until rising_edge(aclk);
        wait until rising_edge(aclk);
        wait until rising_edge(aclk);
        wait until rising_edge(aclk);
        txn_ready <= '0';
        wait until rising_edge(aclk);
        wait for 100 ns; 
        wait;
    end process;
end behavior;


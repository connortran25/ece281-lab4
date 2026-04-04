library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_clk_div : std_logic;
    signal w_clk_div_reset : std_logic;
    signal w_elevator_reset : std_logic;
    signal w_clk_tdm : std_logic;
	signal w_floor_1 : std_logic_vector(3 downto 0);
	signal w_floor_2 : std_logic_vector(3 downto 0);
	signal w_seg_1 : std_logic_vector(6 downto 0);
	signal w_seg_2 : std_logic_vector(6 downto 0);
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 7); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 50000000	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
	
begin
	-- PORT MAPS ----------------------------------------
    clock_divider_inst : clock_divider
        port map (
        i_clk => clk,
        i_reset => w_clk_div_reset,
        o_clk => w_clk_div
        );
    TDM_clk_div : clock_divider
        generic map (k_DIV => 100000)
        port map(
            i_clk => clk,
            i_reset => btnU,
            o_clk => w_clk_tdm
        );
    elevator_controller_fsm_inst : elevator_controller_fsm
        port map(
        i_clk => w_clk_div,
        i_reset => w_elevator_reset,
        is_stopped => sw(0),
        go_up_down => sw(1),
        o_floor => w_floor_1
        );
    sevenseg_decoder_inst : sevenseg_decoder
        port map(
        i_Hex => w_floor_1,
        o_seg_n => w_seg_1
        );
    elevator_controller_fsm_inst_1 : elevator_controller_fsm
        port map(
        i_clk => w_clk_div,
        i_reset => w_elevator_reset,
        is_stopped => sw(14),
        go_up_down => sw(15),
        o_floor => w_floor_2
        );
    sevenseg_decoder_inst_1 : sevenseg_decoder
        port map(
        i_Hex => w_floor_2,
        o_seg_n => w_seg_2
        );
    TDM4_inst : TDM4
        port map(
        i_clk => w_clk_tdm,
        i_reset => btnU,
        i_D3 => "0001110",
        i_D2 => w_seg_2,
        i_D1 => "0001110",
        i_D0 => w_seg_1,
        o_data => seg,
        o_sel(0) => an(0),
        o_sel(1) => an(1),
        o_sel(2) => an(2),
        o_sel(3) => an(3)
        );	
	-- CONCURRENT STATEMENTS ----------------------------
	w_clk_div_reset <= btnL or btnU;
	w_elevator_reset <= btnR or btnU;
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	led(15) <= w_clk_div;
	led(14 downto 0) <= (others => '0');
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;

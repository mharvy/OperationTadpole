module sd_card_reader(
    input logic CLK,
    input logic [15:0] SWITCHES,
    input logic [3:0] KEYS, // KEY[0] => RESET/INIT SD CARD || KEY[1] => READ DATA FROM SD CARD (0x200 + SW)
    input logic D0,
	 output logic D1,
	 output logic CS,
    output logic SD_CLK,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
	 output logic [11:0] LED
);
    logic init_done, read_start, read_done, sd_reset;
    logic [31:0] addr, data, counter;
	 logic [7:0] r1;
	 
    assign sd_reset = ~KEYS[0];
    assign read_start = ~KEYS[1];
    // Debugging
    assign addr = 32'h00000200 | {16'h0000, SWITCHES};
    logic [4:0] cur_state; 

    sd_clock sd_clock (
        .clk(CLK),
        .out_clk(SD_CLK)
    );
	 //assign SD_CLK = SWITCHES[9]; 

	 assign LED[0] = D0;
	 assign LED[1] = D1;
	 assign LED[2] = CS;
	 
    sd_controller state_machine (
        .clk(SD_CLK),
        .reset(sd_reset),
        .addr,
		  .response_flags(r1),
        .response_data(data),
        .D0,
        .D1,
        .CS,
		  .init_start(~KEYS[2]),
        .init_done,
        .read_start,
        .read_done,
		  .cur_state
    );
	 
	 /*
	 sd_cmd cmd(
		.cmd_number(8'h40), 
		.cmd_args(32'h00000000),
		.cmd_crc(8'h95),
		.clk(SD_CLK),
		.start(read_start),
		.done(LED[3]),
		.reset(sd_reset),
		.response_flags(r1),
		.response_data(data),
		.D0,
		.D1,
		.CS
    );
	 */
	 
	 
	 assign LED[6] = cur_state[0];
	 assign LED[7] = cur_state[1];
	 assign LED[8] = cur_state[2];
	 assign LED[9] = cur_state[3];
	 assign LED[10] = cur_state[4];
	 

    HexDriver display0 (.In0(r1[3:0]), .Out0(HEX0));
    HexDriver display1 (.In0(r1[7:4]), .Out0(HEX1));
    //HexDriver display2 (.In0(lst_byte[3:0]), .Out0(HEX2));
    //HexDriver display3 (.In0(lst_byte[7:4]), .Out0(HEX3));
    HexDriver display4 (.In0(data[3:0]), .Out0(HEX4));
    HexDriver display5 (.In0(data[7:4]), .Out0(HEX5));
    HexDriver display6 (.In0(data[11:8]), .Out0(HEX6));
    HexDriver display7 (.In0(data[15:12]), .Out0(HEX7));
endmodule
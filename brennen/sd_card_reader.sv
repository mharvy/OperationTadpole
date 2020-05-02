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
	 logic [7:0] r1, lst_byte;
	 logic cmd_start;
	 
	 
    assign sd_reset = ~KEYS[0];
    assign read_start = ~KEYS[1];
    // Debugging
    assign addr = 32'h00000202; // | {16'h0000, SWITCHES};


    sd_clock sd_clock (
        .clk(CLK),
        .out_clk(SD_CLK)
    );
	 //assign SD_CLK = SWITCHES[9];
	 assign LED[0] = D0;
	 assign LED[1] = D1;
	 
	 always_comb begin
		cmd_start = 1'b1;
		if (D0 == 1'b1) begin
			CS = 1'b0;
		end else begin
			CS = 1'b1;
		end
	 end
	 
	 /*
    sd_control state_machine (
        .clk(SD_CLK),
        .reset(sd_reset),
        .addr,
        .data_transmission(data),
		  .response_flags(r1),
		  .counter,
		  .lst_byte,
        .D0,
        .D1,
        .CS,
        .init_done,
        .read_start,
        .read_done
    );
	 */
	 sd_cmd cmd(
		.cmd_number(8'h40), 
		.cmd_args(32'h00000000),
		.cmd_crc(8'h95),
		.clk(SD_CLK),
		.start(cmd_start),
		.done(LED[3]),
		.reset(sd_reset),
		.response_flags(r1),
		.data_transmission(data),
		.counter,
		.lst_byte,
		.D0,
		.D1,
		.response_received(LED[2])
    );
	 

    HexDriver display0 (.In0(r1[3:0]), .Out0(HEX0));
    HexDriver display1 (.In0(r1[7:4]), .Out0(HEX1));
    HexDriver display2 (.In0(lst_byte[3:0]), .Out0(HEX2));
    HexDriver display3 (.In0(lst_byte[7:4]), .Out0(HEX3));
    HexDriver display4 (.In0(counter[3:0]), .Out0(HEX4));
    HexDriver display5 (.In0(counter[7:4]), .Out0(HEX5));
    HexDriver display6 (.In0(counter[11:8]), .Out0(HEX6));
    HexDriver display7 (.In0(counter[15:12]), .Out0(HEX7));
endmodule
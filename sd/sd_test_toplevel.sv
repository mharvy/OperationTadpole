module sd_test_toplevel(
    input logic CLK,
    input logic [15:0] SWITCHES,
    input logic [3:0] KEYS, // KEY[0] => RESET/INIT SD CARD || KEY[1] => READ DATA FROM SD CARD (0x200 + SW)
    inout wire SD_CMD,
    inout wire [3:0] SD_DAT,
    input logic SD_WP_N,
    output logic SD_CLK,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);
    logic init_start, init_done, read_start, read_done;
    logic [31:0] addr, data;
    logic reset;
	 wire D1, D0, CS;
	 logic [7:0] response_flags;
	 logic [31:0] cnt;

    assign reset = ~KEYS[0];
	 assign D1 = SD_CMD;
	 assign CS = SD_DAT[3];
	 assign D0 = SD_DAT[0];
	 assign SD_CLK = SWITCHES[15];

    enum logic [3:0] {HALTED, INIT, READ, DONE} state, next_state;

    // Module Declaration
    //sd_clock sd_clock (
    //    .clk(CLK),
    //    .out_clk(SD_CLK)
    //);
    sd_init initialize(
        .clk(SD_CLK),
        .start(init_start),
        .done(init_done),
        .D1,
        .CS,
        .D0,
		  .response_flags,
		  .cnt
    );
    sd_read read (
        .clk(SD_CLK),
        .start(read_start),
        .done(read_done),
        .addr,
        .data,
        .D1,
        .CS,
        .D0
    );
	 //HexDriver display0 (.In0(response_flags[3:0]), .Out0(HEX0));
    //HexDriver display1 (.In0(response_flags[7:4]), .Out0(HEX1));
    HexDriver display0 (.In0(cnt[3:0]), .Out0(HEX0));
    HexDriver display1 (.In0(cnt[7:4]), .Out0(HEX1));
    HexDriver display2 (.In0(cnt[11:8]), .Out0(HEX2));
    HexDriver display3 (.In0(cnt[15:12]), .Out0(HEX3));
    HexDriver display4 (.In0(state), .Out0(HEX4));
    HexDriver display5 (.In0(next_state), .Out0(HEX5));
    HexDriver display6 (.In0(response_flags[3:0]), .Out0(HEX6));
    HexDriver display7 (.In0(response_flags[7:4]), .Out0(HEX7));

	always_ff @ (posedge CLK) begin	
		if (reset) // KEYS[0] is reset
			state <= HALTED;
		else 
			state <= next_state;
    end


    always_comb begin

        // Next state logic
        next_state = state;
        unique case(state)
            HALTED: begin
                next_state = INIT;
            end
            INIT: begin
					if (init_done) begin
						next_state = READ;
						init_start = 0;
					end
            end
            READ: begin
               if (read_done) begin
						next_state = DONE;
						read_start = 0;
					end
            end
            DONE: begin
                next_state = HALTED;
            end
        endcase

        // Output logic
        init_start = 1'b0;
        read_start = 1'b0;
        addr = 32'h00000200;
        unique case(state)
            INIT: begin
                init_start = 1'b1;
            end
            READ: begin
                addr = 32'h00000200 | {16'h0000,SWITCHES};
                read_start = 1'b1;
            end
        endcase
    end

endmodule
module sd_card_reader(
    input logic CLK,
    input logic [15:0] SWITCHES,
    input logic [3:0] KEYS, // KEY[0] => RESET/INIT SD CARD || KEY[1] => READ DATA FROM SD CARD (0x200 + SW)
    inout wire SD_CMD,
    inout wire [3:0] SD_DAT,
    input logic SD_WP_N,
    output logic SD_CLK,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    logic init_done, read_start, read_done, sd_reset;
    logic [31:0] addr, data;

    assign sd_reset = ~KEYS[0];
    assign read_start = ~KEYS[1];
    // Debugging
    assign addr = 32'h00000200 | {16'h0000, SWITCHES};


    sd_clock sd_clock (
        .clk(CLK),
        .out_clk(SD_CLK)
    );
    sd_control state_machine (
        .clk(SD_CLK),
        .reset(sd_reset),
        .addr,
        .data,
        .D0(SD_DAT[0]),
        .D1(SD_CMD),
        .CS(SD_DAT[3]),
        .init_done,
        .read_start,
        .read_done
    );

    HexDriver display0 (.In0(data[3:0]), .Out0(HEX0));
    HexDriver display1 (.In0(data[7:4]), .Out0(HEX1));
    HexDriver display2 (.In0(data[11:8]), .Out0(HEX2));
    HexDriver display3 (.In0(data[15:12]), .Out0(HEX3));
    HexDriver display4 (.In0(data[19:16]), .Out0(HEX4));
    HexDriver display5 (.In0(data[23:20]), .Out0(HEX5));
    HexDriver display6 (.In0(data[27:24]), .Out0(HEX6));
    HexDriver display7 (.In0(data[31:28]), .Out0(HEX7));
endmodule
module sd_cmd(
    input logic [7:0] cmd_number,
    input logic [31:0] cmd_args,
    input logic [7:0] cmd_crc,
    input logic clk,
    input logic start,
    output logic done,
	 input logic reset,
    output logic [7:0] response_flags,
    output logic [31:0] data_transmission,
	 output logic [31:0] counter,
	 output logic [7:0] lst_byte,
    input logic D0,
	 output logic D1,
	 output logic response_received
);
    int count, data_count, next_data_count, response_count, next_response_count;
	 int next_count;
	 
    logic [7:0] last_byte, next_last_byte;
    logic [7:0] next_response_flags;
    logic [31:0] next_data_transmission;
	 logic response_finished, data_token_detected;
	 
	 assign counter = count;
	 assign lst_byte = last_byte;

	 initial begin
        response_flags = 8'h00;
        data_transmission = 32'h00000000;
	 end
	 
    always_ff @(posedge clk) begin
        if (start && ~reset) begin
				count <= next_count;
            data_count <= next_data_count;
				response_count <= next_response_count;
				
            last_byte <= next_last_byte;
            response_flags <= next_response_flags;
            data_transmission <= next_data_transmission;
        end
        else begin
				count <= 0;
            data_count <= 0;
				last_byte <= 8'h00;
        end
    end
	 
    always_comb begin
		  next_count = count + 1;
        done = 1'b0;

		  next_data_count = data_count;
		  next_response_count = response_count;
		  
        next_last_byte = last_byte;
        next_response_flags = response_flags;
        next_data_transmission = data_transmission;

        D1 = 1'b1;
		  response_received = 1'b0;
		  response_finished = 1'b0;
		  data_token_detected = 1'b0;
		  
        // SEND COMMAND SEQUENCE
        if (count < 8) // First Byte (Command number)
            D1 = cmd_number[8 - count];
        else if (count < 40) // Second-Fifth Byte (Command arguments)
            D1 = cmd_args[40 - (count - 8)];
        else if (count < 48) // Sixth Byte (CRC)
            D1 = cmd_crc[48 - (count - 40)];

		  // IF RECEIVING A RESPONSE
		  else if (response_received == 1'b0 && D0 == 1'b0)
				response_received = 1'b1;
				
		  if (response_count > 0 && response_count < 8)
				response_received = 1'b1;
		  // READ RESPONSE
        if (response_received == 1'b1) begin // RECEIVE R1 RESPONSE FROM D0
            next_response_flags[response_count] = D0;
				next_response_count = response_count + 1;
        end
		  // WHEN RESPONSE HAS BEEN READ, SET SIGNAL
		  if (response_count == 8)
				response_finished = 1'b1;
				
		  // WAIT FOR DATA TOKEN IF THERE IS A DATA TRANSMISSION (0xFE)
		  if (response_finished == 1'b1 && last_byte != 8'hFE)
            next_last_byte = last_byte << 1 | D0;
        if (last_byte == 8'hFE)
            data_token_detected = 1'b1;

        // if 0xFE has been read, read data transmission (fixed size 32)
        if (data_token_detected == 1'b1 && data_count < 32) begin
            next_data_transmission[data_count] = D0;
            next_data_count = data_count + 1;
        end
        // Once Read 32, you are finished else timeout when count > 1000
        if (data_count >= 32 || count > 1000)
            done = 1;
    end

endmodule
module sd_cmd(
    input logic [7:0] cmd_number,
    input logic [31:0] cmd_args,
    input logic [7:0] cmd_crc,
    input logic clk,
    input logic start,
    output logic done,
	 input logic reset,
    output logic [7:0] response_flags,
    output logic [31:0] response_data,
	 output logic [31:0] counter,
    input logic D0,
	 output logic D1,
	 output logic CS
);
    int count, next_count;
	 
    logic [7:0] next_response_flags;
    logic [31:0] next_response_data;
	 enum logic [5:0] {HALT, WAIT, CS_HIGH, CS_LOW, COMMAND_NUMBER, COMMAND_ARGS, COMMAND_CRC, WAIT_FOR_RESPONSE, READ_RESPONSE, WAIT_FOR_DATA, READ_DATA, DONE} state, next_state;
	 
	 // Debugging
	 assign counter = count;

	 initial begin
        response_flags = 8'h00;
        response_data = 32'h00000000;
	 end
	 
    always_ff @(posedge clk) begin
        if (reset) begin
		      state <= HALT;
            count <= 0;
        end
        else begin
				state <= next_state;
				count <= next_count;

            response_flags <= next_response_flags;
            response_data <= next_response_data;
        end
    end
	 
	 always_comb begin
	     // Necessities
		  next_state = state;
		  next_count = count;
		  next_response_flags = response_flags;
		  next_response_data = response_data;
	     D1 = 1'b1;
		  done = 1'b0;
		  CS = 1'b0;
	 
	     // Next state logic 
        unique case (state)
		      HALT: begin
				    if (start) begin
				        next_state = WAIT;
					 end
				end
				
				WAIT: begin
				    if (count >= 80) begin
					     next_state = CS_HIGH;
					 end
				end
		  
		      CS_HIGH: begin
				    next_state = CS_LOW;
				end
				
				CS_LOW: begin
				    next_state = COMMAND_NUMBER;
				end
		  
		      COMMAND_NUMBER: begin
				    if (count == 7) begin
					     next_state = COMMAND_ARGS;
					 end
				end
				
				COMMAND_ARGS: begin
				    if (count == 39) begin
				        next_state = COMMAND_CRC;
					 end
				end
				
				COMMAND_CRC: begin
				    if (count == 47) begin
				        next_state = WAIT_FOR_RESPONSE;
					 end
				end
				
				WAIT_FOR_RESPONSE: begin
				    if (D0 == 1'b0) begin
					     next_state = READ_RESPONSE; 
				    end
				end
				
				READ_RESPONSE: begin
				    if (count >= 7 && cmd_number == (8'h40 | 8'h11)) begin
					     next_state = WAIT_FOR_DATA;
					 end
					 else if (count >= 7) begin
					     next_state = HALT;
					 end
				end
				
				WAIT_FOR_DATA: begin
				    if (D0 == 1'b0) begin
					     next_state = READ_DATA;
					 end
				end
				
				READ_DATA: begin
				    if (count >= 32) begin
					     next_state = DONE;
					 end
				end
				DONE: begin
                if (~start)
                    next_state = HALT;
				end
		  endcase
	 
	     // Output logic
		  unique case (state)
		      HALT: begin // moved done = 1'b1 out of here, made a DONE state
					 next_count = 0;
				end
				
				WAIT: begin
				    CS = 1'b1;
					 D1 = 1'b1;
					 next_count = count + 1;
				end
				
				CS_HIGH: begin
				    CS = 1'b1;
					 next_count = 0;
				end
		  
		      COMMAND_NUMBER: begin
				    D1 = cmd_number[7 - count];
					 //D1 = cmd_number[count];
				    next_count = count + 1;
				end
				
				COMMAND_ARGS: begin
				    D1 = cmd_args[31 - (count - 8)];
					 //D1 = cmd_number[count - 8];
					 next_count = count + 1;
				end
				
				COMMAND_CRC: begin
				    D1 = cmd_crc[7 - (count - 40)];
				    //D1 = cmd_crc[count - 40];
					 next_count = count + 1;
				end
				
				WAIT_FOR_RESPONSE: begin
				    next_count = 0;
				end
				
				READ_RESPONSE: begin
				    next_response_flags[6 - count] = D0;
				    next_count = count + 1;
				end
				
				WAIT_FOR_DATA: begin
				    next_count = 0;
				end
				
				READ_DATA: begin
				    next_response_data[32 - count] = D0;
					 next_count = count + 1;
				end
				DONE: begin
					done = 1'b1;
				end
		  endcase
	 
    end

endmodule
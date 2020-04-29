module sd_read(
	input logic clk,
	input logic start,
	input logic [31:0] addr,
	output logic [31:0] data,
	output logic done,
	output logic D1,
	output logic CS,
	inout logic D0
);

	logic cmd_start, cmd_done;
	logic [7:0] response_flags;
	enum {HALT, READ, DONE} state, next_state;
	
	sd_cmd cmd(
		.cmd_number(8'h40 | 8'h11), // CMD17 
		.cmd_args(addr),
		.cmd_crc(8'hFF), // CRC doesn't matter?
		.clk,
		.start(cmd_start),
		.done(cmd_done),
		.response_flags,
		.data_transmission(data),
		.D1,
		.D0);
	
	always_ff @ (posedge clk) begin
		if (start)
			state <= next_state;
		else
			state <= HALT;
	end
	
	always_comb begin
		// Default next state logic
		next_state = state;
		
		// Next state logic
		case(state)
			HALT: begin
				next_state = READ;
			end
			
			READ: begin
				if (cmd_done) begin
					if (response_flags == 8'h00)
						next_state = DONE;
					cmd_start = 1'b0;
				end
			end
			
			DONE: begin
				if (~start) begin
					next_state = HALT;
				end
			end
		endcase
		
		// Default output logic
		CS = 1;
		done = 0;
		// Next output logic
		case(state)
			READ: begin
				CS = 0;
				cmd_start = 1'b1;
			end
			
			DONE: begin
				done = 1'b1;
			end
		endcase
	end

endmodule

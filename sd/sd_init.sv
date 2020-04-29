module sd_init(
	input logic clk,
	input logic start,
	output logic done,
	output logic D1,
	output logic CS,
	inout logic D0
);

	logic [7:0] cmd_number;
	logic [31:0] cmd_args;
	logic [7:0] cmd_crc;
	logic cmd_start, cmd_done;
	logic [7:0] response_flags;
	logic [31:0] data_transmission;
	
	enum {HALT, RESET, VOLTAGE_CHECK, INIT1, INIT2, SET_BLOCK_SIZE, DONE} state, next_state;
	
	sd_cmd cmd(
		.cmd_number, 
		.cmd_args,
		.cmd_crc,
		.clk,
		.start(cmd_start),
		.done(cmd_done),
		.response_flags,
		.data_transmission,
		.D1,
		.D0);
	
	always_ff @(posedge clk) begin
		if (start)
			state <= next_state;
		else
			state <= HALT;
	end
	
	always_comb begin
		// Default next state logic
		next_state = state;
		// Next state logic
		case (state)
			HALT: begin
				next_state = RESET;
			end
		
			RESET: begin
				if (cmd_done) begin
					if (response_flags == 8'h01)
						next_state = VOLTAGE_CHECK;
					cmd_start = 0;
				end
			end
			
			VOLTAGE_CHECK: begin
				if (cmd_done) begin
					if (response_flags == 8'h01 && data_transmission == cmd_args)
						next_state = INIT1;
					cmd_start = 0;
				end
			end
			
			INIT1: begin
				if (cmd_done) begin
					if (response_flags == 8'h01)
						next_state = INIT2;
					cmd_start = 0;
				end
			end
			
			INIT2: begin
				if (cmd_done) begin
					if (response_flags == 8'h00)
						next_state = SET_BLOCK_SIZE;
					else if (response_flags == 8'h01)
						next_state = INIT1;
					cmd_start = 0;
				end
			end
			
			SET_BLOCK_SIZE: begin
				if (cmd_done) begin
					if (response_flags == 8'h00)
						next_state = DONE;
					cmd_start = 0;
				end
			end
			
			DONE: begin
				if (~start) begin
					next_state = HALT;
				end
			end
			
		endcase
	
		// Default output values
		CS = 1;
		done = 0;
		cmd_number = 8'h00;
		cmd_args = 32'h00000000;
		cmd_crc = 8'h00;
		// Next output logic
		case (state)
			RESET: begin
				CS = 0;
				cmd_number = 8'h40 | 8'h00; // CMD0
				cmd_args = 32'h00000000;
				cmd_crc = 8'h95;
				cmd_start = 1'b1;
			end
				
			VOLTAGE_CHECK: begin
				CS = 0;
				cmd_number = 8'h40 | 8'h08; // CMD8
				cmd_args = 32'h000001AA;
				cmd_crc = 8'h87;
				cmd_start = 1'b1;
			end
			
			INIT1: begin
				CS = 0;
				cmd_number = 8'h40 | 8'h37;  // CMD55
				cmd_args = 32'h00000000;
				cmd_crc = 8'h65;
				cmd_start = 1'b1;
			end
			
			INIT2: begin
				CS = 0;
				cmd_number = 8'h40 | 8'h29;  // ACMD41
				cmd_args = 32'h40000000;
				cmd_crc = 8'h77;
				cmd_start = 1'b1;
			end
			
			SET_BLOCK_SIZE: begin
				CS = 0;
				cmd_number = 8'h40 | 8'h10; // CMD16
				cmd_args = 32'h00000004;
				cmd_crc = 8'hFF;
				cmd_start = 1'b1;
			end
			
			DONE : begin
				done = 1'b1;
			end
		endcase
	end

endmodule
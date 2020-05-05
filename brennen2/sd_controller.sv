module sd_controller (
	input logic clk, // SD clock (100kHz)
	input logic reset,
	input logic [31:0] addr,
	output logic [7:0] response_flags,
	output logic [31:0] response_data,
	input logic D0,
	output logic D1,
	output logic CS,
	input logic init_start,
	output logic init_done,
	input logic read_start,
	output logic read_done
);
	logic cmd_start, cmd_done;
	logic [7:0] cmd_number, cmd_crc;
	logic [31:0] cmd_args;
	
	logic ld_response_flags, ld_response_data;
	logic [7:0] response_flags_temp;
	logic [31:0] response_data_temp;
	
	enum logic [4:0] {HALT, WAIT, CMD0, CMD0_DONE, CMD8, CMD8_DONE, CMD55, CMD55_DONE, ACMD41, ACMD41_DONE, CMD16, CMD16_DONE, IDLE, CMD17, CMD17_DONE} state, next_state;
	
	sd_cmd cmd (
		.cmd-number,
		.cmd_args,
		.cmd_crc,
		.clk,
		.start(cmd_start),
		.done(cmd_done),
		.reset,
		.response_flags(response_flags_temp),
		.response_data(response_data_temp),
		.D0,
		.D1,
		.CS
	);
	
	register #(.N(8)) rsp_flags (
		.D_In(response_flags_temp),
		.Clk(clk),
		.Reset(reset),
		.Load(ld_response_flags),
		.D_Out(response_flags)
	);
	
	register #(.N(32)) rsp_flags (
		.D_In(response_data_temp),
		.Clk(clk),
		.Reset(reset),
		.Load(ld_response_data),
		.D_Out(response_data)
	);
	
	initial begin
		state <= HALT;
	end
	
	always_ff @ (posedge clk) begin
		if (reset)
			state <= HALT;
		else
			state <= next_state;s
	end
	
	always_comb begin
		next_state = state;
		
		cmd_start = 1'b0;
		init_done = 1'b0;
		read_done = 1'b0;
		
		cmd_number = 8'h00;
		cmd_args = 32'h00000000;
		cmd_crc = 8'h00;
		
		ld_response_flags = 1'b0;
		ld_response_data = 1'b0;
		
		unique case (state)
			HALT: begin
				if (init_start == 1'b1)
					next_state = WAIT;
			end
			WAIT: begin
				if (D0 == 1'b1)
					next_state = CMD0;
			end
			// INIT CMD
			CMD0: begin
				if (cmd_done == 1'b1) begin
					if (response_flags == 8'h01) begin
						next_state = CMD0_DONE
					end
						
				end
			end
			CMD0_DONE: begin
				if (D0 == 1'b1)
					next_state = CMD8;
			end
			// VOLTAGE CHECK
			CMD8: begin
				if (cmd_done == 1'b1) begin
					if (response_flags == 8'h01 && response_data == cmd_args)
						next_state = CMD8_DONE;
				end
			end
			CMD8_DONE: begin
				if (D0 == 1'b1)
					next_state = CMD55;
			end
			// INIT1
			CMD55: begin
				if (cmd_done == 1'b1) begin
					if (response_flags = 8'h01)
						next_state = CMD55_DONE;
				end
			end
			CMD55_DONE: begin
				if (D0 == 1'b1)
					next_state = ACMD41;
			end
			// INIT2
			ACMD41: begin
				if (cmd_done == 1'b1) begin
					if (response_flags == 8'h00)
						next_state = ACMD41_DONE;
				end
			end
			ACMD41_DONE: begin
				if (D0 == 1'b1)
					next_state = CMD16;
			end
			// SET BLOCK SIZE
			CMD16: begin
				if (cmd_done == 1'b1) begin
					if (response_flags == 8'h00)
						next_state = CMD16_DONE;
				end
			end
			CMD16_DONE: begin
				next_state = IDLE;
			end
			// IDLE
			IDLE: begin
				if (read_start && D0 == 1'b1)
					next_state = CMD17;
			end
			// READ
			CMD17: begin
				if (cmd_done == 1'b1) begin
					if (response_flags == 8'h00)
						next_state = CMD17_DONE;
				end
			end
			CMD17_DONE: begin
				if (~read_start)
					next_state = IDLE;
			end
		endcase
		
		unique case (state)
			// INIT CMD
			CMD0: begin
				cmd_number = 8'h40 | 8'h00;
				cmd_args = 32'h00000000;
				cmd_crc = 8'h95;
				
				cmd_start = 1'b1;
				ld_response_flags = 1'b1;
			end
			CMD0_DONE: begin
				cmd_start = 1'b0;
			end
			// VOLTAGE CHECK
			CMD8: begin
				cmd_number = 8'h40 | 8'h08;
				cmd_args = 32'h000001AA;
				cmd_crc = 8'h87;
			
				cmd_start = 1'b1;
				ld_response_flags = 1'b1;
				ld_response_data = 1'b1;
			end
			CMD8_DONE: begin
				cmd_start = 1'b0;
			end
			// INIT1
			CMD55: begin
				cmd_number = 8'h40 | 8'h37;
				cmd_args = 32'h00000000;
				cmd_crc = 8'h65;
				
				cmd_start = 1'b1;
				ld_response_flags = 1'b1;
			end
			CMD55_DONE: begin
				cmd_start = 1'b0;
			end
			// INIT2
			ACMD41: begin
				cmd_number = 8'h40 | 8'h29;
				cmd_args = 32'h40000000;
				cmd_crc = 8'h77;
				
				cmd_start = 1'b1;
				ld_response_flags = 1'b1;
			end
			ACMD41_DONE: begin
				cmd_start = 1'b0;
			end
			// SET BLOCK SIZE
			CMD16: begin
				cmd_number = 8'h40 | 8'h10;
				cmd_args = 32'h00000004;
				cmd_crc = 8'hFF; // doesn't matter
				
				cmd_start = 1'b1;
				ld_response_flags = 1'b1;
			end
			CMD16_DONE: begin
				cmd_start = 1'b0;
			end
			// IDLE
			IDLE: begin
				init_done = 1'b1;
			end
			// READ
			CMD17: begin
				init_done = 1'b1;
			
				cmd_number = 8'h40 | 8'h11;
				cmd_args = addr;
				cmd_crc = 8'hFF; // doesn't matter
			
				cmd_start = 1'b1;
				ld_response_flags = 1'b1;
				ld_response_data = 1'b1;
			end
			CMD17_DONE: begin
				init_done = 1'b1;
			
				cmd_start = 1'b0;
				read_done = 1'b1;
			end
		endcase
		
	
	end



endmodule

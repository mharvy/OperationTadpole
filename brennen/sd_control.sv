module sd_control(
    input logic clk,  // SD clock (100kHz)
    input logic reset,
    input logic [31:0] addr,
	 output logic [7:0] response_flags,
	 output logic [31:0] response_data,
    input logic D0,
    output logic D1,
    output logic CS,
    output logic init_done,
    input logic read_start,  // When 1, break from IDLE, goto READ
    output logic read_done,
	 output logic [5:0] cur_state,
	 input logic cmd_start
);
	//logic cmd_start, next_cmd_start, 
	logic cmd_done;

   logic [7:0] cmd_number;
	logic [31:0] cmd_args;
	logic [7:0] cmd_crc;
	int count, next_count;
	
	//logic [7:0] response_flags;
	//logic [31:0] data_transmission;

	//logic write_to_D0;
	//logic D0_write, D0_read, D1_write, D1_read, CS_write, CS_read;
	
	enum logic [4:0] {HALT, WAIT, RESET, VOLTAGE_CHECK, INIT1, INIT2, SET_BLOCK_SIZE, IDLE, READ} state, next_state;
	//assign cur_state = state;
	
	
	sd_cmd cmd(
		.cmd_number, 
		.cmd_args,
		.cmd_crc,
		.clk,
		.start(cmd_start),
		.done(cmd_done),
		.reset,
		.response_flags,
		.response_data,
		.D0,
		.D1,
		.CS,
		.cur_state
    );
	initial begin
		state <= HALT;
	end

	always_ff @(posedge clk) begin
		if (reset) begin
			state <= HALT;
			count <= 0;
			//cmd_start <= 1'b0;
		end
		else begin
			state <= next_state;
			count <= next_count;
			//cmd_start <= next_cmd_start;
		end
	end

	always_comb begin
		// Default next state logic
		next_state = state;
		next_count = count;
		
		// Default output values
		//cmd_start = 1'b0;
		init_done = 1'b0;
		read_done = 1'b0;

		cmd_number = 8'h00;
		cmd_args = 32'h00000000;
		cmd_crc = 8'h00;
		
		//next_cmd_start = cmd_start;

		// Next state logic
		unique case (state)
			HALT: begin
				next_state = WAIT;
			end
			WAIT: begin
				if (count == 1000000) begin
					next_state = RESET;
				end
			end
			RESET: begin
				if (cmd_done == 1'b1 && response_flags == 8'h01) begin
					next_state = VOLTAGE_CHECK;
				end
			end
			VOLTAGE_CHECK: begin
				if (cmd_done) begin
					if (response_flags == 8'h01 && response_data == cmd_args)
						next_state = INIT1;
					//cmd_start = 1'b0;
				end
			end
			INIT1: begin
				if (cmd_done) begin
					if (response_flags == 8'h01)
						next_state = INIT2;
					//cmd_start = 1'b0;
				end
			end
			INIT2: begin
				if (cmd_done) begin
					if (response_flags == 8'h00)
						next_state = SET_BLOCK_SIZE;
					else if (response_flags == 8'h01)
						next_state = INIT1;
					//cmd_start = 1'b0;
				end
			end
			SET_BLOCK_SIZE: begin
				if (cmd_done) begin
					if (response_flags == 8'h00)
						next_state = IDLE;
					//cmd_start = 1'b0;
				end
			end
			IDLE: begin
				if (read_start)
					next_state = HALT;
			end
			READ: begin
				if (cmd_done) begin
					if (response_flags == 8'h00) begin
						next_state = IDLE;
						read_done = 1'b1;
					end
					//cmd_start = 1'b0;
				end
			end
		endcase

		// Next output logic
		unique case (state)
			
			WAIT: begin
				next_count = count + 1;
			end
		
			RESET: begin
				cmd_number = 8'h40 | 8'h00; // CMD0
				cmd_args = 32'h00000000;
				cmd_crc = 8'h95;
				//if (~cmd_done && D0 == 1'b1)
				//	next_cmd_start = 1'b1;
				//else
				//   next_cmd_start = 1'b0;
			end
				
			VOLTAGE_CHECK: begin
				cmd_number = 8'h40 | 8'h08; // CMD8
				cmd_args = 32'h000001AA;
				cmd_crc = 8'h87;
				//if (D0 == 1'b1)
				//	cmd_start = 1'b1;
			end
			
			INIT1: begin
				cmd_number = 8'h40 | 8'h37;  // CMD55
				cmd_args = 32'h00000000;
				cmd_crc = 8'h65;
				//if (D0 == 1'b1)
				//	cmd_start = 1'b1;
			end
			
			INIT2: begin
				cmd_number = 8'h40 | 8'h29;  // ACMD41
				cmd_args = 32'h40000000;
				cmd_crc = 8'h77;
				//if (D0 == 1'b1)
				//	cmd_start = 1'b1;
			end
			
			SET_BLOCK_SIZE: begin
				cmd_number = 8'h40 | 8'h10; // CMD16
				cmd_args = 32'h00000004;
				cmd_crc = 8'hFF;
				//if (D0 == 1'b1)
				//	cmd_start = 1'b1;
			end
			
			IDLE : begin
				init_done = 1'b1;
			end

			READ: begin
				cmd_number = 8'h40 | 8'h11; // CMD17
				cmd_args = addr;
				cmd_crc = 8'hFF;
				//if (D0 == 1'b1)
				//	cmd_start = 1'b1;
			end
		endcase
	end
endmodule
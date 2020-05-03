module sd_control(
    input logic clk,  // SD clock (100kHz)
    input logic reset,
    input logic [31:0] addr,
    output logic [31:0] response_data,
	 output logic [7:0] response_flags,
	 output logic [31:0] counter,
	 output logic [7:0] lst_byte,
    input logic D0,
    output logic D1,
    output logic CS,
    output logic init_done,
    input logic read_start,  // When 1, break from IDLE, goto READ
    output logic read_done,
	 output logic response_received
);
	logic cmd_start, cmd_done;

   logic [7:0] cmd_number;
	logic [31:0] cmd_args;
	logic [7:0] cmd_crc;
	
	//logic [7:0] response_flags;
	//logic [31:0] data_transmission;

	//logic write_to_D0;
	//logic D0_write, D0_read, D1_write, D1_read, CS_write, CS_read;
	
	enum {HALT, RESET, VOLTAGE_CHECK, INIT1, INIT2, SET_BLOCK_SIZE, IDLE, READ} state, next_state;

	//assign data = data_transmission;
	//assign r1 = response_flags;
	
	//tristate t_D0 (.Clk(clk), .tristate_output_enable(write_to_D0), .Data_write(D0_write), .Data_read(D0_read), .Data(D0));
	//tristate t_D1 (.Clk(clk), .tristate_output_enable(1'b1), .Data_write(D1_write), .Data_read(D1_read), .Data(D1));
	//tristate t_CS (.Clk(clk), .tristate_output_enable(1'b1), .Data_write(CS_write), .Data_read(CS_read), .Data(CS));

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
		.counter,
		.D0,
		.D1,
		.CS,
		.cur_state(5'b00000)
    );
	initial begin
		state <= HALT;
	end

	always_ff @(posedge clk) begin
		if (reset)
			state <= HALT;
		else
			state <= next_state;
	end

	always_comb begin
		// Default next state logic
		next_state = state;
		
		// Default output values
		cmd_start = 1'b0;
		init_done = 1'b0;
		read_done = 1'b0;
		CS = 1'b1;

		cmd_number = 8'h00;
		cmd_args = 32'h00000000;
		cmd_crc = 8'h00;

		// Next state logic
		unique case (state)
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
					if (response_flags == 8'h01 && response_data == cmd_args)
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
						next_state = IDLE;
					cmd_start = 0;
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
					cmd_start = 1'b0;
				end
			end
		endcase

		// Next output logic
		unique case (state)
			RESET: begin
				CS = 1'b0;
				cmd_number = 8'h40 | 8'h00; // CMD0
				cmd_args = 32'h00000000;
				cmd_crc = 8'h95;
				if (D0 == 1'b1)
					cmd_start = 1'b1;
			end
				
			VOLTAGE_CHECK: begin
				CS = 1'b0;
				cmd_number = 8'h40 | 8'h08; // CMD8
				cmd_args = 32'h000001AA;
				cmd_crc = 8'h87;
				if (D0 == 1'b1)
					cmd_start = 1'b1;
			end
			
			INIT1: begin
				CS = 1'b0;
				cmd_number = 8'h40 | 8'h37;  // CMD55
				cmd_args = 32'h00000000;
				cmd_crc = 8'h65;
				if (D0 == 1'b1)
					cmd_start = 1'b1;
			end
			
			INIT2: begin
				CS = 1'b0;
				cmd_number = 8'h40 | 8'h29;  // ACMD41
				cmd_args = 32'h40000000;
				cmd_crc = 8'h77;
				if (D0 == 1'b1)
					cmd_start = 1'b1;
			end
			
			SET_BLOCK_SIZE: begin
				CS = 1'b0;
				cmd_number = 8'h40 | 8'h10; // CMD16
				cmd_args = 32'h00000004;
				cmd_crc = 8'hFF;
				if (D0 == 1'b1)
					cmd_start = 1'b1;
			end
			
			IDLE : begin
				CS = 1'b1;
				init_done = 1'b1;
			end

			READ: begin
				CS = 1'b0;
				cmd_number = 8'h40 | 8'h11; // CMD17
				cmd_args = addr;
				cmd_crc = 8'hFF;
				if (D0 == 1'b1)
					cmd_start = 1'b1;
			end
		endcase
	end
endmodule
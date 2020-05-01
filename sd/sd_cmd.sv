module sd_cmd(
	input logic [7:0] cmd_number, // |= 0x40 (add 64 to cmd number, caller responsible)
	input logic [31:0] cmd_args, // usually contain address of the data/ length of block
	input logic [7:0] cmd_crc, // used for some cmds like CMD0
	input logic clk,
	input logic start,
	output logic done,
	output logic [7:0] response_flags,
	output logic [31:0] data_transmission,
	inout wire D1,
	inout wire D0,
	output logic [31:0] cnt
);
	int count, next_count;
	int data_count, next_data_count;
	
	logic write_to_D0, write_to_D1;
	logic D0_in, D0_out, D1_in, D1_out;
	
	logic [7:0] last_byte, next_last_byte;
	logic [7:0] next_response_flags;
	logic [31:0] next_data_transmission;
	
	assign cnt = count;
	
	tristate t_D0 (.Clk(clk), .tristate_output_enable(write_to_D0), .Data_write(D0_in), .Data_read(D0_out), .Data(D0));
	tristate t_D1 (.Clk(clk), .tristate_output_enable(write_to_D1), .Data_write(D1_in), .Data_read(D1_out), .Data(D1));
	
	
	always_ff @(posedge clk) begin
		if (start) begin
			count = next_count;
			data_count = next_data_count;
			
			last_byte = next_last_byte;
			
			response_flags = next_response_flags;
			data_transmission = next_data_transmission;
		end
		else begin
			count = 0;
			data_count = 0;
			
			last_byte = 8'h00;
			
			response_flags = 8'h00;
			data_transmission = 32'h00000000;
		end
	end

	always_comb begin
		done = 0;
		D1 = 1;
		next_response_flags = response_flags;
		next_data_transmission = data_transmission;
		next_last_byte = last_byte;
		next_data_count = data_count;
		next_count = count;
		
		write_to_D0 = 1'b1;
		write_to_D1 = 1'b1;
		D0_in = 1'b1;
		D1_in = 1'b1;
		
		// first byte for cmd number
		if (count < 8) begin
			D1_in = cmd_number[count];
			next_count = count + 1;
		end
		
		// next four bytes are for argument
		else if (count < 40) begin
			D1_in = cmd_args[count - 8];
			next_count = count + 1;
		end
	
		// last byte is CRC (dummy byte)
		else if (count < 48) begin
			D1_in = cmd_crc[count - 40];
			next_count = count + 1;
		end
			
		// then send another dummy byte while waiting for response
		else if (count < 56) begin
			D1_in = 1'b0; // <<<< expendable
			next_count = count + 1;
		end
			
		// then we receive a response from D0, flags response
		else if (count < 64) begin
			write_to_D0 = 1'b0; // reading from D0
			next_response_flags[count - 56] = D0_out;
			next_count = count + 1;
		end
			
		// once we are done SENDING cmd...
		// wait for 0xFE
		else if (last_byte != 8'hFE) begin
			write_to_D0 = 1'b0; // reading from D0
			next_last_byte = last_byte << 1 | D0_out;
		end
		
		if (last_byte == 8'hFE) begin
			next_data_count = 0;
			next_last_byte = 8'hFF;
		end
			
		// 0xFE has been read, now read data transmission (fixed size 32)
		if (last_byte == 8'hFF && data_count < 32) begin
			write_to_D0 = 1'b0; // reading from D0
			next_data_transmission[data_count] = D0_out;
			next_data_count = data_count + 1;
		end
		
		if (data_count >= 32) begin
			done = 1;
		end
		
		// This is a time out just in case we do't receive data transmission
		if (count > 1000) begin
			done = 1;
		end
	end
	

endmodule
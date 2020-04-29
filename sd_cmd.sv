module sd_cmd(
	input logic [7:0] cmd_number, // |= 0x40 (add 64 to cmd number, caller responsible)
	input logic [31:0] cmd_args, // usually contain address of the data/ length of block
	input logic [7:0] cmd_crc, // used for some cmds like CMD0
	input logic clk,
	input logic start,
	output logic done,
	output logic [7:0] response_flags,
	output logic [31:0] data_transmission,
	output logic D1,
	inout logic D0
);
	int count, next_count;
	int data_count, next_data_count;
	logic [7:0] last_byte, next_last_byte;
	logic [7:0] next_response_flags;
	logic [31:0] next_data_transmission;
	
	
	always_ff @(posedge clk) begin
		if start begin
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
		D0 = D0;
		next_response_flags = response_flags;
		next_data_transmission = data_transmission;
	
		// first byte for cmd number
		if (count < 8) begin
			D1 = cmd_number[count];
			D0 = 1;
		end
		
		// next four bytes are for argument
		elif (count < 40) begin
			D1 = cmd_args[count - 8];
			D0 = 1;
		end
	
		// last byte is CRC (dummy byte)
		elif (count < 48) begin
			D1 = cmd_crc[count - 40];
			D0 = 1;
		end
			
		// then send another dummy byte while waiting for response
		elif (count < 56) begin
			D1 = 0; // <<<< expendable
			D0 = 1;
		end
			
		// then we receive a response from D0, flags response
		elif (count < 64)
			next_response_flags[count - 56] = D0;
			
		// once we are done SENDING cmd...
		// wait for 0xFE
		elif (last_byte != 0xFE)
			next_last_byte = last_byte << 1 || D1;
		if (last_byte == 0xFE)
			next_data_count = 0;
			next_last_byte = 0xFF;
		// 0xFE has been read, now read data transmission (fixed size 32)
		if (last_byte == 0xFF and data_count < 32)
			next_data_count = data_count + 1;
			next_data_transmission[data_count] = D0;
		
		if (data_count >= 32)
			done = 1;
		
		// This is a time out just in case we do't receive data transmission
		if (count > 1000)
			done = 1;
		
		
	end
	


endmodule
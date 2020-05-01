module sd_cmd(
    input logic [7:0] cmd_number,
    input logic [31:0] cmd_args,
    input logic [7:0] cmd_crc,
    input logic clk,
    input logic start,
    output logic done,
    output logic [7:0] response_flags,
    output logic [31:0] data_transmission,
    output logic D1_write,
    output logic write_to_D0,
    output logic D0_write,
    input logic D0_read
);
    int count, data_count, next_data_count;

    logic [7:0] last_byte, next_last_byte;
    logic [7:0] next_response_flags;
    logic [31:0] next_data_transmission;

    always_ff @(posedge clk) begin
        if (start) begin
            count <= count + 1;
            data_count <= next_data_count;

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
        done = 1'b0;
        D1_write = 1'b1;

		  next_data_count = data_count;
		  
        next_last_byte = last_byte;
        next_response_flags = response_flags;
        next_data_transmission = data_transmission;

        write_to_D0 = 1'b1; // Default write to D0
        D0_write = 1'b1; // Default D0 to 1
        D1_write = 1'b1; // Default D1 to 1

        // SEND COMMAND SEQUENCE
        if (count < 8) // First Byte (Command number)
            D1_write = cmd_number[count];
        else if (count < 40) // Second-Fifth Byte (Command arguments)
            D1_write = cmd_args[count - 8];
        else if (count < 48) // Sixth Byte (CRC)
            D1_write = cmd_crc[count - 40];
        else if (count < 56) // DUMMY BYTE
            D1_write = 1'b0;
        else if (count < 64) begin // RECEIVE R1 RESPONSE FROM D0
            write_to_D0 = 1'b0; // Read from D0
            next_response_flags[count - 56] = D0_read;
        end else if (last_byte != 8'hFE) begin // Wait for 0xFE
            write_to_D0 = 1'b0; // Read from D0
            next_last_byte = last_byte << 1 | D0_read;
        end
        if (last_byte == 8'hFE)
            next_last_byte = 8'hFF;

        // if 0xFE has been read, read data transmission (fixed size 32)
        if (last_byte == 8'hFF && data_count < 32) begin
            write_to_D0 = 1'b0; // Read from D0
            next_data_transmission[data_count] = D0_read;
            next_data_count = data_count + 1;
        end
        // Once Read 32, you are finished else timeout when count > 1000
        if (data_count >= 32 || count > 1000)
            done = 1;
    end

endmodule
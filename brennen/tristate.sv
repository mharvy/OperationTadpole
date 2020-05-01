module tristate (
	input logic Clk,
	input logic tristate_output_enable,
	input logic Data_write, // Data to be written to pin
	output logic Data_read, // Data read from pin
	inout wire Data
);
	logic Data_write_buffer, Data_read_buffer;
	
	always_ff @(posedge Clk)
	begin
		// Always read data from the bus
		Data_read_buffer <= Data;
		// Always updated with the data from Mem2IO which will be written to the bus
		Data_write_buffer <= Data_write;
	end
	
	// Drive (write to) Data bus only when tristate_output_enable is active.
	assign Data = tristate_output_enable ? Data_write_buffer : 1'bZ;

	assign Data_read = Data_read_buffer;

endmodule

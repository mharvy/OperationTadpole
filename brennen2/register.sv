module register #(N = 16) (
	input logic [N-1:0] D_In,
	input logic Clk,
	input logic Reset,
	input logic Load,
	output logic [N-1:0] D_Out
);
	always_ff @ (posedge Clk)
		begin
			if (Reset)
				D_Out <= {N{1'b0}};
			else if (Load)
				D_Out <= D_In;
		end
endmodule
s
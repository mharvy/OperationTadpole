module sd_clock (
    input logic clk,
    output logic out_clk
);
    int count, next_count;
    initial begin
        count = 0;
    end

    always_ff @ (posedge clk) begin
        count <= next_count;
    end

    always_comb begin

		  out_clk = (count < 125) ? 1'b0 : 1'b1;
	 
        if (count < 125) begin// out clk low for 500 cycles
            next_count = count + 1;
		  end
        else if (count < 250) begin// out clk high for 500 cycles
            next_count = count + 1;
		  end
		  else begin// reset counter
            next_count = 0;
		  end

    end

endmodule
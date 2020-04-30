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

        out_clk = 1'b0;
        if (count < 500) begin// out clk low for 500 cycles
            next_count = count + 1;
		  end
        else if (count < 1000) begin// out clk high for 500 cycles
            out_clk = 1'b1;
            next_count = count + 1;
		  end
		  else begin// reset counter
            next_count = 0;
		  end

    end

endmodule
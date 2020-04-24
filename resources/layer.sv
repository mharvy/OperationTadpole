module layer #(N = 100) (	input real [N-1:0] d_in,
									input int num,
									input logic clk,
									input logic reset,
									output logic ready,
									output real [N-1:0] d_out	);
									
	// init d_outs to zero before setting ready to 0
	
	enum logic [2:0] {halted, address_calculate, weight_read, node_update} state, next_state;
	
	int right_node, left_node, prev_left_node, prev_right_node;
	int address;
	
	logic addr_calc, weight_rd, node_update;
	real saved_d_out;
	
	always_ff @ (posedge clk)
		begin
			if (ready) begin
				state <= halted;
				prev_right_node <= 0;
				prev_left_node <= 0;
				saved_d_out <= 0;
			end
			else begin
				// gets set every clk
				state <= next_state;
				prev_right_node <= right_node;
				prev_left_node <= left_node;
				// gets set on load
				if (load)
					saved_d_out <= d_out[right_node];
			end
		end
	
	always_comb
	begin
		next_state = state;
		left_node = prev_left_node;
		right_node = prev_right_node;
		
		address = num * (N * N) + N * right_node + left_node;
		// weight = Get float at address!
		
		
		
		// next state logic
		case (state)
			halted:
				if (~ready)
					next_state = address_calculate
			address_calculate:
				next_state = weight_read
			weight_read:
				if (resp)
					next_state = node_update
			node_update:
			begin
				if (~ready)
					next_state = address_calculate
				else
					next_state = halted
			end
		endcase
		
		// output logic
		case (state)
			address_calculate:
				address = num * (N * N) + N * right_node + left_node;
			weight_read:
			begin
				// weight = Get float at address!
				load = 1'b1;
			end
			node_update:
			begin
				d_out[right_node] = saved_d_out + weight * d_in[left_node];
				
				left_node = prev_left_node + 1;
				if (left_node >= N)
					begin
						left_node = 0;
						right_node = prev_right_node + 1;
					end
				if (right_node >= N)
					begin
						right_node = 0
						ready = 1;
					end
			end
	end
	
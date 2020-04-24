module test_toplevel(
    input logic clk,
    input logic reset,


);
    enum logic [X:0] { start_pt, layer_0, layer_1, layer_2, layer_3, ... }   layer, next_layer;
    
    shortreal [9:0] left_nodes, updated_left_nodes, right_nodes; // python determines size based on num input features
    int num, num_next;
    logic start, num, done;

    // initialize linear layer, outputs: done and right_nodes
    layer linear(.d_in(left_nodes),.num,.clk,.start,.done,.d_out(right_nodes));


    always_ff @ (posedge clk) begin
        // state machine
        if (reset) begin
            layer <= start_pt;
            num <= 0;
        end
        else begin
            layer <= next_layer;
            num <= num_next;
            if(update_left_nodes)
                left_nodes  <= updated_left_nodes;
        end
    end

    always_comb begin
        next_layer = layer;
        num_next = num;

        updated_left_nodes = left_nodes
        update_left_nodes = 1'b0;

        // next state logic
        case(layer)
            start_pt: begin
                if(reset)
                    next_layer = layer_0;
            end
            layer_0: begin
                if (done)
                    next_layer = layer_0_reset;
            end
            layer_0_reset: begin
                next_layer = layer_1;
            end
            layer_1: begin
                if (done)
                    next_layer = layer_1_reset;
            end
            layer_1_reset: begin
                next_layer = layer_2;
            end
            layer_2: begin
                if (done)
                    next_layer = layer_2_reset;
            end
            layer_2_reset: begin
                next_layer = finish;
            end
        // output logic
        case(layer)
            layer_0: begin
                // This makes the layer have a certain size by setting certain input nodes to 0.0, effectively deleting their influence in the net
                left_nodes[5] = 0.0;
                left_nodes[6] = 0.0;
                left_nodes[7] = 0.0;
                left_nodes[8] = 0.0;
                left_nodes[9] = 0.0;

                // Start the layer computation
                start = 1'b1;

                if (done) begin
                    // current layer is finished, apply appropriate function and set right_nodes back to the left nodes
                    updated_left_nodes[0] = 1 / 1 + e**right_nodes[0]; // sigmoid is an example
                    updated_left_nodes[1] = 1 / 1 + e**right_nodes[1];
                    updated_left_nodes[2] = 1 / 1 + e**right_nodes[2];
                    updated_left_nodes[3] = 1 / 1 + e**right_nodes[3];
                    updated_left_nodes[4] = 1 / 1 + e**right_nodes[4];
                    updated_left_nodes[5] = 1 / 1 + e**right_nodes[5]; // if 5 past layer size, updated_left_nodes[5] = 0
                    updated_left_nodes[6] = 1 / 1 + e**right_nodes[6]; // if 6 past layer size, updated_left_nodes[5] = 0
                    updated_left_nodes[7] = 1 / 1 + e**right_nodes[7]; // if 7 past layer size, updated_left_nodes[5] = 0
                    updated_left_nodes[8] = 1 / 1 + e**right_nodes[8]; // if 8 past layer size, updated_left_nodes[5] = 0
                    updated_left_nodes[9] = 1 / 1 + e**right_nodes[9]; // if 9 past layer size, updated_left_nodes[5] = 0
                    
                    update_left_nodes = 1'b1;

                    // increment num
                    num_next = num + 1;
                end
            end
            // Reset the layer
            layer_0_reset: begin
                start = 1'b0
            end


            layer_1: begin
                // This makes the layer have a certain size by setting certain input nodes to 0.0, effectively deleting their influence in the net
                left_nodes[8] = 0.0;
                left_nodes[9] = 0.0;

                // Start the layer computation
                start = 1'b1;

                if (done) begin
                    // current layer is finished, apply appropriate function and set right_nodes back to the left nodes
                    updated_left_nodes[0] = 1 / 1 + e**right_nodes[0]; // sigmoid is an example
                    updated_left_nodes[1] = 1 / 1 + e**right_nodes[1];
                    updated_left_nodes[2] = 1 / 1 + e**right_nodes[2];
                    updated_left_nodes[3] = 1 / 1 + e**right_nodes[3];
                    updated_left_nodes[4] = 1 / 1 + e**right_nodes[4];
                    updated_left_nodes[5] = 1 / 1 + e**right_nodes[5];
                    updated_left_nodes[6] = 1 / 1 + e**right_nodes[6];
                    updated_left_nodes[7] = 1 / 1 + e**right_nodes[7];
                    updated_left_nodes[8] = 1 / 1 + e**right_nodes[8];
                    updated_left_nodes[9] = 1 / 1 + e**right_nodes[9];
                    
                    update_left_nodes = 1'b1;

                    // increment num
                    num_next = num + 1;
                end
            end
            layer_1_reset: begin
                start = 1'b0
            end

            layer_2: begin
                // This makes the layer have a certain size by setting certain input nodes to 0.0, effectively deleting their influence in the net
                left_nodes[1] = 0.0;
                left_nodes[2] = 0.0;
                left_nodes[3] = 0.0;
                left_nodes[4] = 0.0;
                left_nodes[5] = 0.0;
                left_nodes[6] = 0.0;
                left_nodes[7] = 0.0;
                left_nodes[8] = 0.0;
                left_nodes[9] = 0.0;

                // Start the layer computation
                start = 1'b1;

                if (done) begin
                    // current layer is finished, apply appropriate function and set right_nodes back to the left nodes
                    updated_left_nodes[0] = 1 / 1 + e**right_nodes[0]; // sigmoid is an example
                    updated_left_nodes[1] = 1 / 1 + e**right_nodes[1];
                    updated_left_nodes[2] = 1 / 1 + e**right_nodes[2];
                    updated_left_nodes[3] = 1 / 1 + e**right_nodes[3];
                    updated_left_nodes[4] = 1 / 1 + e**right_nodes[4];
                    updated_left_nodes[5] = 1 / 1 + e**right_nodes[5];
                    updated_left_nodes[6] = 1 / 1 + e**right_nodes[6];
                    updated_left_nodes[7] = 1 / 1 + e**right_nodes[7];
                    updated_left_nodes[8] = 1 / 1 + e**right_nodes[8];
                    updated_left_nodes[9] = 1 / 1 + e**right_nodes[9];
                    
                    update_left_nodes = 1'b1;

                    // increment num
                    num_next = num + 1;
                end
            end
            layer_2_reset: begin
                start = 1'b0
            end


        
            



    end




endmodule
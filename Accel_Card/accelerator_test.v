module accelerator_adapter_test(
    input clk,
    input aresetn,
    
    // TO/FROM controller
    input                 acc_start,
    output reg            acc_finish

);

reg [6:0]       tmp_cycle_count;
reg [2:0]       current_state;

localparam      WAIT_CYCLES = 7'd100;

localparam      state_idle  = 3'b0,
                state_ack   = 3'b1;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        acc_finish <= 1'b0;
        tmp_cycle_count <= 7'b0;
        current_state <= state_idle;
    end
    else begin
        case (current_state)
            state_idle: begin
                tmp_cycle_count <= tmp_cycle_count + 1;
                if (tmp_cycle_count == WAIT_CYCLES) begin
                    acc_finish <= 1'b1;
                    tmp_cycle_count <= 7'b0;

                    current_state <= state_ack;
                end
            end 

            state_ack: begin
                tmp_cycle_count <= tmp_cycle_count + 1;

                acc_finish <= 1'b0;
                
                current_state <= state_idle;
            end
        endcase
        
    end
end

endmodule
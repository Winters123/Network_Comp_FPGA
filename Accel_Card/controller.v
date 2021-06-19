
module controller(
    input clk,
    input aresetn,

    //from outside
    input                       start_all,

    //TO MONITOR
    output  reg                 ddr_read_start,
    output  reg                 ddr_read_start_valid,
    input                       ddr_read_start_ready,
    
    //TO CAMERA
    output  reg                 ddr_write_start,
    output  reg                 ddr_write_start_valid,
    input                       ddr_write_start_ready,

    //FROM MONITOR
    input                       ddr_read_finish,
    input                       ddr_read_finish_valid,
    output  reg                 ddr_read_finish_ready,

    //FROM CAMERA
    input                       ddr_write_finish,
    input                       ddr_write_finish_valid,
    output  reg                 ddr_write_finish_ready,

    //TO/FROM ACCEL
    output  reg                 acc_start,
    input                       acc_finish,

    input                       cmd_in_wr,
    input           [63:0]      cmd_in,
    output  reg                 cmd_in_alf,

    output 	reg 				cmd_out_wr	,//command write signal
	output 	reg 	[63:0] 		cmd_out		,//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	input 						cmd_out_alf,	 //commadn almostful
    
    output reg                  odd_even_flag
);
    

//bypass accelerator
reg [2:0]  test_state;
reg [10:0] wait_counter;

localparam IDLE_T = 0,
           CAM_T = 1,
           MONI_T = 2,
           WAIT_T = 3;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        odd_even_flag <= 1'b0;
        test_state <= IDLE_T;
        ddr_write_finish_ready <= 1'b1;
        ddr_read_finish_ready <= 1'b1;

        ddr_write_start <= 1'b0;
        ddr_write_start_valid <= 1'b0;

        ddr_read_start <= 1'b0;
        ddr_read_start_valid <= 1'b0;
        
        wait_counter <= 0;
    end
    else begin
        case(test_state)
            IDLE_T: begin
                if(ddr_write_start_ready & start_all) begin
                    //trigger remote camera
                    cmd_out[63:61] <= 3'b100;
                    cmd_out[60]    <= 1'b1;
                    cmd_out[31:0]  <= 32'b1;
                    cmd_out_wr     <= 1'b1;

                    ddr_write_start <= 1'b1;
                    ddr_write_start_valid <= 1'b1;

                    ddr_write_finish_ready <= 1'b1;

                    test_state <= CAM_T;
                end
                else begin
                    //do nothing
                    test_state <= IDLE_T;
                end
            end
            CAM_T: begin
                if(ddr_write_finish & ddr_write_finish_valid & ddr_read_start_ready) begin
                    ddr_write_start <= 1'b0;
                    ddr_write_start_valid <= 1'b0;

                    ddr_write_finish_ready <= 0;
                    ddr_read_start <= 1'b1;
                    ddr_read_start_valid <= 1'b1;
                    ddr_read_finish_ready <= 1'b1;
                    test_state <= MONI_T;
                end
                else begin
                    test_state <= CAM_T;
                end
            end

            MONI_T: begin
                if(ddr_read_finish & ddr_read_finish_valid) begin
                    ddr_read_finish_ready <= 1'b0;
                    odd_even_flag <= ~odd_even_flag;

                    ddr_read_start <= 1'b0;
                    ddr_read_start_valid <= 1'b0;
                    test_state <= WAIT_T;
                end
            end

            WAIT_T: begin
                if(wait_counter == 10) begin
                    wait_counter <= 0;
                    test_state <= IDLE_T;
                end
                else begin
                    wait_counter <= wait_counter + 1;
                    test_state <= WAIT_T;
                end
            end
        endcase
    end
end


// reg accel_done_flag;

// reg [3:0] ctrl_state;

// localparam IDLE_C = 4'd0,
//            TRI_CAMERA_C = 4'd1,
//            TRI_ACCEL_C = 4'd2,
//            TRI_MONIT_C = 4'd3;

// always @(posedge clk or negedge aresetn) begin
//     if(~aresetn) begin
//         ddr_read_start <= 1'b0;
//         ddr_read_start_valid <= 1'b0;
//         ddr_write_start <= 1'b0;
//         ddr_write_start_valid <= 1'b0;
        
//         ddr_read_finish_ready <= 1'b0;
//         ddr_write_finish_ready <= 1'b0;

//         acc_start <= 1'b0;

//         cmd_in_alf <= 1'b1;
//         cmd_out_wr <= 1'b0;
//         cmd_out <= 64'b0;
//         ctrl_state <= 0;

//         odd_even_flag <= 1'b0;
//     end

//     else begin
//         case(ctrl_state) 
//             IDLE_C: begin
//                 if(start_all || (ddr_read_finish && ddr_read_finish_valid)) begin
//                     //trigger remote camera
//                     cmd_out[63:61] <= 3'b100;
//                     cmd_out[60]    <= 1'b1;
//                     cmd_out[31:0]  <= 32'b1;
//                     cmd_out_wr     <= 1'b1;
//                     odd_even_flag <= ~odd_even_flag;
//                     ctrl_state <= TRI_CAMERA_C;
//                 end

//                 else begin
//                     cmd_out[63:61] <= 0;
//                     cmd_out[60]    <= 0;
//                     cmd_out[31:0]  <= 0;
//                     cmd_out_wr     <= 0;
//                 end
//             end
            
//             TRI_CAMERA_C: begin
//                 cmd_out[63:61] <= 0;
//                 cmd_out[60]    <= 0;
//                 cmd_out[31:0]  <= 0;
//                 cmd_out_wr     <= 0;
                
//                 if(ddr_write_start_ready) begin
//                     ddr_write_start <= 1'b1;
//                     ddr_write_start_valid <= 1'b1;
//                     ddr_write_finish_ready <= 1'b1;
//                 end

//                 if(ddr_write_finish_valid && ddr_write_finish) begin
//                     //reset ddr_write_start
//                     ddr_write_start <= 1'b0;
//                     ddr_write_start_valid <= 1'b0;
//                     ddr_write_finish_ready <= 1'b0;
//                     //trigger acclerator if its waiting
//                     if(accel_done_flag) begin
//                         acc_start <= 1'b1;
//                         ctrl_state <= TRI_ACCEL_C;
//                     end
//                 end
//             end

//             TRI_ACCEL_C: begin
//                 acc_start <= 1'b0;
//                 if(acc_finish) ctrl_state <= TRI_MONIT_C;
//             end

//             TRI_MONIT_C: begin
//                 if(ddr_read_start_ready) begin
//                     ddr_read_start <= 1'b1;
//                     ddr_read_start_valid <= 1'b1;
//                     ddr_read_finish_ready <= 1'b1;
//                     ctrl_state <= IDLE_C;
//                 end
//             end
//         endcase
//     end
// end



// always @(posedge clk or negedge aresetn) begin
//     if(~aresetn) begin
//         accel_done_flag <= 1'b0;
//     end
//     else if(acc_finish) begin
//         accel_done_flag <= 1'b1;
//     end
//     else if(acc_start) begin
//         accel_done_flag <= 1'b0;
//     end
//     else begin
//         accel_done_flag <= accel_done_flag;
//     end
// end

endmodule
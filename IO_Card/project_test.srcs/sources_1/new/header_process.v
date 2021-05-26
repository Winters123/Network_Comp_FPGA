`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/23 08:45:45
// Design Name: 
// Module Name: header_process
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module header_process(
    input i_sys_clk,
    input i_sys_rst_n,

    //==  data from PREPARSER == //
    input          [519:0]      o_dpkt_data                     //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
    ,input                       o_dpkt_data_en                  //data enable
    ,output                         i_dpkt_fifo_alf                 //fifo almostfull

    //== data communicate with afifo_128i_32o_128 == //
    ,output reg [127:0] o_data_to_afifo
    ,input i_almost_full_afifo
    ,output reg o_wr_en_afifo
    ,input i_wr_rst_busy_afifo
    ,output reg o_reset_afifo

    // write req to cmos write req gen
    ,output reg new_frame_comming
    );

    reg [3:0] state ;

    localparam IDEL = 0;
    localparam PROCESS_HEADER= 1;
    localparam RESET_FIFO = 2;
    localparam DETECT_DATA_TEMP = 3;
    localparam READY_FOR_WRITEIN = 4;
    localparam WRITE_AFIFO_0 = 5;
    localparam WRITE_AFIFO_1 = 6;
    localparam WRITE_AFIFO_2 = 7;
    localparam WRITE_AFIFO_3 = 8;
    localparam CHECK_LAST_TEMP = 9;

reg [519:0] frame_header;
reg [519:0] frame_data;
reg [4:0] reset_counter;

reg [9:0] frame_num;
reg [4:0] local_beat_num;
reg [13:0] total_beat_num;




always @(posedge i_sys_clk or negedge i_sys_rst_n ) begin
    if(~i_sys_rst_n)begin
        state <= IDEL;
    end
    else begin
        case (state)
            IDEL: begin
                if(~data_fifo_empty)begin    // data_fifo 丝为空，表明FIFO里面存有报文�??????
                    state <= RESET_FIFO;
                end
            end
            RESET_FIFO:begin
                if(reset_counter == 5'd30)begin
                    state <= PROCESS_HEADER;
                end
            end
            PROCESS_HEADER: begin
                if(data_fifo_rden_d0 && data_fifo_out[519:518] == 2'b10)begin
                    state <= DETECT_DATA_TEMP;
                end
                else if(data_fifo_rden_d0 && data_fifo_out[519:518] != 2'b10)begin
                    state <= IDEL;
                end
                else begin
                    state <= PROCESS_HEADER;
                end
            end
            DETECT_DATA_TEMP:begin
                if(data_fifo_rden_d0 && data_fifo_out[519:518] != 2'b10)begin
                    state <= READY_FOR_WRITEIN;
                end
                else begin
                    state <= DETECT_DATA_TEMP;
                end
            end
            READY_FOR_WRITEIN:begin
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    state <= WRITE_AFIFO_0;
                end
            end
            WRITE_AFIFO_0:begin
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    state <= WRITE_AFIFO_1;
                end
            end
            WRITE_AFIFO_1:begin
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    state <= WRITE_AFIFO_2;
                end
            end
            WRITE_AFIFO_2:begin
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    state <= WRITE_AFIFO_3;
                end
            end
            WRITE_AFIFO_3:begin
                if((total_beat_num == 14'd9600))begin
                    state <= CHECK_LAST_TEMP;
                end
                else if (local_beat_num == 5'd16) begin // ???????????
                    state <= PROCESS_HEADER;
                end
                else begin
                    state <= DETECT_DATA_TEMP;
                end
            end
            CHECK_LAST_TEMP:begin
                state <= IDEL;
            end
            default: begin
                state <= IDEL;
            end
        endcase
    end
end

reg data_fifo_rden;
reg data_fifo_rden_d0;
wire [519 : 0] data_fifo_out;


always @(posedge i_sys_clk or negedge i_sys_rst_n ) begin
    if(~i_sys_rst_n)begin
        data_fifo_rden <= 1'b0;
        reset_counter <= 0;
        frame_num <= 10'd0;
        local_beat_num <= 5'd0;
        total_beat_num <= 14'd0;
        new_frame_comming <= 'd0;
        o_reset_afifo <= 'd0;
    end
    else begin
        case (state)
            IDEL: begin
                if(~data_fifo_empty)begin    // data_fifo 丝为空，表明FIFO里面存有报文�??????
                //     data_fifo_rden <= 1'b1;
                    o_reset_afifo <= 1'b1;
                end
                frame_num <= 'd0;
            end
            RESET_FIFO:begin
                o_reset_afifo <= 1'b0;
                reset_counter <= reset_counter + 5'd1;
                if(reset_counter == 5'd30)begin
                    reset_counter <= 5'd0;
                    data_fifo_rden <= 1'b1;
                end
            end
            PROCESS_HEADER: begin
                data_fifo_rden <= 1'b0;
                data_fifo_rden_d0 <= data_fifo_rden;
                if(data_fifo_rden_d0 && data_fifo_out[519:518] == 2'b10)begin
                    frame_header <= data_fifo_out;
                    frame_num <= frame_num + 10'd1;
                    data_fifo_rden <= 1'b0;

                    if(frame_num == 10'd0)begin
                        new_frame_comming <= 1'b1;
                    end
                    else begin
                        new_frame_comming <= 1'b0;
                    end
                end
                else if(data_fifo_empty)begin
                    data_fifo_rden <= 1'b0;
                end
                else if(~(data_fifo_rden_d0 || data_fifo_rden))begin
                    data_fifo_rden <= 1'b1;
                end
            end
            DETECT_DATA_TEMP:begin
                data_fifo_rden <= 1'b0;
                data_fifo_rden_d0 <= data_fifo_rden;
                        new_frame_comming <= 1'b0;      // this will generate write req
                if(data_fifo_rden_d0 && data_fifo_out[519:518] != 2'b10)begin
                    data_fifo_rden <= 1'b0;
                    frame_data <= data_fifo_out;       //报文头部信息
                    local_beat_num <= local_beat_num + 5'd1;
                    total_beat_num <= total_beat_num + 14'd1;
                end
                else if(data_fifo_empty)begin
                    data_fifo_rden <= 1'b0;
                end
                else if(~(data_fifo_rden_d0 || data_fifo_rden)) begin
                    data_fifo_rden <= 1'b1;
                end
            end
            READY_FOR_WRITEIN:begin
                    o_wr_en_afifo <= 1'b0;
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    o_data_to_afifo <= frame_data[511:384];
                    o_wr_en_afifo <= 1'b1;
                end
            end
            WRITE_AFIFO_0:begin
                    o_wr_en_afifo <= 1'b0;
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    o_data_to_afifo <= frame_data[383:256];
                    o_wr_en_afifo <= 1'b1;
                end
            end
            WRITE_AFIFO_1:begin
                    o_wr_en_afifo <= 1'b0;
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    o_data_to_afifo <= frame_data[255:128];
                    o_wr_en_afifo <= 1'b1;
                end
            end
            WRITE_AFIFO_2:begin
                    o_wr_en_afifo <= 1'b0;
                if((~i_almost_full_afifo) && (~i_wr_rst_busy_afifo))begin
                    o_data_to_afifo <= frame_data[127:0];
                    o_wr_en_afifo <= 1'b1;
                end
            end
            WRITE_AFIFO_3:begin
                    o_wr_en_afifo <= 1'b0;
                if((total_beat_num == 14'd9600))begin
                    total_beat_num <= 14'd0;
                end
                else if (local_beat_num == 5'd16) begin
                    local_beat_num <= 5'd0;
                end
            end
            CHECK_LAST_TEMP:begin

            end
            default: begin
            end
        endcase
    end
end



// 该模块完戝数杮的接收，并存入FIFO模块等待坎续擝作�??????
data_fifo data_fifo_i0 (
  .clk(i_sys_clk),      // input wire clk
  .srst(~i_sys_rst_n),    // input wire srst
  .din(o_dpkt_data),      // input wire [519 : 0] din
  .wr_en(o_dpkt_data_en),  // input wire wr_en
  .rd_en(data_fifo_rden),  // input wire rd_en
  .dout(data_fifo_out),    // output wire [519 : 0] dout
  .full(full),    // output wire full
  .almost_full(i_dpkt_fifo_alf),  // output wire almost_full
  .empty(data_fifo_empty)  // output wire empty
);


endmodule


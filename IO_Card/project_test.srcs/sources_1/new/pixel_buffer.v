module pixel_buffer (
//============================================== clk & rst ===========================================//

//system clock & resets
 input                      i_sys_clk                       //system clk
,input                      i_sys_rst_n                     //rst of sys_clk
//=========================================== Input data pkt  ==========================================//
,input          [519:0]      o_dpkt_data                     //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input                       o_dpkt_data_en                  //data enable
,output                         i_dpkt_fifo_alf                 //fifo almostfull

//=========================================== Pixel data output to div encoder =========================//
,output                      pixelclk       // system clock
,output                      pixelclk5x     // system clock x5
,output         [15:0]       vout_data      //video data
,output                      hs                 // horizontal synchronization
,output                      vs                 // vertical synchronization
,output                      de                 // video valid
);
//======================================== internal wires========================================//
        wire video_clk;
        wire video_clk5x;
        assign pixelclk = video_clk;
        assign pixelclk5x = video_clk5x;
        wire data_fifo_empty;
        wire [519 : 0] data_fifo_out;
        reg  [512 : 0] data_fifo_o;
        reg data_fifo_o_valid;
        reg  [519 : 0] data_fifo_o_head;
        wire [13 : 0] dram0_in_addr;
        wire [13 : 0] dram1_in_addr;
        assign dram0_in_addr = dram_0_write_n?dram_write_addr_d2:dram_read_addr;
        assign dram1_in_addr = dram_0_write_n?dram_read_addr:dram_write_addr_d2;
        reg [511 : 0] dram_in_data;
        reg dram0_in_we;
        reg dram1_in_we;
        wire [511 : 0] dram0_out;
        wire [511 : 0] dram0_out;
        reg current_write_dram;
        reg dram_write_done;
        reg [13:0] dram_write_addr;
        reg [13:0] dram_write_addr_d1;
        reg [13:0] dram_write_addr_d2;
        reg [13:0] dram_read_addr;
        reg dram_0_write_n;     // 控制DRAM的读写顺序，1时写DRAM1，读DRAM0; 0时写DRAM0,读DRAM1。
        // reg [511 : 0] dram_write_data;
        // wire                            hdmi_hs;
        // wire                            hdmi_vs;
        // wire                            hdmi_de;
        // output[7:0]                       hdmi_r;
        // output[7:0]                       hdmi_g;
        // output[7:0]                       hdmi_b;
        wire[31:0]                      vout_data;              //video data
        wire                            read_en_cam;                //read enable
        wire[15:0]                      read_data_cam;              //read data
        wire                            read_req_cam;               //read request
        reg                            read_req_ack_cam;           //read request response  
        // assign hdmi_hs     = hs;
        // assign hdmi_vs     = vs;
        // assign hdmi_de     = de;
        // assign hdmi_r      = {vout_data[15:11],3'd0};
        // assign hdmi_g      = {vout_data[10:5],2'd0};
        // assign hdmi_b      = {vout_data[4:0],3'd0};
        reg fifo_write_done;
        wire [511 : 0] dram0_out;
        wire [511 : 0] dram1_out;
        wire [511 : 0] dram_out;
        assign dram_out = dram_0_write_n?dram0_out:dram1_out;
        reg [511 : 0] dram_out_reg;
        reg pixel_fifo_we;
        reg [127:0] pixel_data_in;
        wire [5:0] fifo_pixel_count;
        reg data_fifo_rden;
        reg [1:0] fifo_write_count;
        
//======================================== internal wires========================================//
    
localparam HEAD_OF_DATA = 64'd14114;
//======================================== state machine param========================================//
    reg [2:0] state_wr;        //状态
    reg [2:0] state_rd;        //状态

    localparam INIT_S0  = 3'b000;//0     复位
    localparam IDLE_S0  = 3'b001;//1     IDEL
    localparam FDAT_S0  = 3'b011;//3     处理第一个512b报文头
    localparam WDAT_S0  = 3'b010;//2     剩余图像数据写入DRAM
    localparam EDAT_S0  = 3'b110;//6     写完图像数据
    localparam WAIT_S0  = 3'b111;//7     等待切换DRAM时机
    localparam TRAN_S0  = 3'b101;//5     切换DRAM
    localparam DONE_S0  = 3'b100;//4     完成数据更新操作

    localparam INIT_S1  = 3'b000;//0     上电复位
    localparam IDLE_S1  = 3'b001;//1     帧同步信号复位
    localparam READ_S1  = 3'b011;//3     读DRAM
    localparam PROS_S1  = 3'b010;//2     处理DRAM读出的数据
//======================================== state machine param========================================//

//======================================== state machine for write dram===============================//
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        state_wr <= INIT_S0;
    end
    else begin
        case(state_wr)
        INIT_S0:begin                                       // 上电复位
            state_wr <= IDLE_S0;
        end
        IDLE_S0:begin                                        // IDEL
            if(~data_fifo_empty)begin    // data_fifo 不为空，表明FIFO里面存有报文。
                state_wr <= FDAT_S0;
            end
        end
        FDAT_S0:begin                                        // 处理第一个512b报文头
            if(data_fifo_rden)begin
                state_wr <= WDAT_S0;
            end
        end
        WDAT_S0:begin                                        // 剩余图像数据写入DRAM
            if(dram_write_addr == 14'd9600)begin // 9600 * 512
                state_wr <= EDAT_S0;
            end
        end
        EDAT_S0:begin                                        // 写完图像数据
            state_wr <= WAIT_S0;
        end
        WAIT_S0:begin                                        // 等待切换DRAM时机
            if(read_req_cam)begin       // 发出了读请求
                state_wr <= TRAN_S0;
                read_req_ack_cam <= 1'b1;
            end
        end
        TRAN_S0:begin                                        // 切换DRAM
            if(~read_req_cam)begin       // 读请求回复收到
                read_req_ack_cam <= 1'b0;
            end
            state_wr <= DONE_S0;
        end
        DONE_S0:begin                                        // 完成数据更新操作
            state_wr <= IDLE_S0;
        end
        default: begin
            state_wr <= INIT_S0;
        end
        endcase
    end
end
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        data_fifo_rden <= 1'b0;
        data_fifo_o <= 512'd0;
        data_fifo_o_head <= 520'd0;
        dram_write_addr <= 'd0;
        // dram_write_data <= 520'd0;
        dram_0_write_n <= 'd0;
        data_fifo_o_valid <= 'd0;
    end
    else begin
        case(state_wr)
        INIT_S0:begin                                       // 上电复位
        end
        IDLE_S0:begin                                        // IDEL
        end
        FDAT_S0:begin                                        // 处理第一个512b报文头
            if(data_fifo_rden)begin
                data_fifo_rden <= 1'b0;
                data_fifo_o_head <= data_fifo_out;       //报文头部信息
            end
            else begin
                data_fifo_rden <= 1'b1;
                dram_write_addr <= 14'd0; // begin with addr 0
                // dram_write_addr <= 14'd9597; // begin with addr 0 //for test
            end
        end
        WDAT_S0:begin                                        // 剩余图像数据写入DRAM
            data_fifo_o_valid <= 1'b0;
            data_fifo_rden <= 1'b0;
            //以下两个语句块每次至多执行一个，保证FIFO里面数据只有一个时的数据准确性
            if(data_fifo_rden)begin
                data_fifo_o <= data_fifo_out;
                data_fifo_o_valid <= 1'b1;
                dram_write_addr_d1 <= dram_write_addr;
                dram_write_addr <= dram_write_addr + 14'd1;
            end
            else if(~data_fifo_empty) begin
                data_fifo_rden <= 1'b1;
            end
            if(data_fifo_o_valid)begin
                dram_in_data <= data_fifo_o;
                dram_write_addr_d2 <= dram_write_addr_d1;
                dram1_in_we <= dram_0_write_n;      // 这里控制了读写的。后续只需要完成读出数据的MUX即可
                dram0_in_we <= ~dram_0_write_n;
            end
            else begin
                dram1_in_we <= 1'b0;
                dram0_in_we <= 1'b0;
            end
            if(dram_write_addr == 14'd9600)begin
                dram1_in_we <= 1'b0;
                dram0_in_we <= 1'b0;
            end
        end
        EDAT_S0:begin                                        // 写完图像数据
            data_fifo_rden <= 1'b0;
        end
        WAIT_S0:begin                                        // 等待切换DRAM时机
        end
        TRAN_S0:begin                                        // 切换DRAM
            if(~read_req_cam)begin       // 读请求回复收到
                dram_0_write_n <= ~dram_0_write_n;
            end
        end
        DONE_S0:begin                                        // 完成数据更新操作
        end
        default: begin
        end
        endcase
    end
end
//======================================== state machine for write dram===============================//

//======================================== state machine for read dram===============================//
//该状态机完成从DRAM中读取数据，并写入到FIFO中的功能，主要有三个状态
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        state_rd <= INIT_S1;
    end
    else begin
        case(state_rd)
        INIT_S1:begin                                       // 上电复位
            state_rd <= IDLE_S1;
        end
        IDLE_S1:begin                                        // IDEL,监控FIFO容量大小
            if(fifo_pixel_count <= 6'd50)begin  // 后级的FIFO里面有64 x 128的容量大小，这里取14的阈值。
                state_rd <= READ_S1;
            end
        end
        READ_S1:begin                                        // 读DRAM

        end
        PROS_S1:begin                                        // 处理读出的数据，写入FIFO，大写入位宽情况下，写入速度大于读出速度。
            if((dram_read_addr == 14'd9600) && (fifo_write_done))begin   //读完了一帧图像的所有数据，跳回IDEL状态等待帧同步信号。
                state_rd <= IDLE_S1;
            end
            else if((fifo_pixel_count <= 6'd50) && (fifo_write_done))begin  // 后级的FIFO里面有64 x 128的容量大小，这里取14的阈值。
                state_rd <= READ_S1;
            end
            else if(fifo_write_done)begin
                state_rd <= PROS_S1;
            end
        end
        default: begin
            state_rd <= IDLE_S1;
        end
        endcase
    end
end
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        dram_read_addr <= 14'd0;
        fifo_write_done <= 'd0;
        fifo_write_count <= 2'd0;
    end
    else begin
        case(state_rd)
        INIT_S1:begin                                       // 上电复位
        end
        IDLE_S1:begin                                        // IDEL
            
        end
        READ_S1:begin                                        // 读DRAM
            fifo_write_done <= 'd0;
        end
        PROS_S1:begin                                        // 处理读出的数据，写入FIFO，大写入位宽情况下，写入速度大于读出速度。
            pixel_fifo_we <= 1'b0;
            if(fifo_write_done)begin        //读写完了，在此等待。
                dram_read_addr <= dram_read_addr + 14'd1;
                if(dram_read_addr == 14'd9599)begin   //读完了一帧图像的所有数据，跳回IDEL状态等待帧同步信号。
                    dram_read_addr <= 14'd0;
                end
            end
            else begin
                pixel_fifo_we <= 1'b1;
                case (fifo_write_count)
                    2'b00:begin
                        pixel_data_in <= dram_out[511:384];
                        fifo_write_count <= fifo_write_count + 2'b01;
                    end 
                    2'b01:begin
                        pixel_data_in <= dram_out[383:256];
                        fifo_write_count <= fifo_write_count + 2'b01;
                    end 
                    2'b10:begin
                        pixel_data_in <= dram_out[255:128];
                        fifo_write_count <= fifo_write_count + 2'b01;
                    end 
                    2'b11:begin
                        fifo_write_done <= 'd1;
                        pixel_data_in <= dram_out[127:0];
                        fifo_write_count <= fifo_write_count + 2'b01;
                    end 
                    default: begin
                        pixel_data_in <= 128'd0;
                        fifo_write_count <= 'd0;
                    end
                endcase
            end
        end
        default: begin
        end
        endcase
    end
end
//======================================== state machine for read dram===============================//

// 这个PLL模块是为了生成视频相关的时钟，后续输入dvi_encoder模块。
video_pll video_pll_m0
(
.clk_in1                        (i_sys_clk                  ),
.clk_out1                       (video_clk                ),
.clk_out2                       (video_clk5x              ),
.resetn                          (1'b1                     )
// .locked                         (                         )
);

// 该模块完成数据的接收，并存入FIFO模块等待后续操作。
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

// 以下两个模块进行缓冲式地读写，从而在显示端不冲突。
frame_dram_9600_512_0 frame_dram0 (
  .a(dram0_in_addr),      // input wire [13 : 0] a
  .d(dram_in_data),      // input wire [511 : 0] d
  .clk(i_sys_clk),  // input wire clk
  .we(dram0_in_we),    // input wire we
  .spo(dram0_out)  // output wire [511 : 0] spo
);
frame_dram_9600_512_1 frame_dram1 (
  .a(dram1_in_addr),      // input wire [13 : 0] a
  .d(dram_in_data),      // input wire [511 : 0] d
  .clk(i_sys_clk),  // input wire clk
  .we(dram1_in_we),    // input wire we
  .spo(dram1_out)  // output wire [511 : 0] spo
);

// 该模块自动生成行同步信号和场同步信号，生成读请求
// 该模块以及FIFO读出端口以及dvi_encoder均使用单独的video_clk时钟。
video_timing_data video_timing_data_m0 
(
.video_clk                      (video_clk                 ),
.rst                            (~i_sys_rst_n              ),
.read_req                       (read_req_cam              ),
.read_req_ack                   (read_req_ack_cam          ),
.read_en                        (read_en_cam               ),//这个信号一旦为高，就需要连续地给进去信号
.read_data                      (read_data_cam             ),
.hs                             (hs                        ),
.vs                             (vs                        ),
.de                             (de                        ),
.vout_data                      (vout_data                 )
);

// 该模块配合状态机完成时钟频率的隔离，同时给显示模块提供数据
// 128*64 
pixel_fifo_display pixel_fifo (
  .wr_clk(i_sys_clk),                // input wire wr_clk
  .wr_rst(~i_sys_rst_n),                // input wire wr_rst
  .rd_clk(video_clk),                // input wire rd_clk
  .rd_rst(~i_sys_rst_n),                // input wire rd_rst
  .din(pixel_data_in),                      // input wire [127 : 0] din
  .wr_en(pixel_fifo_we),                  // input wire wr_en
  .rd_en(read_en_cam),                  // input wire rd_en
  .dout(read_data_cam),                    // output wire [15 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .wr_data_count(fifo_pixel_count)  // output wire [5 : 0] wr_data_count
);

endmodule
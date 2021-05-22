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

        reg [511 : 0] dram_in_data;
        reg dram0_in_we;
        reg dram1_in_we;
        reg current_write_dram;
        reg dram_write_done;
        reg [13:0] dram_write_addr;
        reg [13:0] dram_write_addr_d1;
        reg [13:0] dram_write_addr_d2;
        reg [13:0] dram_read_addr;
        reg dram_0_write_n;     // 控制DRAM的读写顺序，1时写DRAM1，读DRAM0; 0时写DRAM0,读DRAM1�???
        
        assign dram0_in_addr = dram_0_write_n?dram_read_addr:dram_write_addr_d2;
        assign dram1_in_addr = dram_0_write_n?dram_write_addr_d2:dram_read_addr;
        // reg [511 : 0] dram_write_data;
        // wire                            hdmi_hs;
        // wire                            hdmi_vs;
        // wire                            hdmi_de;
        // output[7:0]                       hdmi_r;
        // output[7:0]                       hdmi_g;
        // output[7:0]                       hdmi_b;
        // wire[31:0]                      vout_data;              //video data
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
    reg [2:0] state_wr;        //状�??
    reg [2:0] state_rd;        //状�??

    localparam INIT_S0  = 3'b000;//0     复位
    localparam IDLE_S0  = 3'b001;//1     IDEL
    localparam FDAT_S0  = 3'b011;//3     处理第一�???512b报文�???
    localparam WDAT_S0  = 3'b010;//2     剩余图像数据写入DRAM
    localparam EDAT_S0  = 3'b110;//6     写完图像数据
    localparam WAIT_S0  = 3'b111;//7     等待切换DRAM时机
    localparam TRAN_S0  = 3'b101;//5     切换DRAM
    localparam DONE_S0  = 3'b100;//4     完成数据更新操作

    localparam INIT_S1  = 3'b000;//0     上电复位
    localparam IDLE_S1  = 3'b001;//1     帧同步信号复�???
    localparam READ_S1  = 3'b011;//3     读DRAM
    localparam PROS_S1  = 3'b010;//2     处理DRAM读出的数�???
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
            if(~data_fifo_empty)begin    // data_fifo 不为空，表明FIFO里面存有报文�???
                state_wr <= FDAT_S0;
            end
        end
        FDAT_S0:begin                                        // 处理第一�???512b报文�???
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
            if(~read_req_cam)begin       // 读请求回复收�???
                read_req_ack_cam <= 1'b0;
                state_wr <= DONE_S0;
            end
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
        dram1_in_we <= 1'b0;
        dram0_in_we <= 1'b0;
        dram_write_addr_d1 <= 'd0;
        dram_in_data <= 512'd0;
        dram_write_addr_d2 <= 'd0;
    end
    else begin
        case(state_wr)
        INIT_S0:begin                                       // 上电复位
        end
        IDLE_S0:begin                                        // IDEL
        end
        FDAT_S0:begin                                        // 处理第一�???512b报文�???
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
            //以下两个语句块每次至多执行一个，保证FIFO里面数据只有�???个时的数据准确�??
            if(data_fifo_rden)begin
                data_fifo_o <= data_fifo_out[511:0];
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
                dram1_in_we <= dram_0_write_n;      // 这里控制了读写的。后续只�???要完成读出数据的MUX即可
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
            if(~read_req_cam)begin       // 读请求回复收�???
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
//该状态机完成从DRAM中读取数据，并写入到FIFO中的功能，主要有三个状�??
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
            if(fifo_pixel_count <= 6'd32 && (read_req_cam))begin  // 后级的FIFO里面�???64 x 128的容量大小，这里�???14的阈值�??
                state_rd <= READ_S1;
            end
        end
        READ_S1:begin                                        // 读DRAM
            state_rd <= PROS_S1;
        end
        PROS_S1:begin                                        // 处理读出的数据，写入FIFO，大写入位宽情况下，写入速度大于读出速度�???
            if((dram_read_addr == 14'd9599) && (fifo_write_done))begin   //读完了一帧图像的�???有数据，跳回IDEL状�?�等待帧同步信号�???
                state_rd <= IDLE_S1;
            end
            else if((fifo_pixel_count <= 6'd32) && (fifo_write_done))begin  // 后级的FIFO里面�???64 x 128的容量大小，这里�???14的阈值�??
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
        pixel_data_in <= 128'd0;
        pixel_fifo_we <= 1'b0;
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
        PROS_S1:begin                                        // 处理读出的数据，写入FIFO，大写入位宽情况下，写入速度大于读出速度�???
            pixel_fifo_we <= 1'b0;
            if(fifo_write_done)begin        //读写完了，在此等待�??
                if(dram_read_addr == 14'd9599)begin   //读完了一帧图像的�???有数据，跳回IDEL状�?�等待帧同步信号�???
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
                        dram_read_addr <= dram_read_addr + 14'd1;
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

// 这个PLL模块是为了生成视频相关的时钟，后续输入dvi_encoder模块�???
video_pll video_pll_m0
 (
       // Clock out ports
    .clk_out1(video_clk),     // output clk_out1
    .clk_out2(video_clk5x),     // output clk_out2
    // Status and control signals
    .resetn(i_sys_rst_n), // input resetn
   // Clock in ports
    .clk_in1(i_sys_clk));      // input clk_in1


// 该模块完成数据的接收，并存入FIFO模块等待后续操作�???
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

// wire clk_200;
//   clk_200M instance_name
//    (
//     // Clock out ports
//     .clk_out1(clk_200),     // output clk_out1
//     // Status and control signals
//     .resetn(i_sys_rst_n), // input resetn
//     .locked(),       // output locked
//    // Clock in ports
//     .clk_in1(i_sys_clk));      // input clk_in1

//   MIG_DDR3 u_MIG_DDR3 (
//     // Memory interface ports
//     .ddr3_addr                      (ddr3_addr),  // output [14:0]		ddr3_addr   
//     .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba         
//     .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n  
//     .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
//     .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
//     .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
//     .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
//     .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
//     .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
//     .ddr3_dq                        (ddr3_dq),  // inout [31:0]		ddr3_dq
//     .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [3:0]		ddr3_dqs_n
//     .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [3:0]		ddr3_dqs_p
//     .init_calib_complete            (init_calib_complete),  // output			init_calib_complete
//     .ddr3_dm                        (ddr3_dm),  // output [3:0]		ddr3_dm
//     .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt

//     // Application interface ports

//     .app_addr                       (app_addr),  // input [28:0]		app_addr                // 操作地址 rank + bank + row + column
//     .app_cmd                        (app_cmd),  // input [2:0]		app_cmd                     // 操作指令，和操作地址同时出现�?? �??3'd000 �??3‘b001
//     .app_en                         (app_en),  // input				app_en                      // 指令使能信号，高时地�??才有�??
//     .app_wdf_data                   (app_wdf_data),  // input [255:0]		app_wdf_data        // 写入DDR的数�??
//     .app_wdf_end                    (app_wdf_end),  // input				app_wdf_end         // 表示�??后一个写�??
//     .app_wdf_wren                   (app_wdf_wren),  // input				app_wdf_wren        // 写入数据使能�?? 高时写入数据才有�??
//     .app_rd_data                    (app_rd_data),  // output [255:0]		app_rd_data         // 读出的数�??
//     .app_rd_data_end                (app_rd_data_end),  // output			app_rd_data_end     // 表示�??后一个读出时钟周�??
//     .app_rd_data_valid              (app_rd_data_valid),  // output			app_rd_data_valid   // 读数据有�??
//     .app_rdy                        (app_rdy),  // output			app_rdy                     
//     .app_wdf_rdy                    (app_wdf_rdy),  // output			app_wdf_rdy

//     .app_sr_req                     (1'b0),  // input			app_sr_req                  // 保留功能，不用管
//     .app_ref_req                    (1'b0),  // input			app_ref_req
//     .app_zq_req                     (1'b0),  // input			app_zq_req
//     .app_sr_active                  (app_sr_active),  // output			app_sr_active
//     .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack
//     .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack
    
//     .ui_clk                         (ui_clk),  // output			ui_clk                      // 用户逻辑时钟输出 此处4:1模式 �??100MHz
//     .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst     // 高电平用户�?�辑复位输出�?? 与ui_clk同步
//     .app_wdf_mask                   (0),  // input [31:0]		app_wdf_mask                    // 输出mask ，据说一直为0即可

//     // System Clock Ports

//     .sys_clk_i                       (clk_200),
//     .sys_rst                        (i_sys_rst_n) // input sys_rst
//     );


// 这两个由于容量限制，不能够使用，改用上面的BRAM; BRAM 只够存储半幅图像，也不够。�?�虑使用DDR进行存储�??
frame_dram_9600_512_0 frame_dram0 (     //96*512
  .a(dram0_in_addr),      // input wire [13 : 0] a
  .d(dram_in_data),      // input wire [511 : 0] d
  .clk(i_sys_clk),  // input wire clk
  .we(dram0_in_we),    // input wire we
  .spo(dram0_out)  // output wire [511 : 0] spo
);
frame_dram_9600_512_1 frame_dram1 (     //96*512
  .a(dram1_in_addr),      // input wire [13 : 0] a
  .d(dram_in_data),      // input wire [511 : 0] d
  .clk(i_sys_clk),  // input wire clk
  .we(dram1_in_we),    // input wire we
  .spo(dram1_out)  // output wire [511 : 0] spo
);

// 该模块自动生成行同步信号和场同步信号，生成读请求
// 该模块以及FIFO读出端口以及dvi_encoder均使用单独的video_clk时钟�???
video_timing_data video_timing_data_m0 
(
.video_clk                      (video_clk                 ),
.rst                            (~i_sys_rst_n              ),
.read_req                       (read_req_cam              ),   // 这个信号代表即将�??始新�??帧的读取
.read_req_ack                   (read_req_ack_cam          ),
.read_en                        (read_en_cam               ),//这个信号�???旦为高，就需要连续地给进去信�???
.read_data                      (read_data_cam             ),
.hs                             (hs                        ),
.vs                             (vs                        ),
.de                             (de                        ),
.vout_data                      (vout_data                 )
);

// 该模块配合状态机完成时钟频率的隔离，同时给显示模块提供数�???
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
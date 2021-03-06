// 该模块需要完成三个功能，其一是完成CMOS相机的设备初始化，其二是完成相机图像的读取，其三是完成相机的读控制，控制报文的发送。
module cms_covert (
//system clock & resets
    input     wire                 i_sys_clk                       //system clk
    ,input     wire                 i_sys_rst_n                     //rst of sys_clk
//system clock & resets
    // ,output [2:0]   state_o      // for test
//======================================= command from the config path ==================================//
    ,input 	 				    Command_wr_i						//command write signal
    ,input 	 	[63:0] 		    Command_i							//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
    ,output 						Command_alf_i						//command almostful
//======================================= command from the config path ==================================//

//======================================= result to the host=============================================//
    ,output 	reg 				Command_wr_o						//command write signal
    ,output 	reg 	[63:0] 		Command_o							//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
    ,input 						    Command_alf_o						//command almostful
//======================================= result to the host=============================================//

//======================================= CMOS=========================================================//
    ,inout                          cmos_scl                            //cmos i2c clock
    ,inout                          cmos_sda                            //cmos i2c data
    ,input                          cmos_vsync                          //cmos vsync
    ,input                          cmos_href                           //cmos hsync refrence,data valid
    ,input                          cmos_pclk                           //cmos pxiel clock
    ,output                         cmos_xclk                           //cmos externl clock 24Mhz
    ,input   [7:0]                  cmos_db                             //cmos data  
//======================================= CMOS=========================================================//

//======================================== pixel frame to the host ======================================//
    , (* keep = "true" *) output	reg		[519:0]		    IFE_ctrlpkt_out					    //receive pkt
    //[519]为报文的首拍标识SOP，[518]为报文的尾拍标识EOP，均为高有效（若都为高，表示首尾同拍）；[517:512]为当拍报文数据的无效字节数，为6’h00表示64B字节全部有效，为6’h3F表示只有一个字节有效；[511:0]为报文数据payload。
    ,output	reg					    IFE_ctrlpkt_out_wr,				    //receive pkt write singal
//======================================== pixel frame to the host ======================================//
    output                            init_done
);

//=========================== parameters for the head of the frame =====================//
parameter ETH_HEAD = 144'd1;
parameter IP_HEAD = 160'd2;
parameter UDP_HEAD = 64'd3;
parameter TYPE = 8'd4;
parameter INDEX = 16'd5;
parameter PADDING = 120'd6;
//=========================== parameters for the head of the frame =====================//
localparam FRAME_HEADER = {ETH_HEAD, IP_HEAD, UDP_HEAD, TYPE, INDEX, PADDING};

//======================================== state machine param========================================//
 (* keep = "TRUE" *)   reg [3:0] state;        //状态

    localparam RESET_S = 4'b0000;//0     复位
    localparam INIT_S  = 4'b0001;//1     完成初始化相关工作
    localparam IDLE_S  = 4'b0011;//3     IDEL
    localparam WREQ_S  = 4'b0010;//2     收到写请求命令
    localparam WFED_S  = 4'b0110;//6     反馈写请求命令
    localparam WAIW_S  = 4'b0111;//7     等待写条件
    localparam WRIT_S  = 4'b0101;//5     写出数据
    localparam WRID_S  = 4'b0100;//4     写数据完成
    localparam WAIF_S  = 4'b1100;//12       等待FIFO
//======================================== state machine param========================================//

//======================================== internal wires========================================//
    wire[9:0]                       lut_index;               //camera  look up table address
    wire[31:0]                      lut_data;                //camera device address,register address, register data
    wire [63 : 0] cmd_fifo;
    reg [63 : 0] cmd_fifo_o;
    reg cmd_rd_en;
    reg write_req_ack_cam;
    wire[15:0]                      cmos_16bit_data;         //camera  data
    wire[15:0]                      write_data_cam;             //write data
    assign write_data_cam = {cmos_16bit_data[4:0],cmos_16bit_data[10:5],cmos_16bit_data[15:11]};
    wire                            write_en_cam;               //write enable
    wire                            cmos_16bit_wr;           //camera  write enable
    assign write_en_cam = cmos_16bit_wr;
    wire[15:0]                      pixel_data;
    reg                            pixel_fifo_rd_en;
    reg                             pixel_fifo_rd_en_d1;
    reg switch_fifo_done;
    reg pixel_fifo_aclr_n;
    reg[9:0] pkg_counter;
    reg[4:0] mes_counter;
    wire    write_finished;
    assign write_finished = pkg_counter == 10'd600;
    reg fifo_read_flag;
    wire [8:0] fifo_data_num;
    reg write_send_buffer_done;

//======================================== internal wires========================================//
assign state_o = state;
//======================================== dual send buffer ========================================//
    reg [511:0]     send_buffer_0;
    reg [511:0]     send_buffer_1;
    reg [4:0]       write_counter;
    reg             current_write_buffer;
    reg             current_read_buffer;
//======================================== dual send buffer ========================================//

ila_1 your_instance_name (
	.clk(i_sys_clk), // input wire clk


	.probe0(count), // input wire [0:0]  probe0  
	.probe1(cmos_href), // input wire [519:0]  probe1 
	.probe2(byte_count), // input wire [2:0]  probe2
	.probe3(pixel_fifo_rd_en), // input wire [2:0]  probe2
	.probe4(pixel_fifo_empty), // input wire [2:0]  probe2
    .probe5(write_counter),
    .probe6(IFE_ctrlpkt_out[511:496]),
    .probe7(cmos_16bit_data),
    .probe8(state)
);
reg [14:0] byte_count;
always @(posedge cmos_pclk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        byte_count <= 'd0;
    end
    else begin
        if(cmos_href)begin
            byte_count <= byte_count + 1'b1;
        end
    end
end

reg [14:0] count;
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        state <= RESET_S;
        cmd_rd_en <= 1'b0;
        count <= 'd0;
    end
    else begin
        if(Command_wr_i)begin
        count <= 'd0;
            
        end
        else if(IFE_ctrlpkt_out_wr)begin
            count <= count + 'd1;
        end
        case(state)
        RESET_S:begin                                       // 上电复位
            state <= INIT_S;
        end
        INIT_S:begin                                        // 复位状态，进行复位操作
            if(init_done)begin    //初始化模块初始化完成，CMD_FIFO初始化完成。
                state <= IDLE_S;
            end
            else begin
                state <= IDLE_S; //测试用，
                // state <= INIT_S; 
            end
        end
        IDLE_S:begin                                        // 等待状态，等待命令
            if(~cmd_empty)begin                                     // CMD_FIFO不为空，表明现在有命令。
                cmd_rd_en <= 1'b1;
                state <= WREQ_S;
            end
            else begin
                state <= IDLE_S;
            end
        end
        WREQ_S:begin                                        // 收到了写请求命令
            cmd_rd_en <= 1'b0;
            state <= WFED_S;
        end
        WFED_S:begin                                        // 反馈写请求命令
            state <= WAIW_S;
        end
        WAIW_S:begin                                        // 等待写条件，等待一帧新的图像来
            if(write_req_cam)begin      // data write module write request,keep '1' until read_req_ack = '1'
                state <= WAIF_S;
            end
        end
        WAIF_S:begin          // 等待FIFO
            if(write_finished)begin
                state <= WRID_S;
            end
            else if(fifo_data_num >= 9'd32)begin     //32*16=512
                state <= WRIT_S;
            end
            else begin
                state <= WAIF_S;
            end
        end
        WRIT_S:begin                                        // 通过网口写出去数据
            if((&(~write_counter)) & (write_send_buffer_done))begin    //写入了512b后，并且switch_done为0，则启动转化。同时启动发送。
                state <= WAIF_S;
            end

            else begin
                state <= WRIT_S;
            end
        end
        WRID_S:begin                                        // 写完成
            state <= IDLE_S;
        end
        default: begin
            state <= RESET_S;
        end
        endcase
    end
end
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        pixel_fifo_rd_en_d1 <= 'd0;
    end
    else begin
        pixel_fifo_rd_en_d1 <= pixel_fifo_rd_en;
    end
end
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(~i_sys_rst_n)begin
        write_req_ack_cam <= 'd0;
        cmd_fifo_o <= 'd0;
        Command_wr_o <= 'd0;
        Command_o <= 64'd0;
        current_write_buffer = 'd0;
        switch_fifo_done = 'd0;
        pixel_fifo_aclr_n <= 1'b0;
        pkg_counter <= 'd0;
        mes_counter <= 'd0;
        write_counter <= 5'd0;
        fifo_read_flag <= 1'b0;
        IFE_ctrlpkt_out_wr <= 'd0;
        IFE_ctrlpkt_out <= 520'd0;
        pixel_fifo_rd_en <= 'd0;
        write_send_buffer_done <= 'd0;
        send_buffer_0 <= 'd0;
        send_buffer_1 <= 'd0;
    end
    else begin
        if(write_req_cam)begin
                write_req_ack_cam <='d1;
        end
        else begin
                write_req_ack_cam <='d0;
        end
        case(state)
        RESET_S:begin                                       // 上电复位
            IFE_ctrlpkt_out_wr <= 1'b0;
        end
        INIT_S:begin                                        // 复位状态，进行复位操作
            IFE_ctrlpkt_out_wr <= 1'b0;
        end
        IDLE_S:begin                                        // 等待状态，等待命令
            IFE_ctrlpkt_out_wr <= 1'b0;
        end
        WREQ_S:begin                                        // 收到了写请求命令,这一步计算好需要反馈的信息。
            cmd_fifo_o <= cmd_fifo;
        end
        WFED_S:begin                                        // 反馈写请求命令
            //=== 这里暂时不用写回命令===//
            Command_o <= cmd_fifo_o;
            Command_wr_o <= 1'b1;
            //=== 这里暂时不用写回命令===//
        end
        WAIW_S:begin                                        // 等待写条件，等待一帧新的图像来
            Command_wr_o <= 1'b0;
            current_write_buffer = 1'b0;
            // if(write_req_cam)begin      // data write module write request,keep '1' until read_req_ack = '1'
            //     IFE_ctrlpkt_out_wr <= 1'b1;// 发送数据有效
            //     IFE_ctrlpkt_out <= {8'b10000000, FRAME_HEADER};
            // end
            // else begin
            //     IFE_ctrlpkt_out_wr <= 1'b0;// 发送数据有效
            //     IFE_ctrlpkt_out <= 520'd0;
            // end
        end
        WAIF_S:begin        //等待FIFO的数量足够
            pixel_fifo_aclr_n <= 1'b1;              // fifo 复位清除，不用复位。
            IFE_ctrlpkt_out_wr <= 1'b0;
            if(fifo_data_num >= 9'd32)begin     //32*16=512
                pixel_fifo_rd_en <= 1'b1;
                write_counter <= 'd0;
                write_send_buffer_done <='d0;
            end
            else begin
                pixel_fifo_rd_en <= 1'b0;
            end
        end
        WRIT_S:begin                                        // 通过网口写出去数据
            if((&(~write_counter)) & (write_send_buffer_done))begin    //写入了512b后，并且switch_done为0，则启动转化。同时启动发送。
                //以下代码只执行一次。
                write_send_buffer_done <= 1'b0;
                IFE_ctrlpkt_out_wr <= 1'b1;// 发送数据有效
                // 这里有个问题，就是帧头部分的一拍应该包括了这里的SOP信息，所以这里就只需要判断EOP的信息就行了。
                // IFE_ctrlpkt_out <= {((pkg_counter==10'd0)?8'b10000000:((pkg_counter==10'd599)?8'b01000000:8'd0)),  (current_write_buffer)?  send_buffer_0:  send_buffer_1};//因为前面阻塞赋值取反了，因此这里要翻一下。
                IFE_ctrlpkt_out <= {(((mes_counter==10'd15)?8'b01000000:8'd0)),   send_buffer_0};

                mes_counter <= mes_counter + 1'b1;
                if(mes_counter == 5'd15)begin
                    mes_counter <= 5'd0;
                    pkg_counter <= pkg_counter + 10'd1;
                end
            end
            if(pixel_fifo_rd_en)begin
                write_counter <= write_counter + 5'd1;
                if(write_counter == 5'b11111)begin
                    pixel_fifo_rd_en <='d0;     //读满了
                    write_send_buffer_done <= 1'b1;
                    if(mes_counter == 5'd0) begin      // 先发送数据帧头
                        IFE_ctrlpkt_out <= {8'b10000000, FRAME_HEADER};
                        IFE_ctrlpkt_out_wr <= 1'b1;// 发送数据有效
                    end
                end
                else begin
                    write_send_buffer_done <= 1'b0;
                end

                send_buffer_0 <= {send_buffer_0[495:0],pixel_data};

            end
        end
        WRID_S:begin                                        // 写完成
            IFE_ctrlpkt_out_wr <= 1'b0;     // 发送数据失效
            fifo_read_flag <= 'd0;
            write_counter <= 'd0;
            pkg_counter <= 'd0;
            mes_counter <= 'd0;
            pixel_fifo_aclr_n <='d0;
        end
        default: begin
            write_req_ack_cam <= 'd0;
            cmd_fifo_o <= 'd0;
            Command_wr_o <= 'd0;
            Command_o <= 64'd0;
            current_write_buffer = 'd0;
            switch_fifo_done = 'd0;
            pixel_fifo_aclr_n <= 1'b0;
            pkg_counter <= 'd0;
            mes_counter <= 'd0;
            write_counter <= 5'd0;
            fifo_read_flag <= 1'b0;
        end
        endcase
    end
end

sys_pll_to_cmos sys_pll_m0(         // 这个pll的配置没有测试过，所以可能会出错，后期需要注意输入输出的时钟频率。
    .clk_in1                        (i_sys_clk               ),
    .clk_out1                       (cmos_xclk                  ),      // 24MHz
    .resetn                          (i_sys_rst_n                     ),
    .locked                         (                         )
);

// command fifo // fifo的复位需要一段时间，期间wr_rst_busy和rd_rst_busy信号为高电平，此时应禁止读写FIFO，否则会造成数据丢失。
cmd_fifo cmd_fifo_m0 (
  .clk(i_sys_clk),                      // input wire clk
  .srst(~i_sys_rst_n),                    // input wire rst       //高有效
  .din(Command_i),                      // input wire [63 : 0] din
  .wr_en(Command_wr_i),                 // input wire wr_en
  .rd_en(cmd_rd_en),                        // input wire rd_en
  .dout(cmd_fifo),                // output wire [63 : 0] dout
  .full(full),                // output wire full
  .almost_full(Command_alf_i),  // output wire almost_full
  .empty(cmd_empty)              // output wire empty
);

// 以下两个模块自动完成设备的初始化
i2c_config i2c_config_m0(
    .rst                            (~i_sys_rst_n              ),
    .clk                            (i_sys_clk                  ),
    .clk_div_cnt                    (16'd99                   ),
    .i2c_addr_2byte                 (1'b1                     ),
    .lut_index                      (lut_index                ),
    .lut_dev_addr                   (lut_data[31:24]          ),
    .lut_reg_addr                   (lut_data[23:8]           ),
    .lut_reg_data                   (lut_data[7:0]            ),
    .error                          (                         ),
    .done                           (init_done                ),
    .i2c_scl                        (cmos_scl                 ),
    .i2c_sda                        (cmos_sda                 )
);
lut_ov5640_rgb565_640_480 lut_ov5640_rgb565_640_480_m0(
    .lut_index                      (lut_index                ),
    .lut_data                       (lut_data                 )
);

// 这个模块生成写请求信号，代表了新一帧图像的开始
cmos_write_req_gen cmos_write_req_gen_m0(
    .rst                            (~i_sys_rst_n              ),
    .pclk                           (cmos_pclk                ),
    .cmos_vsync                     (cmos_vsync               ),
    .write_req                      (write_req_cam            ),
    .write_req_ack                  (write_req_ack_cam        )
);
// 这个模块将两个周期的数据整理输出成16b。
    cmos_8_16bit cmos_8_16bit_m0(
    .rst                            (~i_sys_rst_n             ),
    .pclk                           (cmos_pclk                ),
    .pdata_i                        (cmos_db                  ),
    .de_i                           (cmos_href                ),
    .pdata_o                        (cmos_16bit_data          ),
    .hblank                         (                         ),
    .de_o                           (cmos_16bit_wr            )
);

// 缓存像素信息，如果不发送的，则复位清除，如果要发送的，则进入，同时利用FIFO实现时钟域的隔离，前面是cmos_pclk，后面是系统时钟。
// 这里主要控制复位信号的操作。
// warning: 此处需要注意，当FIFO复位有，有一段时间不能进行操作，也就是从帧同步信号到第一个像素点来的这段时间可能会出错。
//          但是考虑到像素信息是由两拍的数据组合而成，因此具有一定的鲁棒性，但是不保证完全正确。
pixel_fifo_16b_512 pixel_fifo_m0 (
  .rst(~pixel_fifo_aclr_n),                  // input wire rst  高有效。    // 这里可能存在问题，由于复位后有一段时间是不能够使用的，导致数据没有写进去。
  .wr_clk(cmos_pclk),            // input wire wr_clk
  .rd_clk(i_sys_clk),            // input wire rd_clk
  .din(cmos_16bit_data),                  // input wire [15 : 0] din
  .wr_en(write_en_cam),              // input wire wr_en
  .rd_en(pixel_fifo_rd_en),              // input wire rd_en
  .dout(pixel_data),                // output wire [15 : 0] dout
  .full(),                // output wire full
  .empty(pixel_fifo_empty),              // output wire empty
  .wr_rst_busy(fifo_write_busy),  // output wire wr_rst_busy
  .rd_rst_busy(),  // output wire rd_rst_busy
  .rd_data_count(fifo_data_num)  // output wire [8 : 0] rd_data_count
);
endmodule
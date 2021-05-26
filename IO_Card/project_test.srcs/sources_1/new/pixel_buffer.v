module pixel_buffer (
//============================================== clk & rst ===========================================//

//system clock & resets
 input                      i_sys_clk                       //system clk
,input                      i_sys_rst_n                     //rst of sys_clk
//=========================================== Input data pkt  ==========================================//
,input          [519:0]      o_dpkt_data                     //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input                       o_dpkt_data_en                  //data enable
,output                         i_dpkt_fifo_alf                 //fifo almostfull

//=========================== HDMI interface =============================//
,output          tmds_clk_p,
output          tmds_clk_n,
output[2:0]     tmds_data_p,    //rgb
output[2:0]     tmds_data_n,     //rgb

//ddr3
inout [31:0]                     ddr3_dq,                //ddr3 data
inout [3:0]                      ddr3_dqs_n,             //ddr3 dqs negative
inout [3:0]                      ddr3_dqs_p,             //ddr3 dqs positive
output [14:0]                    ddr3_addr,              //ddr3 address
output [2:0]                     ddr3_ba,                //ddr3 bank
output                           ddr3_ras_n,             //ddr3 ras_n
output                           ddr3_cas_n,             //ddr3 cas_n
output                           ddr3_we_n,              //ddr3 write enable
output                           ddr3_reset_n,           //ddr3 reset,
output [0:0]                     ddr3_ck_p,              //ddr3 clock negative
output [0:0]                     ddr3_ck_n,              //ddr3 clock positive
output [0:0]                     ddr3_cke,               //ddr3_cke,
output [0:0]                     ddr3_cs_n,              //ddr3 chip select,
output [3:0]                     ddr3_dm,                //ddr3_dm
output [0:0]                     ddr3_odt               //ddr3_odt
);

	parameter MEM_DATA_BITS          = 32;
	parameter READ_DATA_BITS         = 16;
	parameter WRITE_DATA_BITS        = 16;
	parameter ADDR_BITS              = 28;
	parameter BUSRT_BITS             = 10;
	parameter BURST_SIZE             = 128;

//======================================== internal wires========================================//
wire                             video_clk;              //video pixel clock
wire                             video_clk5x;            //video 5 x pixel clock
wire                             hs;                     //horizontal synchronization
wire                             vs;                     //vertical synchronization
wire                             de;                     //video valid
wire[31:0]                       vout_data;              //video data

//======================================== internal wires========================================//
    
/*************************************************************************
process the header information and dispatch them to the afifo to write in DDR3
****************************************************************************/ 
wire [127 : 0] o_data_to_afifo;

header_process  header_process_i0 (
    .i_sys_clk               ( i_sys_clk             ),
    .i_sys_rst_n             ( i_sys_rst_n           ),
    .o_dpkt_data             ( o_dpkt_data           ),
    .o_dpkt_data_en          ( o_dpkt_data_en        ),
    .i_almost_full_afifo     ( i_almost_full_afifo   ),
    .i_wr_rst_busy_afifo     ( i_wr_rst_busy_afifo   ),

    .i_dpkt_fifo_alf         ( i_dpkt_fifo_alf       ),
    .o_data_to_afifo         ( o_data_to_afifo       ),
    .o_wr_en_afifo           ( o_wr_en_afifo         ),
    .new_frame_comming       ( new_frame_comming     ),
    .o_reset_afifo           ( o_reset_afifo         )
);
wire o_wr_en_afifo;

wire i_wr_rst_busy;
wire i_almost_full_afifo;
wire                            ui_clk;                  //MIG master clock
wire                            ui_clk_sync_rst;         //MIG master reset
wire                            init_calib_complete;     //MIG initialization omplete

// ila_0 your_instance_name (
// 	.clk(ui_clk), // input wire clk


// 	.probe0(new_frame_comming ), // input wire [0:0]  probe0  
// 	.probe1( read_addr_index ), // input wire   probe1 
// 	.probe2( write_addr_index), // input wire [27:0]  probe2 
    
// 	.probe3( vout_data ),  // input wire [9:0]  probe3 
// 	.probe4( hdmi_de), // input wire  probe4 
// 	.probe5( header_process_i0.state), // input wire [31:0]  probe5 
// 	.probe6(rdusedw), // input wire [0:0]  probe6 
// 	.probe7({3{init_calib_complete}} ), // input wire [0:0]  probe7 
// 	.probe8( frame_fifo_write_m0.state), // input wire [0:0]  probe8 
// 	.probe9(frame_fifo_write_m0.write_cnt), // input wire [0:0]  probe9
// 	.probe10(header_process_i0.data_fifo_rden_d0),
// 	.probe11(header_process_i0.data_fifo_out[519:518])
// );

wire                            wr_burst_data_req_cam;      // write burst data request       
wire                            wr_burst_finish_cam;        // write burst finish flag
wire                            wr_burst_req_cam;           //write burst request
wire[BUSRT_BITS - 1:0]          wr_burst_len_cam;           //write burst length
wire[ADDR_BITS - 1:0]           wr_burst_addr_cam;          //write burst address
wire[MEM_DATA_BITS - 1 : 0]     wr_burst_data_cam;          //write burst data 
wire                            write_en_cam;               //write enable
wire[15:0]                      write_data_cam;             //write data
wire [8 : 0] rdusedw;
wire[15:0]                           wrusedw;                    // write used words

afifo_128i_32o_128 write_buf (
  .rst(o_reset_afifo | (~i_sys_rst_n)),                      // input wire rst
  .wr_clk(i_sys_clk),                // input wire wr_clk
  .rd_clk(ui_clk),                // input wire rd_clk
  .din(o_data_to_afifo),                      // input wire [127 : 0] din
  .wr_en(o_wr_en_afifo),                  // input wire wr_en
  .rd_en(wr_burst_data_req_cam),                  // input wire rd_en
  .dout(wr_burst_data_cam),                    // output wire [31 : 0] dout
  .full(),                    // output wire full
  .almost_full(i_almost_full_afifo),      // output wire almost_full
  .empty(),                  // output wire empty
  .rd_data_count(rdusedw),  // output wire [8 : 0] rd_data_count
  .wr_data_count(),  // output wire [6 : 0] wr_data_count
  .wr_rst_busy(i_wr_rst_busy),      // output wire wr_rst_busy
  .rd_rst_busy( )      // output wire rd_rst_busy
);

wire write_req;
wire write_req_ack;


frame_fifo_write		// 这个模块负责写完一帧的burst传输
#
(
	.MEM_DATA_BITS              (MEM_DATA_BITS            ),    //32
	.ADDR_BITS                  (ADDR_BITS                ),    //28
	.BUSRT_BITS                 (BUSRT_BITS               ),    //10
	.BURST_SIZE                 (BURST_SIZE               )     //128
) 
frame_fifo_write_m0              
(  
	.rst                        (ui_clk_sync_rst                      ),
	.mem_clk                    (ui_clk                  ),
	.wr_burst_req               (wr_burst_req_cam         ),			// 发出写请求信号，完成之前一直为高
	.wr_burst_len               (wr_burst_len_cam             ),
	.wr_burst_addr              (wr_burst_addr_cam            ),
	.wr_burst_finish            (wr_burst_finish_cam          ),
	.write_req                  (write_req                ),
	.write_req_ack              (write_req_ack            ),
	.write_finish               (             ),	//output write finish
.write_addr_0                   (28'haf00000               ), //700MB, each address value here maps to 32 bits
.write_addr_1                   (28'haf80000               ), //702MB
	.write_addr_2               (             ),
	.write_addr_3               (             ),
	.write_addr_index           (write_addr_index         ),    
	.write_len                  (28'd153600               ), //frame size  640 * 480 * 16 / 32
	.fifo_aclr                  (  			          ),
	.rdusedw                    (rdusedw                  ) 
	
);
wire rd_burst_req;
wire rd_burst_data_valid;
wire rd_burst_finish;
wire [MEM_DATA_BITS - 1:0]       rd_burst_data;
wire                            read_en_cam;                //read enable
wire[15:0]                      read_data_cam;              //read data
wire                            read_req_cam;               //read request
wire                            read_req_ack_cam;           //read request response  
wire read_fifo_aclr;

//instantiate an asynchronous FIFO
afifo_32i_16o_256 read_buf (
	.rst                         (read_fifo_aclr          ),                     
	.wr_clk                      (ui_clk                 ),               
	.rd_clk                      (video_clk                ),               
	.din                         (rd_burst_data           ),                     
	.wr_en                       (rd_burst_data_valid     ),                 
	.rd_en                       (read_en_cam                 ),                 
	.dout                        (read_data_cam               ),                   
	.full                        (                        ),                   
	.empty                       (                        ),                 
	.rd_data_count               (                        ), 
	.wr_data_count               (wrusedw                 )  
);

wire[BUSRT_BITS - 1:0]          rd_burst_len;           //read burst length
wire[ADDR_BITS - 1:0]           rd_burst_addr;          //read burst address
wire read_req;
wire read_req_ack;
wire read_addr_index;
wire write_addr_index;

frame_fifo_read
#
(
	.MEM_DATA_BITS              (MEM_DATA_BITS            ),
	.ADDR_BITS                  (ADDR_BITS                ),
	.BUSRT_BITS                 (BUSRT_BITS               ),
	.FIFO_DEPTH                 (256                      ),
	.BURST_SIZE                 (BURST_SIZE               )
)
frame_fifo_read_cam_m0
(
	.rst                        (ui_clk_sync_rst              ),
	.mem_clk                    (ui_clk                  ),
	.rd_burst_req               (rd_burst_req             ),   
	.rd_burst_len               (rd_burst_len             ),  
	.rd_burst_addr              (rd_burst_addr            ),
	.rd_burst_data_valid        (rd_burst_data_valid      ),    
	.rd_burst_finish            (rd_burst_finish          ),
	.read_req                   (read_req                 ),
	.read_req_ack               (read_req_ack             ),
	.read_finish                (              ),
.read_addr_0                    (28'haf00000               ), //The first frame address
.read_addr_1                    (28'haf80000               ),
	.read_addr_2                (              ),
	.read_addr_3                (              ),
	.read_addr_index            (read_addr_index          ),  // 只用一位进行表示，即用两个地址空间交替进行存储。
	.read_len                   (28'd153600                 ),//frame size  640 * 480 * 16 / 32
	.fifo_aclr                  (read_fifo_aclr           ),
	.wrusedw                    (wrusedw                  )
);
/*************************************************************************
CMOS sensor writes the request and generates the read and write address index
****************************************************************************/ 
cmos_write_req_gen cmos_write_req_gen_m0(
.rst                            (~i_sys_rst_n              ),
.pclk                           (i_sys_clk                 ),
.cmos_vsync                     (new_frame_comming         ), // to generate new read/write index
.write_req                      (write_req                 ),
.write_req_ack                  (write_req_ack             ),
.write_addr_index               (write_addr_index          ),
.read_addr_index                (read_addr_index           )
);

// 这个PLL模块是为了生成视频相关的时钟，后续输入dvi_encoder模块�?????
video_pll video_pll_m0
 (
       // Clock out ports
    .clk_out1(video_clk),     // output clk_out1
    .clk_out2(video_clk5x),     // output clk_out2
    // Status and control signals
    .resetn(i_sys_rst_n), // input resetn
   // Clock in ports
    .clk_in1(i_sys_clk));      // input clk_in1


/*************************************************************************
// xilinx MIG IP application interface ports
****************************************************************************/
localparam nCK_PER_CLK           = 4;
localparam DQ_WIDTH              = 32;
localparam ADDR_WIDTH            = 29;
localparam DATA_WIDTH            = 32;
localparam PAYLOAD_WIDTH         = 32;

localparam APP_DATA_WIDTH        = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;     // 256
localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;      // 32

wire [ADDR_WIDTH-1:0]           app_addr;
wire [2:0]                      app_cmd;
wire                            app_en;
wire                            app_rdy;
wire [APP_DATA_WIDTH-1:0]       app_rd_data;
wire                            app_rd_data_end;
wire                            app_rd_data_valid;
wire [APP_DATA_WIDTH-1:0]       app_wdf_data;
wire                            app_wdf_end;
wire [APP_MASK_WIDTH-1:0]       app_wdf_mask;
wire                            app_wdf_rdy;
wire                            app_sr_active;
wire                            app_ref_ack;
wire                            app_zq_ack;
wire                            app_wdf_wren;

// /*************************************************************************
// AXI User Interface Conversion 
// ****************************************************************************/

// wire                        ITCN_M00_AXI_ARESET_OUT_N;
// wire                  ITCN_M00_AXI_AWID;
// wire [31:0]                 ITCN_M00_AXI_AWADDR;
// wire [7:0]                  ITCN_M00_AXI_AWLEN;
// wire [2:0]                  ITCN_M00_AXI_AWSIZE;
// wire [1:0]                  ITCN_M00_AXI_AWBURST;
// wire                        ITCN_M00_AXI_AWLOCK;
// wire [3:0]                  ITCN_M00_AXI_AWCACHE;
// wire [2:0]                  ITCN_M00_AXI_AWPROT;
// wire [3:0]                  ITCN_M00_AXI_AWQOS;
// wire                        ITCN_M00_AXI_AWVALID;
// wire                        ITCN_M00_AXI_AWREADY;
// wire [31:0]                 ITCN_M00_AXI_WDATA;
// wire [3:0]                  ITCN_M00_AXI_WSTRB;
// wire                        ITCN_M00_AXI_WLAST;
// wire                        ITCN_M00_AXI_WVALID;
// wire                        ITCN_M00_AXI_WREADY;
// wire [3:0]                  ITCN_M00_AXI_BID;
// wire [1:0]                  ITCN_M00_AXI_BRESP;
// wire                        ITCN_M00_AXI_BVALID;
// wire                        ITCN_M00_AXI_BREADY;
// wire [3:0]                  ITCN_M00_AXI_ARID;
// wire [31:0]                 ITCN_M00_AXI_ARADDR;
// wire [7:0]                  ITCN_M00_AXI_ARLEN;
// wire [2:0]                  ITCN_M00_AXI_ARSIZE;
// wire [1:0]                  ITCN_M00_AXI_ARBURST;
// wire                        ITCN_M00_AXI_ARLOCK;
// wire [3:0]                  ITCN_M00_AXI_ARCACHE;
// wire [2:0]                  ITCN_M00_AXI_ARPROT;
// wire [3:0]                  ITCN_M00_AXI_ARQOS;
// wire                        ITCN_M00_AXI_ARVALID;
// wire                        ITCN_M00_AXI_ARREADY;
// wire [3:0]                  ITCN_M00_AXI_RID;
// wire [31:0]                 ITCN_M00_AXI_RDATA;
// wire [1:0]                  ITCN_M00_AXI_RRESP;
// wire                        ITCN_M00_AXI_RLAST;
// wire                        ITCN_M00_AXI_RVALID;
// wire                        ITCN_M00_AXI_RREADY;

// aq_axi_master u_aq_axi_master
// (
// .ARESETN                        (~ui_clk_sync_rst         ),
// .ACLK                           (ui_clk                   ),
// .M_AXI_AWID                     (ITCN_M00_AXI_AWID        ),
// .M_AXI_AWADDR                   (ITCN_M00_AXI_AWADDR      ),
// .M_AXI_AWLEN                    (ITCN_M00_AXI_AWLEN       ),
// .M_AXI_AWSIZE                   (ITCN_M00_AXI_AWSIZE      ),
// .M_AXI_AWBURST                  (ITCN_M00_AXI_AWBURST     ),
// .M_AXI_AWLOCK                   (ITCN_M00_AXI_AWLOCK      ),
// .M_AXI_AWCACHE                  (ITCN_M00_AXI_AWCACHE     ),
// .M_AXI_AWPROT                   (ITCN_M00_AXI_AWPROT      ),
// .M_AXI_AWQOS                    (ITCN_M00_AXI_AWQOS       ),
// .M_AXI_AWUSER                   (                         ),
// .M_AXI_AWVALID                  (ITCN_M00_AXI_AWVALID     ),
// .M_AXI_AWREADY                  (ITCN_M00_AXI_AWREADY     ),
// .M_AXI_WDATA                    (ITCN_M00_AXI_WDATA       ),
// .M_AXI_WSTRB                    (ITCN_M00_AXI_WSTRB       ),
// .M_AXI_WLAST                    (ITCN_M00_AXI_WLAST       ),
// .M_AXI_WUSER                    (                         ),
// .M_AXI_WVALID                   (ITCN_M00_AXI_WVALID      ),
// .M_AXI_WREADY                   (ITCN_M00_AXI_WREADY      ),
// .M_AXI_BID                      (ITCN_M00_AXI_BID         ),
// .M_AXI_BRESP                    (ITCN_M00_AXI_BRESP       ),
// .M_AXI_BUSER                    (                         ),
// .M_AXI_BVALID                   (ITCN_M00_AXI_BVALID      ),
// .M_AXI_BREADY                   (ITCN_M00_AXI_BREADY      ),
// .M_AXI_ARID                     (ITCN_M00_AXI_ARID        ),
// .M_AXI_ARADDR                   (ITCN_M00_AXI_ARADDR      ),
// .M_AXI_ARLEN                    (ITCN_M00_AXI_ARLEN       ),
// .M_AXI_ARSIZE                   (ITCN_M00_AXI_ARSIZE      ),
// .M_AXI_ARBURST                  (ITCN_M00_AXI_ARBURST     ),
// .M_AXI_ARLOCK                   (ITCN_M00_AXI_ARLOCK      ),
// .M_AXI_ARCACHE                  (ITCN_M00_AXI_ARCACHE     ),
// .M_AXI_ARPROT                   (ITCN_M00_AXI_ARPROT      ),
// .M_AXI_ARQOS                    (ITCN_M00_AXI_ARQOS       ),
// .M_AXI_ARUSER                   (                         ),
// .M_AXI_ARVALID                  (ITCN_M00_AXI_ARVALID     ),
// .M_AXI_ARREADY                  (ITCN_M00_AXI_ARREADY     ),
// .M_AXI_RID                      (ITCN_M00_AXI_RID         ),
// .M_AXI_RDATA                    (ITCN_M00_AXI_RDATA       ),
// .M_AXI_RRESP                    (ITCN_M00_AXI_RRESP       ),
// .M_AXI_RLAST                    (ITCN_M00_AXI_RLAST       ),
// .M_AXI_RUSER                    (                         ),
// .M_AXI_RVALID                   (ITCN_M00_AXI_RVALID      ),
// .M_AXI_RREADY                   (ITCN_M00_AXI_RREADY      ),
// .MASTER_RST                     (1'b0                     ),

// .WR_START                       (wr_burst_req_cam             ),
// .WR_ADRS                        ({wr_burst_addr_cam,2'd0}     ),
// .WR_LEN                         ({wr_burst_len_cam,3'd0}      ),		//128*8
// .WR_READY                       (                         ),
// .WR_FIFO_RE                     (wr_burst_data_req_cam        ),
// .WR_FIFO_EMPTY                  (1'b0                     ),
// .WR_FIFO_AEMPTY                 (1'b0                     ),
// .WR_FIFO_DATA                   (wr_burst_data_cam            ),
// .WR_DONE                        (wr_burst_finish_cam          ),
// .RD_START                       (rd_burst_req             ),
// .RD_ADRS                        ({rd_burst_addr,2'd0}     ),
// .RD_LEN                         ({rd_burst_len,3'd0}      ),
// .RD_READY                       (                         ),
// .RD_FIFO_WE                     (rd_burst_data_valid      ),
// .RD_FIFO_FULL                   (1'b0                     ),
// .RD_FIFO_AFULL                  (1'b0                     ),
// .RD_FIFO_DATA                   (rd_burst_data            ),
// .RD_DONE                        (rd_burst_finish          ),
// .DEBUG                          (                         )
// );
mem_burst		// 这个模块负责写完一次的burst传输，不同于上面的一幅图像的burst传输。
#(
.MEM_DATA_BITS                  (APP_DATA_WIDTH         ),
.ADDR_BITS                      (ADDR_WIDTH             )
)
mem_burst_m0
(
.rst                            (ui_clk_sync_rst                    ),                                  
.mem_clk                        (ui_clk                    ),                              
.rd_burst_req                   (rd_burst_req           ),                
.wr_burst_req                   (wr_burst_req_cam           ),     // 写请求信号，完成之前一直为高           
.rd_burst_len                   (rd_burst_len           ),                
.wr_burst_len                   (wr_burst_len_cam           ),     // 写长度，应当是传输的次数
.rd_burst_addr                  (rd_burst_addr          ),               
.wr_burst_addr                  (wr_burst_addr_cam          ),     // 写地址   
.rd_burst_data_valid            (rd_burst_data_valid    ),   
.wr_burst_data_req              (wr_burst_data_req_cam      ),       // 输出写数据的数据请求，代表FIFO的读使能信号
.rd_burst_data                  (rd_burst_data          ),               
.wr_burst_data                  (wr_burst_data_cam          ),            // 输入写的数据   
.rd_burst_finish                (rd_burst_finish        ),           
.wr_burst_finish                (wr_burst_finish_cam        ),           // burst写传输完成。
.burst_finish                   (                       ),                             

.app_addr                       (app_addr               ),
.app_cmd                        (app_cmd                ),
.app_en                         (app_en                 ),
.app_wdf_data                   (app_wdf_data           ),
.app_wdf_end                    (app_wdf_end            ),
.app_wdf_mask                   (app_wdf_mask           ),
.app_wdf_wren                   (app_wdf_wren           ),
.app_rd_data                    (app_rd_data            ),
.app_rd_data_end                (app_rd_data_end        ),
.app_rd_data_valid              (app_rd_data_valid      ),
.app_rdy                        (app_rdy                ),
.app_wdf_rdy                    (app_wdf_rdy            ),
.ui_clk_sync_rst                (                       ),  
.init_calib_complete            (init_calib_complete    )
);
wire clk_200;
clk_200M clk_200M_i0
(
// Clock out ports
.clk_out1(clk_200),     // output clk_out1
// Status and control signals
.resetn(i_sys_rst_n), // input resetn
.locked(),       // output locked
// Clock in ports
.clk_in1(i_sys_clk));      // input clk_in1

// /*************************************************************************
// XILINX MIG IP with AXI bus
// ****************************************************************************/
// ddr3_mig u_ddr3 
// (
// // Memory interface ports
// .ddr3_addr                      (ddr3_addr                 ), 
// .ddr3_ba                        (ddr3_ba                   ), 
// .ddr3_cas_n                     (ddr3_cas_n                ), 
// .ddr3_ck_n                      (ddr3_ck_n                 ), 
// .ddr3_ck_p                      (ddr3_ck_p                 ),
// .ddr3_cke                       (ddr3_cke                  ),  
// .ddr3_ras_n                     (ddr3_ras_n                ), 
// .ddr3_reset_n                   (ddr3_reset_n              ), 
// .ddr3_we_n                      (ddr3_we_n                 ),  
// .ddr3_dq                        (ddr3_dq                   ),  
// .ddr3_dqs_n                     (ddr3_dqs_n                ),  
// .ddr3_dqs_p                     (ddr3_dqs_p                ),  
// .init_calib_complete            (init_calib_complete       ),  
 
// .ddr3_cs_n                      (ddr3_cs_n                 ),  
// .ddr3_dm                        (ddr3_dm                   ),  
// .ddr3_odt                       (ddr3_odt                  ),  
// // Application interface ports
// .ui_clk                         (ui_clk                    ), 
// .ui_clk_sync_rst                (ui_clk_sync_rst           ),  // output	   ui_clk_sync_rst
// .mmcm_locked                    (                          ),  // output	    mmcm_locked
// .aresetn                        (1'b1                      ),  // input			aresetn
// .app_sr_req                     (1'b0                      ),  // input			app_sr_req
// .app_ref_req                    (1'b0                      ),  // input			app_ref_req
// .app_zq_req                     (1'b0                      ),  // input			app_zq_req
// .app_sr_active                  (                          ),  // output	    app_sr_active
// .app_ref_ack                    (                          ),  // output		app_ref_ack
// .app_zq_ack                     (                          ),  // output		app_zq_ack
// // Slave Interface Write Address Ports
// .s_axi_awid                     (ITCN_M00_AXI_AWID              ),  // input [0:0]	s_axi_awid
// .s_axi_awaddr                   (ITCN_M00_AXI_AWADDR            ),  // input [29:0]	s_axi_awaddr
// .s_axi_awlen                    (ITCN_M00_AXI_AWLEN             ),  // input [7:0]	s_axi_awlen
// .s_axi_awsize                   (ITCN_M00_AXI_AWSIZE            ),  // input [2:0]	s_axi_awsize
// .s_axi_awburst                  (ITCN_M00_AXI_AWBURST           ),  // input [1:0]	s_axi_awburst
// .s_axi_awlock                   (ITCN_M00_AXI_AWLOCK            ),  // input [0:0]	s_axi_awlock
// .s_axi_awcache                  (ITCN_M00_AXI_AWCACHE           ),  // input [3:0]	s_axi_awcache
// .s_axi_awprot                   (ITCN_M00_AXI_AWPROT            ),  // input [2:0]	s_axi_awprot
// .s_axi_awqos                    (ITCN_M00_AXI_AWQOS             ),  // input [3:0]	s_axi_awqos
// .s_axi_awvalid                  (ITCN_M00_AXI_AWVALID           ),  // input		s_axi_awvalid
// .s_axi_awready                  (ITCN_M00_AXI_AWREADY           ),  // output	    s_axi_awready
// // Slave Interface Write Data Ports
// .s_axi_wdata                    (ITCN_M00_AXI_WDATA             ),  // input [63:0]	s_axi_wdata
// .s_axi_wstrb                    (ITCN_M00_AXI_WSTRB             ),  // input [7:0]	s_axi_wstrb
// .s_axi_wlast                    (ITCN_M00_AXI_WLAST             ),  // input		s_axi_wlast
// .s_axi_wvalid                   (ITCN_M00_AXI_WVALID            ),  // input		s_axi_wvalid
// .s_axi_wready                   (ITCN_M00_AXI_WREADY            ),  // output		s_axi_wready
// // Slave Interface Write Response Ports
// .s_axi_bid                      (ITCN_M00_AXI_BID               ),  // output [0:0]	s_axi_bid
// .s_axi_bresp                    (ITCN_M00_AXI_BRESP             ),  // output [1:0]	s_axi_bresp
// .s_axi_bvalid                   (ITCN_M00_AXI_BVALID            ),  // output		s_axi_bvalid
// .s_axi_bready                   (ITCN_M00_AXI_BREADY            ),  // input		s_axi_bready
// // Slave Interface Read Address Ports
// .s_axi_arid                     (ITCN_M00_AXI_ARID              ),  // input [0:0]	s_axi_arid
// .s_axi_araddr                   (ITCN_M00_AXI_ARADDR            ),  // input [29:0]	s_axi_araddr
// .s_axi_arlen                    (ITCN_M00_AXI_ARLEN             ),  // input [7:0]	s_axi_arlen
// .s_axi_arsize                   (ITCN_M00_AXI_ARSIZE            ),  // input [2:0]	s_axi_arsize
// .s_axi_arburst                  (ITCN_M00_AXI_ARBURST           ),  // input [1:0]	s_axi_arburst
// .s_axi_arlock                   (ITCN_M00_AXI_ARLOCK            ),  // input [0:0]	s_axi_arlock
// .s_axi_arcache                  (ITCN_M00_AXI_ARCACHE           ),  // input [3:0]	s_axi_arcache
// .s_axi_arprot                   (ITCN_M00_AXI_ARPROT            ),  // input [2:0]	s_axi_arprot
// .s_axi_arqos                    (ITCN_M00_AXI_ARQOS             ),  // input [3:0]	s_axi_arqos
// .s_axi_arvalid                  (ITCN_M00_AXI_ARVALID           ),  // input		s_axi_arvalid
// .s_axi_arready                  (ITCN_M00_AXI_ARREADY           ),  // output		s_axi_arready
// // Slave Interface Read Data Ports
// .s_axi_rid                      (ITCN_M00_AXI_RID               ),  // output [0:0]	s_axi_rid
// .s_axi_rdata                    (ITCN_M00_AXI_RDATA             ),  // output [63:0]s_axi_rdata
// .s_axi_rresp                    (ITCN_M00_AXI_RRESP             ),  // output [1:0]	s_axi_rresp
// .s_axi_rlast                    (ITCN_M00_AXI_RLAST             ),  // output	    s_axi_rlast
// .s_axi_rvalid                   (ITCN_M00_AXI_RVALID            ),  // output		s_axi_rvalid
// .s_axi_rready                   (ITCN_M00_AXI_RREADY            ),  // input		s_axi_rready
// // System Clock Ports
// .sys_clk_i                      (clk_200                ),  //               MIG clock
// .sys_rst                        (i_sys_rst_n                     )   //              input sys_rst
// );
ddr3_usr u_ddr3
(
// Memory interface ports
.ddr3_addr                      (ddr3_addr              ),
.ddr3_ba                        (ddr3_ba                ),
.ddr3_cas_n                     (ddr3_cas_n             ),
.ddr3_ck_n                      (ddr3_ck_n              ),
.ddr3_ck_p                      (ddr3_ck_p              ),
.ddr3_cke                       (ddr3_cke               ),
.ddr3_ras_n                     (ddr3_ras_n             ),
.ddr3_we_n                      (ddr3_we_n              ),
.ddr3_dq                        (ddr3_dq                ),
.ddr3_dqs_n                     (ddr3_dqs_n             ),
.ddr3_dqs_p                     (ddr3_dqs_p             ),
.ddr3_reset_n                   (ddr3_reset_n           ),
.init_calib_complete            (init_calib_complete    ),
.ddr3_cs_n                      (ddr3_cs_n              ),
.ddr3_dm                        (ddr3_dm                ),
.ddr3_odt                       (ddr3_odt               ),
// Application interface ports
.app_addr                       (app_addr               ),
.app_cmd                        (app_cmd                ),
.app_en                         (app_en                 ),
.app_wdf_data                   (app_wdf_data           ),
.app_wdf_end                    (app_wdf_end            ),
.app_wdf_wren                   (app_wdf_wren           ),
.app_rd_data                    (app_rd_data            ),
.app_rd_data_end                (app_rd_data_end        ),
.app_rd_data_valid              (app_rd_data_valid      ),
.app_rdy                        (app_rdy                ),
.app_wdf_rdy                    (app_wdf_rdy            ),
.app_sr_req                     (1'b0                   ),
.app_ref_req                    (1'b0                   ),
.app_zq_req                     (1'b0                   ),
.app_sr_active                  (app_sr_active          ),
.app_ref_ack                    (app_ref_ack            ),
.app_zq_ack                     (app_zq_ack             ),
.ui_clk                         (ui_clk                    ),
.ui_clk_sync_rst                (ui_clk_sync_rst                    ),

.app_wdf_mask                   (app_wdf_mask           ),

.sys_clk_i                      (clk_200         ),      // System Clock Ports    
.sys_rst                        (i_sys_rst_n                  )
);

// 该模块自动生成行同步信号和场同步信号，生成读请求
// 该模块以及FIFO读出端口以及dvi_encoder均使用单独的video_clk时钟�?????
/*************************************************************************
The video output timing generator and generate a frame read data request
****************************************************************************/ 
video_timing_data video_timing_data_m0
(
.video_clk                      (video_clk                 ),
.rst                            (~i_sys_rst_n                    ),
.read_req                       (read_req                  ),
.read_req_ack                   (read_req_ack              ),
.read_en                        (read_en_cam                   ),
.read_data                      (read_data_cam                 ),
.hs                             (hs                        ),
.vs                             (vs                        ),
.de                             (de                        ),
.vout_data                      (vout_data                 )
);


wire                            hdmi_hs;
wire                            hdmi_vs;
wire                            hdmi_de;
wire[7:0]                       hdmi_r;
wire[7:0]                       hdmi_g;
wire[7:0]                       hdmi_b;
assign  hdmi_hs    = hs;
assign  hdmi_vs     = vs;
assign  hdmi_de    = de;
assign hdmi_r      = {vout_data[15:11],3'd0};
assign hdmi_g      = {vout_data[10:5],2'd0};
assign hdmi_b      = {vout_data[4:0],3'd0};

/*************************************************************************
RGB to DVI conversion module
****************************************************************************/
dvi_encoder dvi_encoder_m0
(
.pixelclk                       (video_clk                 ),// system clock
.pixelclk5x                     (video_clk5x               ),// system clock x5
.rstin                          (~i_sys_rst_n                    ),// reset
.blue_din                       (hdmi_b                    ),// Blue data in
.green_din                      (hdmi_g                    ),// Green data in
.red_din                        (hdmi_r                    ),// Red data in
.hsync                          (hdmi_hs                   ),// hsync data
.vsync                          (hdmi_vs                   ),// vsync data
.de                             (hdmi_de                   ),// data enable
.tmds_clk_p                     (tmds_clk_p                ),
.tmds_clk_n                     (tmds_clk_n                ),
.tmds_data_p                    (tmds_data_p               ),//rgb
.tmds_data_n                    (tmds_data_n               ) //rgb
);
endmodule
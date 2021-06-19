//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2020 11:25:59 AM
// Design Name: 
// Module Name: GMII_TRI_ETH_TOP
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
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
module GMII_TRI_ETH_TOP  
(
input	wire			i_sys_clk,					//system clk
input	wire			i_sys_rst_n,				//rst of sys_clk

input	wire			clk_csr_i,					//CSR clk,----25-300MHz!!!!
input	wire			rst_clk_csr_n,				//active low reset synch to clk_csr_i

input	wire			clk_tx_i,					//GMII transmit reference clock,all port share the transmit clock
input	wire			rst_clk_tx_n,				//active low reset synch to clk_tx_i

input	wire			tri_refclk_i,				//TRI reference clock


// GMII Interface
//---------------
output 	wire	[7:0]	gmii_txd,
output 	wire	     	gmii_tx_en,
output 	wire	     	gmii_tx_er,
output 	wire	     	gmii_tx_clk,
input  	wire	[7:0]	gmii_rxd,
input  	wire	     	gmii_rx_dv,
input  	wire	     	gmii_rx_er,
input  	wire	     	gmii_rx_clk,
input  	wire	     	mii_tx_clk,

output	wire	[0:0]	mac_speed_0_o,				//Speed select output for MAC

// Master Write Address (unused)
output [0:0]    	    M_AXI_AWID,
output [31:0]   	    M_AXI_AWADDR,
output [7:0]    	    M_AXI_AWLEN,    // Burst Length: 0-255
output [2:0]    	    M_AXI_AWSIZE,   // Burst Size: Fixed 2'b011
output [1:0]    	    M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
output          	    M_AXI_AWLOCK,   // Lock: Fixed 2'b00
output [3:0]    	    M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
output [2:0]    	    M_AXI_AWPROT,   // Protect: Fixed 2'b000
output [3:0]    	    M_AXI_AWQOS,    // QoS: Fixed 2'b0000
output          	    M_AXI_AWVALID,
input           	    M_AXI_AWREADY,    
// Master Write Data (unused)
output [31:0]     	    M_AXI_WDATA,
output [7:0]      	    M_AXI_WSTRB,
output            	    M_AXI_WLAST,
output            	    M_AXI_WVALID,
input             	    M_AXI_WREADY,
// Master Write Response (unused)
input [0:0]     	    M_AXI_BID,
input [1:0]     	    M_AXI_BRESP,
input           	    M_AXI_BVALID,
output          	    M_AXI_BREADY,

// Master Read Address
output [0:0]     	    M_AXI_ARID,
output [31:0]    	    M_AXI_ARADDR,
output [7:0]     	    M_AXI_ARLEN,
output [2:0]     	    M_AXI_ARSIZE,
output [1:0]     	    M_AXI_ARBURST,
output [1:0]     	    M_AXI_ARLOCK,
output [3:0]     	    M_AXI_ARCACHE,
output [2:0]     	    M_AXI_ARPROT,
output [3:0]     	    M_AXI_ARQOS,
output           	    M_AXI_ARVALID,
input            	    M_AXI_ARREADY,

// Master Read Data 
input [0:0]       	    M_AXI_RID,
input [31:0]      	    M_AXI_RDATA,
input [1:0]       	    M_AXI_RRESP,
input             	    M_AXI_RLAST,
input             	    M_AXI_RVALID,
output            	    M_AXI_RREADY

);
	  

 //     (*MARK_DEBUG="true"*)   reg [7:0] gmii_rx_d_1_reg;
 //     (*MARK_DEBUG="true"*)   reg       gmii_rx_dv_1_reg;
      

      // asynchronous reset
      wire	                glbl_rstn;
      wire	                rx_axi_rstn;
      wire	                tx_axi_rstn;
      // Receiver Interface
      //--------------------------
	  wire            		rx_enable;
	  wire      [27:0]		rx_statistics_vector;
	  wire            		rx_statistics_valid;
      wire            		rx_mac_aclk;
      wire            		rx_reset;
      wire      [7:0] 		rx_axis_mac_tdata;
      wire            		rx_axis_mac_tvalid;
      wire            		rx_axis_mac_tlast;
      wire            		rx_axis_mac_tuser;
      // Transmitter Interface
      //-----------------------------
      wire            		tx_enable;
      wire      [7:0] 		tx_ifg_delay;
      wire      [31:0] 		tx_ifg_delay_reg;
	  wire      [31:0]		tx_statistics_vector;
	  wire            		tx_statistics_valid;
      wire            		tx_mac_aclk;
      wire            		tx_reset;
      wire      [7:0] 		tx_axis_mac_tdata;
      wire            		tx_axis_mac_tvalid;
      wire            		tx_axis_mac_tlast;
      wire            		tx_axis_mac_tuser;
      wire            		tx_axis_mac_tready;
      // MAC Control Interface
      //----------------------
      wire             		pause_req		=	1'b0;
      wire       [15:0]		pause_val		=	16'b0;
      wire              	speedis100;
      wire              	speedis10100;
	  assign	mac_speed_0_o	= speedis10100;


//(*MARK_DEBUG="true"*)   reg [15:0] gmii_byte_outcnt;
//(*MARK_DEBUG="true"*) reg [31:0] axi_byte_outcnt;


wire	[7:0]	tx_axis_mac_tdata0		;	
wire            tx_axis_mac_tlast0		;	
wire            tx_axis_mac_tuser0		;	
wire            tx_axis_mac_tvalid0		;
wire			tx_axis_mac_tready0     ;

//always@(posedge gmii_tx_clk or negedge rst_clk_tx_n) if(!rst_clk_tx_n)  gmii_byte_outcnt  <= 16'b0; else if(gmii_tx_en) gmii_byte_outcnt  <= gmii_byte_outcnt  + 16'b1; else gmii_byte_outcnt  <= gmii_byte_outcnt;
//always@(posedge tx_mac_aclk or posedge tx_reset) if(tx_reset)  axi_byte_outcnt <= 32'b0; else if(tx_statistics_valid) axi_byte_outcnt <= axi_byte_outcnt + {18'b0,tx_statistics_vector[18:5]}; else axi_byte_outcnt <= axi_byte_outcnt;

tri_mode_ethernet_mac_0 tri_mode_ethernet_mac_inst (
  .gtx_clk(clk_tx_i),                                 // input wire gtx_clk
  .glbl_rstn(rst_clk_csr_n),                          // input wire glbl_rstn
  .rx_axi_rstn(rst_clk_tx_n),                         // input wire rx_axi_rstn
  .tx_axi_rstn(rst_clk_tx_n),                         // input wire tx_axi_rstn
  .rx_statistics_vector(rx_statistics_vector),        // output wire [27 : 0] rx_statistics_vector
  .rx_statistics_valid(rx_statistics_valid),          // output wire rx_statistics_valid
  .rx_mac_aclk(rx_mac_aclk),                          // output wire rx_mac_aclk
  .rx_reset(rx_reset),                                // output wire rx_reset
  .rx_enable(rx_enable),                              // output wire rx_enable
  .rx_axis_mac_tdata(rx_axis_mac_tdata),              // output wire [7 : 0] rx_axis_mac_tdata
  .rx_axis_mac_tvalid(rx_axis_mac_tvalid),            // output wire rx_axis_mac_tvalid
  .rx_axis_mac_tlast(rx_axis_mac_tlast),              // output wire rx_axis_mac_tlast
  .rx_axis_mac_tuser(rx_axis_mac_tuser),              // output wire rx_axis_mac_tuser
  .tx_ifg_delay(8'hc),                                // input wire [7 : 0] tx_ifg_delay
  .tx_statistics_vector(tx_statistics_vector),        // output wire [31 : 0] tx_statistics_vector
  .tx_statistics_valid(tx_statistics_valid),          // output wire tx_statistics_valid
  .tx_mac_aclk(tx_mac_aclk),                          // output wire tx_mac_aclk
  .tx_reset(tx_reset),                                // output wire tx_reset
  .tx_enable(tx_enable),                              // output wire tx_enable
  .tx_axis_mac_tdata(tx_axis_mac_tdata0),              // input wire [7 : 0] tx_axis_mac_tdata
  .tx_axis_mac_tvalid(tx_axis_mac_tvalid0),            // input wire tx_axis_mac_tvalid
  .tx_axis_mac_tlast(tx_axis_mac_tlast0),              // input wire tx_axis_mac_tlast
  .tx_axis_mac_tuser(tx_axis_mac_tuser0),              // input wire [0 : 0] tx_axis_mac_tuser
  .tx_axis_mac_tready(tx_axis_mac_tready0),            // output wire tx_axis_mac_tready
  .pause_req(pause_req),                              // input wire pause_req
  .pause_val(pause_val),                              // input wire [15 : 0] pause_val
  .refclk(tri_refclk_i),                              // input wire refclk
  .speedis100(speedis100),                            // output wire speedis100
  .speedis10100(speedis10100),                        // output wire speedis10100
  .gmii_txd(gmii_txd),                                // output wire [7 : 0] gmii_txd
  .gmii_tx_en(gmii_tx_en),                            // output wire gmii_tx_en
  .gmii_tx_er(gmii_tx_er),                            // output wire gmii_tx_er
  .gmii_tx_clk(gmii_tx_clk),                          // output wire gmii_tx_clk
  .gmii_rxd(gmii_rxd),                                // input wire [7 : 0] gmii_rxd
  .gmii_rx_dv(gmii_rx_dv),                            // input wire gmii_rx_dv
  .gmii_rx_er(gmii_rx_er),                            // input wire gmii_rx_er
  .gmii_rx_clk(gmii_rx_clk),                          // input wire gmii_rx_clk
  .mii_tx_clk(mii_tx_clk),                            // input wire mii_tx_clk
  .rx_configuration_vector({16'h3,32'h22221111,32'h00002806}),  // input wire [79 : 0] rx_configuration_vector
  .tx_configuration_vector({16'h3,32'h22223333,32'h00002006})  // input wire [79 : 0] tx_configuration_vector
);

wire    m_axis_rx_alf                   ;

wire	[519:0]	TF_8to512_out			;
wire			TF_8to512_out_wr		;
wire	[111:0] TF_8to512_out_valid		;
wire			TF_8to512_out_valid_wr	;
wire			TF_8to512_in_alf       ;

wire	[519:0]	TF_512to8_in			;
wire			TF_512to8_in_wr			;
wire	[111:0] TF_512to8_in_valid		;
wire			TF_512to8_in_valid_wr	;
wire			TF_512to8_out_alf		;



TF_8to512 TF_8to512_inst(
	.clk					(rx_mac_aclk				),
	.rst_n					(~rx_reset					),
	
	.TF_8to512_out			(TF_8to512_out				),
	.TF_8to512_out_wr		(TF_8to512_out_wr			),
	.TF_8to512_out_valid	(TF_8to512_out_valid		),
	.TF_8to512_out_valid_wr	(TF_8to512_out_valid_wr		),
	.TF_8to512_in_alf		(TF_8to512_in_alf			),
	
	.m_axis_rx_tdata		(rx_axis_mac_tdata			),
	.m_axis_rx_tlast		(rx_axis_mac_tlast			),
	.m_axis_rx_tuser		(rx_axis_mac_tuser			),
	.m_axis_rx_tvalid		(rx_axis_mac_tvalid			) 
);


TF_512to8 TF_512to8_inst(
	.wr_clk					(i_sys_clk					),
	.rd_clk					(tx_mac_aclk				),
	.wr_rst_n				(i_sys_rst_n				),
	.rd_rst_n				(~tx_reset					),
	
	.s_axis_tx_alf			(m_axis_rx_alf				),
	.s_axis_tx_tdata		(tx_axis_mac_tdata			),
	.s_axis_tx_tlast		(tx_axis_mac_tlast			),
	.s_axis_tx_tuser		(tx_axis_mac_tuser			),
	.s_axis_tx_tvalid		(tx_axis_mac_tvalid			),
	
	.TF_512to8_in			(TF_512to8_in				),
	.TF_512to8_in_wr		(TF_512to8_in_wr			),
	.TF_512to8_in_valid		(TF_512to8_in_valid			),
	.TF_512to8_in_valid_wr	(TF_512to8_in_valid_wr		),
	.TF_512to8_out_alf		(TF_512to8_out_alf			) 
);

gmii_test_pkt	gmii_test_pkt_inst(
	.rdclk				(tx_mac_aclk				),
	.rd_reset			(~rx_reset					),
	.wrclk				(tx_mac_aclk				),
	.wr_reset			(~rx_reset					),

	.s_axis_tx_tready	(tx_axis_mac_tready0		),
	.s_axis_tx_tdata	(tx_axis_mac_tdata0			),
	.s_axis_tx_tlast	(tx_axis_mac_tlast0			),
	.s_axis_tx_tuser	(tx_axis_mac_tuser0			),
	.s_axis_tx_tvalid	(tx_axis_mac_tvalid0		),

	.m_axis_rx_tdata	(tx_axis_mac_tdata			),
	.m_axis_rx_tlast	(tx_axis_mac_tlast			),
	.m_axis_rx_tuser	(tx_axis_mac_tuser			),
	.m_axis_rx_tvalid	(tx_axis_mac_tvalid			), 
	.s_axis_rx_alf		(m_axis_rx_alf				) 
);

wire	[519:0]	o_dpkt_data    			;
wire			o_dpkt_data_en 			;
wire	[111:0] o_dpkt_meta    			;
wire			o_dpkt_meta_en 			;
wire			i_dpkt_fifo_alf			;

wire	[519:0]	o_cpkt_data       		;
wire			o_cpkt_data_en    		;
wire	[255:0] o_cpkt_meta       		;
wire			o_cpkt_meta_en    		;
wire			i_cpkt_fifo_alf   		;

PREPARSE PREPARSE
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  .i_sys_clk                 	(rx_mac_aclk				)//system clk
 ,.i_sys_rst_n               	(~rx_reset					)//rst of sys_clk
 
 ,.rd_sys_clk                   (i_sys_clk					)//system clk 
 ,.rd_sys_rst_n                 (i_sys_rst_n				)//rst of sys_clk  
 
//=========================================== Input ARI  ==========================================//

//input pkt data form application(ARI)
,.i_ari_data                   	(TF_8to512_out				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_data_en                	(TF_8to512_out_wr			)//data enable
,.i_ari_info					(TF_8to512_out_valid		)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_info_en                	(TF_8to512_out_valid_wr		)//info enable
,.o_ari_fifo_alf               	(TF_8to512_in_alf			)//fifo almostfull

//=========================================== control signal ===========================================//

,.i_nacpc_mac                   (48'h888888888888   )//the chip's MAC address of NACP control pkt

//=========================================== Output data pkt  ==========================================//
,.o_dpkt_data                 	(o_dpkt_data    	)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.o_dpkt_data_en              	(o_dpkt_data_en 	)//data enable
,.o_dpkt_meta                 	(o_dpkt_meta    	)//metadata
,.o_dpkt_meta_en              	(o_dpkt_meta_en 	)//meta enable
,.i_dpkt_fifo_alf             	(i_dpkt_fifo_alf	)//fifo almostfull

//=========================================== Output control pkt  ==========================================//
,.o_cpkt_data                	(o_cpkt_data       	)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.o_cpkt_data_en             	(o_cpkt_data_en    	)//data enable
,.o_cpkt_meta                	(o_cpkt_meta       	)//metadata
,.o_cpkt_meta_en             	(o_cpkt_meta_en    	)//meta enable
,.i_cpkt_fifo_alf            	(i_cpkt_fifo_alf   	)//fifo almostfull


);

//controller related signals
wire ddr_write_finish;
wire ddr_write_finish_valid;
wire ddr_write_finish_ready;

wire odd_even_flag;

wire ddr_write_start;
wire ddr_write_start_valid;
wire ddr_write_start_ready;


	wire		[63:0]			gmii_command;
	wire						gmii_command_wr;
	wire						gmii_command_alf;
	wire		[63:0]			gmii_result;
	wire						gmii_result_wr;
	wire						gmii_result_alf;
	wire 						Sequence_wr						;//pkt sequence write
	wire 		[255:0]			Sequence						;//pkt sequence
	wire 						Sequence_alf					;//pkt allmostfull
	wire	 	[31:0] 			command_pkt_in_cnt				;//pkt input cnt
	wire		[31:0]			command_out_cnt					;//command out cnt
	wire		[31:0]			command_debug_current			;//debug signal
	wire	 	[31:0] 			result_pkt_in_cnt				;//pkt input cnt
	wire		[31:0]			result_out_cnt					;//command out cnt
	wire		[31:0]			result_debug_current			;//debug signal


// camera_adaptor camera_adaptor(
//     // Reset, Clock
//     .aresetn(i_sys_rst_n),
//     .clk(i_sys_clk),

//     //ctrls from controller
//     .ddr_write_finish(ddr_write_finish),
//     .ddr_write_finish_valid(ddr_write_finish_valid),
//     .ddr_write_finish_ready(ddr_write_finish_ready),

//     .odd_even_flag(odd_even_flag),

//     .ddr_write_start(ddr_write_start),
//     .ddr_write_start_valid(ddr_write_start_valid),
//     .ddr_write_start_ready(ddr_write_start_ready),

//     //generate packets
//     .pktin_data(o_dpkt_data),
//     .pktin_en(o_dpkt_data_en),
//     .pkt_in_md(o_dpkt_meta),
//     .pkt_in_md_en(o_dpkt_meta_en),
//     .pkt_data_alf(i_dpkt_fifo_alf),
  

//     // Master Write Address
//     .M_AXI_AWID(M_AXI_AWID),
//     .M_AXI_AWADDR(M_AXI_AWADDR),
//     .M_AXI_AWLEN(M_AXI_AWLEN),    // Burst Length: 0-255
//     .M_AXI_AWSIZE(M_AXI_AWSIZE),   // Burst Size: Fixed 2'b011
//     .M_AXI_AWBURST(M_AXI_AWBURST),  // Burst Type: Fixed 2'b01(Incremental Burst)
//     .M_AXI_AWLOCK(M_AXI_AWLOCK),   // Lock: Fixed 2'b00
//     .M_AXI_AWCACHE(M_AXI_AWCACHE),  // Cache: Fiex 2'b0011
//     .M_AXI_AWPROT(M_AXI_AWPROT),   // Protect: Fixed 2'b000
//     .M_AXI_AWQOS(M_AXI_AWQOS),    // QoS: Fixed 2'b0000
//     .M_AXI_AWVALID(M_AXI_AWVALID),
//     .M_AXI_AWREADY(M_AXI_AWREADY),    

//     // Master Write Data
//     .M_AXI_WDATA(M_AXI_WDATA),
//     .M_AXI_WSTRB(M_AXI_WSTRB),
//     .M_AXI_WLAST(M_AXI_WLAST),
//     .M_AXI_WVALID(M_AXI_WVALID),
//     .M_AXI_WREADY(M_AXI_WREADY),

//     // Master Write Response
//     .M_AXI_BID(M_AXI_BID),
//     .M_AXI_BRESP(M_AXI_BRESP),
//     .M_AXI_BVALID(M_AXI_BVALID),
//     .M_AXI_BREADY(M_AXI_BREADY)
    
// );

wire 		start_all;

wire 		ddr_read_start;
wire 		ddr_read_start_valid;
wire 		ddr_read_start_ready;

wire 		r_write_start;
wire 		r_write_start_valid;
wire 		r_write_start_ready;

wire 	    	acc_start;
wire 			acc_finish;
wire 			cmd_out_wr;
wire [63:0]		cmd_out;
wire 			cmd_out_alf;


// controller controller(
//     .clk(i_sys_clk),
//     .aresetn(i_sys_rst_n),

//     //from outside
//     .start_all(1'b1),
//     //TO MONITOR
//     .ddr_read_start(ddr_read_start),
//     .ddr_read_start_valid(ddr_read_start_valid),
//     .ddr_read_start_ready(ddr_read_start_ready),
    
//     //TO CAMERA
//     .ddr_write_start(ddr_write_start),
//     .ddr_write_start_valid(ddr_write_start_valid),
//     .ddr_write_start_ready(ddr_write_start_ready),

//     //FROM MONITOR
//     .ddr_read_finish(ddr_read_finish),
//     .ddr_read_finish_valid(ddr_read_finish_valid),
//     .ddr_read_finish_ready(ddr_read_finish_ready),

//     //FROM CAMERA
//     .ddr_write_finish(ddr_write_finish),
//     .ddr_write_finish_valid(ddr_write_finish_valid),
//     .ddr_write_finish_ready(ddr_write_finish_ready),

//     //TO/FROM ACCEL
//     .acc_start(acc_start),
//     .acc_finish(acc_finish),
//     .cmd_in_wr				(gmii_result_wr				),
//     .cmd_in					(gmii_result					),
//     .cmd_in_alf				(gmii_command_alf				),

// //TODO: connect to accel modules && cmd pkt module
//     .cmd_out_wr(gmii_command_wr),
// 	.cmd_out(),
// 	.cmd_out_alf(),
//     .odd_even_flag(odd_even_flag)
// );


wire	[519:0]	pkt_out_data    			;
wire			pkt_out_en 					;
wire	[111:0] pkt_out_md    				;
wire			pkt_out_md_en 				;
wire			pkt_out_data_alf			;


// monitor_adaptor monitor_adaptor(
//     // Reset, Clock
//     .aresetn(i_sys_rst_n),
//     .clk(i_sys_clk),

//     //ctrls from controller
//     .ddr_read_finish(ddr_read_finish),
//     .ddr_read_finish_valid(ddr_read_finish_valid),
//     .ddr_read_finish_ready(ddr_read_finish_ready),
//     .odd_even_flag(~odd_even_flag),

//     .ddr_read_start(ddr_read_start),
//     .ddr_read_start_valid(ddr_read_start_valid),
//     .ddr_read_start_ready(ddr_read_start_ready),

//     //generate packets
//     .pkt_out_data(pkt_out_data),
//     .pkt_out_en(pkt_out_en),
//     .pkt_out_md(pkt_out_md),
//     .pkt_out_md_en(pkt_out_md_en),
//     .pkt_out_data_alf(pkt_out_data_alf),
  

//     // Master Read Address
//     .M_AXI_ARID(M_AXI_ARID),
//     .M_AXI_ARADDR(M_AXI_ARADDR),
//     .M_AXI_ARLEN(M_AXI_ARLEN),
//     .M_AXI_ARSIZE(M_AXI_ARSIZE),
//     .M_AXI_ARBURST(M_AXI_ARBURST),
//     .M_AXI_ARLOCK(M_AXI_ARLOCK),
//     .M_AXI_ARCACHE(M_AXI_ARCACHE),
//     .M_AXI_ARPROT(M_AXI_ARPROT),
//     .M_AXI_ARQOS(M_AXI_ARQOS),
//     .M_AXI_ARVALID(M_AXI_ARVALID),
//     .M_AXI_ARREADY(M_AXI_ARREADY),
    
//     // Master Read Data 
//     .M_AXI_RID(M_AXI_RID),
//     .M_AXI_RDATA(M_AXI_RDATA),
//     .M_AXI_RRESP(M_AXI_RRESP),
//     .M_AXI_RLAST(M_AXI_RLAST),
//     .M_AXI_RVALID(M_AXI_RVALID),
//     .M_AXI_RREADY(M_AXI_RREADY)
    
// );



cur_top_pt curr_top(
    .clk(i_sys_clk),
    .aresetn(i_sys_rst_n),

    // generate packets from preparser
    .pktin_data            (o_dpkt_data)  	 ,
    .pktin_en              (o_dpkt_data_en)  ,
    .pkt_in_md             (o_dpkt_meta) 	 ,
    .pkt_in_md_en          (o_dpkt_meta_en)  ,
    .pkt_data_alf          (i_dpkt_fifo_alf) ,

    // commands from ctlpkt
    .cmd_in_wr             (gmii_command_wr	)  ,
    .cmd_in                (gmii_command	)  ,
    .cmd_in_alf            (gmii_command_alf)  ,

    // commands to result2ctl
    .cmd_out_wr            (gmii_result_wr  )  ,       //command write signal
    .cmd_out               (gmii_result     )  ,       //command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
    .cmd_out_alf           ()  ,

    // generate packets to MUX
    .pkt_out_data          (pkt_out_data)		 ,
    .pkt_out_en            (pkt_out_en) 		 ,
    .pkt_out_md            (pkt_out_md) 		 ,
    .pkt_out_md_en         (pkt_out_md_en)  	 ,
    .pkt_out_data_alf      (pkt_out_data_alf)    ,


    // AXI signal TO/FROM axi_interconnect_0
    .S00_AXI_ARESET_OUT_N   ()    ,    // S00 for monitor
    .S01_AXI_ARESET_OUT_N   ()    ,    // S01 for camera
    .S02_AXI_ARESET_OUT_N   ()    ,    // S02 for accelerator
    .S03_AXI_ARESET_OUT_N   ()    ,    // S03 for accelerator
    .M00_AXI_ARESET_OUT_N   ()    ,

    .M00_AXI_ACLK           (i_sys_clk)      ,          

    .M00_AXI_AWID           (M_AXI_AWID)  	  ,
    .M00_AXI_AWADDR         (M_AXI_AWADDR)    ,
    .M00_AXI_AWLEN          (M_AXI_AWLEN)  	  ,
    .M00_AXI_AWSIZE         (M_AXI_AWSIZE)    ,
    .M00_AXI_AWBURST        (M_AXI_AWBURST)   ,
    .M00_AXI_AWLOCK         (M_AXI_AWLOCK)    ,
    .M00_AXI_AWCACHE        (M_AXI_AWCACHE)   ,
    .M00_AXI_AWPROT         (M_AXI_AWPROT)    ,
    .M00_AXI_AWQOS          (M_AXI_AWQOS)     ,
    .M00_AXI_AWVALID        (M_AXI_AWVALID)   ,
    .M00_AXI_AWREADY        (M_AXI_AWREADY)   ,

    .M00_AXI_WDATA          (M_AXI_WDATA)    ,
    .M00_AXI_WSTRB          (M_AXI_WSTRB)    ,
    .M00_AXI_WLAST          (M_AXI_WLAST)    ,
    .M00_AXI_WVALID         (M_AXI_WVALID)   ,
    .M00_AXI_WREADY         (M_AXI_WREADY)   ,

    .M00_AXI_BID            (M_AXI_BID)      ,
    .M00_AXI_BRESP          (M_AXI_BRESP)    ,
    .M00_AXI_BVALID         (M_AXI_BVALID)   ,
    .M00_AXI_BREADY         (M_AXI_BREADY)   ,

    .M00_AXI_ARID           (M_AXI_ARID)     ,
    .M00_AXI_ARADDR         (M_AXI_ARADDR)   ,
    .M00_AXI_ARLEN          (M_AXI_ARLEN)    ,
    .M00_AXI_ARSIZE         (M_AXI_ARSIZE)   ,
    .M00_AXI_ARBURST        (M_AXI_ARBURST)  ,
    .M00_AXI_ARLOCK         (M_AXI_ARLOCK)   ,
    .M00_AXI_ARCACHE        (M_AXI_ARCACHE)  ,
    .M00_AXI_ARPROT         (M_AXI_ARPROT)   ,
    .M00_AXI_ARQOS          (M_AXI_ARQOS)    ,
    .M00_AXI_ARVALID        (M_AXI_ARVALID)  ,
    .M00_AXI_ARREADY        (M_AXI_ARREADY)  ,

    .M00_AXI_RID            (M_AXI_RID)      ,
    .M00_AXI_RDATA          (M_AXI_RDATA)    ,
    .M00_AXI_RRESP          (M_AXI_RRESP)    ,
    .M00_AXI_RLAST          (M_AXI_RLAST)    ,
    .M00_AXI_RVALID         (M_AXI_RVALID)   ,
    .M00_AXI_RREAD          (M_AXI_RREADY)    
);

	
	wire	[519:0]				IFE_ctrlpkt_out			;
	wire						IFE_ctrlpkt_out_wr		;
	wire	[111:0] 			IFE_ctrlpkt_out_valid	;
	wire						IFE_ctrlpkt_out_valid_wr;
	wire						IFE_ctrlpkt_in_alf		;
	
CTRLPKT2COMMAND	CTRLPKT2COMMAND_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(i_sys_clk						),//clock, this is synchronous clock
	.Reset_N					(i_sys_rst_n					),//Reset the all signal, active high
//=========================================== frame from IFE ===========================================//
	.IFE_ctrlpkt_in				(o_cpkt_data       				),//receive pkt
	.IFE_ctrlpkt_in_wr			(o_cpkt_data_en    				),//receive pkt write singal
	.IFE_ctrlpkt_in_valid		(o_cpkt_meta       				),//receive metadata
	.IFE_ctrlpkt_in_valid_wr	(o_cpkt_meta_en    				),//receive metadata write signal 
	.IFE_ctrlpkt_out_alf		(   							),//output allmostfull
//======================================= command to the config path ==================================//
	.Command_wr					(gmii_command_wr				),//command write signal
	.Command					(gmii_command					),//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	.Command_alf				(gmii_command_alf				),//commadn almostful
//=================================== counter & debug ====================================//
	.pkt_in_cnt					(command_pkt_in_cnt				),//pkt input cnt
	.com_out_cnt				(command_out_cnt				)//command out cnt
);
	


RESULT2CTRLPKT	RESULT2CTRLPKT_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(i_sys_clk						),//clock, this is synchronous clock
	.Reset_N					(i_sys_rst_n					),//Reset the all signal, active high
//=========================================== frame to IFE ===========================================//
	.IFE_ctrlpkt_out			(IFE_ctrlpkt_out				),//receive pkt
	.IFE_ctrlpkt_out_wr			(IFE_ctrlpkt_out_wr				),//receive pkt write singal
	.IFE_ctrlpkt_out_valid		(IFE_ctrlpkt_out_valid			),//receive metadata
	.IFE_ctrlpkt_out_valid_wr	(IFE_ctrlpkt_out_valid_wr		),//receive metadata write signal 
	.IFE_ctrlpkt_in_alf			(IFE_ctrlpkt_in_alf				),//output allmostfull
//======================================= command to the config path ==================================//
	.Result_wr					(gmii_result_wr					),//command write signal
	.Result						(gmii_result					),

//=================================== counter & debug ====================================//
	.pkt_out_cnt				(result_pkt_in_cnt				),//pkt output cnt
	.result_in_cnt				(result_out_cnt					)//result in cnt	
);


POLL_MUX4 POLL_MUX4_inst
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  .i_sys_clk                   	(i_sys_clk						)//system clk
 ,.i_sys_rst_n                 	(i_sys_rst_n					)//rst of sys_clk
 
//=========================================== Input ARI*4  ==========================================//

//input pkt data form ARI
,.i_ari_0_data                	(IFE_ctrlpkt_out				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_0_data_en             	(IFE_ctrlpkt_out_wr				)//data enable
,.i_ari_0_info                	(IFE_ctrlpkt_out_valid			)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_0_info_en             	(IFE_ctrlpkt_out_valid_wr		)//info enable
,.o_ari_0_fifo_alf            	(IFE_ctrlpkt_in_alf				)//fifo almostfull

,.i_ari_1_data                 	(pkt_out_data    				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_1_data_en              	(pkt_out_en 					)//data enable
,.i_ari_1_info                 	(pkt_out_md    					)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_1_info_en              	(pkt_out_md_en 					)//info enable
,.o_ari_1_fifo_alf             	(pkt_out_data_alf				)//fifo almostfull

,.i_ari_2_data                 	(520'b0				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_2_data_en              	(1'b0				)//data enable
,.i_ari_2_info                 	(112'b0				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_2_info_en              	(1'b0				)//info enable
,.o_ari_2_fifo_alf             	(1'b0				)//fifo almostfull

,.i_ari_3_data                	(520'b0				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_3_data_en				(1'b0				)//data enable
,.i_ari_3_info					(112'b0				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_3_info_en				(1'b0				)//info enable
,.o_ari_3_fifo_alf				(1'b0				)//fifo almostfull

//=========================================== Output ARI  ==========================================//
,.o_ari_data                	(TF_512to8_in			)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.o_ari_data_en             	(TF_512to8_in_wr		)//data enable
,.o_ari_info                	(TF_512to8_in_valid		)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.o_ari_info_en             	(TF_512to8_in_valid_wr	)//info enable
,.i_ari_fifo_alf            	(TF_512to8_out_alf		)//fifo almostfull
);

endmodule

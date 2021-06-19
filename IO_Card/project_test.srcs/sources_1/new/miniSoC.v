module miniSoC #(
    parameter AXIS_DATA_WIDTH = 8,
    parameter AXIS_KEEP_WIDTH = 1
)(
//system clock & resets
    input       wire            i_sys_clk,  // 50MHz
    input       wire            i_sys_rst_n,
//system clock & resets
    input key1,

// CMOS
    inout                            cmos_scl,               //cmos i2c clock
    inout                            cmos_sda,               //cmos i2c data
    input                            cmos_vsync,             //cmos vsync
    input                            cmos_href,              //cmos hsync refrence,data valid
    input                            cmos_pclk,              //cmos pxiel clock
    output                           cmos_xclk,              //cmos externl clock
    input   [7:0]                    cmos_db,                //cmos data  
// CMOS

// HDMI
    output                           tmds_clk_p,             //HDMI differential clock positive
    output                           tmds_clk_n,             //HDMI differential clock negative
    output[2:0]                      tmds_data_p,            //HDMI differential data positive
    output[2:0]                      tmds_data_n,             //HDMI differential data negative
// HDMI

// rgmii interface
    output              e_mdc,                           //phy emdio clock
    inout               e_mdio,                          //phy emdio data
    output[3:0]         rgmii_txd,                       //phy data send
    output              rgmii_txctl,                     //phy data send control
    output              rgmii_txc,                       //Clock for sending data //125MHz for 1000M
    input [3:0]         rgmii_rxd,                       //recieve data
    input               rgmii_rxctl,                     //Control signal for receiving data
    input               rgmii_rxc                        //Clock for recieving data
// rgmii interface	
    //ddr3
,inout [31:0]                     ddr3_dq,                //ddr3 data
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
    
wire i_sys_clk_IBUFG;
    reg key1_d1;
    reg Command_wr_i_key;
    always @(posedge i_sys_clk_IBUFG or negedge i_sys_rst_n) begin
        if(~i_sys_rst_n)begin
            // IFE_ctrlpkt_out_wr_reg <= 1'b0;
            // IFE_ctrlpkt_out_reg <= 520'd0;
            key1_d1<='d0;
        end
        else begin
            // IFE_ctrlpkt_out_wr_reg <= IFE_ctrlpkt_out_wr;
            // IFE_ctrlpkt_out_reg <= IFE_ctrlpkt_out;
            key1_d1 <= key1;
            if(key1_d1 && (~key1))begin
                Command_wr_i_key <= 1'b1;
            end
            else begin
                Command_wr_i_key <= 1'b0;
            end
        end
    end



IBUFG #(
  .IBUF_LOW_PWR("TRUE"),  // Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards 
  .IOSTANDARD("LVCMOS33")  // Specify the input I/O standard
) ibuf_global_clk (
  .I(i_sys_clk),
  .O(i_sys_clk_IBUFG)
);


/*
 * AXI input
 */
wire [AXIS_DATA_WIDTH-1:0] tx_axis_tdata;
wire [AXIS_KEEP_WIDTH-1:0] tx_axis_tkeep;
wire                       tx_axis_tvalid;
wire                       tx_axis_tready;
wire                       tx_axis_tlast;
wire                       tx_axis_tuser;
/*
 * AXI output
 */
wire [AXIS_DATA_WIDTH-1:0] rx_axis_tdata;
wire [AXIS_KEEP_WIDTH-1:0] rx_axis_tkeep;
wire                       rx_axis_tvalid;
wire                       rx_axis_tready;
wire                       rx_axis_tlast;
wire                       rx_axis_tuser;

    wire rgmii_rxc_90;



// ila_0 your_instance_name (
// 	.clk(i_sys_clk_IBUFG), // input wire clk


// 	.probe0(rx_axis_tlast), // input wire [0:0]  probe0  //这个是进来的512位数据使能信号，然后进行分派
// 	.probe1(rx_axis_tdata), // input wire [0:0]  probe1   // 这个是分派给显示器的数据使能
//     .probe2(TF_8to512_out_wr),
//     .probe3(o_cpkt_data_en),
//     .probe4(o_dpkt_data_en),
//     .probe5(gmii_command_wr),
//     .probe6(Command_wr_o),
//     .probe7(IFE_ctrlpkt_out_wr_0),
//     .probe8(TF_512to8_in_wr),
//     .probe9(TF_512to8_in_valid_wr),
//     .probe10(tx_axis_tvalid),
//     .probe11(tx_axis_tlast)

// );
  pll_90_degree pll_90_degree_i0
   (
    // Clock out ports
    .clk_out1(rgmii_rxc_90),     // output clk_out1
    // Status and control signals
    .reset('b0), // input reset
    .locked( ),       // output locked
   // Clock in ports
    .clk_in1(rgmii_rxc));      // input clk_in1

eth_mac_1g_rgmii_fifo #
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    .TARGET("XILINX"),
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    .IODDR_STYLE("IODDR"),
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-5, Virtex-6, 7-series
    // Use BUFG for Ultrascale
    // Use BUFIO2 for Spartan-6
    .CLOCK_INPUT_STYLE("BUFG"),
    // Use 90 degree clock for RGMII transmit ("TRUE", "FALSE")
    .USE_CLK90("TRUE"),
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    // .AXIS_KEEP_ENABLE(),
    .AXIS_KEEP_WIDTH (AXIS_KEEP_WIDTH),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    // .TX_FIFO_DEPTH(),
    .TX_FIFO_PIPELINE_OUTPUT(2),
    .TX_FRAME_FIFO(1),
    .TX_DROP_BAD_FRAME(0),
    .TX_DROP_WHEN_FULL(0),
    // .RX_FIFO_DEPTH(),
    // .RX_FIFO_PIPELINE_OUTPUT(),
    .RX_FRAME_FIFO(1),
    .RX_DROP_BAD_FRAME(1),
    .RX_DROP_WHEN_FULL(1)
)rgmii_mac_1g
(
    .gtx_clk(rgmii_rxc),  //use 125Mhz    //use received 125M clk
    .gtx_clk90(rgmii_rxc_90),              // did not using 90degreee clock
    .gtx_rst(~i_sys_rst_n),
    .logic_clk(i_sys_clk_IBUFG),      // system 50MHz system clk
    .logic_rst(~i_sys_rst_n),

    /*
     * AXI input
     */
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep('b0),      // 这个tkeep信号是输入，没有接信号
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),        // output not wired
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    /*
     * AXI output
     */
    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tkeep(rx_axis_tkeep),      // 这个tkeep信号是输出，没有接信号
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready('b1),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    /*
     * RGMII interface
     */
    .rgmii_rx_clk(rgmii_rxc_90),       // 这个时钟经过一个BUFG后控制其他模块
    .rgmii_rxd(rgmii_rxd),
    .rgmii_rx_ctl(rgmii_rxctl),
    .rgmii_tx_clk(rgmii_txc),       // 这个时钟是由gtx_clk/gtx_clk90经过oddr后输出的。
    .rgmii_txd(rgmii_txd),
    .rgmii_tx_ctl(rgmii_txctl),

    /*
     * Status
     */
    .tx_error_underflow(),
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(rx_fifo_bad_frame),
    .rx_fifo_good_frame(rx_fifo_good_frame),
    .speed(),

    /*
     * Configuration
     */
    .ifg_delay('d0)
    ,.e_mdc(e_mdc)
    ,.e_mdio(e_mdio)
);

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


TF_8to512 TF_8to512_inst_io_card(
	.clk					(i_sys_clk_IBUFG					),
	.rst_n					(i_sys_rst_n				),
	
	.TF_8to512_out			(TF_8to512_out				),
	.TF_8to512_out_wr		(TF_8to512_out_wr			),
	.TF_8to512_out_valid	(TF_8to512_out_valid		),
	.TF_8to512_out_valid_wr	(TF_8to512_out_valid_wr		),
	.TF_8to512_in_alf		(TF_8to512_in_alf			),
	
	.m_axis_rx_tdata		(rx_axis_tdata			),
	.m_axis_rx_tlast		(rx_axis_tlast			),
	.m_axis_rx_tuser		(rx_axis_tuser			),
	.m_axis_rx_tvalid		(rx_axis_tvalid		    ) 
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
  .i_sys_clk                 	(i_sys_clk_IBUFG					)//system clk
 ,.i_sys_rst_n               	(i_sys_rst_n				)//rst of sys_clk
 ,.rd_sys_clk                   (i_sys_clk_IBUFG            )
 ,.rd_sys_rst_n                 (i_sys_rst_n                )
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
,.o_dpkt_meta                 	(    	)//metadata
,.o_dpkt_meta_en              	( 	)//meta enable
,.i_dpkt_fifo_alf             	(i_dpkt_fifo_alf	)//fifo almostfull

//=========================================== Output control pkt  ==========================================//
,.o_cpkt_data                	(o_cpkt_data       	)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.o_cpkt_data_en             	(o_cpkt_data_en    	)//data enable
,.o_cpkt_meta                	(o_cpkt_meta       	)//metadata
,.o_cpkt_meta_en             	(o_cpkt_meta_en    	)//meta enable
,.i_cpkt_fifo_alf            	(i_cpkt_fifo_alf   	)//fifo almostfull

);


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

	
	wire	[519:0]				IFE_ctrlpkt_out_0			;
	wire	[519:0]				IFE_ctrlpkt_out_1			;
	wire						IFE_ctrlpkt_out_wr_0		;
	wire						IFE_ctrlpkt_out_wr_1		;
	wire	[111:0] 			IFE_ctrlpkt_out_valid_0	;
	wire	[111:0] 			IFE_ctrlpkt_out_valid_1	;
	wire						IFE_ctrlpkt_out_valid_wr_0;
	wire						IFE_ctrlpkt_out_valid_wr_1;
	wire						IFE_ctrlpkt_in_alf_0		;
	wire						IFE_ctrlpkt_in_alf_1		;
	
CTRLPKT2COMMAND	CTRLPKT2COMMAND_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(i_sys_clk_IBUFG						),//clock, this is synchronous clock
	.Reset_N					(i_sys_rst_n							),//Reset the all signal, active high
//=========================================== frame from IFE ===========================================//
	.IFE_ctrlpkt_in				(o_cpkt_data       				),//receive pkt
	.IFE_ctrlpkt_in_wr			(o_cpkt_data_en    				),//receive pkt write singal
	.IFE_ctrlpkt_in_valid		(o_cpkt_meta       				),//receive metadata
	.IFE_ctrlpkt_in_valid_wr	(o_cpkt_meta_en    				),//receive metadata write signal 
	.IFE_ctrlpkt_out_alf		(				                ),//output allmostfull
//======================================= command to the config path ==================================//
	.Command_wr					(gmii_command_wr				),//command write signal
	.Command					(gmii_command					),//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	.Command_alf				(gmii_command_alf				),//commadn almostful
//=================================== counter & debug ====================================//
	.pkt_in_cnt					(command_pkt_in_cnt				),//pkt input cnt
	.com_out_cnt				(command_out_cnt				)//command out cnt
);

wire packet_end;
//=============================????????????===============================================//
cms_covert  u_cms_covert (
    .i_sys_clk               ( i_sys_clk_IBUFG            ),
    .i_sys_rst_n             ( i_sys_rst_n          ),
    .Command_wr_i            ( gmii_command_wr |Command_wr_i_key       ),
    .Command_i               ( gmii_command            ),
    .Command_alf_o           ( gmii_command_alf        ),
    .cmos_vsync              ( cmos_vsync           ),
    .cmos_href               ( cmos_href            ),
    .cmos_pclk               ( cmos_pclk            ),
    .cmos_db                 ( cmos_db              ),

    .Command_alf_i           (         ),
    .Command_wr_o            ( Command_wr_o         ),
    .Command_o               (             ),//output [63:0] command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
    .cmos_xclk               ( cmos_xclk            ),
    .IFE_ctrlpkt_out         ( IFE_ctrlpkt_out_0      ),    // output [519:0]	
    .IFE_ctrlpkt_out_wr      ( IFE_ctrlpkt_out_wr_0   ),
    .packet_end              ( packet_end),

    .cmos_scl                ( cmos_scl             ),
    .cmos_sda                ( cmos_sda             )
);
//===================================================================================================//

RESULT2CTRLPKT	RESULT2CTRLPKT_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(i_sys_clk_IBUFG						),//clock, this is synchronous clock
	.Reset_N					(i_sys_rst_n							),//Reset the all signal, active high
//=========================================== frame to IFE ===========================================//
	.IFE_ctrlpkt_out			(IFE_ctrlpkt_out_1				),//receive pkt
	.IFE_ctrlpkt_out_wr			(IFE_ctrlpkt_out_wr_1				),//receive pkt write singal
	.IFE_ctrlpkt_out_valid		(IFE_ctrlpkt_out_valid_1			),//receive metadata
	.IFE_ctrlpkt_out_valid_wr	(IFE_ctrlpkt_out_valid_wr_1		),//receive metadata write signal 
	.IFE_ctrlpkt_in_alf			(IFE_ctrlpkt_in_alf_1				),//output allmostfull
//======================================= command to the config path ==================================//
	.Result_wr					(Command_wr_o			),//command write signal
//================================ sequence of command to Result2ctrlpkt ================================//
	.IFE_ctrlpkt_in				(o_cpkt_data       				),//input [519:0]receive pkt
	.IFE_ctrlpkt_in_wr			(o_cpkt_data_en    				),//receive pkt write singal
	.IFE_ctrlpkt_in_valid		(o_cpkt_meta       				),//input [255:0] receive metadata
	.IFE_ctrlpkt_in_valid_wr	(o_cpkt_meta_en  				),//receive metadata write signal 
	.IFE_ctrlpkt_out_alf		(i_cpkt_fifo_alf   				),//output allmostfull
//=================================== counter & debug ====================================//
	.pkt_out_cnt				(result_pkt_in_cnt				),//pkt output cnt
	.result_in_cnt				(result_out_cnt					)//result in cnt	
);

POLL_MUX4 POLL_MUX4_inst
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  .i_sys_clk                   	(i_sys_clk_IBUFG						)//system clk
 ,.i_sys_rst_n                 	(i_sys_rst_n							)//rst of sys_clk
 
//=========================================== Input ARI*4  ==========================================//

//input pkt data form ARI
// 第一个接口是控制的命令报文
,.i_ari_0_data                	(IFE_ctrlpkt_out_0				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_0_data_en             	(IFE_ctrlpkt_out_wr_0				)//data enable
,.i_ari_0_info                	(112'b0			)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_0_info_en             	(packet_end		)//info enable
,.o_ari_0_fifo_alf            	(				)//fifo almostfull
//  这里输入的 info 部分是256位的metadata转换成的112位的valid信号。只再最后一个报文处拉高就行。
// 第二个几口是摄像头图像数据报文
,.i_ari_1_data                 	(IFE_ctrlpkt_out_1    				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_1_data_en              	(IFE_ctrlpkt_out_wr_1 				)//data enable
,.i_ari_1_info                 	(IFE_ctrlpkt_out_valid_1    				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_1_info_en              	(IFE_ctrlpkt_out_valid_wr_1 				)//info enable
,.o_ari_1_fifo_alf             	(IFE_ctrlpkt_in_alf_1				)//fifo almostfull

//=========================================== Output ARI  ==========================================//
,.o_ari_data                	(TF_512to8_in			)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.o_ari_data_en             	(TF_512to8_in_wr		)//data enable
,.o_ari_info                	(TF_512to8_in_valid		)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.o_ari_info_en             	(TF_512to8_in_valid_wr	)//info enable
,.i_ari_fifo_alf            	(TF_512to8_out_alf		)//fifo almostfull
);

TF_512to8 TF_512to8_inst(
	.wr_clk					(i_sys_clk_IBUFG					),
	.rd_clk					(i_sys_clk_IBUFG				),      // mac的发送时钟
	// .rd_clk					(tx_mac_aclk				),
	.wr_rst_n				(i_sys_rst_n				),
	.rd_rst_n				(i_sys_rst_n    			),
	// .rd_rst_n				(~tx_reset					),
	
	.s_axis_tx_alf			(				),  //input 
	// .s_axis_tx_alf			(m_axis_rx_alf				),
	.s_axis_tx_tdata		(tx_axis_tdata			),
	.s_axis_tx_tlast		(tx_axis_tlast			),
	.s_axis_tx_tuser		(tx_axis_tuser			),
	.s_axis_tx_tvalid		(tx_axis_tvalid			),
	
	.TF_512to8_in			(TF_512to8_in				),
	.TF_512to8_in_wr		(TF_512to8_in_wr			),
	.TF_512to8_in_valid		(TF_512to8_in_valid			),
	.TF_512to8_in_valid_wr	(TF_512to8_in_valid_wr		),
	.TF_512to8_out_alf		(TF_512to8_out_alf			) 
);




//================ pixel buffer 负责将接收到的图像报文数据存入DDR并进行显示 ==========================================//
// pixel_buffer Outputs
pixel_buffer  u_pixel_buffer (
    .i_sys_clk               ( i_sys_clk_IBUFG         ),
    .i_sys_rst_n             ( i_sys_rst_n       ),
    .o_dpkt_data             ( o_dpkt_data       ),
    .o_dpkt_data_en          ( o_dpkt_data_en    ),
    .i_dpkt_fifo_alf         ( i_dpkt_fifo_alf   ),

    .tmds_clk_p              ( tmds_clk_p        ),
    .tmds_clk_n              ( tmds_clk_n        ),
    .tmds_data_p             ( tmds_data_p       ),
    .tmds_data_n             ( tmds_data_n       ),

    .ddr3_addr               ( ddr3_addr         ),
    .ddr3_ba                 ( ddr3_ba           ),
    .ddr3_ras_n              ( ddr3_ras_n        ),
    .ddr3_cas_n              ( ddr3_cas_n        ),
    .ddr3_we_n               ( ddr3_we_n         ),
    .ddr3_reset_n            ( ddr3_reset_n      ),
    .ddr3_ck_p               ( ddr3_ck_p         ),
    .ddr3_ck_n               ( ddr3_ck_n         ),
    .ddr3_cke                ( ddr3_cke          ),
    .ddr3_cs_n               ( ddr3_cs_n         ),
    .ddr3_dm                 ( ddr3_dm           ),
    .ddr3_odt                ( ddr3_odt          ),

    .ddr3_dq                 ( ddr3_dq           ),
    .ddr3_dqs_n              ( ddr3_dqs_n        ),
    .ddr3_dqs_p              ( ddr3_dqs_p        )
    
);

endmodule
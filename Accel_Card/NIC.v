`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2020 03:44:07 PM
// Design Name: 
// Module Name: NIC
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


module NIC(
input   MGT114_CLKP,  //aj32
input   MGT114_CLKN, //ak32
input   V7_RESET,  //AH31
input   MGT112_CLKP,//at8
input   MGT112_CLKN,
input      SFP_RXN,
input      SFP_RXP,
output     SFP_TXN,
output     SFP_TXP



);

wire	sys_clk;   
wire	reset;
wire	locked;

clk_wiz_1 clk_wiz_1 (
      // Clock out ports
.clk_out1               (sys_clk),
//.clk_out5               (mstr_aclk),
//.clk_out6               (axi_aclk_156P25),
      // Status and control signals
.reset                  (~V7_RESET),
//.reset                  (1'b0), //zq1008
.locked                 (locked),
     // Clock in ports
.clk_in1_p              (MGT114_CLKP),
.clk_in1_n              (MGT114_CLKN));
//assign clk_625 = sys_clk;



assign reset = locked ;

wire	tx_mac_aclk;
wire	rx_mac_aclk;
wire	tx_reset;
wire	rx_reset;

wire		sg_s_axis_tx_tready		;
wire [7:0]  sg_s_axis_tx_tdata		;	
wire    	sg_s_axis_tx_tlast		;	
wire    	sg_s_axis_tx_tuser		;	
wire    	sg_s_axis_tx_tvalid		;

wire [7:0]  sg_m_axis_rx_tdata		;
wire    	sg_m_axis_rx_tlast	    ;
wire    	sg_m_axis_rx_tuser	    ;
wire    	sg_m_axis_rx_tvalid     ;

sgmii_eth_m axi_1g_ethernet (
	.s_axi_lite_resetn          (reset						),            // input wire tx_axis_aresetn
	.s_axi_lite_clk            	(sys_clk					),            // input wire rx_axis_aresetn
	.mac_irq					(							),
	.tx_mac_aclk				(tx_mac_aclk				),
	.rx_mac_aclk				(rx_mac_aclk				),
	.tx_reset					(tx_reset					),
	.rx_reset					(rx_reset					),
	.glbl_rst					(~reset						),
	.tx_ifg_delay               (8'd12						),                  // input wire [7 : 0] tx_ifg_delay
	.status_vector				(							),
	.signal_detect              (1'b1           			),                // input wire signal_detect
	.mmcm_locked_out			(							),
	.rxuserclk_out				(							),
	.rxuserclk2_out				(							),
	.userclk_out				(							),
	.userclk2_out				(							),
	.pma_reset_out				(							),
	.gt0_qplloutclk_out			(							),
	.gt0_qplloutrefclk_out		(							),
	.phy_rst_n					(					    	),
	.ref_clk					(sys_clk					),
	.gtref_clk_out				(							),
	.gtref_clk_buf_out			(							),
	.s_axi_araddr				(11'b0						),                      // input wire [10 : 0] s_axi_araddr
	.s_axi_arready				(							),                    // output wire s_axi_arready
	.s_axi_arvalid				(1'b0						),                    // input wire s_axi_arvalid
	.s_axi_awaddr				(11'b0						),                      // input wire [10 : 0] s_axi_awaddr
	.s_axi_awready				(							),                    // output wire s_axi_awready
	.s_axi_awvalid				(1'b0						),                    // input wire s_axi_awvalid
	.s_axi_bready				(1'b0						),                      // input wire s_axi_bready
	.s_axi_bresp				(							),                        // output wire [1 : 0] s_axi_bresp
	.s_axi_bvalid				(							),                      // output wire s_axi_bvalid
	.s_axi_rdata				(							),                        // output wire [31 : 0] s_axi_rdata
	.s_axi_rready				(1'b0						),                      // input wire s_axi_rready
	.s_axi_rresp				(							),                        // output wire [1 : 0] s_axi_rresp
	.s_axi_rvalid				(							),                      // output wire s_axi_rvalid
	.s_axi_wdata				(32'b0						),                        // input wire [31 : 0] s_axi_wdata
	.s_axi_wready				(							),                      // output wire s_axi_wready
	.s_axi_wvalid				(1'b0						),                      // input wire s_axi_wvalid
	  
	.s_axis_tx_tready			(sg_s_axis_tx_tready		),
	.s_axis_tx_tdata			(sg_s_axis_tx_tdata			),
	.s_axis_tx_tlast			(sg_s_axis_tx_tlast			),
	.s_axis_tx_tuser			(sg_s_axis_tx_tuser			),
	.s_axis_tx_tvalid			(sg_s_axis_tx_tvalid		),

	.m_axis_rx_tdata			(sg_m_axis_rx_tdata			),
	.m_axis_rx_tlast			(sg_m_axis_rx_tlast			),
	.m_axis_rx_tuser			(sg_m_axis_rx_tuser			),
	.m_axis_rx_tvalid			(sg_m_axis_rx_tvalid		),
	.s_axis_pause_tdata			(16'b0						),          // input wire [15 : 0] s_axis_pause_tdata
	.s_axis_pause_tvalid		(1'b0						),        // input wire s_axis_pause_tvalid		  
	.rx_statistics_statistics_data		(					),
	.rx_statistics_statistics_valid		(					),
	.tx_statistics_statistics_data		(					),
	.tx_statistics_statistics_valid		(					),		
	.sgmii_rxn					(SFP_RXN					),
	.sgmii_rxp					(SFP_RXP					),
	.sgmii_txn					(SFP_TXN					),
	.sgmii_txp					(SFP_TXP					),
	.mdio_mdc					(							),
	.mdio_mdio_i				(1'b1						),
	.mdio_mdio_o				(							),
	.mdio_mdio_t				(							),
	.mgt_clk_clk_n				(MGT112_CLKN				),
	.mgt_clk_clk_p				(MGT112_CLKP				)
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


TF_8to512 TF_8to512_inst(
	.clk					(rx_mac_aclk				),
	.rst_n					(~rx_reset					),
	
	.TF_8to512_out			(TF_8to512_out				),
	.TF_8to512_out_wr		(TF_8to512_out_wr			),
	.TF_8to512_out_valid	(TF_8to512_out_valid		),
	.TF_8to512_out_valid_wr	(TF_8to512_out_valid_wr		),
	.TF_8to512_in_alf		(TF_8to512_in_alf			),
	
	.m_axis_rx_tdata		(sg_m_axis_rx_tdata			),
	.m_axis_rx_tlast		(sg_m_axis_rx_tlast			),
	.m_axis_rx_tuser		(sg_m_axis_rx_tuser			),
	.m_axis_rx_tvalid		(sg_m_axis_rx_tvalid		) 
);


TF_512to8 TF_512to8_inst(
	.clk					(tx_mac_aclk				),
	.rst_n					(~tx_reset					),
	
	.s_axis_tx_tready		(sg_s_axis_tx_tready		),
	.s_axis_tx_tdata		(sg_s_axis_tx_tdata			),
	.s_axis_tx_tlast		(sg_s_axis_tx_tlast			),
	.s_axis_tx_tuser		(sg_s_axis_tx_tuser			),
	.s_axis_tx_tvalid		(sg_s_axis_tx_tvalid		),
	
	.TF_512to8_in			(TF_512to8_in				),
	.TF_512to8_in_wr		(TF_512to8_in_wr			),
	.TF_512to8_in_valid		(TF_512to8_in_valid			),
	.TF_512to8_in_valid_wr	(TF_512to8_in_valid_wr		),
	.TF_512to8_out_alf		(TF_512to8_out_alf			) 
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

	
	wire	[519:0]				IFE_ctrlpkt_out			;
	wire						IFE_ctrlpkt_out_wr		;
	wire	[111:0] 			IFE_ctrlpkt_out_valid	;
	wire						IFE_ctrlpkt_out_valid_wr;
	wire						IFE_ctrlpkt_in_alf		;
	
CTRLPKT2COMMAND	CTRLPKT2COMMAND_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(rx_mac_aclk				),//clock, this is synchronous clock
	.Reset_N					(~rx_reset					),//Reset the all signal, active high
//=========================================== frame from IFE ===========================================//
	.IFE_ctrlpkt_in				(o_cpkt_data       				),//receive pkt
	.IFE_ctrlpkt_in_wr			(o_cpkt_data_en    				),//receive pkt write singal
	.IFE_ctrlpkt_in_valid		(o_cpkt_meta       				),//receive metadata
	.IFE_ctrlpkt_in_valid_wr	(o_cpkt_meta_en    				),//receive metadata write signal 
	.IFE_ctrlpkt_out_alf		(   							),//output allmostfull
//======================================= command to the config path ==================================//
	.Command_wr					(gmii_command_wr				),//command write signal
	.Command					(gmii_command					),//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	.Command_alf				(1'b0							),//commadn almostful
//=================================== counter & debug ====================================//
	.pkt_in_cnt					(command_pkt_in_cnt				),//pkt input cnt
	.com_out_cnt				(command_out_cnt				)//command out cnt
);
	
RESULT2CTRLPKT	RESULT2CTRLPKT_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(tx_mac_aclk					),//clock, this is synchronous clock
	.Reset_N					(~tx_reset						),//Reset the all signal, active high
//=========================================== frame to IFE ===========================================//
	.IFE_ctrlpkt_out			(IFE_ctrlpkt_out				),//receive pkt
	.IFE_ctrlpkt_out_wr			(IFE_ctrlpkt_out_wr				),//receive pkt write singal
	.IFE_ctrlpkt_out_valid		(IFE_ctrlpkt_out_valid			),//receive metadata
	.IFE_ctrlpkt_out_valid_wr	(IFE_ctrlpkt_out_valid_wr		),//receive metadata write signal 
	.IFE_ctrlpkt_in_alf			(IFE_ctrlpkt_in_alf				),//output allmostfull
//======================================= command to the config path ==================================//
	.Result_wr					(gmii_command_wr				),//command write signal
//================================ sequence of command to Result2ctrlpkt ================================//
	.IFE_ctrlpkt_in				(o_cpkt_data       				),//receive pkt
	.IFE_ctrlpkt_in_wr			(o_cpkt_data_en    				),//receive pkt write singal
	.IFE_ctrlpkt_in_valid		(o_cpkt_meta       				),//receive metadata
	.IFE_ctrlpkt_in_valid_wr	(o_cpkt_meta_en    				),//receive metadata write signal 
	.IFE_ctrlpkt_out_alf		(i_cpkt_fifo_alf   				),//output allmostfull
//=================================== counter & debug ====================================//
	.pkt_out_cnt				(result_pkt_in_cnt				),//pkt output cnt
	.result_in_cnt				(result_out_cnt					)//result in cnt	
);

wire	[519:0]	i_ari_01_data    		;
wire			i_ari_01_data_en 		;
wire	[111:0] i_ari_01_info    		;
wire			i_ari_01_info_en 		;
wire			o_ari_01_fifo_alf		;


POLL_MUX4 POLL_MUX4_inst
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  .i_sys_clk                   	(tx_mac_aclk					)//system clk
 ,.i_sys_rst_n                 	(~tx_reset						)//rst of sys_clk
 
//=========================================== Input ARI*4  ==========================================//

//input pkt data form ARI
,.i_ari_0_data                	(IFE_ctrlpkt_out				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_0_data_en             	(IFE_ctrlpkt_out_wr				)//data enable
,.i_ari_0_info                	(IFE_ctrlpkt_out_valid			)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_0_info_en             	(IFE_ctrlpkt_out_valid_wr		)//info enable
,.o_ari_0_fifo_alf            	(IFE_ctrlpkt_in_alf				)//fifo almostfull

,.i_ari_1_data                 	(i_ari_01_data    				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_1_data_en              	(i_ari_01_data_en 				)//data enable
,.i_ari_1_info                 	(i_ari_01_info    				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_1_info_en              	(i_ari_01_info_en 				)//info enable
,.o_ari_1_fifo_alf             	(o_ari_01_fifo_alf				)//fifo almostfull

,.i_ari_2_data                 	(520'b0				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_2_data_en              	(1'b0				)//data enable
,.i_ari_2_info                 	(112'b0				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_2_info_en              	(1'b0				)//info enable
,.o_ari_2_fifo_alf             	(					)//fifo almostfull

,.i_ari_3_data                	(520'b0				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_3_data_en				(1'b0				)//data enable
,.i_ari_3_info					(112'b0				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_3_info_en				(1'b0				)//info enable
,.o_ari_3_fifo_alf				(					)//fifo almostfull

//=========================================== Output ARI  ==========================================//
,.o_ari_data                	(TF_512to8_in			)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.o_ari_data_en             	(TF_512to8_in_wr		)//data enable
,.o_ari_info                	(TF_512to8_in_valid		)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.o_ari_info_en             	(TF_512to8_in_valid_wr	)//info enable
,.i_ari_fifo_alf            	(TF_512to8_out_alf		)//fifo almostfull
);

endmodule

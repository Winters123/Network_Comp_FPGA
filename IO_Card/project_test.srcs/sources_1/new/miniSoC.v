module miniSoC (
//system clock & resets
    input       wire            i_sys_clk,  // 50MHz
    input       wire            i_sys_rst_n,
//system clock & resets

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

// MAC
	//input port
	input		[7:0]			m_axis_rx_tdata			,//send packet
	input						m_axis_rx_tvalid		,//send valid
	input						m_axis_rx_tlast			,//send valid write
	input						m_axis_rx_tuser			,//receive allmostfull	

	//output port			
	output	wire	[7:0]		s_axis_tx_tdata	    			,//send packet
	output	wire				s_axis_tx_tvalid	    		,//send write
	output	wire				s_axis_tx_tlast	    			,//send valid
	output	wire				s_axis_tx_tuser    				,//send valid write
	input						s_axis_tx_tready			 	//receive allmostfull		
// MAC
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
	.clk					(i_sys_clk					),
	.rst_n					(i_sys_rst_n				),
	
	.TF_8to512_out			(TF_8to512_out				),
	.TF_8to512_out_wr		(TF_8to512_out_wr			),
	.TF_8to512_out_valid	(TF_8to512_out_valid		),
	.TF_8to512_out_valid_wr	(TF_8to512_out_valid_wr		),
	.TF_8to512_in_alf		(TF_8to512_in_alf			),
	
	.m_axis_rx_tdata		(m_axis_rx_tdata			),
	.m_axis_rx_tlast		(m_axis_rx_tlast			),
	.m_axis_rx_tuser		(m_axis_rx_tuser			),
	.m_axis_rx_tvalid		(m_axis_rx_tvalid		    ) 
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
  .i_sys_clk                 	(i_sys_clk					)//system clk
 ,.i_sys_rst_n               	(i_sys_rst_n				)//rst of sys_clk
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
	.Clk						(sys_clk						),//clock, this is synchronous clock
	.Reset_N					(reset							),//Reset the all signal, active high
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

//=============================接收命令，控制数据读�?===============================================//
cms_covert  u_cms_covert (
    .i_sys_clk               ( i_sys_clk            ),
    .i_sys_rst_n             ( i_sys_rst_n          ),
    .Command_wr_i            ( Command_wr_i         ),
    .Command_i               ( Command_i            ),
    .Command_alf_o           ( Command_alf_o        ),
    .cmos_vsync              ( cmos_vsync           ),
    .cmos_href               ( cmos_href            ),
    .cmos_pclk               ( cmos_pclk            ),
    .cmos_db                 ( cmos_db              ),

    .Command_alf_i           ( Command_alf_i        ),
    .Command_wr_o            ( Command_wr_o         ),
    .Command_o               ( Command_o            ),
    .cmos_xclk               ( cmos_xclk            ),
    .IFE_ctrlpkt_out         ( IFE_ctrlpkt_out      ),
    .IFE_ctrlpkt_out_wr      ( IFE_ctrlpkt_out_wr   ),

    .cmos_scl                ( cmos_scl             ),
    .cmos_sda                ( cmos_sda             )
);
//===================================================================================================//

RESULT2CTRLPKT	RESULT2CTRLPKT_inst(
//=========================================== clk & rst ===========================================//
	.Clk						(sys_clk						),//clock, this is synchronous clock
	.Reset_N					(reset							),//Reset the all signal, active high
//=========================================== frame to IFE ===========================================//
	.IFE_ctrlpkt_out			(IFE_ctrlpkt_out				),//receive pkt
	.IFE_ctrlpkt_out_wr			(IFE_ctrlpkt_out_wr				),//receive pkt write singal
	.IFE_ctrlpkt_out_valid		(IFE_ctrlpkt_out_valid			),//receive metadata
	.IFE_ctrlpkt_out_valid_wr	(IFE_ctrlpkt_out_valid_wr		),//receive metadata write signal 
	.IFE_ctrlpkt_in_alf			(IFE_ctrlpkt_in_alf				),//output allmostfull
//======================================= command to the config path ==================================//
	.Result_wr					(				),//command write signal
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


POLL_MUX4 POLL_MUX4_inst
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  .i_sys_clk                   	(sys_clk						)//system clk
 ,.i_sys_rst_n                 	(reset							)//rst of sys_clk
 
//=========================================== Input ARI*4  ==========================================//

//input pkt data form ARI
,.i_ari_0_data                	(IFE_ctrlpkt_out				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_0_data_en             	(IFE_ctrlpkt_out_wr				)//data enable
,.i_ari_0_info                	(IFE_ctrlpkt_out_valid			)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_0_info_en             	(IFE_ctrlpkt_out_valid_wr		)//info enable
,.o_ari_0_fifo_alf            	(IFE_ctrlpkt_in_alf				)//fifo almostfull

,.i_ari_1_data                 	(o_dpkt_data    				)//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,.i_ari_1_data_en              	(o_dpkt_data_en 				)//data enable
,.i_ari_1_info                 	(o_dpkt_meta    				)//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,.i_ari_1_info_en              	(o_dpkt_meta_en 				)//info enable
,.o_ari_1_fifo_alf             	(i_dpkt_fifo_alf				)//fifo almostfull

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


TF_512to8 TF_512to8_inst(
	.clk					(sys_clk					),
	.rst_n					(reset						),
	
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





//================ 以下是�?�过PREPARSER 后分配至HDMI显示的数据报文信�? ==========================================//
// pixel_buffer Outputs
    wire  pixelclk;         // 25.2MHz
    wire  pixelclk5x;       // 126MHz
    wire  [15:0]  vout_data;
    wire  hs;
    wire  vs;
    wire  de;
// pixel_buffer Outputs
pixel_buffer  u_pixel_buffer (
    .i_sys_clk               ( i_sys_clk         ),
    .i_sys_rst_n             ( i_sys_rst_n       ),
    .o_dpkt_data             ( o_dpkt_data       ),
    .o_dpkt_data_en          ( o_dpkt_data_en    ),

    .i_dpkt_fifo_alf         ( i_dpkt_fifo_alf   ),
    .pixelclk                ( pixelclk          ),
    .pixelclk5x              ( pixelclk5x        ),
    .vout_data               ( vout_data         ),
    .hs                      ( hs                ),
    .vs                      ( vs                ),
    .de                      ( de                )
);

// dvi_encoder Inputs  
    wire   [7:0]  blue_din; 
    wire   [7:0]  green_din;
    wire   [7:0]  red_din;  
    wire   hsync;
    wire   vsync;


    wire                            hdmi_hs;
    wire                            hdmi_vs;
    wire                            hdmi_de;
    wire[7:0]                       hdmi_r;
    wire[7:0]                       hdmi_g;
    wire[7:0]                       hdmi_b;

    assign hdmi_hs     = hs;
    assign hdmi_vs     = vs;
    assign hdmi_de     = de;
    assign hdmi_r      = {vout_data[15:11],3'd0};
    assign hdmi_g      = {vout_data[10:5],2'd0};
    assign hdmi_b      = {vout_data[4:0],3'd0};
// dvi_encoder Inputs  
// dvi_encoder Outputs  // system mac output
    // wire  tmds_clk_p;
    // wire  tmds_clk_n;
    // wire  [2:0]  tmds_data_p;
    // wire  [2:0]  tmds_data_n;
// dvi_encoder Outputs
dvi_encoder  u_dvi_encoder (
    .pixelclk                ( pixelclk      ),
    .pixelclk5x              ( pixelclk5x    ),
    .rstin                   ( ~i_sys_rst_n  ),// 高电平有�?
    .blue_din                ( hdmi_b        ),
    .green_din               ( hdmi_g        ),
    .red_din                 ( hdmi_r        ),
    .hsync                   ( hdmi_hs       ),
    .vsync                   ( hdmi_vs       ),
    .de                      ( hdmi_de       ),

    .tmds_clk_p              ( tmds_clk_p    ),
    .tmds_clk_n              ( tmds_clk_n    ),
    .tmds_data_p             ( tmds_data_p   ),
    .tmds_data_n             ( tmds_data_n   )
);


endmodule
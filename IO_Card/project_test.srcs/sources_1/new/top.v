
//================================================================================
//  Revision History:
//  Date          By            Revision    Change Description
//--------------------------------------------------------------------------------
//2018/01/05                    1.0          Original

//*******************************************************************************/
module top(
    input                       sys_clk,
    input                        rst_n,
    input key,
	//hdmi output        
    output                      tmds_clk_p,
    output                      tmds_clk_n,
    output[2:0]                 tmds_data_p,       
    output[2:0]                 tmds_data_n        
);
wire                            video_clk;
wire                            video_clk5x;

wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;
wire                            hs;
wire                            vs;
wire                            de;
wire                            hdmi_hs;
wire                            hdmi_vs;
wire                            hdmi_de;
wire[7:0]                       hdmi_r;
wire[7:0]                       hdmi_g;
wire[7:0]                       hdmi_b;

wire                             sys_clk_g;
wire                             video_clk_w;       
wire                             video_clk5x_w;

assign sys_clk_g = sys_clk;
assign video_clk = video_clk_w;
assign video_clk5x = video_clk5x_w ;

assign  hdmi_hs    = hs;
assign  hdmi_vs     = vs;
assign  hdmi_de    = de;
assign hdmi_r      = video_r;
assign hdmi_g      = video_g;
assign hdmi_b      = video_b;
color_bar hdmi_color_bar(
	.clk(video_clk),
	.rst(1'b0     ),
	.hs (hs       ),
	.vs (vs       ),
	.de (de       ),
	.rgb_r(video_r),
	.rgb_g(video_g),
	.rgb_b(video_b)
);

video_pll video_pll_m0
 (
       // Clock out ports
    .clk_out1(video_clk_w),     // output clk_out1
    .clk_out2(video_clk5x_w),     // output clk_out2
    // Status and control signals
    .resetn(rst_n), // input resetn
   // Clock in ports
    .clk_in1(sys_clk));      // input clk_in1

    // .pll_rst(1'b0),
    // .clkin1(sys_clk_g),
    // .pll_lock(),
    // .clkout0(video_clk5x_w),
    // .clkout1(video_clk_w));


dvi_encoder dvi_encoder_m0
 (
     .pixelclk      (video_clk          ),// system clock
     .pixelclk5x    (video_clk5x        ),// system clock x5
     .rstin         (~rst_n             ),// reset
     .blue_din      (hdmi_b            ),// Blue data in
     .green_din     (hdmi_g            ),// Green data in
     .red_din       (hdmi_r            ),// Red data in
     .hsync         (hdmi_hs           ),// hsync data
     .vsync         (hdmi_vs           ),// vsync data
     .de            (hdmi_de         ),// data enable
     .tmds_clk_p    (tmds_clk_p         ),
     .tmds_clk_n    (tmds_clk_n         ),
     .tmds_data_p   (tmds_data_p        ),//rgb
     .tmds_data_n   (tmds_data_n        ) //rgb
 );
endmodule
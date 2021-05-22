module miniSoC_test (
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
    output                           cmos_xclk,              //cmos externl clock   //例程使用的是24MHz
    input   [7:0]                    cmos_db,                //cmos data  
// CMOS

// HDMI
    output                           tmds_clk_p,             //HDMI differential clock positive
    output                           tmds_clk_n,             //HDMI differential clock negative
    output[2:0]                      tmds_data_p,            //HDMI differential data positive
    output[2:0]                      tmds_data_n             //HDMI differential data negative
// HDMI

);
// reg Command_wr_i;
// reg key_d1;

// reg [25:0] temp_counter;

//     always @(negedge i_sys_clk or negedge  i_sys_rst_n) begin
//         if(i_sys_rst_n)begin
//             Command_wr_i <= 1'b0;
//             temp_counter <= 'b0;
//         end
//         else begin
//             temp_counter <= temp_counter + 1'b1;
//             if(&temp_counter)begin
//                 Command_wr_i <= 1'b1;
//             end
//             else begin
//                 Command_wr_i <= 1'b0;
//             end
//         end
//     end
    // wire IFE_ctrlpkt_out_wr;
    // reg IFE_ctrlpkt_out_wr_reg;
    // wire [519:0]  IFE_ctrlpkt_out;
    // reg [519:0]  IFE_ctrlpkt_out_reg;
    reg key1_d1;
    reg Command_wr_i;
    always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
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
                Command_wr_i <= 1'b1;
            end
            else begin
                Command_wr_i <= 1'b0;
            end
        end
    end



(* MARK_DEBUG = "TRUE" *) wire [519:0]		    IFE_ctrlpkt_out;
(* MARK_DEBUG = "TRUE" *) wire IFE_ctrlpkt_out_wr;
ila ila_i0 (
	.clk(i_sys_clk), // input wire clk


	.probe0(IFE_ctrlpkt_out), // input wire [519:0]  probe0  
	.probe1(IFE_ctrlpkt_out_wr) // input wire [0:0]  probe1
);
//=============================接收命令，控制数杮读�?===============================================//
cms_covert  u_cms_covert (
    .i_sys_clk               ( i_sys_clk            ),
    .i_sys_rst_n             ( i_sys_rst_n          ),
    .Command_wr_i            ( Command_wr_i         ),
    .Command_i               ( 'd0            ),
    .Command_alf_o           (         ),
    .cmos_vsync              ( cmos_vsync           ),
    .cmos_href               ( cmos_href            ),
    .cmos_pclk               ( cmos_pclk            ),
    .cmos_db                 ( cmos_db              ),

    .Command_alf_i           (         ),
    .Command_wr_o            (           ),
    .Command_o               (             ),
    .cmos_xclk               ( cmos_xclk            ),
    .IFE_ctrlpkt_out         ( IFE_ctrlpkt_out      ),
    .IFE_ctrlpkt_out_wr      ( IFE_ctrlpkt_out_wr   ),

    .cmos_scl                ( cmos_scl             ),
    .cmos_sda                ( cmos_sda             )
);
//===================================================================================================//



//================ 以下是�?�过PREPARSER 坎分酝至HDMI显示的数杮报文信�? ==========================================//
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
    .o_dpkt_data             ( IFE_ctrlpkt_out       ),
    .o_dpkt_data_en          ( IFE_ctrlpkt_out_wr    ),

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
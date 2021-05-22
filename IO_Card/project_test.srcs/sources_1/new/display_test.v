module display_test (
    //system clock & resets
    input       wire            i_sys_clk,  // 50MHz
    input       wire            i_sys_rst_n,
    //system clock & resets
    input key1,
    input key2,
    // HDMI
    output                           tmds_clk_p,             //HDMI differential clock positive
    output                           tmds_clk_n,             //HDMI differential clock negative
    output[2:0]                      tmds_data_p,            //HDMI differential data positive
    output[2:0]                      tmds_data_n             //HDMI differential data negative
    // HDMI
);

//define the RGB values for 8 colors
parameter WHITE_R       = 8'hff;
parameter WHITE_G       = 8'hff;
parameter WHITE_B       = 8'hff;

parameter BLACK_R       = 8'h00;
parameter BLACK_G       = 8'h00;
parameter BLACK_B       = 8'h00;
// pixel_buffer Inputs     
    reg   [519:0]  o_dpkt_data;
    reg   o_dpkt_data_en;      

    always @(negedge i_sys_clk or negedge  i_sys_rst_n) begin
        if(~i_sys_rst_n)begin
            o_dpkt_data <= 520'd0;
        end
        else begin
            o_dpkt_data_en <= 1'b0;
            if((~key1))begin
                o_dpkt_data <= 520'd0;
                o_dpkt_data_en <= 1'b1;
            end
            else if(~key2) begin
                o_dpkt_data <= {130{4'hf}};
                o_dpkt_data_en <= 1'b1;
            end
        end
    end
  


// pixel_buffer Inputs     
// pixel_buffer Outputs
    wire  i_dpkt_fifo_alf;
    wire  pixelclk;         // 25.2MHz
    wire  pixelclk5x;       // 126MHz
    wire  [15:0]  vout_data;
    wire  hs;
    wire  vs;
    wire  de;
// pixel_buffer Outputs
pixel_buffer  u_pixel_buffer (
    .i_sys_clk               ( i_sys_clk         ),
    .i_sys_rst_n             ( i_sys_rst_n       ),//?????
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
    .rstin                   ( ~i_sys_rst_n  ),// é«˜ç”µå¹³æœ?æ???
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
`timescale  1ns / 1ps  

module tb_miniSoC;     

// miniSoC Parameters  
parameter PERIOD  = 10;


// miniSoC Inputs
reg   i_sys_clk                            = 0 ;
reg   i_sys_rst_n                          = 0 ;
reg   key                                  = 0 ;
reg   cmos_vsync                           = 0 ;
reg   cmos_href                            = 0 ;
reg   cmos_pclk                            = 0 ;
reg   [7:0]  cmos_db                       = 0 ;

// miniSoC Outputs
wire  cmos_xclk                            ;
wire  tmds_clk_p                           ;
wire  tmds_clk_n                           ;
wire  [2:0]  tmds_data_p                   ;
wire  [2:0]  tmds_data_n                   ;

// miniSoC Bidirs
wire  cmos_scl                             ;
wire  cmos_sda                             ;


initial
begin
    forever #(PERIOD/2)  i_sys_clk=~i_sys_clk;
end

initial
begin
    #(PERIOD*2) i_sys_rst_n  =  1;
end

miniSoC  u_miniSoC (
    .i_sys_clk               ( i_sys_clk          ),
    .i_sys_rst_n             ( i_sys_rst_n        ),
    .key                     ( key                ),
    .cmos_vsync              ( cmos_vsync         ),
    .cmos_href               ( cmos_href          ),
    .cmos_pclk               ( cmos_pclk          ),
    .cmos_db                 ( cmos_db      [7:0] ),

    .cmos_xclk               ( cmos_xclk          ),
    .tmds_clk_p              ( tmds_clk_p         ),
    .tmds_clk_n              ( tmds_clk_n         ),
    .tmds_data_p             ( tmds_data_p  [2:0] ),
    .tmds_data_n             ( tmds_data_n  [2:0] ),

    .cmos_scl                ( cmos_scl           ),
    .cmos_sda                ( cmos_sda           )
);

endmodule
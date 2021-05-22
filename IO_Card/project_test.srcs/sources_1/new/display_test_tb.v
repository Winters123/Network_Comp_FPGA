`timescale  1ns / 1ns     

module tb_display_test;   

parameter PERIOD = 20;
// display_test Inputs
reg   i_sys_clk                            = 0 ;
reg   i_sys_rst_n                          = 0 ;
reg   key                                  = 0 ;

// display_test Outputs
wire  tmds_clk_p                           ;
wire  tmds_clk_n                           ;
wire  [2:0]  tmds_data_p                   ;
wire  [2:0]  tmds_data_n                   ;


initial
begin
    forever #(PERIOD/2)  i_sys_clk=~i_sys_clk;
end

initial
begin
    #(PERIOD*2) i_sys_rst_n  =  1;
end

initial begin
    #(PERIOD*200) key  =  ~key;
end

display_test  u_display_test (
    .i_sys_clk               ( i_sys_clk          ),
    .i_sys_rst_n             ( i_sys_rst_n        ),
    .key                     ( key                ),

    .tmds_clk_p              ( tmds_clk_p         ),
    .tmds_clk_n              ( tmds_clk_n         ),
    .tmds_data_p             ( tmds_data_p  [2:0] ),
    .tmds_data_n             ( tmds_data_n  [2:0] )
);

endmodule
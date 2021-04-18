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

// MAC
);
    
endmodule
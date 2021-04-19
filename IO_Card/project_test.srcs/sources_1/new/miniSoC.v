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
    
endmodule
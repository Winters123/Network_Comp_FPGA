############## NET - IOSTANDARD ###################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

############## Clock ##############################
create_clock -period 20.000 [get_ports i_sys_clk]
#50MHz system clk
set_property IOSTANDARD LVCMOS33 [get_ports i_sys_clk]
set_property PACKAGE_PIN P15 [get_ports i_sys_clk]

############## Buttons #############################
set_property IOSTANDARD LVCMOS33 [get_ports i_sys_rst_n]
set_property PACKAGE_PIN M15 [get_ports i_sys_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports key1]
set_property PACKAGE_PIN L15 [get_ports key1]
# set_property IOSTANDARD LVCMOS33    [get_ports key2]
# set_property PACKAGE_PIN AB19        [get_ports key2]

############## Buttons #############################
set_property IOSTANDARD LVTTL    [get_ports init_done]
set_property PACKAGE_PIN K15        [get_ports init_done]

#############HDMI_O####################################
set_property IOSTANDARD LVTTL [get_ports tmds_clk_n]
set_property PACKAGE_PIN A20 [get_ports tmds_clk_n]

set_property PACKAGE_PIN B20 [get_ports tmds_clk_p]
set_property IOSTANDARD LVTTL [get_ports tmds_clk_p]

set_property IOSTANDARD LVTTL [get_ports {tmds_data_n[0]}]
set_property PACKAGE_PIN A17 [get_ports {tmds_data_n[0]}]

set_property PACKAGE_PIN A16 [get_ports {tmds_data_p[0]}]
set_property IOSTANDARD LVTTL [get_ports {tmds_data_p[0]}]

set_property IOSTANDARD LVTTL [get_ports {tmds_data_n[1]}]
set_property PACKAGE_PIN A13 [get_ports {tmds_data_n[1]}]

set_property PACKAGE_PIN B13 [get_ports {tmds_data_p[1]}]
set_property IOSTANDARD LVTTL [get_ports {tmds_data_p[1]}]

set_property IOSTANDARD LVTTL [get_ports {tmds_data_n[2]}]
set_property PACKAGE_PIN A12 [get_ports {tmds_data_n[2]}]

set_property PACKAGE_PIN A11 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD LVTTL [get_ports {tmds_data_p[2]}]

############## CMOS define############################
set_property PACKAGE_PIN C22 [get_ports cmos_scl]
set_property PACKAGE_PIN D21 [get_ports cmos_sda]
set_property PACKAGE_PIN B22 [get_ports cmos_pclk]
set_property PACKAGE_PIN D18 [get_ports cmos_href]
set_property PACKAGE_PIN B21 [get_ports cmos_vsync]
set_property PACKAGE_PIN B19 [get_ports {cmos_db[7]}]
set_property PACKAGE_PIN C19 [get_ports {cmos_db[6]}]
set_property PACKAGE_PIN C16 [get_ports {cmos_db[5]}]
set_property PACKAGE_PIN D16 [get_ports {cmos_db[4]}]
set_property PACKAGE_PIN C20 [get_ports {cmos_db[3]}]
set_property PACKAGE_PIN D20 [get_ports {cmos_db[2]}]
set_property PACKAGE_PIN C15 [get_ports {cmos_db[1]}]
set_property PACKAGE_PIN C17 [get_ports {cmos_db[0]}]
set_property PACKAGE_PIN C18 [get_ports cmos_xclk]

set_property IOSTANDARD LVCMOS33 [get_ports cmos_sda]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_scl]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_href]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_xclk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cmos_pclk_IBUF]

############## ethernet define#########################
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[*]}]
set_property SLEW FAST [get_ports {rgmii_txd[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports e_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports e_mdio]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rxc]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rxctl]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_txctl]
set_property SLEW FAST [get_ports rgmii_txc]
set_property SLEW FAST [get_ports rgmii_txctl]

set_property PACKAGE_PIN G21 [get_ports {rgmii_rxd[3]}]
set_property PACKAGE_PIN F22 [get_ports {rgmii_rxd[2]}]
set_property PACKAGE_PIN F21 [get_ports {rgmii_rxd[1]}]
set_property PACKAGE_PIN E22 [get_ports {rgmii_rxd[0]}]
set_property PACKAGE_PIN E18 [get_ports {rgmii_txd[3]}]
set_property PACKAGE_PIN E17 [get_ports {rgmii_txd[2]}]
set_property PACKAGE_PIN D19 [get_ports {rgmii_txd[1]}]
set_property PACKAGE_PIN E19 [get_ports {rgmii_txd[0]}]
set_property PACKAGE_PIN E16 [get_ports e_mdc]
set_property PACKAGE_PIN G14 [get_ports e_mdio]

create_clock -period 8 [get_ports rgmii_rxc]
# means 125MHz for rx clock. 
set_property PACKAGE_PIN G22 [get_ports rgmii_rxc]
set_property PACKAGE_PIN D22 [get_ports rgmii_rxctl]
set_property PACKAGE_PIN F19 [get_ports rgmii_txc]
set_property PACKAGE_PIN F20 [get_ports rgmii_txctl]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets rgmii_rxc_IBUF]




# create_debug_core u_ila_0 ila
# set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
# set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
# set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
# set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
# set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
# set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
# set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
# set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
# set_property port_width 1 [get_debug_ports u_ila_0/clk]
# connect_debug_port u_ila_0/clk [get_nets [list u_pixel_buffer/video_pll_m0/inst/clk_out1]]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
# set_property port_width 16 [get_debug_ports u_ila_0/probe0]
# connect_debug_port u_ila_0/probe0 [get_nets [list {vout_data[0]} {vout_data[1]} {vout_data[2]} {vout_data[3]} {vout_data[4]} {vout_data[5]} {vout_data[6]} {vout_data[7]} {vout_data[8]} {vout_data[9]} {vout_data[10]} {vout_data[11]} {vout_data[12]} {vout_data[13]} {vout_data[14]} {vout_data[15]}]]
# create_debug_port u_ila_0 probe
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
# set_property port_width 1 [get_debug_ports u_ila_0/probe1]
# connect_debug_port u_ila_0/probe1 [get_nets [list u_pixel_buffer/dram_0_write_n_reg_n_0]]
# create_debug_port u_ila_0 probe
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
# set_property port_width 1 [get_debug_ports u_ila_0/probe2]
# connect_debug_port u_ila_0/probe2 [get_nets [list hdmi_de]]
# create_debug_port u_ila_0 probe
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
# set_property port_width 1 [get_debug_ports u_ila_0/probe3]
# connect_debug_port u_ila_0/probe3 [get_nets [list hdmi_hs]]
# create_debug_port u_ila_0 probe
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
# set_property port_width 1 [get_debug_ports u_ila_0/probe4]
# connect_debug_port u_ila_0/probe4 [get_nets [list hdmi_vs]]
# create_debug_port u_ila_0 probe
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
# set_property port_width 1 [get_debug_ports u_ila_0/probe5]
# connect_debug_port u_ila_0/probe5 [get_nets [list i_sys_clk_IBUF]]
# create_debug_core u_ila_1 ila
# set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
# set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_1]
# set_property C_ADV_TRIGGER true [get_debug_cores u_ila_1]
# set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_1]
# set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
# set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
# set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
# set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
# set_property port_width 1 [get_debug_ports u_ila_1/clk]
# connect_debug_port u_ila_1/clk [get_nets [list cmos_pclk_IBUF_BUFG]]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
# set_property port_width 1 [get_debug_ports u_ila_1/probe0]
# connect_debug_port u_ila_1/probe0 [get_nets [list IFE_ctrlpkt_out_wr]]
# set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
# set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
# set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
# connect_debug_port dbg_hub/clk [get_nets i_sys_clk_IBUF]

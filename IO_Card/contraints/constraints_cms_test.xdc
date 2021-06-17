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

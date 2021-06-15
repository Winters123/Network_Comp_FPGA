#gmii 1
set_property -dict {PACKAGE_PIN AK19 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[0]}]
set_property -dict {PACKAGE_PIN AH19 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[1]}]
set_property -dict {PACKAGE_PIN AG19 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[2]}]
set_property -dict {PACKAGE_PIN AE18 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[3]}]
set_property -dict {PACKAGE_PIN AD16 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[4]}]
set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[5]}]
set_property -dict {PACKAGE_PIN AC19 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[6]}]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD LVCMOS18} [get_ports {gmii_tx_d_1[7]}]
set_property -dict {PACKAGE_PIN AB19 IOSTANDARD LVCMOS18} [get_ports gmii_tx_en_1]
set_property -dict {PACKAGE_PIN AJ18 IOSTANDARD LVCMOS18} [get_ports gmii_tx_er_1]
set_property -dict {PACKAGE_PIN AK18 IOSTANDARD LVCMOS18} [get_ports gmii_gtxclk_1]

set_property -dict {PACKAGE_PIN AF17 IOSTANDARD LVCMOS18} [get_ports gmii_rx_clk_1]
set_property -dict {PACKAGE_PIN AD17 IOSTANDARD LVCMOS18} [get_ports gmii_tx_clk_1]

set_property -dict {PACKAGE_PIN AH17 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[0]}]
set_property -dict {PACKAGE_PIN AJ19 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[1]}]
set_property -dict {PACKAGE_PIN AH16 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[2]}]
set_property -dict {PACKAGE_PIN AJ17 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[3]}]
set_property -dict {PACKAGE_PIN AJ16 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[4]}]
set_property -dict {PACKAGE_PIN AG14 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[5]}]
set_property -dict {PACKAGE_PIN AH15 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[6]}]
set_property -dict {PACKAGE_PIN AG15 IOSTANDARD LVCMOS18} [get_ports {gmii_rx_d_1[7]}]
set_property -dict {PACKAGE_PIN AF15 IOSTANDARD LVCMOS18} [get_ports gmii_rx_dv_1]
set_property -dict {PACKAGE_PIN AE16 IOSTANDARD LVCMOS18} [get_ports gmii_rx_er_1]
set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS18} [get_ports gmii_rx_col_1]

set_property PACKAGE_PIN AE23 [get_ports FPGA_RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_RESET_N]
set_property IOSTANDARD LVCMOS18 [get_ports gmii_rx_csr_1]
set_property PACKAGE_PIN AA18 [get_ports gmii_rx_csr_1]




set_property MARK_DEBUG true [get_nets PORT0_GMII/tri_mode_ethernet_mac_inst/inst/tri_mode_ethernet_mac_i/gmii_tx_en_int]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[7]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[6]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[5]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[4]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[3]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[2]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[1]}]
set_property DRIVE 12 [get_ports {gmii_tx_d_1[0]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[7]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[6]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[5]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[4]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[3]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[2]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[1]}]
set_property SLEW FAST [get_ports {gmii_tx_d_1[0]}]




create_clock -period 8.000 -name gmii_rx_clk_1 [get_ports gmii_rx_clk_1]

create_clock -period 8.000 -name gmii_tx_clk_1 [get_ports gmii_tx_clk_1]






set_property PACKAGE_PIN L25 [get_ports FPGA_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_CLK]
connect_debug_port u_ila_0/clk [get_nets [list u_ila_0_tx_gmii_mii_clk]]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_tx_gmii_mii_clk]


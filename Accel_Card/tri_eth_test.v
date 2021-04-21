// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Description: Xilinx FPGA top-level
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module tri_eth_test (
//clk
input           FPGA_REFCLK_P,
input           FPGA_REFCLK_N,//125Mhz
//rst
input 			FPGA_RESET_N,//FPGA_RESET
//gmii_port
  input   wire  [7:0]  gmii_rx_d_1,
  input   wire         gmii_rx_dv_1,
  input   wire         gmii_rx_er_1,
  input   wire         gmii_rx_col_1,
  input   wire         gmii_rx_csr_1,
  input   wire         gmii_rx_clk_1,
  output  wire  [7:0]  gmii_tx_d_1,
  output  wire         gmii_tx_en_1,
  output  wire         gmii_tx_er_1,
  input   wire         gmii_tx_clk_1,
//  output  wire         gmii_rx_mdc_1,
//  inout   wire         gmii_rx_mdio_1,
// output  wire         gmii_rst_1,
  output  wire         gmii_gtxclk_1
);

wire	usr_clk			;	//125Mhz
wire    Port_clk		;	//125Mhz
wire    GMII_ref_clk	;	//200Mhz
wire	locked			;
wire	reset			;


clk_wiz_0  clk_wiz_0(
 // Clock out ports
.clk_out1(usr_clk		),
.clk_out3(Port_clk		),
.clk_out2(GMII_ref_clk	),
 // Status and control signals
.reset(!FPGA_RESET_N),
.locked(locked),
// Clock in ports
.clk_in1_p(FPGA_REFCLK_P ),
.clk_in1_n(FPGA_REFCLK_N));

assign reset = locked & FPGA_RESET_N	;


GMII_TRI_ETH_TOP  PORT0_GMII
(
	.i_sys_clk					(usr_clk								),				//system clk
	.i_sys_rst_n				(reset									),				//rst of sys_clk
	.clk_csr_i					(usr_clk								),				//CSR clk,----25-300MHz!!!!
	.rst_clk_csr_n				(reset									),				//active low reset synch to clk_csr_i
	.clk_tx_i					(Port_clk								),					//GMII transmit reference clock,all port share the transmit clock
	.rst_clk_tx_n				(reset									),				//active low reset synch to clk_tx_i
	.tri_refclk_i				(GMII_ref_clk							),				//TRI reference clock

//===================================== LocalBus port command =====================================//
	.LocalBus_command_wr		(1'b0									),		//LocalBus command wirte	
	.LocalBus_command			(64'b0									),			//LocalBus command
	.LocalBus_allmostfull		(										),		//LocalBus allmostfull
	.NextLocalBus_command_wr	(										),	//LocalBus command wirte	
	.NextLocalBus_command		(										),		//LocalBus command
	.NextLocalBus_allmostfull	(1'b0									),	//LocalBus allmostfull	
//=========================================== ARI & ATI =========================================//

// GMII Interface
//---------------
	.gmii_txd					(gmii_tx_d_1							),
	.gmii_tx_en					(gmii_tx_en_1							),
	.gmii_tx_er					(gmii_tx_er_1							),
	.gmii_tx_clk				(gmii_gtxclk_1    			            ),
	.gmii_rxd					(gmii_rx_d_1							),
	.gmii_rx_dv					(gmii_rx_dv_1							),
	.gmii_rx_er					(gmii_rx_er_1							),
	.gmii_rx_clk				(gmii_rx_clk_1  						),
	.mii_tx_clk					(gmii_tx_clk_1							),

	.mac_speed_0_o				(										)//Speed select output for MAC

      );

endmodule

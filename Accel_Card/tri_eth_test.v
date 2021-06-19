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
input           FPGA_CLK, //125MHz
//rst
input 			FPGA_RESET_N,//FPGA_RESET
//gmii_port
  input   wire  [7:0]  gmii_rx_d_1,
  input   wire         gmii_rx_dv_1,
  input   wire         gmii_rx_er_1,
  input   wire         gmii_rx_col_1,
  input   wire         gmii_rx_csr_1,
  input   wire         gmii_rx_clk_1,  //125MHz
  output  wire  [7:0]  gmii_tx_d_1,
  output  wire         gmii_tx_en_1,
  output  wire         gmii_tx_er_1,
  input   wire         gmii_tx_clk_1,
//  output  wire         gmii_rx_mdc_1,
//  inout   wire         gmii_rx_mdio_1,
// output  wire         gmii_rst_1,
  output  wire         gmii_gtxclk_1,

  //System Interfaces
	//clk
	input                       sys_clk_p,
	input                       sys_clk_n,

	input                       sys_rst                 ,
	//DDR3 Interfaces           
	output  wire    [14:0]      ddr3_addr               ,
	output  wire    [ 2:0]      ddr3_ba                 ,
	output  wire                ddr3_cas_n              ,
	output  wire                ddr3_ck_n               ,
	output  wire                ddr3_ck_p               ,
	output  wire                ddr3_cke                ,
	output  wire                ddr3_ras_n              ,
	output  wire                ddr3_reset_n            ,
	output  wire                ddr3_we_n               ,
	inout           [31:0]      ddr3_dq                 ,
	inout           [ 3:0]      ddr3_dqs_n              ,
	inout           [ 3:0]      ddr3_dqs_p              ,
	output  wire    [ 0:0]      ddr3_cs_n               ,
	output  wire    [ 3:0]      ddr3_dm                 ,
	output  wire    [ 0:0]      ddr3_odt                
);

wire	usr_clk			;
wire    config_clk	    ;
wire    Port_clk		;
wire    GMII_ref_clk	;
wire	locked			;
wire	reset			;
wire 	clk_100M		;


wire 	[3:0]		s_axi_awid      ;
wire 	[31:0]		s_axi_awaddr    ;
wire 	[7:0]		s_axi_awlen     ;
wire 	[2:0]		s_axi_awsize    ;
wire 	[1:0]		s_axi_awburst   ;
wire 				s_axi_awlock    ;
wire 	[3:0]		s_axi_awcache   ;
wire 	[2:0]		s_axi_awprot    ;
wire 	[3:0]		s_axi_awqos     ;
wire 				s_axi_awvalid   ;
wire 				s_axi_awready   ;

wire 	[31:0]		s_axi_wdata     ;
wire 	[3:0]		s_axi_wstrb     ;
wire 				s_axi_wlast     ;
wire 				s_axi_wvalid    ;
wire 				s_axi_wready    ;
		
wire 	[3:0]		s_axi_bid       ;
wire 	[1:0]		s_axi_bresp     ;
wire 				s_axi_bvalid    ;
wire 				s_axi_bready    ;
		
wire 	[3:0]		s_axi_arid      ;
wire 	[31:0]		s_axi_araddr    ;
wire 	[7:0]		s_axi_arlen     ;
wire 	[2:0]		s_axi_arsize    ;
wire 	[1:0]		s_axi_arburst   ;
wire 				s_axi_arlock    ;
wire 	[3:0]		s_axi_arcache   ;
wire 	[2:0]		s_axi_arprot    ;
wire 	[3:0]		s_axi_arqos     ;
wire 				s_axi_arvalid   ;
wire 				s_axi_arready   ;
		
wire 	[3:0]		s_axi_rid       ;
wire 	[31:0]		s_axi_rdata     ;
wire 	[1:0]		s_axi_rresp     ;
wire 				s_axi_rlast     ;
wire 				s_axi_rvalid    ;
wire 				s_axi_rready    ;
		
wire 				sys_clk_i       ;
//wire 				sys_rst         ;

clk_wiz_0  clk_wiz_0(
 // Clock out ports
.clk_out1(GMII_ref_clk		),//125Mhz
.reset(!FPGA_RESET_N),
.locked(locked),
// Clock in ports
.clk_in1(FPGA_CLK ));//125Mhz

assign reset = locked 	;



GMII_TRI_ETH_TOP  PORT0_GMII
(
	//.i_sys_clk					(usr_clk								),					//system clk
	.i_sys_clk					(clk_100M),
	.i_sys_rst_n				(reset									),				//rst of sys_clk
	.clk_csr_i					(usr_clk								),					//CSR clk,----25-300MHz!!!!
	.rst_clk_csr_n				(reset									),				//active low reset synch to clk_csr_i
	.clk_tx_i					(Port_clk								),					//GMII transmit reference clock,all port share the transmit clock
	.rst_clk_tx_n				(reset									),				//active low reset synch to clk_tx_i
	.tri_refclk_i				(GMII_ref_clk							),				//TRI reference clock

//=========================================== ARI & ATI =========================================//

// GMII Interface
//---------------
	.gmii_txd						(gmii_tx_d_1							),
	.gmii_tx_en						(gmii_tx_en_1							),
	.gmii_tx_er						(gmii_tx_er_1							),
	.gmii_tx_clk					(gmii_gtxclk_1    			            ),
	.gmii_rxd						(gmii_rx_d_1							),
	.gmii_rx_dv						(gmii_rx_dv_1							),
	.gmii_rx_er						(gmii_rx_er_1							),
	.gmii_rx_clk					(gmii_rx_clk_1  						),
	.mii_tx_clk						(gmii_tx_clk_1							),

	.mac_speed_0_o					(										),//Speed select output for MAC
	// TODO: check if ui_clk is global
	.ui_clk                         (clk_100M                    ),  //100MHz ui_clk
	.ui_clk_sync_rst                (clk_100M_sync_rst           ),  // output	    ui_clk_sync_rst
	
	// Slave Interface Write Address Ports
	.M_AXI_AWID                      (s_axi_awid              ),  // input [0:0]	s_axi_awid
	.M_AXI_AWADDR                    (s_axi_awaddr            ),  // input [29:0]	s_axi_awaddr
	.M_AXI_AWLEN                     (s_axi_awlen             ),  // input [7:0]	s_axi_awlen
	.M_AXI_AWSIZE                    (s_axi_awsize            ),  // input [2:0]	s_axi_awsize
	.M_AXI_AWBURST                   (s_axi_awburst           ),  // input [1:0]	s_axi_awburst
	.M_AXI_AWLOCK                    (s_axi_awlock            ),  // input [0:0]	s_axi_awlock
	.M_AXI_AWCACHE                   (s_axi_awcache           ),  // input [3:0]	s_axi_awcache
	.M_AXI_AWPROT                    (s_axi_awprot            ),  // input [2:0]	s_axi_awprot
	.M_AXI_AWQOS                     (s_axi_awqos             ),  // input [3:0]	s_axi_awqos
	.M_AXI_AWVALID                   (s_axi_awvalid           ),  // input		s_axi_awvalid
	.M_AXI_AWREADY                   (s_axi_awready           ),  // output	    s_axi_awready
	// Slave Interface Write Data Ports
	.M_AXI_WDATA                     (s_axi_wdata             ),  // input [63:0]	s_axi_wdata
	.M_AXI_WSTRB                     (s_axi_wstrb             ),  // input [7:0]	s_axi_wstrb
	.M_AXI_WLAST                     (s_axi_wlast             ),  // input		s_axi_wlast
	.M_AXI_WVALID                    (s_axi_wvalid            ),  // input		s_axi_wvalid
	.M_AXI_WREADY                    (s_axi_wready            ),  // output		s_axi_wready
	// Slave Interface Write Response Ports
	.M_AXI_BID                       (s_axi_bid               ),  // output [0:0]	s_axi_bid
	.M_AXI_BRESP                     (s_axi_bresp             ),  // output [1:0]	s_axi_bresp
	.M_AXI_BVALID                    (s_axi_bvalid            ),  // output		s_axi_bvalid
	.M_AXI_BREADY                    (s_axi_bready            ),  // input		s_axi_bready
	// Slave Interface Read Address Ports
	.M_AXI_ARID                      (s_axi_arid              ),  // input [0:0]	s_axi_arid
	.M_AXI_ARADDR                    (s_axi_araddr            ),  // input [29:0]	s_axi_araddr
	.M_AXI_ARLEN                     (s_axi_arlen             ),  // input [7:0]	s_axi_arlen
	.M_AXI_ARSIZE                    (s_axi_arsize            ),  // input [2:0]	s_axi_arsize
	.M_AXI_ARBURST                   (s_axi_arburst           ),  // input [1:0]	s_axi_arburst
	.M_AXI_ARLOCK                    (s_axi_arlock            ),  // input [0:0]	s_axi_arlock
	.M_AXI_ARCACHE                   (s_axi_arcache           ),  // input [3:0]	s_axi_arcache
	.M_AXI_ARPROT                    (s_axi_arprot            ),  // input [2:0]	s_axi_arprot
	.M_AXI_ARQOS                     (s_axi_arqos             ),  // input [3:0]	s_axi_arqos
	.M_AXI_ARVALID                   (s_axi_arvalid           ),  // input		s_axi_arvalid
	.M_AXI_ARREADY                   (s_axi_arready           ),  // output		s_axi_arready
	// Slave Interface Read Data Ports
	.M_AXI_RID   	                 (s_axi_rid               ),  // output [0:0]	s_axi_rid
	.M_AXI_RDATA	                 (s_axi_rdata             ),  // output [63:0]s_axi_rdata
	.M_AXI_RRESP	                 (s_axi_rresp             ),  // output [1:0]	s_axi_rresp
	.M_AXI_RLAST	                 (s_axi_rlast             ),  // output	    s_axi_rlast
	.M_AXI_RVALID	                 (s_axi_rvalid            ),  // output		s_axi_rvalid
	.M_AXI_RREADY                    (s_axi_rready            ),  // input		s_axi_rready
	// TODO: System Clock Ports
	.sys_clk_i                       (clk_200M                     ),  // MIG clock
	.sys_rst                         (reset                        )   // input sys_rst
);


wire 				ui_clk          ;  //100MHz ui clock
wire 				ui_clk_sync_rst ;  //rst_n on 100MHz



mig_7series_0 u_ddr3 
(
// Memory interface ports
.ddr3_addr                      (ddr3_addr                 ), 
.ddr3_ba                        (ddr3_ba                   ),
.ddr3_ras_n                     (ddr3_ras_n                ), 
.ddr3_cas_n                     (ddr3_cas_n                ),
.ddr3_we_n                      (ddr3_we_n                 ), 
.ddr3_reset_n                   (ddr3_reset_n              ),
.ddr3_ck_p                      (ddr3_ck_p                 ),
.ddr3_ck_n                      (ddr3_ck_n                 ),
.ddr3_cke                       (ddr3_cke                  ),  
.ddr3_cs_n                      (ddr3_cs_n                 ), 
.ddr3_dm                        (ddr3_dm                   ),  
.ddr3_odt                       (ddr3_odt                  ), 
.ddr3_dq                        (ddr3_dq                   ),  
.ddr3_dqs_n                     (ddr3_dqs_n                ),  
.ddr3_dqs_p                     (ddr3_dqs_p                ),  
.init_calib_complete            (                          ),   
// Application interface ports
.ui_clk                         (ui_clk                    ),  //100MHz ui_clk
.ui_clk_sync_rst                (ui_clk_sync_rst           ),  // output	    ui_clk_sync_rst
.mmcm_locked                    (                          ),  // output	    mmcm_locked
.aresetn                        (1'b1                      ),  // input			aresetn
.app_sr_req                     (1'b0                      ),  // input			app_sr_req
.app_ref_req                    (1'b0                      ),  // input			app_ref_req
.app_zq_req                     (1'b0                      ),  // input			app_zq_req
.app_sr_active                  (                          ),  // output	    app_sr_active
.app_ref_ack                    (                          ),  // output		app_ref_ack
.app_zq_ack                     (                          ),  // output		app_zq_ack
// Slave Interface Write Address Ports
.s_axi_awid                     (s_axi_awid        	       ),  // input [0:0]	s_axi_awid
.s_axi_awaddr                   (s_axi_awaddr      	       ),  // input [29:0]	s_axi_awaddr
.s_axi_awlen                    (s_axi_awlen       	       ),  // input [7:0]	s_axi_awlen
.s_axi_awsize                   (s_axi_awsize      	       ),  // input [2:0]	s_axi_awsize
.s_axi_awburst                  (s_axi_awburst     	       ),  // input [1:0]	s_axi_awburst
.s_axi_awlock                   (s_axi_awlock      	       ),  // input [0:0]	s_axi_awlock
.s_axi_awcache                  (s_axi_awcache     	       ),  // input [3:0]	s_axi_awcache
.s_axi_awprot                   (s_axi_awprot      	       ),  // input [2:0]	s_axi_awprot
.s_axi_awqos                    (s_axi_awqos       	       ),  // input [3:0]	s_axi_awqos
.s_axi_awvalid                  (s_axi_awvalid     	       ),  // input		s_axi_awvalid
.s_axi_awready                  (s_axi_awready     	       ),  // output	    s_axi_awready
// Slave Interface Write Data Ports
.s_axi_wdata                    (s_axi_wdata               ),  // input [63:0]	s_axi_wdata
.s_axi_wstrb                    (s_axi_wstrb               ),  // input [7:0]	s_axi_wstrb
.s_axi_wlast                    (s_axi_wlast               ),  // input		s_axi_wlast
.s_axi_wvalid                   (s_axi_wvalid              ),  // input		s_axi_wvalid
.s_axi_wready                   (s_axi_wready              ),  // output		s_axi_wready
// Slave Interface Write Response Ports
.s_axi_bid                      (s_axi_bid                 ),  // output [0:0]	s_axi_bid
.s_axi_bresp                    (s_axi_bresp               ),  // output [1:0]	s_axi_bresp
.s_axi_bvalid                   (s_axi_bvalid              ),  // output		s_axi_bvalid
.s_axi_bready                   (s_axi_bready              ),  // input		s_axi_bready
// Slave Interface Read Address Ports
.s_axi_arid                     (s_axi_arid                ),  // input [0:0]	s_axi_arid
.s_axi_araddr                   (s_axi_araddr              ),  // input [29:0]	s_axi_araddr
.s_axi_arlen                    (s_axi_arlen               ),  // input [7:0]	s_axi_arlen
.s_axi_arsize                   (s_axi_arsize              ),  // input [2:0]	s_axi_arsize
.s_axi_arburst                  (s_axi_arburst             ),  // input [1:0]	s_axi_arburst
.s_axi_arlock                   (s_axi_arlock              ),  // input [0:0]	s_axi_arlock
.s_axi_arcache                  (s_axi_arcache             ),  // input [3:0]	s_axi_arcache
.s_axi_arprot                   (s_axi_arprot              ),  // input [2:0]	s_axi_arprot
.s_axi_arqos                    (s_axi_arqos               ),  // input [3:0]	s_axi_arqos
.s_axi_arvalid                  (s_axi_arvalid             ),  // input		s_axi_arvalid
.s_axi_arready                  (s_axi_arready             ),  // output		s_axi_arready
// Slave Interface Read Data Ports
.s_axi_rid                      (s_axi_rid                 ),  // output [0:0]	s_axi_rid
.s_axi_rdata                    (s_axi_rdata               ),  // output [63:0]s_axi_rdata
.s_axi_rresp                    (s_axi_rresp               ),  // output [1:0]	s_axi_rresp
.s_axi_rlast                    (s_axi_rlast               ),  // output	    s_axi_rlast
.s_axi_rvalid                   (s_axi_rvalid              ),  // output		s_axi_rvalid
.s_axi_rready                   (s_axi_rready              ),  // input		s_axi_rready
// TODO: System Clock Ports
.sys_clk_i                      (GMII_ref_clk              ),  // MIG clock
.sys_rst                        (sys_rst                   )   // input sys_rst

);

endmodule

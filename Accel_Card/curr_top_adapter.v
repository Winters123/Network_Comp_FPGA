module curr_top_adapter (
    input clk,
    input aresetn,

    // generate packets from preparser
    input [519:0]               pktin_data              ,
    input                       pktin_en                ,
    input [255:0]               pkt_in_md               ,
    input                       pkt_in_md_en            ,
    output                      pkt_data_alf            ,

    // commands from ctlpkt
    input                       cmd_in_wr               ,
    input [63:0]                cmd_in                  ,
    output                      cmd_in_alf              ,

    // commands to result2ctl
    output       				cmd_out_wr	            ,       //command write signal
	output [63:0] 		        cmd_out		            ,       //command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	input 						cmd_out_alf             ,

    // generate packets to MUX
    output [519:0]              pkt_out_data            ,
    output                      pkt_out_en              ,
    output [255:0]              pkt_out_md              ,
    output                      pkt_out_md_en           ,
    input                       pkt_out_data_alf        ,

    // AXI signal TO/FROM axi_interconnect_0
    output                      S00_AXI_ARESET_OUT_N       ,    // S00 for monitor
    output                      S01_AXI_ARESET_OUT_N       ,    // S01 for camera
    output                      S02_AXI_ARESET_OUT_N       ,    // S02 for accelerator
    output                      S03_AXI_ARESET_OUT_N       ,    // S03 for accelerator
    output                      M00_AXI_ARESET_OUT_N       ,
    input                       M00_AXI_ACLK               ,               
    output  [3 : 0]             M00_AXI_AWID               ,
    output  [31 : 0]            M00_AXI_AWADDR             ,
    output  [7 : 0]             M00_AXI_AWLEN              ,
    output  [2 : 0]             M00_AXI_AWSIZE             ,
    output  [1 : 0]             M00_AXI_AWBURST            ,
    output                      M00_AXI_AWLOCK             ,
    output  [3 : 0]             M00_AXI_AWCACHE            ,
    output  [2 : 0]             M00_AXI_AWPROT             ,
    output  [3 : 0]             M00_AXI_AWQOS              ,
    output                      M00_AXI_AWVALID            ,
    input                       M00_AXI_AWREADY            ,
    output  [31 : 0]            M00_AXI_WDATA              ,
    output  [3 : 0]             M00_AXI_WSTRB              ,
    output                      M00_AXI_WLAST              ,
    output                      M00_AXI_WVALID             ,
    input                       M00_AXI_WREADY             ,
    input [3 : 0]               M00_AXI_BID                ,
    input [1 : 0]               M00_AXI_BRESP              ,
    input                       M00_AXI_BVALID             ,
    output                      M00_AXI_BREADY             ,
    output  [3 : 0]             M00_AXI_ARID               ,
    output  [31 : 0]            M00_AXI_ARADDR             ,
    output  [7 : 0]             M00_AXI_ARLEN              ,
    output  [2 : 0]             M00_AXI_ARSIZE             ,
    output  [1 : 0]             M00_AXI_ARBURST            ,
    output                      M00_AXI_ARLOCK             ,
    output  [3 : 0]             M00_AXI_ARCACHE            ,
    output  [2 : 0]             M00_AXI_ARPROT             ,
    output  [3 : 0]             M00_AXI_ARQOS              ,
    output                      M00_AXI_ARVALID            ,
    input                       M00_AXI_ARREADY            ,
    input [3 : 0]               M00_AXI_RID                ,
    input [31 : 0]              M00_AXI_RDATA              ,
    input [1 : 0]               M00_AXI_RRESP              ,
    input                       M00_AXI_RLAST              ,
    input                       M00_AXI_RVALID             ,
    output                      M00_AXI_RREAD              

);

    // monitor -> ctrls from controller
    wire                    ddr_read_finish;
    wire                    ddr_read_finish_valid;
    wire                    ddr_read_finish_ready;

    wire                    ddr_read_start;
    wire                    ddr_read_start_valid;
    wire                    ddr_read_start_ready;

    // monitor -> Master Read Address
    wire [0:0]              Mo_M_AXI_ARID;
    wire [31:0]             Mo_M_AXI_ARADDR;
    wire [7:0]              Mo_M_AXI_ARLEN;
    wire [2:0]              Mo_M_AXI_ARSIZE;
    wire [1:0]              Mo_M_AXI_ARBURST;
    wire [1:0]              Mo_M_AXI_ARLOCK;
    wire [3:0]              Mo_M_AXI_ARCACHE;
    wire [2:0]              Mo_M_AXI_ARPROT;
    wire [3:0]              Mo_M_AXI_ARQOS;
    wire [0:0]              Mo_M_AXI_ARUSER;
    wire                    Mo_M_AXI_ARVALID;
    wire                    Mo_M_AXI_ARREADY; 
    
    // monitor -> Master Read Data 
    wire [0:0]              Mo_M_AXI_RID;   
    wire [31:0]             Mo_M_AXI_RDATA;   
    wire [1:0]              Mo_M_AXI_RRESP;   
    wire                    Mo_M_AXI_RLAST;   
    wire [0:0]              Mo_M_AXI_RUSER;   
    wire                    Mo_M_AXI_RVALID;  
    wire                    Mo_M_AXI_RREADY;

    // camera -> ctrls from controller
    wire                    ddr_write_finish;
    wire                    ddr_write_finish_valid;
    wire                    ddr_write_finish_ready;

    wire                    ddr_write_start;
    wire                    ddr_write_start_valid;
    wire                    ddr_write_start_ready;

    // camera -> Master Write Address
    wire [0:0]              Ca_M_AXI_AWID;
    wire [31:0]             Ca_M_AXI_AWADDR;
    wire [7:0]              Ca_M_AXI_AWLEN;    // Burst Length: 0-255
    wire [2:0]              Ca_M_AXI_AWSIZE;   // Burst Size: Fixed 2'b011
    wire [1:0]              Ca_M_AXI_AWBURST;  // Burst Type: Fixed 2'b01(Incremental Burst)
    wire                    Ca_M_AXI_AWLOCK;   // Lock: Fixed 2'b00
    wire [3:0]              Ca_M_AXI_AWCACHE;  // Cache: Fiex 2'b0011
    wire [2:0]              Ca_M_AXI_AWPROT;   // Protect: Fixed 2'b000
    wire [3:0]              Ca_M_AXI_AWQOS;    // QoS: Fixed 2'b0000
    wire [0:0]              Ca_M_AXI_AWUSER;   // User: Fixed 32'd0
    wire                    Ca_M_AXI_AWVALID;
    wire                    Ca_M_AXI_AWREADY;    

    // camera -> Master Write Data
    wire [31:0]             Ca_M_AXI_WDATA;
    wire [7:0]              Ca_M_AXI_WSTRB;
    wire                    Ca_M_AXI_WLAST;
    wire [0:0]              Ca_M_AXI_WUSER;
    wire                    Ca_M_AXI_WVALID;
    wire                    Ca_M_AXI_WREADY;

    // camera -> Master Write Response
    wire [0:0]               Ca_M_AXI_BID;
    wire [1:0]               Ca_M_AXI_BRESP;
    wire [0:0]               Ca_M_AXI_BUSER;
    wire                     Ca_M_AXI_BVALID;
    wire                     Ca_M_AXI_BREADY;

    // controller -> from outside
    wire                     start_all;

    // controller -> flag
    wire                     odd_even_flag;

    // accelerator -> TO/FROM controller
    wire                     acc_start;
    wire                     acc_finish;

// end

monitor_adaptor monitor_uut(
    // Reset, Clock
    .aresetn(aresetn),
    .clk(clk),

    //ctrls from controller
    .ddr_read_finish(ddr_read_finish),
    .ddr_read_finish_valid(ddr_read_finish_valid),
    .ddr_read_finish_ready(ddr_read_finish_ready),
    .odd_even_flag(odd_even_flag),

    .ddr_read_start(ddr_read_start),
    .ddr_read_start_valid(ddr_read_start_valid),
    .ddr_read_start_ready(ddr_read_start_ready),

    //generate packets
    .pkt_out_data(pkt_out_data),
    .pkt_out_en(pkt_out_en),
    .pkt_out_md(pkt_out_md),
    .pkt_out_md_en(pkt_out_md_en),
    .pkt_out_data_alf(pkt_out_data_alf),
  

    // Master Read Address
    .M_AXI_ARID(Mo_M_AXI_ARID),
    .M_AXI_ARADDR(Mo_M_AXI_ARADDR),
    .M_AXI_ARLEN(Mo_M_AXI_ARLEN),
    .M_AXI_ARSIZE(Mo_M_AXI_ARSIZE),
    .M_AXI_ARBURST(Mo_M_AXI_ARBURST),
    .M_AXI_ARLOCK(Mo_M_AXI_ARLOCK),
    .M_AXI_ARCACHE(Mo_M_AXI_ARCACHE),
    .M_AXI_ARPROT(Mo_M_AXI_ARPROT),
    .M_AXI_ARQOS(Mo_M_AXI_ARQOS),
    .M_AXI_ARUSER(Mo_M_AXI_ARUSER),
    .M_AXI_ARVALID(Mo_M_AXI_ARVALID),
    .M_AXI_ARREADY(Mo_M_AXI_ARREADY),
    
    // Master Read Data 
    .M_AXI_RID(Mo_M_AXI_RID),
    .M_AXI_RDATA(Mo_M_AXI_RDATA),
    .M_AXI_RRESP(Mo_M_AXI_RRESP),
    .M_AXI_RLAST(Mo_M_AXI_RLAST),
    .M_AXI_RUSER(Mo_M_AXI_RUSER),
    .M_AXI_RVALID(Mo_M_AXI_RVALID),
    .M_AXI_RREADY(Mo_M_AXI_RREADY)
    
);

camera_adaptor camera_uut(
    // Reset, Clock
    .aresetn(aresetn),
    .clk(clk),

    //ctrls from controller
    .ddr_write_finish(ddr_write_finish),
    .ddr_write_finish_valid(ddr_write_finish_valid),
    .ddr_write_finish_ready(ddr_write_finish_ready),

    .odd_even_flag(odd_even_flag),

    .ddr_write_start(ddr_write_start),
    .ddr_write_start_valid(ddr_write_start_valid),
    .ddr_write_start_ready(ddr_write_start_ready),

    //generate packets
    .pktin_data(pktin_data),
    .pktin_en(pktin_en),
    .pkt_in_md(pkt_in_md),
    .pkt_in_md_en(pkt_in_md_en),
    .pkt_data_alf(pkt_data_alf),
  

    // Master Write Address
    .M_AXI_AWID(Ca_M_AXI_AWID),
    .M_AXI_AWADDR(Ca_M_AXI_AWADDR),
    .M_AXI_AWLEN(Ca_M_AXI_AWLEN),    // Burst Length: 0-255
    .M_AXI_AWSIZE(Ca_M_AXI_AWSIZE),   // Burst Size: Fixed 2'b011
    .M_AXI_AWBURST(Ca_M_AXI_AWBURST),  // Burst Type: Fixed 2'b01(Incremental Burst)
    .M_AXI_AWLOCK(Ca_M_AXI_AWLOCK),   // Lock: Fixed 2'b00
    .M_AXI_AWCACHE(Ca_M_AXI_AWCACHE),  // Cache: Fiex 2'b0011
    .M_AXI_AWPROT(Ca_M_AXI_AWPROT),   // Protect: Fixed 2'b000
    .M_AXI_AWQOS(Ca_M_AXI_AWQOS),    // QoS: Fixed 2'b0000
    .M_AXI_AWUSER(Ca_M_AXI_AWUSER),   // User: Fixed 32'd0
    .M_AXI_AWVALID(Ca_M_AXI_AWVALID),
    .M_AXI_AWREADY(Ca_M_AXI_AWREADY),    

    // Master Write Data
    .M_AXI_WDATA(Ca_M_AXI_WDATA),
    .M_AXI_WSTRB(Ca_M_AXI_WSTRB),
    .M_AXI_WLAST(Ca_M_AXI_WLAST),
    .M_AXI_WUSER(Ca_M_AXI_WUSER),
    .M_AXI_WVALID(Ca_M_AXI_WVALID),
    .M_AXI_WREADY(Ca_M_AXI_WREADY),

    // Master Write Response
    .M_AXI_BID(Ca_M_AXI_BID),
    .M_AXI_BRESP(Ca_M_AXI_BRESP),
    .M_AXI_BUSER(Ca_M_AXI_BUSER),
    .M_AXI_BVALID(Ca_M_AXI_BVALID),
    .M_AXI_BREADY(Ca_M_AXI_BREADY)
    
);

controller controller_uut(
    .clk(clk),
    .aresetn(aresetn),

    //from outside
    .start_all(start_all),

    //TO MONITOR
    .ddr_read_start(ddr_read_start),
    .ddr_read_start_valid(ddr_read_start_valid),
    .ddr_read_start_ready(ddr_read_start_ready),
    
    //TO CAMERA
    .ddr_write_start(ddr_write_start),
    .ddr_write_start_valid(ddr_write_start_valid),
    .ddr_write_start_ready(ddr_write_start_ready),

    //FROM MONITOR
    .ddr_read_finish(ddr_read_finish),
    .ddr_read_finish_valid(ddr_read_finish_valid),
    .ddr_read_finish_ready(ddr_read_finish_ready),

    //FROM CAMERA
    .ddr_write_finish(ddr_write_finish),
    .ddr_write_finish_valid(ddr_write_finish_valid),
    .ddr_write_finish_ready(ddr_write_finish_ready),

    //TO/FROM ACCEL
    .acc_start(acc_start),
    .acc_finish(acc_finish),

    .cmd_in_wr(cmd_in_wr),
    .cmd_in(cmd_in),
    .cmd_in_alf(cmd_in_alf),

    .cmd_out_wr(cmd_out_wr),
	.cmd_out(cmd_out),
	.cmd_out_alf(cmd_out_alf),
    
    .odd_even_flag(odd_even_flag)
);

accelerator_adapter_test accelerator_uut(
    .clk(clk),
    .aresetn(aresetn),
    
    // TO/FROM controller
    .acc_start(acc_start),
    .acc_finish(acc_finish)

);

axi_interconnect_0 axi_interconnect_uut(
  .INTERCONNECT_ACLK                (clk),        // input wire INTERCONNECT_ACLK
  .INTERCONNECT_ARESETN             (aresetn),  // input wire INTERCONNECT_ARESETN
  
  .S00_AXI_ARESET_OUT_N             (S00_AXI_ARESET_OUT_N),  // output wire S00_AXI_ARESET_OUT_N
  .S00_AXI_ACLK                     (clk),                  // input wire S00_AXI_ACLK
  .S00_AXI_AWID                     (1'b0),                  // input wire [0 : 0] S00_AXI_AWID
  .S00_AXI_AWADDR                   (32'b0),              // input wire [31 : 0] S00_AXI_AWADDR
  .S00_AXI_AWLEN                    (8'b0),                // input wire [7 : 0] S00_AXI_AWLEN
  .S00_AXI_AWSIZE                   (3'b0),              // input wire [2 : 0] S00_AXI_AWSIZE
  .S00_AXI_AWBURST                  (2'b0),            // input wire [1 : 0] S00_AXI_AWBURST
  .S00_AXI_AWLOCK                   (1'b0),              // input wire S00_AXI_AWLOCK
  .S00_AXI_AWCACHE                  (4'b0),            // input wire [3 : 0] S00_AXI_AWCACHE
  .S00_AXI_AWPROT                   (3'b0),              // input wire [2 : 0] S00_AXI_AWPROT
  .S00_AXI_AWQOS                    (4'b0),                // input wire [3 : 0] S00_AXI_AWQOS
  .S00_AXI_AWVALID                  (1'b0),            // input wire S00_AXI_AWVALID
  .S00_AXI_AWREADY                  (),            // output wire S00_AXI_AWREADY
  .S00_AXI_WDATA                    (32'b0),                // input wire [31 : 0] S00_AXI_WDATA
  .S00_AXI_WSTRB                    (4'b0),                // input wire [3 : 0] S00_AXI_WSTRB
  .S00_AXI_WLAST                    (1'b0),                // input wire S00_AXI_WLAST
  .S00_AXI_WVALID                   (1'b0),              // input wire S00_AXI_WVALID
  .S00_AXI_WREADY                   (),              // output wire S00_AXI_WREADY
  .S00_AXI_BID                      (),                    // output wire [0 : 0] S00_AXI_BID
  .S00_AXI_BRESP                    (),                // output wire [1 : 0] S00_AXI_BRESP
  .S00_AXI_BVALID                   (),              // output wire S00_AXI_BVALID
  .S00_AXI_BREADY                   (1'b0),              // input wire S00_AXI_BREADY
  .S00_AXI_ARID                     (Mo_M_AXI_ARID),                  // input wire [0 : 0] S00_AXI_ARID
  .S00_AXI_ARADDR                   (Mo_M_AXI_ARADDR),              // input wire [31 : 0] S00_AXI_ARADDR
  .S00_AXI_ARLEN                    (Mo_M_AXI_ARLEN),                // input wire [7 : 0] S00_AXI_ARLEN
  .S00_AXI_ARSIZE                   (Mo_M_AXI_ARSIZE),              // input wire [2 : 0] S00_AXI_ARSIZE
  .S00_AXI_ARBURST                  (Mo_M_AXI_ARBURST),            // input wire [1 : 0] S00_AXI_ARBURST
  .S00_AXI_ARLOCK                   (Mo_M_AXI_ARLOCK),              // input wire S00_AXI_ARLOCK
  .S00_AXI_ARCACHE                  (Mo_M_AXI_ARCACHE),            // input wire [3 : 0] S00_AXI_ARCACHE
  .S00_AXI_ARPROT                   (Mo_M_AXI_ARPROT),              // input wire [2 : 0] S00_AXI_ARPROT
  .S00_AXI_ARQOS                    (Mo_M_AXI_ARQOS),                // input wire [3 : 0] S00_AXI_ARQOS
  .S00_AXI_ARVALID                  (Mo_M_AXI_ARVALID),            // input wire S00_AXI_ARVALID
  .S00_AXI_ARREADY                  (Mo_M_AXI_ARREADY),            // output wire S00_AXI_ARREADY
  .S00_AXI_RID                      (Mo_M_AXI_RID),                    // output wire [0 : 0] S00_AXI_RID
  .S00_AXI_RDATA                    (Mo_M_AXI_RDATA),                // output wire [31 : 0] S00_AXI_RDATA
  .S00_AXI_RRESP                    (Mo_M_AXI_RRESP),                // output wire [1 : 0] S00_AXI_RRESP
  .S00_AXI_RLAST                    (Mo_M_AXI_RLAST),                // output wire S00_AXI_RLAST
  .S00_AXI_RVALID                   (Mo_M_AXI_RVALID),              // output wire S00_AXI_RVALID
  .S00_AXI_RREADY                   (Mo_M_AXI_RREADY),              // input wire S00_AXI_RREADY
  
  .S01_AXI_ARESET_OUT_N             (S01_AXI_ARESET_OUT_N),  // output wire S01_AXI_ARESET_OUT_N
  .S01_AXI_ACLK                     (clk),                  // input wire S01_AXI_ACLK
  .S01_AXI_AWID                     (Ca_M_AXI_AWID),                  // input wire [0 : 0] S01_AXI_AWID
  .S01_AXI_AWADDR                   (Ca_M_AXI_AWADDR),              // input wire [31 : 0] S01_AXI_AWADDR
  .S01_AXI_AWLEN                    (Ca_M_AXI_AWLEN),                // input wire [7 : 0] S01_AXI_AWLEN
  .S01_AXI_AWSIZE                   (Ca_M_AXI_AWSIZE),              // input wire [2 : 0] S01_AXI_AWSIZE
  .S01_AXI_AWBURST                  (Ca_M_AXI_AWBURST),            // input wire [1 : 0] S01_AXI_AWBURST
  .S01_AXI_AWLOCK                   (Ca_M_AXI_AWLOCK),              // input wire S01_AXI_AWLOCK
  .S01_AXI_AWCACHE                  (Ca_M_AXI_AWCACHE),            // input wire [3 : 0] S01_AXI_AWCACHE
  .S01_AXI_AWPROT                   (Ca_M_AXI_AWPROT),              // input wire [2 : 0] S01_AXI_AWPROT
  .S01_AXI_AWQOS                    (Ca_M_AXI_AWQOS),                // input wire [3 : 0] S01_AXI_AWQOS
  .S01_AXI_AWVALID                  (Ca_M_AXI_AWVALID),            // input wire S01_AXI_AWVALID
  .S01_AXI_AWREADY                  (Ca_M_AXI_AWREADY),            // output wire S01_AXI_AWREADY
  .S01_AXI_WDATA                    (Ca_M_AXI_WDATA),                // input wire [31 : 0] S01_AXI_WDATA
  .S01_AXI_WSTRB                    (Ca_M_AXI_WSTRB),                // input wire [3 : 0] S01_AXI_WSTRB
  .S01_AXI_WLAST                    (Ca_M_AXI_WLAST),                // input wire S01_AXI_WLAST
  .S01_AXI_WVALID                   (Ca_M_AXI_WVALID),              // input wire S01_AXI_WVALID
  .S01_AXI_WREADY                   (Ca_M_AXI_WREADY),              // output wire S01_AXI_WREADY
  .S01_AXI_BID                      (Ca_M_AXI_BID),                    // output wire [0 : 0] S01_AXI_BID
  .S01_AXI_BRESP                    (Ca_M_AXI_BRESP),                // output wire [1 : 0] S01_AXI_BRESP
  .S01_AXI_BVALID                   (Ca_M_AXI_BVALID),              // output wire S01_AXI_BVALID
  .S01_AXI_BREADY                   (Ca_M_AXI_BREADY),              // input wire S01_AXI_BREADY
  .S01_AXI_ARID                     (1'b0),                  // input wire [0 : 0] S01_AXI_ARID
  .S01_AXI_ARADDR                   (32'b0),              // input wire [31 : 0] S01_AXI_ARADDR
  .S01_AXI_ARLEN                    (8'b0),                // input wire [7 : 0] S01_AXI_ARLEN
  .S01_AXI_ARSIZE                   (3'b0),              // input wire [2 : 0] S01_AXI_ARSIZE
  .S01_AXI_ARBURST                  (2'b0),            // input wire [1 : 0] S01_AXI_ARBURST
  .S01_AXI_ARLOCK                   (1'b0),              // input wire S01_AXI_ARLOCK
  .S01_AXI_ARCACHE                  (4'b0),            // input wire [3 : 0] S01_AXI_ARCACHE
  .S01_AXI_ARPROT                   (3'b0),              // input wire [2 : 0] S01_AXI_ARPROT
  .S01_AXI_ARQOS                    (4'b0),                // input wire [3 : 0] S01_AXI_ARQOS
  .S01_AXI_ARVALID                  (1'b0),            // input wire S01_AXI_ARVALID
  .S01_AXI_ARREADY                  (),            // output wire S01_AXI_ARREADY
  .S01_AXI_RID                      (),                    // output wire [0 : 0] S01_AXI_RID
  .S01_AXI_RDATA                    (),                // output wire [31 : 0] S01_AXI_RDATA
  .S01_AXI_RRESP                    (),                // output wire [1 : 0] S01_AXI_RRESP
  .S01_AXI_RLAST                    (),                // output wire S01_AXI_RLAST
  .S01_AXI_RVALID                   (),              // output wire S01_AXI_RVALID
  .S01_AXI_RREADY                   (1'b0),              // input wire S01_AXI_RREADY

  .S02_AXI_ARESET_OUT_N             (S02_AXI_ARESET_OUT_N),  // output wire S02_AXI_ARESET_OUT_N
  .S02_AXI_ACLK                     (1'b0),                  // input wire S02_AXI_ACLK
  .S02_AXI_AWID                     (1'b0),                  // input wire [0 : 0] S02_AXI_AWID
  .S02_AXI_AWADDR                   (32'b0),              // input wire [31 : 0] S02_AXI_AWADDR
  .S02_AXI_AWLEN                    (8'b0),                // input wire [7 : 0] S02_AXI_AWLEN
  .S02_AXI_AWSIZE                   (3'b0),              // input wire [2 : 0] S02_AXI_AWSIZE
  .S02_AXI_AWBURST                  (2'b0),            // input wire [1 : 0] S02_AXI_AWBURST
  .S02_AXI_AWLOCK                   (1'b0),              // input wire S02_AXI_AWLOCK
  .S02_AXI_AWCACHE                  (4'b0),            // input wire [3 : 0] S02_AXI_AWCACHE
  .S02_AXI_AWPROT                   (3'b0),              // input wire [2 : 0] S02_AXI_AWPROT
  .S02_AXI_AWQOS                    (4'b0),                // input wire [3 : 0] S02_AXI_AWQOS
  .S02_AXI_AWVALID                  (1'b0),            // input wire S02_AXI_AWVALID
  .S02_AXI_AWREADY                  (),            // output wire S02_AXI_AWREADY
  .S02_AXI_WDATA                    (32'b0),                // input wire [31 : 0] S02_AXI_WDATA
  .S02_AXI_WSTRB                    (4'b0),                // input wire [3 : 0] S02_AXI_WSTRB
  .S02_AXI_WLAST                    (1'b0),                // input wire S02_AXI_WLAST
  .S02_AXI_WVALID                   (1'b0),              // input wire S02_AXI_WVALID
  .S02_AXI_WREADY                   (),              // output wire S02_AXI_WREADY
  .S02_AXI_BID                      (),                    // output wire [0 : 0] S02_AXI_BID
  .S02_AXI_BRESP                    (),                // output wire [1 : 0] S02_AXI_BRESP
  .S02_AXI_BVALID                   (),              // output wire S02_AXI_BVALID
  .S02_AXI_BREADY                   (1'b0),              // input wire S02_AXI_BREADY
  .S02_AXI_ARID                     (1'b0),                  // input wire [0 : 0] S02_AXI_ARID
  .S02_AXI_ARADDR                   (32'b0),              // input wire [31 : 0] S02_AXI_ARADDR
  .S02_AXI_ARLEN                    (8'b0),                // input wire [7 : 0] S02_AXI_ARLEN
  .S02_AXI_ARSIZE                   (3'b0),              // input wire [2 : 0] S02_AXI_ARSIZE
  .S02_AXI_ARBURST                  (2'b0),            // input wire [1 : 0] S02_AXI_ARBURST
  .S02_AXI_ARLOCK                   (1'b0),              // input wire S02_AXI_ARLOCK
  .S02_AXI_ARCACHE                  (4'b0),            // input wire [3 : 0] S02_AXI_ARCACHE
  .S02_AXI_ARPROT                   (3'b0),              // input wire [2 : 0] S02_AXI_ARPROT
  .S02_AXI_ARQOS                    (4'b0),                // input wire [3 : 0] S02_AXI_ARQOS
  .S02_AXI_ARVALID                  (1'b0),            // input wire S02_AXI_ARVALID
  .S02_AXI_ARREADY                  (),            // output wire S02_AXI_ARREADY
  .S02_AXI_RID                      (),                    // output wire [0 : 0] S02_AXI_RID
  .S02_AXI_RDATA                    (),                // output wire [31 : 0] S02_AXI_RDATA
  .S02_AXI_RRESP                    (),                // output wire [1 : 0] S02_AXI_RRESP
  .S02_AXI_RLAST                    (),                // output wire S02_AXI_RLAST
  .S02_AXI_RVALID                   (),              // output wire S02_AXI_RVALID
  .S02_AXI_RREADY                   (1'b0),              // input wire S02_AXI_RREADY

  .S03_AXI_ARESET_OUT_N             (S03_AXI_ARESET_OUT_N),  // output wire S03_AXI_ARESET_OUT_N
  .S03_AXI_ACLK                     (1'b0),                   // input wire S03_AXI_ACLK
  .S03_AXI_AWID                     (1'b0),                   // input wire [0 : 0] S03_AXI_AWID
  .S03_AXI_AWADDR                   (32'b0),              // input wire [31 : 0] S03_AXI_AWADDR
  .S03_AXI_AWLEN                    (8'b0),                 // input wire [7 : 0] S03_AXI_AWLEN
  .S03_AXI_AWSIZE                   (3'b0),               // input wire [2 : 0] S03_AXI_AWSIZE
  .S03_AXI_AWBURST                  (2'b0),             // input wire [1 : 0] S03_AXI_AWBURST
  .S03_AXI_AWLOCK                   (1'b0),               // input wire S03_AXI_AWLOCK
  .S03_AXI_AWCACHE                  (4'b0),             // input wire [3 : 0] S03_AXI_AWCACHE
  .S03_AXI_AWPROT                   (3'b0),               // input wire [2 : 0] S03_AXI_AWPROT
  .S03_AXI_AWQOS                    (4'b0),                 // input wire [3 : 0] S03_AXI_AWQOS
  .S03_AXI_AWVALID                  (1'b0),             // input wire S03_AXI_AWVALID
  .S03_AXI_AWREADY                  (),                 // output wire S03_AXI_AWREADY
  .S03_AXI_WDATA                    (32'b0),                // input wire [31 : 0] S03_AXI_WDATA
  .S03_AXI_WSTRB                    (4'b0),                 // input wire [3 : 0] S03_AXI_WSTRB
  .S03_AXI_WLAST                    (1'b0),                 // input wire S03_AXI_WLAST
  .S03_AXI_WVALID                   (1'b0),               // input wire S03_AXI_WVALID
  .S03_AXI_WREADY                   (),                   // output wire S03_AXI_WREADY
  .S03_AXI_BID                      (),                         // output wire [0 : 0] S03_AXI_BID
  .S03_AXI_BRESP                    (),                     // output wire [1 : 0] S03_AXI_BRESP
  .S03_AXI_BVALID                   (),                   // output wire S03_AXI_BVALID
  .S03_AXI_BREADY                   (1'b0),               // input wire S03_AXI_BREADY
  .S03_AXI_ARID                     (1'b0),                   // input wire [0 : 0] S03_AXI_ARID
  .S03_AXI_ARADDR                   (32'b0),              // input wire [31 : 0] S03_AXI_ARADDR
  .S03_AXI_ARLEN                    (8'b0),                 // input wire [7 : 0] S03_AXI_ARLEN
  .S03_AXI_ARSIZE                   (3'b0),               // input wire [2 : 0] S03_AXI_ARSIZE
  .S03_AXI_ARBURST                  (2'b0),             // input wire [1 : 0] S03_AXI_ARBURST
  .S03_AXI_ARLOCK                   (1'b0),               // input wire S03_AXI_ARLOCK
  .S03_AXI_ARCACHE                  (4'b0),             // input wire [3 : 0] S03_AXI_ARCACHE
  .S03_AXI_ARPROT                   (3'b0),               // input wire [2 : 0] S03_AXI_ARPROT
  .S03_AXI_ARQOS                    (4'b0),                 // input wire [3 : 0] S03_AXI_ARQOS
  .S03_AXI_ARVALID                  (1'b0),             // input wire S03_AXI_ARVALID
  .S03_AXI_ARREADY                  (),                 // output wire S03_AXI_ARREADY
  .S03_AXI_RID                      (),                         // output wire [0 : 0] S03_AXI_RID
  .S03_AXI_RDATA                    (),                     // output wire [31 : 0] S03_AXI_RDATA
  .S03_AXI_RRESP                    (),                     // output wire [1 : 0] S03_AXI_RRESP
  .S03_AXI_RLAST                    (),                     // output wire S03_AXI_RLAST
  .S03_AXI_RVALID                   (),                   // output wire S03_AXI_RVALID
  .S03_AXI_RREADY                   (1'b0),               // input wire S03_AXI_RREADY

  .M00_AXI_ARESET_OUT_N             (M00_AXI_ARESET_OUT_N),  // output wire M00_AXI_ARESET_OUT_N
  .M00_AXI_ACLK                     (M00_AXI_ACLK),                  // input wire M00_AXI_ACLK
  .M00_AXI_AWID                     (M00_AXI_AWID),                  // output wire [3 : 0] M00_AXI_AWID
  .M00_AXI_AWADDR                   (M00_AXI_AWADDR),              // output wire [31 : 0] M00_AXI_AWADDR
  .M00_AXI_AWLEN                    (M00_AXI_AWLEN),                // output wire [7 : 0] M00_AXI_AWLEN
  .M00_AXI_AWSIZE                   (M00_AXI_AWSIZE),              // output wire [2 : 0] M00_AXI_AWSIZE
  .M00_AXI_AWBURST                  (M00_AXI_AWBURST),            // output wire [1 : 0] M00_AXI_AWBURST
  .M00_AXI_AWLOCK                   (M00_AXI_AWLOCK),              // output wire M00_AXI_AWLOCK
  .M00_AXI_AWCACHE                  (M00_AXI_AWCACHE),            // output wire [3 : 0] M00_AXI_AWCACHE
  .M00_AXI_AWPROT                   (M00_AXI_AWPROT),              // output wire [2 : 0] M00_AXI_AWPROT
  .M00_AXI_AWQOS                    (M00_AXI_AWQOS),                // output wire [3 : 0] M00_AXI_AWQOS
  .M00_AXI_AWVALID                  (M00_AXI_AWVALID),            // output wire M00_AXI_AWVALID
  .M00_AXI_AWREADY                  (M00_AXI_AWREADY),            // input wire M00_AXI_AWREADY
  .M00_AXI_WDATA                    (M00_AXI_WDATA),                // output wire [31 : 0] M00_AXI_WDATA
  .M00_AXI_WSTRB                    (M00_AXI_WSTRB),                // output wire [3 : 0] M00_AXI_WSTRB
  .M00_AXI_WLAST                    (M00_AXI_WLAST),                // output wire M00_AXI_WLAST
  .M00_AXI_WVALID                   (M00_AXI_WVALID),              // output wire M00_AXI_WVALID
  .M00_AXI_WREADY                   (M00_AXI_WREADY),              // input wire M00_AXI_WREADY
  .M00_AXI_BID                      (M00_AXI_BID),                    // input wire [3 : 0] M00_AXI_BID
  .M00_AXI_BRESP                    (M00_AXI_BRESP),                // input wire [1 : 0] M00_AXI_BRESP
  .M00_AXI_BVALID                   (M00_AXI_BVALID),              // input wire M00_AXI_BVALID
  .M00_AXI_BREADY                   (M00_AXI_BREADY),              // output wire M00_AXI_BREADY
  .M00_AXI_ARID                     (M00_AXI_ARID),                  // output wire [3 : 0] M00_AXI_ARID
  .M00_AXI_ARADDR                   (M00_AXI_ARADDR),              // output wire [31 : 0] M00_AXI_ARADDR
  .M00_AXI_ARLEN                    (M00_AXI_ARLEN),                // output wire [7 : 0] M00_AXI_ARLEN
  .M00_AXI_ARSIZE                   (M00_AXI_ARSIZE),              // output wire [2 : 0] M00_AXI_ARSIZE
  .M00_AXI_ARBURST                  (M00_AXI_ARBURST),            // output wire [1 : 0] M00_AXI_ARBURST
  .M00_AXI_ARLOCK                   (M00_AXI_ARLOCK),              // output wire M00_AXI_ARLOCK
  .M00_AXI_ARCACHE                  (M00_AXI_ARCACHE),            // output wire [3 : 0] M00_AXI_ARCACHE
  .M00_AXI_ARPROT                   (M00_AXI_ARPROT),              // output wire [2 : 0] M00_AXI_ARPROT
  .M00_AXI_ARQOS                    (M00_AXI_ARQOS),                // output wire [3 : 0] M00_AXI_ARQOS
  .M00_AXI_ARVALID                  (M00_AXI_ARVALID),            // output wire M00_AXI_ARVALID
  .M00_AXI_ARREADY                  (M00_AXI_ARREADY),            // input wire M00_AXI_ARREADY
  .M00_AXI_RID                      (M00_AXI_RID),                    // input wire [3 : 0] M00_AXI_RID
  .M00_AXI_RDATA                    (M00_AXI_RDATA),                // input wire [31 : 0] M00_AXI_RDATA
  .M00_AXI_RRESP                    (M00_AXI_RRESP),                // input wire [1 : 0] M00_AXI_RRESP
  .M00_AXI_RLAST                    (M00_AXI_RLAST),                // input wire M00_AXI_RLAST
  .M00_AXI_RVALID                   (M00_AXI_RVALID),              // input wire M00_AXI_RVALID
  .M00_AXI_RREADY                   (M00_AXI_RREADY)              // output wire M00_AXI_RREADY
);

endmodule
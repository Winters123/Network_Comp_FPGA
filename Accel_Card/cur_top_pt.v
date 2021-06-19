module cur_top_pt (
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

    //from outside
    reg                       start_all;
    //TO MONITO;
    wire                      ddr_read_start;
    wire                      ddr_read_start_valid;
    wire                      ddr_read_start_ready;
    
    //TO CAMERA
    wire                      ddr_write_start;
    wire                      ddr_write_start_valid;
    wire                      ddr_write_start_ready;

    //FROM MONITOR
    wire                      ddr_read_finish;
    wire                      ddr_read_finish_valid;
    wire                      ddr_read_finish_ready;

    //FROM CAMERA
    wire                      ddr_write_finish;
    wire                      ddr_write_finish_valid;
    wire                      ddr_write_finish_ready;

    //TO/FROM ACCEL
    wire                      acc_start;
    wire                      acc_finish;


    wire                      odd_even_flag;



    //     // Master Write Address
    // wire [0:0]           M00_AXI_AWID;
    // wire [31:0]          M00_AXI_AWADDR;
    // wire [7:0]           M00_AXI_AWLEN;    // Burst Length: 0-255
    // wire [2:0]           M00_AXI_AWSIZE;   // Burst Size: Fixed 2'b011
    // wire [1:0]           M00_AXI_AWBURST;  // Burst Type: Fixed 2'b01(Incremental Burst)
    // wire                 M00_AXI_AWLOCK;   // Lock: Fixed 2'b00
    // wire [3:0]           M00_AXI_AWCACHE;  // Cache: Fiex 2'b0011
    // wire [2:0]           M00_AXI_AWPROT;   // Protect: Fixed 2'b000
    // wire [3:0]           M00_AXI_AWQOS;    // QoS: Fixed 2'b0000
    // wire [0:0]           M00_AXI_AWUSER;   // User: Fixed 32'd0
    // wire                 M00_AXI_AWVALID;
    // wire                 M00_AXI_AWREADY;    

    // // Master Write Data
    // wire [31:0]          M00_AXI_WDATA;
    // wire [3:0]           M00_AXI_WSTRB;
    // wire                 M00_AXI_WLAST;
    // wire [0:0]           M00_AXI_WUSER;
    // wire                 M00_AXI_WVALID;
    // wire                 M00_AXI_WREADY;

    // // Master Write Response
    // wire [0:0]           M00_AXI_BID;
    // wire [1:0]           M00_AXI_BRESP;
    // wire [0:0]           M00_AXI_BUSER;
    // wire                 M00_AXI_BVALID;
    // wire                 M00_AXI_BREADY;

    //     // Master Read Address
    // wire [0:0]              M00_AXI_ARID;
    // wire [31:0]             M00_AXI_ARADDR;
    // wire [7:0]              M00_AXI_ARLEN;
    // wire [2:0]              M00_AXI_ARSIZE;
    // wire [1:0]              M00_AXI_ARBURST;
    // wire [1:0]              M00_AXI_ARLOCK;
    // wire [3:0]              M00_AXI_ARCACHE;
    // wire [2:0]              M00_AXI_ARPROT;
    // wire [3:0]              M00_AXI_ARQOS;
    // wire [0:0]              M00_AXI_ARUSER;
    // wire                    M00_AXI_ARVALID;
    // wire                    M00_AXI_ARREADY;  //reg
    
    // // Master Read Data 
    // wire [0:0]               M00_AXI_RID;   //reg
    // wire [31:0]              M00_AXI_RDATA;   //reg
    // wire [1:0]               M00_AXI_RRESP;   //reg
    // wire                     M00_AXI_RLAST;   //reg
    // wire [0:0]               M00_AXI_RUSER;   //reg
    // wire                     M00_AXI_RVALID;   //reg
    // wire                     M00_AXI_RREADY;



// initial begin
//     clk <= 1;
//     aresetn <= 1;
//     #(CYCLE)
//     aresetn <= 0;
//     #(2*CYCLE)
//     aresetn <= 1;
// end


// always begin
//     #(8*CYCLE)  //wait for rst_n finish

//     //reset
//     ddr_read_start_ready <= 1'b0;
//     ddr_write_start_ready <= 1'b0;

//     //start working
//     #(CYCLE)
//     start_all <= 1'b1;
//     ddr_write_start_ready <= 1'b1;
//     ddr_read_start_ready <= 1'b1;

//     ddr_read_finish <= 1;
//     ddr_read_finish_valid <= 1;

//     ddr_write_finish <= 0;
//     ddr_write_finish_valid <= 0;


//     #(10*CYCLE)
//     ddr_write_finish <= 1;
//     ddr_write_finish_valid <= 1;
//     ddr_write_start_ready <= 1;

//     #(CYCLE)
//     ddr_write_finish <= 0;
//     ddr_write_finish_valid <= 0;
    
//     #(10*CYCLE)
//     ddr_read_finish <= 1;
//     ddr_read_finish_valid <= 1;

//     #(CYCLE)
//     ddr_read_finish <= 0;
//     ddr_read_finish_valid <= 0;
//     #(20*CYCLE);



//     //#(1024*CYCLE);
// end

// end

controller controller_uut(
    .clk(clk),
    .aresetn(aresetn),

    //from outside
    .start_all(1'b1),

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

camera_adaptor camera_adaptor(
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
    //note: here is the trigger for the testbench
    .pktin_data(pktin_data),
    .pktin_en(pktin_en),
    .pkt_in_md(pkt_in_md),
    .pkt_in_md_en(pkt_in_md_en),
    .pkt_data_alf(pkt_data_alf),
  

    // Master Write Address
    .M_AXI_AWID(M00_AXI_AWID),
    .M_AXI_AWADDR(M00_AXI_AWADDR),
    .M_AXI_AWLEN(M00_AXI_AWLEN),    // Burst Length: 0-255
    .M_AXI_AWSIZE(M00_AXI_AWSIZE),   // Burst Size: Fixed 2'b011
    .M_AXI_AWBURST(M00_AXI_AWBURST),  // Burst Type: Fixed 2'b01(Incremental Burst)
    .M_AXI_AWLOCK(M00_AXI_AWLOCK),   // Lock: Fixed 2'b00
    .M_AXI_AWCACHE(M00_AXI_AWCACHE),  // Cache: Fiex 2'b0011
    .M_AXI_AWPROT(M00_AXI_AWPROT),   // Protect: Fixed 2'b000
    .M_AXI_AWQOS(M00_AXI_AWQOS),    // QoS: Fixed 2'b0000
    //.M00_AXI_AWUSER(M00_AXI_AWUSER),   // User: Fixed 32'd0
    .M_AXI_AWVALID(M00_AXI_AWVALID),
    .M_AXI_AWREADY(M00_AXI_AWREADY),    

    // Master Write Data
    .M_AXI_WDATA(M00_AXI_WDATA),
    .M_AXI_WSTRB(M00_AXI_WSTRB),
    .M_AXI_WLAST(M00_AXI_WLAST),
    //.M00_AXI_WUSER(M00_AXI_WUSER),
    .M_AXI_WVALID(M00_AXI_WVALID),
    .M_AXI_WREADY(M00_AXI_WREADY),

    // Master Write Response
    .M_AXI_BID(M00_AXI_BID),
    .M_AXI_BRESP(M00_AXI_BRESP),
    //.M00_AXI_BUSER(M00_AXI_BUSER),
    .M_AXI_BVALID(M00_AXI_BVALID),
    .M_AXI_BREADY(M00_AXI_BREADY)
    
);

monitor_adaptor monitor_adaptor(
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
    .M_AXI_ARID(M00_AXI_ARID),
    .M_AXI_ARADDR(M00_AXI_ARADDR),
    .M_AXI_ARLEN(M00_AXI_ARLEN),
    .M_AXI_ARSIZE(M00_AXI_ARSIZE),
    .M_AXI_ARBURST(M00_AXI_ARBURST),
    .M_AXI_ARLOCK(M00_AXI_ARLOCK),
    .M_AXI_ARCACHE(M00_AXI_ARCACHE),
    .M_AXI_ARPROT(M00_AXI_ARPROT),
    .M_AXI_ARQOS(M00_AXI_ARQOS),
    //.M00_AXI_ARUSER(M00_AXI_ARUSER),
    .M_AXI_ARVALID(M00_AXI_ARVALID),
    .M_AXI_ARREADY(M00_AXI_ARREADY),
    
    // Master Read Data 
    .M_AXI_RID(M00_AXI_RID),
    .M_AXI_RDATA(M00_AXI_RDATA),
    .M_AXI_RRESP(M00_AXI_RRESP),
    .M_AXI_RLAST(M00_AXI_RLAST),
    //.M00_AXI_RUSER(M00_AXI_RUSER),
    .M_AXI_RVALID(M00_AXI_RVALID),
    .M_AXI_RREADY(M00_AXI_RREADY)
    
);

// axi_vip_0 axi_ddr_demo (
//     .aclk(clk),                    // input wire aclk
//     .aresetn(aresetn),               //input wire aresetn

//     // Master Write Address
//     .s_axi_awid(M00_AXI_AWID),
//     .s_axi_awaddr(M00_AXI_AWADDR),
//     .s_axi_awlen(M00_AXI_AWLEN),    // Burst Length: 0-255
//     .s_axi_awsize(M00_AXI_AWSIZE),   // Burst Size: Fixed 2'b011
//     .s_axi_awburst(M00_AXI_AWBURST),  // Burst Type: Fixed 2'b01(Incremental Burst)
//     .s_axi_awlock(M00_AXI_AWLOCK),   // Lock: Fixed 2'b00
//     .s_axi_awcache(M00_AXI_AWCACHE),  // Cache: Fiex 2'b0011
//     .s_axi_awprot(M00_AXI_AWPROT),   // Protect: Fixed 2'b000
//     .s_axi_awqos(M00_AXI_AWQOS),    // QoS: Fixed 2'b0000
//     //.s_axi_awuser(M00_AXI_AWUSER),   // User: Fixed 32'd0
//     .s_axi_awvalid(M00_AXI_AWVALID),
//     .s_axi_awready(M00_AXI_AWREADY),    

//     // Master Write Data
//     .s_axi_wdata(M00_AXI_WDATA),
//     .s_axi_wstrb(M00_AXI_WSTRB),
//     .s_axi_wlast(M00_AXI_WLAST),
//     //.s_axi_wuser(M00_AXI_WUSER),
//     .s_axi_wvalid(M00_AXI_WVALID),
//     .s_axi_wready(M00_AXI_WREADY),

//     // Master Write Response
//     .s_axi_bid(M00_AXI_BID),
//     .s_axi_bresp(M00_AXI_BRESP),
//     //.s_axi_buser(M00_AXI_BUSER),
//     .s_axi_bvalid(M00_AXI_BVALID),
//     .s_axi_bready(M00_AXI_BREADY),

//     .s_axi_arid(M00_AXI_ARID),        // input wire [0 : 0] s_axi_arid
//     .s_axi_araddr(M00_AXI_ARADDR),    // input wire [31 : 0] s_axi_araddr
//     .s_axi_arlen(M00_AXI_ARLEN),      // input wire [7 : 0] s_axi_arlen
//     .s_axi_arsize(M00_AXI_ARSIZE),    // input wire [2 : 0] s_axi_arsize
//     .s_axi_arburst(M00_AXI_ARBURST),  // input wire [1 : 0] s_axi_arburst
//     .s_axi_arcache(M00_AXI_ARCACHE),  // input wire [3 : 0] s_axi_arcache
//     .s_axi_arprot(M00_AXI_ARPROT),    // input wire [2 : 0] s_axi_arprot
//     .s_axi_arqos(M00_AXI_ARQOS),      // input wire [3 : 0] s_axi_arqos,
//     .s_axi_arlock(M00_AXI_ARLOCK),
//     //.s_axi_aruser(M00_AXI_ARUSER),    // input wire [0 : 0] s_axi_aruser
//     .s_axi_arvalid(M00_AXI_ARVALID),  // input wire s_axi_arvalid
//     .s_axi_arready(M00_AXI_ARREADY),  // output wire s_axi_arready


//     .s_axi_rid(M00_AXI_RID),          // output wire [0 : 0] s_axi_rid
//     .s_axi_rdata(M00_AXI_RDATA),      // output wire [31 : 0] s_axi_rdata
//     .s_axi_rresp(M00_AXI_RRESP),      // output wire [1 : 0] s_axi_rresp
//     .s_axi_rlast(M00_AXI_RLAST),      // output wire s_axi_rlast
//     //.s_axi_ruser(M00_AXI_RUSER),      // output wire [0 : 0] s_axi_ruser
//     .s_axi_rvalid(M00_AXI_RVALID),    // output wire s_axi_rvalid
//     .s_axi_rready(M00_AXI_RREADY)    // input wire s_axi_rready
// );

endmodule
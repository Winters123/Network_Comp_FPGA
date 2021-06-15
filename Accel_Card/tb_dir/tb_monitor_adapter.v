module tb_monitor_adapter (
    input clk,
    input aresetn
);
    // Reset, Clock
    // reg                     aresetn;
    // reg                     clk;

    //ctrls from controller
    wire                    ddr_read_finish;
    wire                    ddr_read_finish_valid;
    reg                     ddr_read_finish_ready;

    reg                     odd_even_flag;

    reg                     ddr_read_start;
    reg                     ddr_read_start_valid;
    wire                    ddr_read_start_ready;

    //generate packets
    wire [519:0]            pkt_out_data;
    wire                    pkt_out_en;
    wire [255:0]            pkt_out_md;
    wire                    pkt_out_md_en;
    reg                     pkt_out_data_alf;
  

    // Master Read Address
    wire [0:0]              M_AXI_ARID;
    wire [31:0]             M_AXI_ARADDR;
    wire [7:0]              M_AXI_ARLEN;
    wire [2:0]              M_AXI_ARSIZE;
    wire [1:0]              M_AXI_ARBURST;
    wire [1:0]              M_AXI_ARLOCK;
    wire [3:0]              M_AXI_ARCACHE;
    wire [2:0]              M_AXI_ARPROT;
    wire [3:0]              M_AXI_ARQOS;
    wire [0:0]              M_AXI_ARUSER;
    wire                    M_AXI_ARVALID;
    wire                    M_AXI_ARREADY;  //reg
    
    // Master Read Data 
    wire [0:0]               M_AXI_RID;   //reg
    wire [31:0]              M_AXI_RDATA;   //reg
    wire [1:0]               M_AXI_RRESP;   //reg
    wire                     M_AXI_RLAST;   //reg
    wire [0:0]               M_AXI_RUSER;   //reg
    wire                     M_AXI_RVALID;   //reg
    wire                     M_AXI_RREADY;


parameter CYCLE = 10;

// always begin
//     #(CYCLE/2) clk <= ~clk;
// end

// initial begin
//     clk <= 1;
//     aresetn <= 1;
//     #(CYCLE)
//     aresetn <= 0;
//     #(2*CYCLE)
//     aresetn <= 1;
// end

initial begin
    #(2*CYCLE+CYCLE/2)  //wait for rst_n finish

    //reset
    ddr_read_start <= 1'b0;
    ddr_read_start_valid <= 1'b0;
    odd_even_flag <= 1'b0;

    //start working
    #(3*CYCLE - CYCLE/2)
    ddr_read_start <= 1'b1;
    ddr_read_start_valid <= 1'b1;
    odd_even_flag <= 1'b1;

    pkt_out_data_alf <= 1'b0;

    #(10*CYCLE);
end

// end

monitor_adaptor uut(
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
    .M_AXI_ARID(M_AXI_ARID),
    .M_AXI_ARADDR(M_AXI_ARADDR),
    .M_AXI_ARLEN(M_AXI_ARLEN),
    .M_AXI_ARSIZE(M_AXI_ARSIZE),
    .M_AXI_ARBURST(M_AXI_ARBURST),
    .M_AXI_ARLOCK(M_AXI_ARLOCK),
    .M_AXI_ARCACHE(M_AXI_ARCACHE),
    .M_AXI_ARPROT(M_AXI_ARPROT),
    .M_AXI_ARQOS(M_AXI_ARQOS),
    .M_AXI_ARUSER(M_AXI_ARUSER),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    
    // Master Read Data 
    .M_AXI_RID(M_AXI_RID),
    .M_AXI_RDATA(M_AXI_RDATA),
    .M_AXI_RRESP(M_AXI_RRESP),
    .M_AXI_RLAST(M_AXI_RLAST),
    .M_AXI_RUSER(M_AXI_RUSER),
    .M_AXI_RVALID(M_AXI_RVALID),
    .M_AXI_RREADY(M_AXI_RREADY)
    
);

axi_vip_0 axi_ddr_demo (
  .aclk(clk),                    // input wire aclk
  .aresetn(aresetn),               //input wire aresetn
  .s_axi_arid(M_AXI_ARID),        // input wire [0 : 0] s_axi_arid
  .s_axi_araddr(M_AXI_ARADDR),    // input wire [31 : 0] s_axi_araddr
  .s_axi_arlen(M_AXI_ARLEN),      // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(M_AXI_ARSIZE),    // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(M_AXI_ARBURST),  // input wire [1 : 0] s_axi_arburst
  .s_axi_arcache(M_AXI_ARCACHE),  // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(M_AXI_ARPROT),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arqos(M_AXI_ARQOS),      // input wire [3 : 0] s_axi_arqos
  .s_axi_aruser(M_AXI_ARUSER),    // input wire [0 : 0] s_axi_aruser
  .s_axi_arvalid(M_AXI_ARVALID),  // input wire s_axi_arvalid
  .s_axi_arready(M_AXI_ARREADY),  // output wire s_axi_arready


  .s_axi_rid(M_AXI_RID),          // output wire [0 : 0] s_axi_rid
  .s_axi_rdata(M_AXI_RDATA),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(M_AXI_RRESP),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(M_AXI_RLAST),      // output wire s_axi_rlast
  .s_axi_ruser(M_AXI_RUSER),      // output wire [0 : 0] s_axi_ruser
  .s_axi_rvalid(M_AXI_RVALID),    // output wire s_axi_rvalid
  .s_axi_rready(M_AXI_RREADY)    // input wire s_axi_rready
);

endmodule
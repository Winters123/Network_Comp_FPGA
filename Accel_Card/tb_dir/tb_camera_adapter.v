module tb_camera_adapter ();
    // Reset, Clock
    reg                     aresetn;
    reg                     clk;

    //ctrls from controller
    wire                 ddr_write_finish;
    wire                 ddr_write_finish_valid;
    reg                  ddr_write_finish_ready;

    reg                  odd_even_flag;

    reg                  ddr_write_start;
    reg                  ddr_write_start_valid;
    wire                 ddr_write_start_ready;

    //generate packets
    reg [519:0]          pktin_data;
    reg                  pktin_en;
    reg [255:0]          pkt_in_md;
    reg                  pkt_in_md_en;
    wire                 pkt_data_alf;
  

    // Master Write Address
    wire [0:0]           M_AXI_AWID;
    wire [31:0]          M_AXI_AWADDR;
    wire [7:0]           M_AXI_AWLEN;    // Burst Length: 0-255
    wire [2:0]           M_AXI_AWSIZE;   // Burst Size: Fixed 2'b011
    wire [1:0]           M_AXI_AWBURST;  // Burst Type: Fixed 2'b01(Incremental Burst)
    wire                 M_AXI_AWLOCK;   // Lock: Fixed 2'b00
    wire [3:0]           M_AXI_AWCACHE;  // Cache: Fiex 2'b0011
    wire [2:0]           M_AXI_AWPROT;   // Protect: Fixed 2'b000
    wire [3:0]           M_AXI_AWQOS;    // QoS: Fixed 2'b0000
    wire [0:0]           M_AXI_AWUSER;   // User: Fixed 32'd0
    wire                 M_AXI_AWVALID;
    reg                  M_AXI_AWREADY;    

    // Master Write Data
    wire [31:0]          M_AXI_WDATA;
    wire [7:0]           M_AXI_WSTRB;
    wire                 M_AXI_WLAST;
    wire [0:0]           M_AXI_WUSER;
    wire                 M_AXI_WVALID;
    reg                  M_AXI_WREADY;

    // Master Write Response
    reg [0:0]            M_AXI_BID;
    reg [1:0]            M_AXI_BRESP;
    reg [0:0]            M_AXI_BUSER;
    reg                  M_AXI_BVALID;
    wire                 M_AXI_BREADY;


parameter CYCLE = 10;

always begin
    #(CYCLE/2) clk <= ~clk;
end

initial begin
    clk <= 1;
    aresetn <= 1;
    #(CYCLE)
    aresetn <= 0;
    #(2*CYCLE)
    aresetn <= 1;
end

initial begin
    #(2*CYCLE+CYCLE/2)  //wait for rst_n finish

    pktin_data <= 520'b0;
    pktin_en <= 1'b0;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;
    
    M_AXI_BVALID <= 1'b0;
    M_AXI_BUSER <= 1'b0;
    M_AXI_BRESP <= 2'b0;
    M_AXI_BID <= 1'b0;

    /**
    1st data packet (1024B payload)
    */
    #(3*CYCLE-CYCLE/2)
    pktin_data <= {2'b10, 6'b0, 512'b0};
    pktin_data[511 -: 48] <= 48'hadadadadadad;
    pktin_data[463 -: 48] <= 48'hacacacacacac;
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b1;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf1, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf2, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf3, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf4, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf5, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf6, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf7, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf8, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'hf9, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'h10, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'h11, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'h12, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'h13, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'h14, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    pktin_data <= {2'b00, 6'b0, 8'h15, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;


    #(CYCLE)
    pktin_data <= {2'b01, 6'b0, 8'h16, 504'b1};
    pktin_en <= 1'b1;
    pkt_in_md <= 256'b1;
    pkt_in_md_en <= 1'b1;

    #(CYCLE)
    pktin_data <= 520'b0;
    pktin_en <= 1'b0;
    pkt_in_md <= 256'b0;
    pkt_in_md_en <= 1'b0;

    #(CYCLE)
    odd_even_flag <= 1'b1;
    ddr_write_start <= 1'b1;
    ddr_write_start_valid <= 1'b1;

    #(CYCLE)
    M_AXI_AWREADY <= 1'b1;

    #(CYCLE)
    M_AXI_WREADY <= 1'b1;

    #(CYCLE)
    M_AXI_BVALID <= 1'b1;

end

camera_adaptor uut(
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
    .M_AXI_AWID(M_AXI_AWID),
    .M_AXI_AWADDR(M_AXI_AWADDR),
    .M_AXI_AWLEN(M_AXI_AWLEN),    // Burst Length: 0-255
    .M_AXI_AWSIZE(M_AXI_AWSIZE),   // Burst Size: Fixed 2'b011
    .M_AXI_AWBURST(M_AXI_AWBURST),  // Burst Type: Fixed 2'b01(Incremental Burst)
    .M_AXI_AWLOCK(M_AXI_AWLOCK),   // Lock: Fixed 2'b00
    .M_AXI_AWCACHE(M_AXI_AWCACHE),  // Cache: Fiex 2'b0011
    .M_AXI_AWPROT(M_AXI_AWPROT),   // Protect: Fixed 2'b000
    .M_AXI_AWQOS(M_AXI_AWQOS),    // QoS: Fixed 2'b0000
    .M_AXI_AWUSER(M_AXI_AWUSER),   // User: Fixed 32'd0
    .M_AXI_AWVALID(M_AXI_AWVALID),
    .M_AXI_AWREADY(M_AXI_AWREADY),    

    // Master Write Data
    .M_AXI_WDATA(M_AXI_WDATA),
    .M_AXI_WSTRB(M_AXI_WSTRB),
    .M_AXI_WLAST(M_AXI_WLAST),
    .M_AXI_WUSER(M_AXI_WUSER),
    .M_AXI_WVALID(M_AXI_WVALID),
    .M_AXI_WREADY(M_AXI_WREADY),

    // Master Write Response
    .M_AXI_BID(M_AXI_BID),
    .M_AXI_BRESP(M_AXI_BRESP),
    .M_AXI_BUSER(M_AXI_BUSER),
    .M_AXI_BVALID(M_AXI_BVALID),
    .M_AXI_BREADY(M_AXI_BREADY)
    
);


endmodule
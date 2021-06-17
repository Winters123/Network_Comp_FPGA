module camera_adaptor(
    // Reset, Clock
    input                  aresetn,
    input                  clk,

    //ctrls from controller
    output  reg            ddr_write_finish,
    output  reg            ddr_write_finish_valid,
    input                  ddr_write_finish_ready,

    input                  odd_even_flag,

    input                  ddr_write_start,
    input                  ddr_write_start_valid,
    output                 ddr_write_start_ready,

    //generate packets
    input [519:0]          pktin_data,
    input                  pktin_en,
    input [255:0]          pkt_in_md,
    input                  pkt_in_md_en,
    output                 pkt_data_alf,
  

    // Master Write Address
    output [0:0]           M_AXI_AWID,
    output [31:0]          M_AXI_AWADDR,
    output [7:0]           M_AXI_AWLEN,    // Burst Length: 0-255
    output [2:0]           M_AXI_AWSIZE,   // Burst Size: Fixed 2'b011
    output [1:0]           M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
    output                 M_AXI_AWLOCK,   // Lock: Fixed 2'b00
    output [3:0]           M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
    output [2:0]           M_AXI_AWPROT,   // Protect: Fixed 2'b000
    output [3:0]           M_AXI_AWQOS,    // QoS: Fixed 2'b0000
    output [0:0]           M_AXI_AWUSER,   // User: Fixed 32'd0
    output                 M_AXI_AWVALID,
    input                  M_AXI_AWREADY,    

    // Master Write Data
    output [31:0]          M_AXI_WDATA,
    output [7:0]           M_AXI_WSTRB,
    output                 M_AXI_WLAST,
    output [0:0]           M_AXI_WUSER,
    output                 M_AXI_WVALID,
    input                  M_AXI_WREADY,

    // Master Write Response
    input [0:0]            M_AXI_BID,
    input [1:0]            M_AXI_BRESP,
    input [0:0]            M_AXI_BUSER,
    input                  M_AXI_BVALID,
    output                 M_AXI_BREADY
    
);

reg                     fifo_wr_en;
reg                     fifo_rd_en;
wire [511:0]            fifo_data_out;
reg  [511:0]            fifo_data_in;
wire                    fifo_empty;
wire                    fifo_full;

//AXI-related
reg [31:0]              ddr_wr_addr;
reg [7:0]               ddr_wr_len;
reg                     ddr_wr_awvalid;
reg [31:0]              ddr_data_out;

reg                     ddr_wr_wlast;
reg                     ddr_wr_wvalid;


localparam SRC_MAC = 48'hacacacacacac;
localparam DST_MAC = 48'hadadadadadad;
localparam DATA_TYPE = 16'h9000;

localparam WR_ADDR_IDX0 = {28'haf00000,2'b0}; //each addr is 4B.
localparam WR_ADDR_IDX1 = {28'haf80000,2'b0}; 
localparam FRAME_SIZE = 28'd153600;


//TODO 1: when write start, parse the payload from pkts and write to ddr;

//TODO 1.1: write to FIFO;




//push data to FIFO
reg [2:0] fifo_write_state;
localparam IDLE_S1 = 3'd0,
           WR_FIFO_S1 = 3'd2;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        fifo_data_in <= 512'b0;
        fifo_wr_en <= 1'b0;
        fifo_write_state <= IDLE_S1;
    end
    else begin
        case(fifo_write_state)
            // IDLE_S1: begin
            //     fifo_data_in <= 512'b0;
            //     fifo_wr_en <= 1'b0;
            //     if(ddr_write_start_valid && ddr_write_start_ready && ddr_write_start) begin
            //         //ready to write FIFO
            //         fifo_write_state <= READY_S1;
            //     end
            // end
            IDLE_S1: begin
                fifo_data_in <= 512'b0;
                fifo_wr_en <= 1'b0;
                //if the header matches:
                if(pktin_en) begin
                    if(pktin_data[511-:48] == DST_MAC && pktin_data[463-:48] == SRC_MAC) begin
                       fifo_write_state <= WR_FIFO_S1;
                    end
                    else fifo_write_state <= IDLE_S1;
                end
                //TODO could add a timer to fallback to IDLE
                else fifo_write_state <= IDLE_S1;
            end

            WR_FIFO_S1: begin
                if(pktin_en && ~fifo_full) begin
                    fifo_data_in <= pktin_data[511:0];
                    fifo_wr_en <= 1'b1;    
                    //use pktin_md_en to mark last segment.
                    if(pkt_in_md_en && pktin_data[519:518] == 2'b01) begin
                        fifo_write_state <= IDLE_S1;
                    end
                end
                //in case there is a bible.
                //TODO: how to deal with fifo full?
                else begin
                    fifo_wr_en <= 1'b0;
                end
                
            end
        endcase
    end
end

//TODO 1.2: read from FIFO to AXI;

assign M_AXI_AWID         = 1'b0;
assign M_AXI_AWADDR[31:0] = ddr_wr_addr[31:0];
assign M_AXI_AWLEN[7:0]   = ddr_wr_len[7:0];
assign M_AXI_AWSIZE[2:0]  = 3'b010;  //4B for each transfer
assign M_AXI_AWBURST[1:0] = 2'b01;
assign M_AXI_AWLOCK       = 1'b0;
assign M_AXI_AWCACHE[3:0] = 4'b0011;
assign M_AXI_AWPROT[2:0]  = 3'b000;
assign M_AXI_AWQOS[3:0]   = 4'b0000;
assign M_AXI_AWUSER[0]    = 1'b1;
assign M_AXI_AWVALID      = ddr_wr_awvalid;

assign M_AXI_WDATA        = ddr_data_out;
assign M_AXI_WSTRB[3:0]   = (M_AXI_WVALID & ~fifo_empty)?4'hf:4'h0;
assign M_AXI_WLAST        = ddr_wr_wlast;
assign M_AXI_WUSER        = 1'b1;
assign M_AXI_WVALID       = ddr_wr_wvalid;
assign M_AXI_BREADY       = M_AXI_BVALID;

//9600 bursts totally, this is the cursor for recording
reg  [13:0]   frame_4B_cursor;
wire [511:0]  fifo_to_axi_data_w;
reg  [3:0]    segment_cursor;

reg [2:0] fifo_read_state;

localparam IDLE_S2 = 3'd0,
           WA_WD_START_S2 = 3'd1,
           WD_PROC_S2 = 3'd2,
           WD_WAIT_S2 = 3'd3,
           WR_WAIT_S2 = 3'd4,
           WR_DONE_S2 = 3'd5;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        ddr_wr_addr <= 32'b0;
        ddr_wr_len[7:0] <= 8'd0;
        //ddr_awvalid <= 1'b0;
        ddr_wr_awvalid <= 1'b0;
        ddr_wr_wlast <= 1'b0;
        
        fifo_rd_en <= 1'b0;

        frame_4B_cursor <= 14'b0;
        segment_cursor <= 4'b0;
        fifo_read_state <= IDLE_S2;

    end

    else begin
        case(fifo_read_state)
            IDLE_S2: begin
                fifo_rd_en <= 1'b0;
                if(~fifo_empty && ddr_write_start && ddr_write_start_valid) begin
                    fifo_read_state <=WA_WD_START_S2;
                    ddr_wr_awvalid <= 1'b1;
                    ddr_wr_len <= 8'd16 - 1'b1;
                    //a new frame
                    if(odd_even_flag && frame_4B_cursor == 14'b0) ddr_wr_addr <= WR_ADDR_IDX1;
                    else if(~odd_even_flag && frame_4B_cursor == 14'b0) ddr_wr_addr <= WR_ADDR_IDX0;
                    //continue to write
                    else begin
                        ddr_wr_addr <= ddr_wr_addr + 32'd16;
                    end
                end
                else begin
                    ddr_wr_awvalid <= 1'b0;
                    ddr_wr_wlast <= 1'b0;

                    fifo_read_state <= IDLE_S2;
                    //start over again
                    if(frame_4B_cursor == 14'b0) ddr_wr_addr <= 32'b0;
                    else ddr_wr_addr <= ddr_wr_addr;
                end

            end
            WA_WD_START_S2: begin
                if(M_AXI_AWREADY) begin
                    ddr_wr_awvalid <= 1'b0;
                    ddr_wr_wvalid <= 1'b1;
                    ddr_data_out[31:0] <= fifo_to_axi_data_w[31:0];
                    segment_cursor <= segment_cursor + 4'b1;
                    fifo_read_state <= WD_PROC_S2;
                end
                else fifo_read_state <= WA_WD_START_S2;
            end

            WD_PROC_S2: begin
                if(M_AXI_WREADY && ~fifo_empty) begin
                    ddr_wr_wvalid <= 1'b1;
                    ddr_data_out[31:0] <= fifo_to_axi_data_w[32*segment_cursor +: 32];
                    if(segment_cursor == 4'd15) begin
                        segment_cursor <= 4'b0;
                        ddr_wr_wlast <= 1'b1;
                        fifo_read_state <= WD_WAIT_S2;
                        fifo_rd_en <= 1'b1;
                    end
                    else begin
                        segment_cursor <= segment_cursor + 4'b1;
                        fifo_rd_en <= 1'b0;
                        fifo_read_state <= WD_PROC_S2;
                    end
                end

                else begin
                    fifo_read_state <= WD_PROC_S2;
                end
            end
            WD_WAIT_S2: begin
                if(M_AXI_WREADY) begin
                    fifo_rd_en <= 1'b0;
                    ddr_wr_wvalid <= 1'b0;
                    ddr_wr_wlast <= 1'b0;
                    fifo_read_state <= WR_WAIT_S2;
                end            
            end
            WR_WAIT_S2: begin
                if(M_AXI_BVALID && (M_AXI_BRESP == 2'b00)) begin
                    fifo_read_state <= WR_DONE_S2;
                end
                else fifo_read_state <= WR_WAIT_S2;
            end

            WR_DONE_S2: begin
                //cursor move forward once or reset to zero.
                if(frame_4B_cursor != 14'd9599) begin
                    frame_4B_cursor <= frame_4B_cursor + 14'b1;
                    fifo_read_state <= IDLE_S2;
                end 
                else if(ddr_write_finish_ready) begin
                    frame_4B_cursor <= 14'b0;
                    ddr_write_finish <= 1'b1;
                    ddr_write_finish_valid <= 1'b1;
                    fifo_read_state <= IDLE_S2;
                end
                else begin
                    fifo_read_state <= WR_DONE_S2;
                end
            end
            
        endcase
    end
end


//TODO 2: trigger the controller when completing frame write;


//IP core initialized here
//fall-through fifo
fifo_512w_32d ddr_write_fifo (
  .clk(clk),                  // input wire clk
  .srst(~aresetn),                // input wire srst
  .din(fifo_data_in),              // input wire [511 : 0] din
  .wr_en(fifo_wr_en),              // input wire wr_en
  .rd_en(fifo_rd_en),              // input wire rd_en
  .dout(fifo_to_axi_data_w),            // output wire [511 : 0] dout
  .full(fifo_full),                // output wire full
  .empty(fifo_empty)              // output wire empty
);


endmodule
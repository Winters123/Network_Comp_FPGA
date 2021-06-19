module monitor_adaptor(
  // Reset, Clock
    input           aresetn,
    input           clk,

    //ctrls from controller
    input               ddr_read_start,
    input               ddr_read_start_valid,
    output  reg         ddr_read_start_ready,

    input               odd_even_flag,
    
    output reg          ddr_read_finish,
    output reg          ddr_read_finish_valid,
    input               ddr_read_finish_ready,

    //generate packets
    output  reg [519:0]     pkt_out_data,
    output  reg             pkt_out_en,
    output  reg [255:0]     pkt_out_md,
    output  reg             pkt_out_md_en,
    input                   pkt_out_data_alf,
  

    // Master Write Address (unused)
    output [0:0]        M_AXI_AWID,
    output [31:0]       M_AXI_AWADDR,
    output [7:0]        M_AXI_AWLEN,    // Burst Length: 0-255
    output [2:0]        M_AXI_AWSIZE,   // Burst Size: Fixed 2'b011
    output [1:0]        M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
    output              M_AXI_AWLOCK,   // Lock: Fixed 2'b00
    output [3:0]        M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
    output [2:0]        M_AXI_AWPROT,   // Protect: Fixed 2'b000
    output [3:0]        M_AXI_AWQOS,    // QoS: Fixed 2'b0000
    output [0:0]        M_AXI_AWUSER,   // User: Fixed 32'd0
    output              M_AXI_AWVALID,
    input               M_AXI_AWREADY,    

    // Master Write Data (unused)
    output [31:0]       M_AXI_WDATA,
    output [7:0]        M_AXI_WSTRB,
    output              M_AXI_WLAST,
    output [0:0]        M_AXI_WUSER,
    output              M_AXI_WVALID,
    input               M_AXI_WREADY,

    // Master Write Response (unused)
    input [0:0]         M_AXI_BID,
    input [1:0]         M_AXI_BRESP,
    input [0:0]         M_AXI_BUSER,
    input               M_AXI_BVALID,
    output              M_AXI_BREADY,
    
    // Master Read Address
    output [0:0]        M_AXI_ARID,
    output [31:0]       M_AXI_ARADDR,
    output [7:0]        M_AXI_ARLEN,
    output [2:0]        M_AXI_ARSIZE,
    output [1:0]        M_AXI_ARBURST,
    output [1:0]        M_AXI_ARLOCK,
    output [3:0]        M_AXI_ARCACHE,
    output [2:0]        M_AXI_ARPROT,
    output [3:0]        M_AXI_ARQOS,
    output [0:0]        M_AXI_ARUSER,
    output              M_AXI_ARVALID,
    input               M_AXI_ARREADY,
    
    // Master Read Data 
    input [0:0]         M_AXI_RID,
    input [31:0]        M_AXI_RDATA,
    input [1:0]         M_AXI_RRESP,
    input               M_AXI_RLAST,
    input [0:0]         M_AXI_RUSER,
    input               M_AXI_RVALID,
    output              M_AXI_RREADY
);

//TODO 1: receive signal from ctrl, read a frame out;

reg                     fifo_wr_en_1;
reg                     fifo_rd_en_1;
wire [255:0]            fifo_data_out_1;
reg  [31:0]             fifo_data_in_1;

reg                     fifo_wr_en_2;
reg                     fifo_rd_en_2;
wire [511:0]            fifo_data_out_2;
reg  [255:0]            fifo_data_in_2;


reg  [31:0]             ddr_read_addr;
reg  [31:0]             ddr_read_data;
reg  [7:0]              ddr_read_len;
reg                     ddr_read_arvalid, ddr_read_last;


wire                    fifo_full_1;
wire                    fifo_empty_1;

wire                    fifo_full_2;
wire                    fifo_empty_2;

//generate packets
reg [519:0]     pkt_out_data_r;
reg             pkt_out_en_r;
reg [255:0]     pkt_out_md_r;
reg             pkt_out_md_en_r;



always @(posedge clk) begin
    fifo_data_in_2 <= fifo_data_out_1;
    fifo_wr_en_2 <= fifo_rd_en_1;
end

always @(posedge clk) begin
    if(~fifo_empty_1 && ~fifo_rd_en_1) begin
        fifo_rd_en_1 <= 1'b1;
    end
    else begin
        fifo_rd_en_1 <= 1'b0;
    end
end

reg  [519:0]            pkt_segment;
reg  [5:0]              pkt_segment_cnt;  //for state machine ctrl
reg  [9:0]              pkt_cnt;  //for frame index

reg [4:0]               fifo_read_state;
reg [4:0]               fifo_write_state;

localparam DST_MAC = 48'habababababab;
localparam SRC_MAC = 48'hacacacacacac;
localparam DATA_TYPE = 16'h9000;

localparam IDLE_S1 = 4'd0,
           COLLECT_S1 = 4'd1;

reg ddr_read_start_flag;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        ddr_read_start_flag <= 1'b0;
    end
    else begin
        if(ddr_read_start_valid) begin
            ddr_read_start_flag <= 1'b1;
        end

        else if(ddr_read_finish) begin
            ddr_read_start_flag <= 1'b0;
        end
    end
end

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin


        fifo_rd_en_2 <= 1'b0;
        pkt_segment <= 520'b0;
        pkt_segment_cnt <= 6'b0;
        pkt_cnt <= 10'b0;

        fifo_read_state <= IDLE_S1;

    end 
    else begin
        case(fifo_read_state)
            IDLE_S1: begin
                fifo_rd_en_2 <= 1'b0;
                pkt_out_md_en_r <= 1'b0;
                pkt_out_md_r <= 256'b0;
                //start generating packets
                if(ddr_read_start_ready & ddr_read_start_flag & (~fifo_empty_2)) begin
                    //start generate pkt hdr
                    pkt_out_data_r[519 -:  2] <= 2'b10;
                    pkt_out_data_r[517 -:  6] <= 6'b0; 
                    pkt_out_data_r[511 -: 48] <= DST_MAC;
                    pkt_out_data_r[483 -: 48] <= SRC_MAC;
                    pkt_out_data_r[435 -: 32] <= 32'b0; //TODO: where TSN jumps in
                    pkt_out_data_r[403 -: 16] <= DATA_TYPE;
                    pkt_out_data_r[387  : 10] <= 378'b0;
                    pkt_out_data_r[9    :  0] <= pkt_cnt; //note: for hdmi index

                    pkt_out_en_r <= 1'b1;

                    pkt_segment_cnt <= pkt_segment_cnt + 1'b1;                  
                    fifo_read_state <= COLLECT_S1;
                end
                else begin
                    pkt_segment <= 0;
                    pkt_segment_cnt <= 0;

                    pkt_segment <= 520'b0;
                    pkt_segment_cnt <= 6'b0;

                    pkt_out_data_r <= 0;
                    pkt_out_en_r <= 0;

                    //deal with pkt_cnt (index)
                    if(pkt_cnt == 10'd600) pkt_cnt <= 10'd0;

                    fifo_read_state <= IDLE_S1;

                end
            end
            COLLECT_S1: begin
                //send pkt out
                if(~pkt_out_data_alf && pkt_segment_cnt < 6'd16) begin
                    pkt_out_md_en_r <= 0;
                    pkt_out_md_r <= 0;

                    //update pkt_segment
                    if (~fifo_empty_2 && ~fifo_rd_en_2) begin
                        //read FIFO data out
                        fifo_rd_en_2 <= 1'b1;

                        pkt_out_data_r <= {2'b00, 6'b0, fifo_data_out_2};
                        pkt_out_en_r <= 1'b1;
                        pkt_segment_cnt <= pkt_segment_cnt + 1'b1;
                    end
                    else begin
                        pkt_out_en_r <= 1'b0;
                        fifo_rd_en_2 <= 1'b0;
                    end
                end

                //last segment
                else if(~pkt_out_data_alf && pkt_segment_cnt == 6'd16) begin
                    //update pkt_segment
                    if (~fifo_empty_2 && ~fifo_rd_en_2) begin
                        //read FIFO data out
                        fifo_rd_en_2 <= 1'b1;

                        pkt_out_data_r <= {2'b00, 6'b0, fifo_data_out_2};
                        pkt_out_en_r <= 1'b1;
                        pkt_out_md_en_r <= 1'b1;
                        pkt_out_md_r <= 256'h3f;  //default for debug
                        //update pkt_cnt for index
                        pkt_cnt <= pkt_cnt + 1'b1;
                        pkt_segment_cnt <= 0;
                        //stop read from fifo
                        fifo_read_state <= IDLE_S1;
                    end
                    else begin
                        pkt_out_en_r <= 1'b0;
                        fifo_rd_en_2 <= 1'b0;
                    end

                end

                else begin //pkt_alf == 1
                    //hold, wait for data ready to send
                    pkt_out_en_r <= 1'b0;
                    pkt_out_data_r <= pkt_out_data_r;
                    fifo_rd_en_2 <= 1'b0;
                    pkt_out_data_r <= 0;
                end


            end
        endcase 
    end   
end

//TODO 3: read DDR data out to the FIFO
//checkme: need rewriting....

// Master Read Address
assign M_AXI_ARID         = 1'b0;
assign M_AXI_ARADDR[31:0] = ddr_read_addr[31:0];
//num of transfers each burst
assign M_AXI_ARLEN[7:0]   = ddr_read_len[7:0];
//4B each transfer
assign M_AXI_ARSIZE[2:0]  = 3'b010;
assign M_AXI_ARBURST[1:0] = 2'b01;

assign M_AXI_ARLOCK       = 1'b0;
assign M_AXI_ARCACHE[3:0] = 4'b0011;
assign M_AXI_ARPROT[2:0]  = 3'b000;
assign M_AXI_ARQOS[3:0]   = 4'b0000;
assign M_AXI_ARUSER[0]    = 1'b1;
assign M_AXI_ARVALID      = ddr_read_arvalid;

assign M_AXI_RREADY       = M_AXI_RVALID & ~fifo_full_2;



localparam IDLE_S2 = 5'd0,
           WAIT_S2 = 5'd1,
           PROC_S2 = 5'd2,
           BURST_SUCC_S2 = 5'd3;

localparam READ_ADDR_IDX0 = {28'haf00000,2'b0};
localparam READ_ADDR_IDX1 = {28'haf80000,2'b0};
localparam FRAME_SIZE = 28'd153600;  //needs 153600 4B ddr reads;
localparam TRANSAC_NUM = 14'd9600;

reg  [3:0]               axi_rnd_cnt;
reg  [13:0]              axi_burst_cnt;

//every AXI read, generate 512b data, repeat for 9600 times
//each burst is a 512b (16 x 32b) fifo_data_in, need a counter
always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        fifo_wr_en_1 <= 1'b0;
        fifo_data_in_1 <= 32'b0;

        ddr_read_addr <= 32'b0;
        ddr_read_data <= 32'b0;
        ddr_read_len <= 8'd16 - 8'd1; //transfer 512b per transaction
        ddr_read_arvalid <= 1'b0;
        ddr_read_last <= 1'b0;
        
        axi_rnd_cnt <= 0;
        axi_burst_cnt <= 0;
        fifo_write_state <= IDLE_S2;

        ddr_read_start_ready <= 1'b1;
        ddr_read_finish_valid <= 1'b1;
        ddr_read_finish <= 1'b1;
    end
    else begin
        case(fifo_write_state)
            IDLE_S2: begin
                //TODO add almost full for fifo
                if(ddr_read_start_flag && ddr_read_start_ready && !fifo_full_1) begin
                    //start read
                    axi_burst_cnt <= axi_burst_cnt + 14'b1;
                    ddr_read_arvalid <= 1'b1;

                    if(odd_even_flag) ddr_read_addr <= READ_ADDR_IDX1; 
                    else ddr_read_addr <= READ_ADDR_IDX0;

                    fifo_wr_en_1 <= 1'b0;
                    fifo_write_state <= WAIT_S2;

                    ddr_read_finish <= 1'b0;
                    ddr_read_finish_valid <= 1'b0;
                end
                else begin
                    ddr_read_arvalid <= 1'b0;
                    ddr_read_addr <= 32'b0;
                    axi_rnd_cnt <= 4'b0;
                    axi_burst_cnt <= 14'b0;
                    fifo_write_state <= IDLE_S2;
                end
            end

            WAIT_S2: begin
                //wait for data back
                if(M_AXI_ARREADY) begin
                    fifo_write_state <= PROC_S2;
                    ddr_read_arvalid <= 1'b0;
                end
            end
            //obtain the values
            PROC_S2: begin
                if(M_AXI_RVALID) begin
                    if(M_AXI_RLAST) begin
                        //write the fifo_data_in into fifo
                        fifo_wr_en_1 <= 1'b1;
                        fifo_data_in_1 <= M_AXI_RDATA;
                        //if this is the final burst of the frame
                        //todo: change it to 14'd9599
                        if(axi_burst_cnt == 14'd3) begin
                            //todo: set read_finish high here:
                            ddr_read_finish <= 1'b1;
                            ddr_read_finish_valid <= 1'b1;

                            axi_rnd_cnt <= 4'b0;
                            axi_burst_cnt <= 14'b0;
                            fifo_write_state <= IDLE_S2;
                        end
                        else begin
                            //next burst
                            fifo_wr_en_1 <= 1'b1;
                            axi_burst_cnt <= axi_burst_cnt + 14'b1;
                            axi_rnd_cnt <= 4'b0;
                            fifo_write_state <= BURST_SUCC_S2;
                        end
                    end
                    else begin
                        //within a burst, put rdata into fifo_data_in
                        fifo_wr_en_1 <= 1'b1;
                        fifo_data_in_1 <= M_AXI_RDATA;
                        axi_rnd_cnt <= axi_rnd_cnt + 4'b1;
                        fifo_write_state <= PROC_S2;
                    end
                end
                    //TODO: wait for ddr data to come
                else begin
                    fifo_wr_en_1 <= 1'b0;
                    fifo_data_in_1 <= fifo_data_in_1;
                end
            end
            //within 9600 bursts
            BURST_SUCC_S2: begin
                //reset fifo signals
                fifo_wr_en_1 <= 1'b0;
                fifo_data_in_1 <= 32'b0;

                //proceed to next burst
                axi_burst_cnt <= axi_burst_cnt + 14'b1;
                ddr_read_arvalid <= 1'b1;
                ddr_read_addr <= ddr_read_addr + 32'b100; //read 512b once
                fifo_write_state <= WAIT_S2;
            end
        endcase
    end
end


//IP core initialized here
fifo_32i_256o_32d ddr_read_fifo_1 (
  .clk(clk),                  // input wire clk
  .srst(~aresetn),                // input wire srst
  .din(fifo_data_in_1),              // input wire [31 : 0] din
  .wr_en(fifo_wr_en_1),              // input wire wr_en
  .rd_en(fifo_rd_en_1),              // input wire rd_en
  .dout(fifo_data_out_1),            // output wire [255 : 0] dout
  .full(fifo_full_1),                // output wire full
  .empty(fifo_empty_1)              // output wire empty
);

fifo_256i_512o_32d ddr_read_fifo_2 (
  .clk(clk),                  // input wire clk
  .srst(~aresetn),                // input wire srst
  .din(fifo_data_in_2),              // input wire [31 : 0] din
  .wr_en(fifo_wr_en_2),              // input wire wr_en
  .rd_en(fifo_rd_en_2),              // input wire rd_en
  .dout(fifo_data_out_2),            // output wire [255 : 0] dout
  .full(fifo_full_2),                // output wire full
  .empty(fifo_empty_2)              // output wire empty
);


reg          pkt_fifo_rd_en;
wire [519:0] pkt_fifo_out_data;
wire [255:0] pkt_fifo_out_md;
wire         pkt_fifo_out_md_en;
wire [6:0]   pkt_fifo_cnt;
wire         pkt_fifo_empty;

reg [1:0]   trans_state;

localparam IDLE_TRS = 2'b0,
           SEND_TRS = 2'b1;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        pkt_fifo_rd_en <= 1'b0;
        pkt_out_en <= 1'b0;
        pkt_out_data <= 0;
        pkt_out_md <= 0;
        pkt_out_md_en <= 0;

        trans_state <= IDLE_TRS;

    end
    else begin
        case(trans_state)
            IDLE_TRS: begin
                if(pkt_fifo_cnt > 16 & ~pkt_out_data_alf) begin
                    pkt_fifo_rd_en <= 1'b1;
                    pkt_out_en <= 1'b0;
                    pkt_out_data <= pkt_fifo_out_data;
                    pkt_out_md <= pkt_fifo_out_md;
                    pkt_out_md_en <= pkt_fifo_out_md_en;
                    trans_state <= SEND_TRS;
                end
                else begin
                    pkt_fifo_rd_en <= 1'b0;
                    pkt_out_en <= 1'b0;
                    pkt_out_data <= pkt_fifo_out_data;
                    pkt_out_md <= pkt_fifo_out_md;
                    pkt_out_md_en <= pkt_fifo_out_md_en;
                end
            end
            SEND_TRS: begin
                if(pkt_fifo_out_md_en) begin
                    pkt_fifo_rd_en <= 1'b0;
                    pkt_out_en <= 1'b1;
                    pkt_out_data <= pkt_fifo_out_data;
                    pkt_out_md <= pkt_fifo_out_md;
                    pkt_out_md_en <= pkt_fifo_out_md_en;
                    trans_state <= IDLE_TRS; 
                end 
                else begin
                    pkt_fifo_rd_en <= 1'b1;
                    pkt_out_en <= 1'b1;
                    pkt_out_data <= pkt_fifo_out_data;
                    pkt_out_md <= pkt_fifo_out_md;
                    pkt_out_md_en <= pkt_fifo_out_md_en;
                    trans_state <= SEND_TRS;
                end
            end
        endcase
    end

end


//TODO: this might cause halt if its the last packet
fifo_777w_32d pkt_fifo (
  .clk(clk),                  // input wire clk
  .srst(~aresetn),                // input wire srst
  .din({pkt_out_data_r, pkt_out_md_r, pkt_out_md_en_r}),              // input wire [31 : 0] din
  .wr_en(pkt_out_en_r),              // input wire wr_en
  .rd_en(pkt_fifo_rd_en),              // input wire rd_en
  .dout({pkt_fifo_out_data, pkt_fifo_out_md, pkt_fifo_out_md_en}),            // output wire [255 : 0] dout
  .full(),                // output wire full
  .empty(pkt_fifo_empty),              // output wire empty
  .data_count(pkt_fifo_cnt)
);


endmodule
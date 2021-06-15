/*
    本模块负责把r\c\s的数据�?�过AXI_INTERCONNECT写到DDR�??
    要用到一个FIFO，下面是DDR中存储rcs的地�??，accel1存储地址为rcs1，accel2存储地址为rcs2
	int* 		rcs1 = (int*) 0x28040000UL;
	int*		rcs2 = (int*) 0x28400010UL;
*/
module Command_AXI_WRITE(
    input clk,
    input aresetn,

    //Command
    input                 start_write,//wr_en
    input [31:0]          r,//din
    input [31:0]          c1,//din
    input [31:0]          c2,//din
    input [31:0]          s, //din
    output  reg           done_write,

      // Master Write Address
    output [0:0]  M_AXI_AWID,
    output [31:0] M_AXI_AWADDR,
    output [7:0]  M_AXI_AWLEN,    // Burst Length: 0-255
    output [2:0]  M_AXI_AWSIZE,   // Burst Size: Fixed 2'b011
    output [1:0]  M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
    output        M_AXI_AWLOCK,   // Lock: Fixed 2'b00
    output [3:0]  M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
    output [2:0]  M_AXI_AWPROT,   // Protect: Fixed 2'b000
    output [3:0]  M_AXI_AWQOS,    // QoS: Fixed 2'b0000
    output [0:0]  M_AXI_AWUSER,   // User: Fixed 1'b0
    output        M_AXI_AWVALID,
    input         M_AXI_AWREADY,

    // Master Write Data
    output [31:0] M_AXI_WDATA,
    output [3:0]  M_AXI_WSTRB,
    output        M_AXI_WLAST,
    output [0:0]  M_AXI_WUSER,
    output        M_AXI_WVALID,
    input         M_AXI_WREADY,

    // Master Write Response
    input [0:0]   M_AXI_BID,
    input [1:0]   M_AXI_BRESP,
    input [0:0]   M_AXI_BUSER,
    input         M_AXI_BVALID,
    output        M_AXI_BREADY,
        
    // Master Read Address
    output [0:0]  M_AXI_ARID,
    output [31:0] M_AXI_ARADDR,
    output [7:0]  M_AXI_ARLEN,
    output [2:0]  M_AXI_ARSIZE,
    output [1:0]  M_AXI_ARBURST,
    output [1:0]  M_AXI_ARLOCK,
    output [3:0]  M_AXI_ARCACHE,
    output [2:0]  M_AXI_ARPROT,
    output [3:0]  M_AXI_ARQOS,
    output [0:0]  M_AXI_ARUSER,
    output        M_AXI_ARVALID,
    input         M_AXI_ARREADY,
        
    // Master Read Data 
    input [0:0]   M_AXI_RID,
    input [31:0]  M_AXI_RDATA,
    input [1:0]   M_AXI_RRESP,
    input         M_AXI_RLAST,
    input [0:0]   M_AXI_RUSER,
    input         M_AXI_RVALID,
    output  reg   M_AXI_RREADY
);

//fifo variable
wire [127:0] fifo_data_out;
reg          fifo_rd_en;
wire         fifo_full;
wire         fifo_empty;


//AXI-related
reg [31:0]              ddr_wr_addr;
reg [7:0]               ddr_wr_len;
reg                     ddr_wr_awvalid;
reg [31:0]              ddr_wr_data;

reg                     ddr_wr_wlast;
reg                     ddr_wr_wvalid;



parameter RCS_ADDR_1 = 32'h28040000;
parameter RCS_ADDR_2 = 32'h28400010;

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

assign M_AXI_WDATA        = ddr_wr_data;
assign M_AXI_WSTRB[7:0]   = (M_AXI_WVALID & ~fifo_empty)?8'hff:8'h00;
assign M_AXI_WLAST        = ddr_wr_wlast;
assign M_AXI_WUSER        = 1'b1;
assign M_AXI_WVALID       = ddr_wr_wvalid;
assign M_AXI_BREADY       = M_AXI_BVALID;

reg [5:0] axi_write_state;
reg [2:0] axi_burst_cursor;

localparam IDLE_S = 5'd0,
           WRITE_R1_S = 5'd1,
           WRITE_C1_S = 5'd2,
           WRITE_S1_S = 5'd3,
           WRITE_ADDR2_S = 5'd4,
           WRITE_R2_S = 5'd5,
           WRITE_C2_S = 5'd6,
           WRITE_S2_S = 5'd7,
           WRITE_DONE_S = 5'd8;

always @(posedge clk or negedge aresetn) begin
  if(~aresetn) begin
    ddr_wr_addr <= 0;
    ddr_wr_len <= 0;
    ddr_wr_awvalid <= 0;
    ddr_wr_data <= 0;

    ddr_wr_wlast <= 0;
    ddr_wr_wvalid <= 0;

    done_write <= 1'b0;
    M_AXI_RREADY <= 1'b1;

    axi_write_state <= IDLE_S;
  end
  else begin
    case(axi_write_state) 
        IDLE_S: begin
          fifo_rd_en <= 1'b0;
          done_write <= 1'b0;
          if(~fifo_empty) begin
            axi_write_state <= WRITE_R1_S;
            //write addr channel
            ddr_wr_awvalid <= 1'b1;
            ddr_wr_addr <= RCS_ADDR_1;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b0;
            ddr_wr_wlast <= 1'b0;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= 32'b0;  //write r1
            ddr_wr_wvalid <= 1'b0;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= IDLE_S;
          end
        end

        WRITE_R1_S: begin
          if(M_AXI_AWREADY) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_C1_S;
            
          end
          else begin
            axi_write_state <= WRITE_R1_S;
            //write addr channel
            ddr_wr_awvalid <= 1'b1;
            ddr_wr_addr <= RCS_ADDR_1;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b0;
            ddr_wr_wlast <= 1'b0;
          end
        end

        WRITE_C1_S: begin
          if(M_AXI_WREADY) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[95 -: 32];  //write c1
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_S1_S;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_C1_S;
          end
        end

        WRITE_S1_S: begin
          if(M_AXI_WREADY) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[0 +: 32];  //write c1
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b1;
            axi_write_state <= WRITE_ADDR2_S;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[95 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_S1_S;
          end
        end

        WRITE_ADDR2_S: begin
            if(M_AXI_WREADY && M_AXI_BRESP == 2'b00) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b1;
            ddr_wr_addr <= RCS_ADDR_2;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write c1
            ddr_wr_wvalid <= 1'b0;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_R2_S;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b1;
            axi_write_state <= WRITE_ADDR2_S;
          end
        end

        WRITE_R2_S: begin
          if(M_AXI_AWREADY) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r2
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_C2_S;
            
          end
          else begin
            axi_write_state <= WRITE_R2_S;
            //write addr channel
            ddr_wr_awvalid <= 1'b1;
            ddr_wr_addr <= RCS_ADDR_2;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r1
            ddr_wr_wvalid <= 1'b0;
            ddr_wr_wlast <= 1'b0;
          end
        end
        WRITE_C2_S: begin
          if(M_AXI_WREADY) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[63 -: 32];  //write c2
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_S2_S;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[127 -: 32];  //write r2
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_C2_S;
          end
        end

        WRITE_S2_S: begin
            if(M_AXI_WREADY) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[0 +: 32];  //write s2
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b1;
            axi_write_state <= WRITE_DONE_S;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[95 -: 32];  //write c2
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= WRITE_S2_S;
          end
        end

        WRITE_DONE_S: begin
          //reset axi interface
          if(M_AXI_WREADY && M_AXI_BRESP == 2'b00) begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= 32'b0;  //write s2
            ddr_wr_wvalid <= 1'b0;
            ddr_wr_wlast <= 1'b0;
            axi_write_state <= IDLE_S;
            //reset fifo
            fifo_rd_en <= 1'b1;
            done_write <= 1'b1;
          end
          else begin
            //write addr channel
            ddr_wr_awvalid <= 1'b0;
            ddr_wr_addr <= 32'b0;     

            //write data channel
            ddr_wr_len <= 8'b10;  //write 96b into axi_ddr;
            ddr_wr_data <= fifo_data_out[95 -: 32];  //write c2
            ddr_wr_wvalid <= 1'b1;
            ddr_wr_wlast <= 1'b1;
            axi_write_state <= WRITE_S2_S;
          end
        end
    endcase
  end
end


fifo_128w_32d rcs_write_fifo (
  .clk(clk),                // input wire clk
  .srst(aresetn),              // input wire srst
  .din({r, c1, c2, s}),                // input wire [95 : 0] din
  .wr_en(start_write),            // input wire wr_en
  .rd_en(fifo_rd_en),            // input wire rd_en
  .dout(fifo_data_out),              // output wire [95 : 0] dout
  .full(fifo_full),              // output wire full
  .empty(fifo_empty),            // output wire empty
  .data_count()  // output wire [3 : 0] data_count
);

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/02/25 14:26:12
// Design Name: 
// Module Name: test_pkt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gmii_test_pkt(
input 	wire			rdclk,
input 	wire			rd_reset,
input 	wire			wrclk,
input 	wire			wr_reset,

input 	wire 			s_axis_tx_tready,
output 	wire [7 : 0] 	s_axis_tx_tdata,
output 	wire 			s_axis_tx_tlast,
output 	wire [0 : 0] 	s_axis_tx_tuser,
output 	wire 			s_axis_tx_tvalid,

output  wire			s_axis_rx_alf,
input 	wire [7 : 0] 	m_axis_rx_tdata,
input 	wire 			m_axis_rx_tlast,
input 	wire 			m_axis_rx_tuser,
input 	wire 			m_axis_rx_tvalid 
);

parameter 	idle_s  	= 	3'b0,
			rev_s		=	3'b001,
			discard_s	=	3'b010,
			send_s		=	3'b011;
reg 		wr_en;
wire		rd_en;
reg [8:0] 	din;
wire [8:0] dout;
wire [12:0]	data_count;
reg			din_v;
wire		dout_v;
wire		empty;
reg 		wr_en_v;
wire		rd_en_v;

reg	[1:0] 	rec_stat,send_stat;

assign	s_axis_rx_alf =	data_count[12];

(*MARK_DEBUG="true"*)      reg       [15:0]   pkt_in_cnt;
(*MARK_DEBUG="true"*)      reg       [15:0]   pkt_out_cnt;
always@(posedge wrclk or negedge wr_reset) if(!wr_reset)  pkt_in_cnt  <= 16'b0; else if(m_axis_rx_tlast) pkt_in_cnt  <= pkt_in_cnt  + 16'b1; else pkt_in_cnt  <= pkt_in_cnt;
always@(posedge rdclk or negedge rd_reset) if(!rd_reset)  pkt_out_cnt <= 16'b0; else if(s_axis_tx_tlast) pkt_out_cnt <= pkt_out_cnt + 16'b1; else pkt_out_cnt <= pkt_out_cnt;

always@(posedge wrclk or negedge wr_reset)
if(!wr_reset)	begin
	din 	<= 9'b0;
	din_v	<=	1'b0;
	wr_en	<=	1'b0;
	wr_en_v	<=	1'b0;
	rec_stat	<=	idle_s;
	end
	else	begin
		case(rec_stat)
			idle_s:	begin
				wr_en	<=	1'b0;
				wr_en_v	<=	1'b0;
				if(data_count[12] == 1'b1)	begin
					if(m_axis_rx_tvalid == 1'b1)	begin
						rec_stat	<=	discard_s;
						end
					else	begin
						rec_stat	<=	idle_s;
					end
				end
				else	begin
					if(m_axis_rx_tvalid == 1'b1)	begin
						wr_en		<=	m_axis_rx_tvalid;
						din			<=	{m_axis_rx_tlast,m_axis_rx_tdata};
						rec_stat	<=	rev_s;
					end
					else	begin
						rec_stat	<=	idle_s;
					end
				end
			end
			rev_s:	begin
				wr_en		<=	m_axis_rx_tvalid;
				din			<=	{m_axis_rx_tlast,m_axis_rx_tdata};
				if((m_axis_rx_tlast == 1'b1)&&(m_axis_rx_tvalid == 1'b1))	begin
					rec_stat	<=	idle_s;
					din_v		<=	1'b1;
					wr_en_v		<=	1'b1;
				end
				else	begin
					rec_stat	<=	rev_s;
						
				end
			end
			discard_s:	begin
				wr_en		<=	1'b0;
				if((m_axis_rx_tlast == 1'b1)&&(m_axis_rx_tvalid == 1'b1))	begin
					rec_stat	<=	idle_s;
				end
				else	begin
					rec_stat	<=	discard_s;
				end
			end
			endcase
		end

		
		

//======================================= transmit function always block =======================================//
reg		mti_val_o,r_drop_data_rd,mti_valid_rd;
assign rd_en			= 	(mti_val_o & s_axis_tx_tready) | r_drop_data_rd;		//read the fifo in transmission or dropping
assign rd_en_v			= 	mti_valid_rd;											//read the fifo in transmission or dropping
assign s_axis_tx_tdata	=	mti_val_o ? dout[7:0]	: 8'b0;
assign s_axis_tx_tlast	=	mti_val_o ? dout[8] : 1'b0;
assign s_axis_tx_tuser	=	mti_val_o ? 1'b0 : 1'b0;
assign s_axis_tx_tvalid =	mti_val_o;

always @(posedge rdclk or negedge rd_reset)begin
	if(!rd_reset)begin
		//MAC Transmit Inteface(MTI)
		mti_val_o <= 1'b0;						//data valid signal，also mti_sof_o/mti_eof_o/mti_be_o/mti_discrc_o/mti_dispad_o
		mti_valid_rd <= 1'b0;						//data valid signal，also mti_sof_o/mti_eof_o/mti_be_o/mti_discrc_o/mti_dispad_o
		//control reg
		r_drop_data_rd <= 1'b0;
	
		send_stat <= idle_s;
	end
	else begin
		case(send_stat)
			idle_s:begin
				//control reg
				r_drop_data_rd <= 1'b0;
				if(!empty)begin										//fifo not empty,transmit frame
					mti_val_o <= 1'b1;								//valid
					mti_valid_rd <= 1'b1;							//valid
					send_stat <= send_s;
				end
				else begin											//fifo is empty,wait at idle
					mti_val_o <= 1'b0;
					mti_valid_rd <= 1'b0;
					send_stat <= idle_s;
				end
			end
			send_s:begin
				if(s_axis_tx_tready && dout[8])begin				//GMAC_CORE accepted the last data,go to wait the status of the pkt
					mti_val_o <= 1'b0;
					r_drop_data_rd <= 1'b0;
					mti_valid_rd <= 1'b0;
					send_stat <= idle_s;
				end
				else begin											//continue transmission
					if(dout_v == 1'b0)begin						//a error occurs at GMAC_CORE's transmission,drop the rest of frame
						mti_val_o <= 1'b0;
						r_drop_data_rd <= 1'b1;
						mti_valid_rd <= 1'b0;
						send_stat <= discard_s;
					end
					else begin
						mti_val_o <= 1'b1;							//valid
						r_drop_data_rd <= 1'b0;
						mti_valid_rd <= 1'b0;
						send_stat <= send_s;
					end
				end
			end
			discard_s:begin
				mti_val_o <= 1'b0;
				if(dout[8])begin							//drop the last data,ready to next frame
					r_drop_data_rd <= 1'b0;
					send_stat <= idle_s;
				end
				else begin											//continue dropping
					r_drop_data_rd <= 1'b1;
					send_stat <= discard_s;
				end
			end
			default:begin
				send_stat <= idle_s;
			end
		endcase
	end
end

	
 fifo_asyn_9_1024 data_fifo(
  .wr_clk(wrclk),                // input wire wrclk
  .rd_clk(rdclk),                // input wire wrclk
  .rst(~wr_reset),              // input wire srst
  .din(din),                // input wire [8 : 0] din
  .wr_en(wr_en),            // input wire wr_en
  .rd_en(rd_en),            // input wire rd_en
  .dout(dout),              // output wire [8 : 0] dout.
  .full(),              // output wire full
  .empty(),            // output wire empty
  .wr_data_count(data_count)  // output wire [10 : 0] data_count
);
fifo_asyn_1_256 valid_fifo (
  .wr_clk(wrclk),                // input wire wrclk
  .rd_clk(rdclk),                // input wire wrclk
  .rst(~wr_reset),              // input wire srst
  .din(din_v),                // input wire [0 : 0] din
  .wr_en(wr_en_v),            // input wire wr_en
  .rd_en(rd_en_v),            // input wire rd_en
  .dout(dout_v),              // output wire [63 : 0] dout
  .full(),    // output wire full
  .empty(empty)            // output wire empty
);
endmodule

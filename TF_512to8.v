// ****************************************************************************
// Copyright		: 	NUDT.
// ============================================================================
// FILE NAME		:	ACE_TSM.v
// CREATE DATE		:	2020-9-4
// AUTHOR			:	xiongzhiting
// AUTHOR'S EMAIL	:	
// AUTHOR'S TEL		:	
// ============================================================================
// RELEASE 	HISTORY		-------------------------------------------------------
// VERSION 			DATE				AUTHOR				DESCRIPTION
// WM0.0			2020-9-4			xiongzhiting		modify the packet metadata
// ============================================================================
// KEYWORDS 		: 	TSM
// ----------------------------------------------------------------------------
// PURPOSE 			: 	modify the packet metadata: send the TMS to next metadata.
// ----------------------------------------------------------------------------
// ============================================================================
// REUSE ISSUES
// Reset Strategy	:	Async clear,active low
// Clock Domains	:	clk
// Critical TiminG	:	N/A
// Instantiations	:	N/A
// Synthesizable	:	N/A
// Others			:	N/A
// ****************************************************************************
module TF_512to8(
	//clock and reset signal
	input 						clk								,//clock, this is synchronous clock
	input 						rst_n							,//Reset the all signal, active high
	//input port		
	input		[519:0]			TF_512to8_in			    	,//send packet
	input						TF_512to8_in_wr		    		,//send write
	input		[111:0]			TF_512to8_in_valid	    		,//send valid
	input						TF_512to8_in_valid_wr	    	,//send valid write
	output	wire				TF_512to8_out_alf		    	,//receive allmostfull	
	//output port			
	output	reg	[7:0]			s_axis_tx_tdata	    			,//send packet
	output	reg					s_axis_tx_tvalid	    		,//send write
	output	reg					s_axis_tx_tlast	    			,//send valid
	output	wire				s_axis_tx_tuser    				,//send valid write
	input						s_axis_tx_tready			 	//receive allmostfull		

);
	reg			[1	:0]			current_state;
	reg			[10 :0]			pkt_length;
	reg			[5	:0]			byte_cnt;
	wire		[519:0]			TF_512to8_in_q;
	wire		[111:0]			TF_512to8_in_valid_q;
	wire						TF_512to8_in_rd;
	reg							TF_512to8_in_valid_rd;
	wire						TF_512to8_in_valid_empty;
	wire						TF_512to8_in_valid_alempty;
	wire		[6:0]			data_count;
	
	reg			[15:0]			pkt_out_cnt;
	reg			[31:0]			pktbyte_out_cnt;
	
always @(posedge clk or negedge rst_n) if (!rst_n) pkt_out_cnt			<= 16'b0; else if (s_axis_tx_tlast == 1'b1	)	pkt_out_cnt 		<= pkt_out_cnt +1'b1; 			else pkt_out_cnt 		<= pkt_out_cnt;		//tmp is used to restore cnt	
always @(posedge clk or negedge rst_n) if (!rst_n) pktbyte_out_cnt		<= 32'b0; else if (s_axis_tx_tvalid == 1'b1	)	pktbyte_out_cnt 	<= pktbyte_out_cnt +1'b1; 		else pktbyte_out_cnt 	<= pktbyte_out_cnt;		//tmp is used to restore cnt	
	assign s_axis_tx_tuser	= 1'b0;	
	assign TF_512to8_in_rd	= (byte_cnt == 6'd63 || pkt_length == 11'b1)? 1'b1 : 1'b0;
	assign TF_512to8_out_alf = data_count[6];
	localparam 			idle_s 			= 2'b00,																			//waiting
						pkt_send_s	= 2'b01;																			//save packet
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin                                                                                                   	//ResetN is low-active
		s_axis_tx_tdata	    		<= 8'b0;																			//clean all signal
		s_axis_tx_tvalid	    	<= 1'b0;                                                                    		//clean all signal
		s_axis_tx_tlast	    		<= 1'b0;                                                                    	    //clean all signal
		current_state				<= idle_s;                                                                          //clean all signal																		//clean all signal
		TF_512to8_in_valid_rd	    <= 1'b0;																			//clean all signal
		byte_cnt					<= 6'b0;
		pkt_length					<= 11'b0;
	end
	else begin
		case(current_state)
			idle_s:begin
				if ((!TF_512to8_in_valid_empty)&&(s_axis_tx_tready))begin						
					TF_512to8_in_valid_rd		<= 1'b1;
					pkt_length					<= TF_512to8_in_valid_q[106:96];
					byte_cnt					<= 6'b0;
					s_axis_tx_tdata				<= 8'b0;
					s_axis_tx_tvalid	    	<= 1'b0;
					s_axis_tx_tlast	    		<= 1'b0; 
					current_state				<= pkt_send_s;
				end
				else begin
					s_axis_tx_tdata				<= 8'b0;	
					s_axis_tx_tvalid	    	<= 1'b0;    
                    s_axis_tx_tlast	    		<= 1'b0;    
					current_state				<= idle_s;  
				end
			end
			pkt_send_s:begin
				TF_512to8_in_valid_rd			<= 1'b0;
				if(s_axis_tx_tready)begin
					s_axis_tx_tvalid	    	<= 1'b1;					
					case(byte_cnt)
					6'd0:begin
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 0)*8 + 7:(63 - 0)*8];
					end
					6'd1:begin
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 1)*8 + 7:(63 - 1)*8];
					end
					6'd2:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 2)*8 + 7:(63 - 2)*8];
					end	
					6'd3:begin		
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 3)*8 + 7:(63 - 3)*8];
					end		
					6'd4:begin		
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 4)*8 + 7:(63 - 4)*8];
					end		
					6'd5:begin		
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 5)*8 + 7:(63 - 5)*8];
					end		
					6'd6:begin		
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 6)*8 + 7:(63 - 6)*8];
					end	
					6'd7:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 7)*8 + 7:(63 - 7)*8];
					end
					6'd8:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 8)*8 + 7:(63 - 8)*8];
					end	
					6'd9:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 9)*8 + 7:(63 - 9)*8];
					end
					6'd10:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 10)*8 + 7:(63 - 10)*8];
					end
					6'd11:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 11)*8 + 7:(63 - 11)*8];
					end	
					6'd12:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 12)*8 + 7:(63 - 12)*8];
					end
					6'd13:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 13)*8 + 7:(63 - 13)*8];
					end
					6'd14:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 14)*8 + 7:(63 - 14)*8];
					end	
					6'd15:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 15)*8 + 7:(63 - 15)*8];
					end
					6'd16:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 16)*8 + 7:(63 - 16)*8];
					end
					6'd17:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 17)*8 + 7:(63 - 17)*8];
					end	
					6'd18:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 18)*8 + 7:(63 - 18)*8];
					end
					6'd19:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 19)*8 + 7:(63 - 19)*8];
					end
					6'd20:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 20)*8 + 7:(63 - 20)*8];
					end	
					6'd21:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 21)*8 + 7:(63 - 21)*8];
					end
					6'd22:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 22)*8 + 7:(63 - 22)*8];
					end
					6'd23:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 23)*8 + 7:(63 - 23)*8];
					end	
					6'd24:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 24)*8 + 7:(63 - 24)*8];
					end
					6'd25:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 25)*8 + 7:(63 - 25)*8];
					end
					6'd26:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 26)*8 + 7:(63 - 26)*8];
					end	
					6'd27:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 27)*8 + 7:(63 - 27)*8];
					end
					6'd28:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 28)*8 + 7:(63 - 28)*8];
					end
					6'd29:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 29)*8 + 7:(63 - 29)*8];
					end	
					6'd30:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 30)*8 + 7:(63 - 30)*8];
					end
					6'd31:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 31)*8 + 7:(63 - 31)*8];
					end
					6'd32:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 32)*8 + 7:(63 - 32)*8];
					end	
					6'd33:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 33)*8 + 7:(63 - 33)*8];
					end
					6'd34:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 34)*8 + 7:(63 - 34)*8];
					end
					6'd35:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 35)*8 + 7:(63 - 35)*8];
					end	
					6'd36:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 36)*8 + 7:(63 - 36)*8];
					end
					6'd37:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 37)*8 + 7:(63 - 37)*8];
					end
					6'd38:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 38)*8 + 7:(63 - 38)*8];
					end	
					6'd39:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 39)*8 + 7:(63 - 39)*8];
					end
					6'd40:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 40)*8 + 7:(63 - 40)*8];
					end
					6'd41:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 41)*8 + 7:(63 - 41)*8];
					end	
					6'd42:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 42)*8 + 7:(63 - 42)*8];
					end
					6'd43:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 43)*8 + 7:(63 - 43)*8];
					end
					6'd44:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 44)*8 + 7:(63 - 44)*8];
					end	
					6'd45:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 45)*8 + 7:(63 - 45)*8];
					end
					6'd46:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 46)*8 + 7:(63 - 46)*8];
					end
					6'd47:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 47)*8 + 7:(63 - 47)*8];
					end	
					6'd48:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 48)*8 + 7:(63 - 48)*8];
					end
					6'd49:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 49)*8 + 7:(63 - 49)*8];
					end
					6'd50:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 50)*8 + 7:(63 - 50)*8];
					end	
					6'd51:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 51)*8 + 7:(63 - 51)*8];
					end
					6'd52:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 52)*8 + 7:(63 - 52)*8];
					end
					6'd53:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 53)*8 + 7:(63 - 53)*8];
					end	
					6'd54:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 54)*8 + 7:(63 - 54)*8];
					end
					6'd55:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 55)*8 + 7:(63 - 55)*8];
					end
					6'd56:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 56)*8 + 7:(63 - 56)*8];
					end
					6'd57:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 57)*8 + 7:(63 - 57)*8];
					end	
					6'd58:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 58)*8 + 7:(63 - 58)*8];
					end
					6'd59:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 59)*8 + 7:(63 - 59)*8];
					end
					6'd60:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 60)*8 + 7:(63 - 60)*8];
					end	
					6'd61:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 61)*8 + 7:(63 - 61)*8];
					end
					6'd62:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 62)*8 + 7:(63 - 62)*8];
					end
					6'd63:begin	
						s_axis_tx_tdata			<= TF_512to8_in_q[(63 - 63)*8 + 7:(63 - 63)*8];
					end
					endcase					
					if(pkt_length > 11'b1)begin
						s_axis_tx_tlast	    		<= 1'b0;
						byte_cnt					<= byte_cnt + 1'b1;
						pkt_length					<= pkt_length - 1'b1;	
						current_state				<= pkt_send_s;
					end
					else begin
						s_axis_tx_tlast	    		<= 1'b1;
						byte_cnt					<= 6'b0;
                        if(!TF_512to8_in_valid_alempty)begin
							current_state				<= pkt_send_s;
							TF_512to8_in_valid_rd		<= 1'b1;
							pkt_length					<= TF_512to8_in_valid_q[106:96];
						end
						else begin
							current_state				<= idle_s;
						end	
					end
				end
				else begin
					s_axis_tx_tdata				<= 8'b0;
					s_axis_tx_tvalid	    	<= 1'b0;
					s_axis_tx_tlast	    		<= 1'b0;
					current_state				<= pkt_send_s;
				end
			end
			default:begin			
				current_state			<= idle_s;	
				s_axis_tx_tdata			<= 8'b0;	
		        s_axis_tx_tvalid	    <= 1'b0;	
		        s_axis_tx_tlast	    	<= 1'b0;
				byte_cnt				<= 6'b0;
				pkt_length				<= 11'b0;
			end				
		endcase	
	end
end	
			

SCFIFO_520bit_64words SCFIFO_520bit_64words_inst(
			.srst								  (~rst_n							),	//Reset the all signal, active high
			.din								  (TF_512to8_in						),	//The Inport of data 
			.rd_en								  (TF_512to8_in_rd					),	//active-high
			.clk								  (clk								),	//ASYNC WriteClk, SYNC use wrclk
			.wr_en								  (TF_512to8_in_wr					),	//active-high
			.dout								  (TF_512to8_in_q					),	//The Outport of data	
			.data_count						  	  (data_count						)
);

SYNCFIFO_128x112 SCFIFO_112bit_128words_inst(
			.srst								  (~rst_n							),	//Reset the all signal, active high
			.din								  (TF_512to8_in_valid				),	//The Inport of data 
			.rd_en								  (TF_512to8_in_valid_rd			),	//active-high
			.clk								  (clk								),	//ASYNC WriteClk, SYNC use wrclk
			.wr_en								  (TF_512to8_in_valid_wr			),	//active-high
			.dout								  (TF_512to8_in_valid_q				),	//The Outport of data	
			.empty								  (TF_512to8_in_valid_empty			),
			.almost_empty						  (TF_512to8_in_valid_alempty		)
);
				
endmodule
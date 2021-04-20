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
module TF_8to512(
	//clock and reset signal
	input 						clk							,//clock, this is synchronous clock
	input 						rst_n						,//Reset the all signal, active high
	//input port
	input		[7:0]			m_axis_rx_tdata			,//send packet
	input						m_axis_rx_tvalid		,//send valid
	input						m_axis_rx_tlast			,//send valid write
	input						m_axis_rx_tuser			,//receive allmostfull	
	//output port
	output	reg	[519:0]			TF_8to512_out				,//send packet
	output	reg					TF_8to512_out_wr			,//send write
	output	reg	[111:0]			TF_8to512_out_valid			,//send valid
	output	reg					TF_8to512_out_valid_wr		,//send valid write
	input						TF_8to512_in_alf			 //receive allmostfull		
	
);

	reg			[511:0]			TF_8to512_out_reg;
	reg			[5	:0]			byte_cnt;
	reg			[4	:0]			byte64_cnt;	
	reg 		[1  :0]			current_state;
	localparam 			idle_s 			= 2'b00,																			//waiting
						save_s			= 2'b01,																			//save packet
						pkt_end_s       = 2'b11;

	reg			[31:0]			pktbyte_in_cnt;
	reg			[15:0]			pkt_in_cnt;
	
always @(posedge clk or negedge rst_n) if (!rst_n) pkt_in_cnt			<= 16'b0; else if (m_axis_rx_tlast == 1'b1	)	pkt_in_cnt 		<= pkt_in_cnt +1'b1; 			else pkt_in_cnt 		<= pkt_in_cnt;		//tmp is used to restore cnt	
always @(posedge clk or negedge rst_n) if (!rst_n) pktbyte_in_cnt		<= 32'b0; else if (m_axis_rx_tvalid == 1'b1	)	pktbyte_in_cnt 	<= pktbyte_in_cnt +1'b1; 		else pktbyte_in_cnt 	<= pktbyte_in_cnt;		//tmp is used to restore cnt	

						
	
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin                                                                                                   	//ResetN is low-active
		TF_8to512_out				<= 520'b0;																			//clean all signal
		TF_8to512_out_wr			<= 1'b0;                                                                            //clean all signal
		TF_8to512_out_valid			<= 112'b0;                                                                          //clean all signal
		TF_8to512_out_valid_wr		<= 1'b0;                                                                          	//clean all signal	
		TF_8to512_out_reg			<= 512'b0;																			//clean all signal
		byte_cnt					<= 6'b0;																			//clean all signal		
		byte64_cnt					<= 5'b0;																			//clean all signal
		current_state				<= idle_s;                                                                          //clean all signal
	end
	else begin
		case(current_state)
			idle_s:begin
				if ((!TF_8to512_in_alf)&&(m_axis_rx_tvalid))begin
					TF_8to512_out				<= 520'b0;
					TF_8to512_out_wr			<= 1'b0;  
					TF_8to512_out_valid			<= 112'b0;
					TF_8to512_out_valid_wr		<= 1'b0; 
					byte_cnt					<= byte_cnt + 1'b1;
					TF_8to512_out_reg[511:504]	<= m_axis_rx_tdata;
					current_state				<= save_s;
				end
				else begin
					TF_8to512_out			<= 520'b0;	
					TF_8to512_out_wr		<= 1'b0;  
                    TF_8to512_out_valid		<= 112'b0;
                    TF_8to512_out_valid_wr	<= 1'b0;  
					current_state			<= idle_s;
				end
			end
			save_s:begin		
				if((m_axis_rx_tvalid)&&(m_axis_rx_tlast))begin
					byte_cnt				<= 6'b0;
					byte64_cnt				<= 5'b0;
					current_state			<= idle_s;
					if(byte64_cnt != 5'b0)begin					
						if(byte_cnt == 6'd63)begin
							TF_8to512_out			<= {2'b01,6'b0,TF_8to512_out_reg[511:8],m_axis_rx_tdata};	
							TF_8to512_out_wr		<= 1'b1;
							TF_8to512_out_valid 	<= {1'b1,1'b0,3'b0,{byte64_cnt+1'b1},6'b0,64'b0,32'b1};
							TF_8to512_out_valid_wr	<= 1'b1;
							TF_8to512_out_reg		<= 512'b0;
						end
						else begin
							TF_8to512_out			<= 520'b0;
							TF_8to512_out_wr		<= 1'b0;  
							TF_8to512_out_valid 	<= 112'b0;
							TF_8to512_out_valid_wr	<= 1'b0;
							byte_cnt				<= byte_cnt;
							byte64_cnt				<= byte64_cnt;							
							current_state			<= pkt_end_s;
							case(byte_cnt)
							6'd0:begin
								TF_8to512_out_reg[(63-0)*8+7:(63-0)*8]	<= m_axis_rx_tdata;
							end
                            6'd1:begin
                            	TF_8to512_out_reg[(63-1)*8+7:(63-1)*8]	<= m_axis_rx_tdata;
                            end
                            6'd2:begin	
                            	TF_8to512_out_reg[(63-2)*8+7:(63-2)*8]	<= m_axis_rx_tdata;	
                            end	
                            6'd3:begin		
                            	TF_8to512_out_reg[(63-3)*8+7:(63-3)*8]	<= m_axis_rx_tdata;	
                            end		
                            6'd4:begin		
                            	TF_8to512_out_reg[(63-4)*8+7:(63-4)*8]	<= m_axis_rx_tdata;	
                            end		
                            6'd5:begin		
                            	TF_8to512_out_reg[(63-5)*8+7:(63-5)*8]	<= m_axis_rx_tdata;	
                            end		
                            6'd6:begin		
                            	TF_8to512_out_reg[(63-6)*8+7:(63-6)*8]	<= m_axis_rx_tdata;	
                            end	
                            6'd7:begin	
                            	TF_8to512_out_reg[(63-7)*8+7:(63-7)*8]	<= m_axis_rx_tdata;
                            end
                            6'd8:begin	
                            	TF_8to512_out_reg[(63-8)*8+7:(63-8)*8]	<= m_axis_rx_tdata;
                            end	
                            6'd9:begin	
                            	TF_8to512_out_reg[(63-9)*8+7:(63-9)*8]	<= m_axis_rx_tdata;
                            end
                            6'd10:begin	
                            	TF_8to512_out_reg[(63-10)*8+7:(63-10)*8]<= m_axis_rx_tdata;
                            end
                            6'd11:begin	
                            	TF_8to512_out_reg[(63-11)*8+7:(63-11)*8]<= m_axis_rx_tdata;
                            end	
                            6'd12:begin	
                            	TF_8to512_out_reg[(63-12)*8+7:(63-12)*8]<= m_axis_rx_tdata;
                            end
                            6'd13:begin	
                            	TF_8to512_out_reg[(63-13)*8+7:(63-13)*8]<= m_axis_rx_tdata;
                            end
                            6'd14:begin	
                            	TF_8to512_out_reg[(63-14)*8+7:(63-14)*8]<= m_axis_rx_tdata;
                            end	
                            6'd15:begin	
                            	TF_8to512_out_reg[(63-15)*8+7:(63-15)*8]<= m_axis_rx_tdata;
                            end
                            6'd16:begin	
                            	TF_8to512_out_reg[(63-16)*8+7:(63-16)*8]<= m_axis_rx_tdata;
                            end
                            6'd17:begin	
                            	TF_8to512_out_reg[(63-17)*8+7:(63-17)*8]<= m_axis_rx_tdata;
                            end	
                            6'd18:begin	
                            	TF_8to512_out_reg[(63-18)*8+7:(63-18)*8]<= m_axis_rx_tdata;
                            end
                            6'd19:begin	
                            	TF_8to512_out_reg[(63-19)*8+7:(63-19)*8]<= m_axis_rx_tdata;
                            end
                            6'd20:begin	
                            	TF_8to512_out_reg[(63-20)*8+7:(63-20)*8]<= m_axis_rx_tdata;
                            end	
                            6'd21:begin	
                            	TF_8to512_out_reg[(63-21)*8+7:(63-21)*8]<= m_axis_rx_tdata;
                            end
                            6'd22:begin	
                            	TF_8to512_out_reg[(63-22)*8+7:(63-22)*8]<= m_axis_rx_tdata;
                            end
                            6'd23:begin	
                            	TF_8to512_out_reg[(63-23)*8+7:(63-23)*8]<= m_axis_rx_tdata;
                            end	
                            6'd24:begin	
                            	TF_8to512_out_reg[(63-24)*8+7:(63-24)*8]<= m_axis_rx_tdata;
                            end
                            6'd25:begin	
                            	TF_8to512_out_reg[(63-25)*8+7:(63-25)*8]<= m_axis_rx_tdata;
                            end
                            6'd26:begin	
                            	TF_8to512_out_reg[(63-26)*8+7:(63-26)*8]<= m_axis_rx_tdata;
                            end	
                            6'd27:begin	
                            	TF_8to512_out_reg[(63-27)*8+7:(63-27)*8]<= m_axis_rx_tdata;
                            end
                            6'd28:begin	
                            	TF_8to512_out_reg[(63-28)*8+7:(63-28)*8]<= m_axis_rx_tdata;
                            end
                            6'd29:begin	
                            	TF_8to512_out_reg[(63-29)*8+7:(63-29)*8]<= m_axis_rx_tdata;
                            end	
                            6'd30:begin	
                            	TF_8to512_out_reg[(63-30)*8+7:(63-30)*8]<= m_axis_rx_tdata;
                            end
                            6'd31:begin	
                            	TF_8to512_out_reg[(63-31)*8+7:(63-31)*8]<= m_axis_rx_tdata;
                            end
                            6'd32:begin	
                            	TF_8to512_out_reg[(63-32)*8+7:(63-32)*8]<= m_axis_rx_tdata;
                            end	
                            6'd33:begin	
                            	TF_8to512_out_reg[(63-33)*8+7:(63-33)*8]<= m_axis_rx_tdata;
                            end
                            6'd34:begin	
                            	TF_8to512_out_reg[(63-34)*8+7:(63-34)*8]<= m_axis_rx_tdata;
                            end
                            6'd35:begin	
                            	TF_8to512_out_reg[(63-35)*8+7:(63-35)*8]<= m_axis_rx_tdata;
                            end	
                            6'd36:begin	
                            	TF_8to512_out_reg[(63-36)*8+7:(63-36)*8]<= m_axis_rx_tdata;
                            end
                            6'd37:begin	
                            	TF_8to512_out_reg[(63-37)*8+7:(63-37)*8]<= m_axis_rx_tdata;
                            end
                            6'd38:begin	
                            	TF_8to512_out_reg[(63-38)*8+7:(63-38)*8]<= m_axis_rx_tdata;
                            end	
                            6'd39:begin	
                            	TF_8to512_out_reg[(63-39)*8+7:(63-39)*8]<= m_axis_rx_tdata;
                            end
                            6'd40:begin	
                            	TF_8to512_out_reg[(63-40)*8+7:(63-40)*8]<= m_axis_rx_tdata;
                            end
                            6'd41:begin	
                            	TF_8to512_out_reg[(63-41)*8+7:(63-41)*8]<= m_axis_rx_tdata;
                            end	
                            6'd42:begin	
                            	TF_8to512_out_reg[(63-42)*8+7:(63-42)*8]<= m_axis_rx_tdata;
                            end
                            6'd43:begin	
                            	TF_8to512_out_reg[(63-43)*8+7:(63-43)*8]<= m_axis_rx_tdata;
                            end
                            6'd44:begin	
                            	TF_8to512_out_reg[(63-44)*8+7:(63-44)*8]<= m_axis_rx_tdata;
                            end	
                            6'd45:begin	
                            	TF_8to512_out_reg[(63-45)*8+7:(63-45)*8]<= m_axis_rx_tdata;
                            end
                            6'd46:begin	
                            	TF_8to512_out_reg[(63-46)*8+7:(63-46)*8]<= m_axis_rx_tdata;
                            end
                            6'd47:begin	
                            	TF_8to512_out_reg[(63-47)*8+7:(63-47)*8]<= m_axis_rx_tdata;
                            end	
                            6'd48:begin	
                            	TF_8to512_out_reg[(63-48)*8+7:(63-48)*8]<= m_axis_rx_tdata;
                            end
                            6'd49:begin	
                            	TF_8to512_out_reg[(63-49)*8+7:(63-49)*8]<= m_axis_rx_tdata;
                            end
                            6'd50:begin	
                            	TF_8to512_out_reg[(63-50)*8+7:(63-50)*8]<= m_axis_rx_tdata;
                            end	
                            6'd51:begin	
                            	TF_8to512_out_reg[(63-51)*8+7:(63-51)*8]<= m_axis_rx_tdata;
                            end
                            6'd52:begin	
                            	TF_8to512_out_reg[(63-52)*8+7:(63-52)*8]<= m_axis_rx_tdata;
                            end
                            6'd53:begin	
                            	TF_8to512_out_reg[(63-53)*8+7:(63-53)*8]<= m_axis_rx_tdata;
                            end	
                            6'd54:begin	
                            	TF_8to512_out_reg[(63-54)*8+7:(63-54)*8]<= m_axis_rx_tdata;
                            end
                            6'd55:begin	
                            	TF_8to512_out_reg[(63-55)*8+7:(63-55)*8]<= m_axis_rx_tdata;
                            end
                            6'd56:begin	
                            	TF_8to512_out_reg[(63-56)*8+7:(63-56)*8]<= m_axis_rx_tdata;
                            end
                            6'd57:begin	
                            	TF_8to512_out_reg[(63-57)*8+7:(63-57)*8]<= m_axis_rx_tdata;
                            end	
                            6'd58:begin	
                            	TF_8to512_out_reg[(63-58)*8+7:(63-58)*8]<= m_axis_rx_tdata;
                            end
                            6'd59:begin	
                            	TF_8to512_out_reg[(63-59)*8+7:(63-59)*8]<= m_axis_rx_tdata;
                            end
                            6'd60:begin	
                            	TF_8to512_out_reg[(63-60)*8+7:(63-60)*8]<= m_axis_rx_tdata;
                            end	
                            6'd61:begin	
                            	TF_8to512_out_reg[(63-61)*8+7:(63-61)*8]<= m_axis_rx_tdata;
                            end
                            6'd62:begin	
                            	TF_8to512_out_reg[(63-62)*8+7:(63-62)*8]<= m_axis_rx_tdata;
                            end
                            endcase	
						end
					end
					else begin
						TF_8to512_out			<= {2'b11,6'b0,TF_8to512_out_reg[511:8],m_axis_rx_tdata};	
						TF_8to512_out_wr		<= 1'b1;
						TF_8to512_out_valid 	<= {1'b1,1'b0,3'b0,{byte64_cnt+1'b1},6'b0,64'b0,32'b1};
						TF_8to512_out_valid_wr	<= 1'b1;
						TF_8to512_out_reg		<= 512'b0;
					end	
				end
				else if	((m_axis_rx_tvalid)&&(!m_axis_rx_tlast))begin				
					current_state				<= save_s;
					byte_cnt					<=	byte_cnt + 1'b1;
					if(byte_cnt	== 6'd63)begin
						if(byte64_cnt == 5'b0)begin
							TF_8to512_out		<= {2'b10,6'b0,TF_8to512_out_reg[511:8],m_axis_rx_tdata};
							TF_8to512_out_wr	<= 1'b1;
							byte64_cnt			<= byte64_cnt + 1'b1;
						end
						else begin
							TF_8to512_out		<= {2'b00,6'b0,TF_8to512_out_reg[511:8],m_axis_rx_tdata};
							TF_8to512_out_wr	<= 1'b1;
							byte64_cnt			<= byte64_cnt + 1'b1;
						end
					end
					else begin						
						TF_8to512_out			<= 520'b0;
                        TF_8to512_out_wr		<= 1'b0;  
                        TF_8to512_out_valid		<= 112'b0;
                        TF_8to512_out_valid_wr	<= 1'b0; 
						case(byte_cnt)
						6'd0:begin
							TF_8to512_out_reg[(63-0)*8+7:(63-0)*8]	<= m_axis_rx_tdata;
						end
						6'd1:begin
							TF_8to512_out_reg[(63-1)*8+7:(63-1)*8]	<= m_axis_rx_tdata;
						end
						6'd2:begin	
							TF_8to512_out_reg[(63-2)*8+7:(63-2)*8]	<= m_axis_rx_tdata;	
						end	
						6'd3:begin		
							TF_8to512_out_reg[(63-3)*8+7:(63-3)*8]	<= m_axis_rx_tdata;	
						end		
						6'd4:begin		
							TF_8to512_out_reg[(63-4)*8+7:(63-4)*8]	<= m_axis_rx_tdata;	
						end		
						6'd5:begin		
							TF_8to512_out_reg[(63-5)*8+7:(63-5)*8]	<= m_axis_rx_tdata;	
						end		
						6'd6:begin		
							TF_8to512_out_reg[(63-6)*8+7:(63-6)*8]	<= m_axis_rx_tdata;	
						end	
						6'd7:begin	
                        	TF_8to512_out_reg[(63-7)*8+7:(63-7)*8]	<= m_axis_rx_tdata;
                        end
						6'd8:begin	
                        	TF_8to512_out_reg[(63-8)*8+7:(63-8)*8]	<= m_axis_rx_tdata;
                        end	
						6'd9:begin	
                        	TF_8to512_out_reg[(63-9)*8+7:(63-9)*8]	<= m_axis_rx_tdata;
                        end
						6'd10:begin	
                        	TF_8to512_out_reg[(63-10)*8+7:(63-10)*8]<= m_axis_rx_tdata;
                        end
						6'd11:begin	
                        	TF_8to512_out_reg[(63-11)*8+7:(63-11)*8]<= m_axis_rx_tdata;
                        end	
						6'd12:begin	
							TF_8to512_out_reg[(63-12)*8+7:(63-12)*8]<= m_axis_rx_tdata;
						end
						6'd13:begin	
                        	TF_8to512_out_reg[(63-13)*8+7:(63-13)*8]<= m_axis_rx_tdata;
                        end
						6'd14:begin	
							TF_8to512_out_reg[(63-14)*8+7:(63-14)*8]<= m_axis_rx_tdata;
						end	
						6'd15:begin	
							TF_8to512_out_reg[(63-15)*8+7:(63-15)*8]<= m_axis_rx_tdata;
						end
						6'd16:begin	
							TF_8to512_out_reg[(63-16)*8+7:(63-16)*8]<= m_axis_rx_tdata;
						end
						6'd17:begin	
							TF_8to512_out_reg[(63-17)*8+7:(63-17)*8]<= m_axis_rx_tdata;
						end	
						6'd18:begin	
							TF_8to512_out_reg[(63-18)*8+7:(63-18)*8]<= m_axis_rx_tdata;
						end
						6'd19:begin	
							TF_8to512_out_reg[(63-19)*8+7:(63-19)*8]<= m_axis_rx_tdata;
						end
						6'd20:begin	
							TF_8to512_out_reg[(63-20)*8+7:(63-20)*8]<= m_axis_rx_tdata;
						end	
						6'd21:begin	
							TF_8to512_out_reg[(63-21)*8+7:(63-21)*8]<= m_axis_rx_tdata;
						end
						6'd22:begin	
							TF_8to512_out_reg[(63-22)*8+7:(63-22)*8]<= m_axis_rx_tdata;
						end
						6'd23:begin	
							TF_8to512_out_reg[(63-23)*8+7:(63-23)*8]<= m_axis_rx_tdata;
						end	
						6'd24:begin	
							TF_8to512_out_reg[(63-24)*8+7:(63-24)*8]<= m_axis_rx_tdata;
						end
						6'd25:begin	
							TF_8to512_out_reg[(63-25)*8+7:(63-25)*8]<= m_axis_rx_tdata;
						end
						6'd26:begin	
							TF_8to512_out_reg[(63-26)*8+7:(63-26)*8]<= m_axis_rx_tdata;
						end	
						6'd27:begin	
							TF_8to512_out_reg[(63-27)*8+7:(63-27)*8]<= m_axis_rx_tdata;
						end
						6'd28:begin	
							TF_8to512_out_reg[(63-28)*8+7:(63-28)*8]<= m_axis_rx_tdata;
						end
						6'd29:begin	
							TF_8to512_out_reg[(63-29)*8+7:(63-29)*8]<= m_axis_rx_tdata;
						end	
						6'd30:begin	
							TF_8to512_out_reg[(63-30)*8+7:(63-30)*8]<= m_axis_rx_tdata;
						end
						6'd31:begin	
							TF_8to512_out_reg[(63-31)*8+7:(63-31)*8]<= m_axis_rx_tdata;
						end
						6'd32:begin	
							TF_8to512_out_reg[(63-32)*8+7:(63-32)*8]<= m_axis_rx_tdata;
						end	
						6'd33:begin	
							TF_8to512_out_reg[(63-33)*8+7:(63-33)*8]<= m_axis_rx_tdata;
						end
						6'd34:begin	
							TF_8to512_out_reg[(63-34)*8+7:(63-34)*8]<= m_axis_rx_tdata;
						end
						6'd35:begin	
							TF_8to512_out_reg[(63-35)*8+7:(63-35)*8]<= m_axis_rx_tdata;
						end	
						6'd36:begin	
							TF_8to512_out_reg[(63-36)*8+7:(63-36)*8]<= m_axis_rx_tdata;
						end
						6'd37:begin	
							TF_8to512_out_reg[(63-37)*8+7:(63-37)*8]<= m_axis_rx_tdata;
						end
						6'd38:begin	
							TF_8to512_out_reg[(63-38)*8+7:(63-38)*8]<= m_axis_rx_tdata;
						end	
						6'd39:begin	
							TF_8to512_out_reg[(63-39)*8+7:(63-39)*8]<= m_axis_rx_tdata;
						end
						6'd40:begin	
							TF_8to512_out_reg[(63-40)*8+7:(63-40)*8]<= m_axis_rx_tdata;
						end
						6'd41:begin	
							TF_8to512_out_reg[(63-41)*8+7:(63-41)*8]<= m_axis_rx_tdata;
						end	
						6'd42:begin	
							TF_8to512_out_reg[(63-42)*8+7:(63-42)*8]<= m_axis_rx_tdata;
						end
						6'd43:begin	
							TF_8to512_out_reg[(63-43)*8+7:(63-43)*8]<= m_axis_rx_tdata;
						end
						6'd44:begin	
							TF_8to512_out_reg[(63-44)*8+7:(63-44)*8]<= m_axis_rx_tdata;
						end	
						6'd45:begin	
							TF_8to512_out_reg[(63-45)*8+7:(63-45)*8]<= m_axis_rx_tdata;
						end
						6'd46:begin	
							TF_8to512_out_reg[(63-46)*8+7:(63-46)*8]<= m_axis_rx_tdata;
						end
						6'd47:begin	
							TF_8to512_out_reg[(63-47)*8+7:(63-47)*8]<= m_axis_rx_tdata;
						end	
						6'd48:begin	
							TF_8to512_out_reg[(63-48)*8+7:(63-48)*8]<= m_axis_rx_tdata;
                        end
                        6'd49:begin	
                        	TF_8to512_out_reg[(63-49)*8+7:(63-49)*8]<= m_axis_rx_tdata;
                        end
                        6'd50:begin	
                        	TF_8to512_out_reg[(63-50)*8+7:(63-50)*8]<= m_axis_rx_tdata;
                        end	
                        6'd51:begin	
                        	TF_8to512_out_reg[(63-51)*8+7:(63-51)*8]<= m_axis_rx_tdata;
                        end
                        6'd52:begin	
                        	TF_8to512_out_reg[(63-52)*8+7:(63-52)*8]<= m_axis_rx_tdata;
                        end
                        6'd53:begin	
                        	TF_8to512_out_reg[(63-53)*8+7:(63-53)*8]<= m_axis_rx_tdata;
                        end	
                        6'd54:begin	
                        	TF_8to512_out_reg[(63-54)*8+7:(63-54)*8]<= m_axis_rx_tdata;
                        end
                        6'd55:begin	
							TF_8to512_out_reg[(63-55)*8+7:(63-55)*8]<= m_axis_rx_tdata;
						end
						6'd56:begin	
							TF_8to512_out_reg[(63-56)*8+7:(63-56)*8]<= m_axis_rx_tdata;
						end
						6'd57:begin	
							TF_8to512_out_reg[(63-57)*8+7:(63-57)*8]<= m_axis_rx_tdata;
						end	
						6'd58:begin	
							TF_8to512_out_reg[(63-58)*8+7:(63-58)*8]<= m_axis_rx_tdata;
						end
						6'd59:begin	
                        	TF_8to512_out_reg[(63-59)*8+7:(63-59)*8]<= m_axis_rx_tdata;
                        end
                        6'd60:begin	
							TF_8to512_out_reg[(63-60)*8+7:(63-60)*8]<= m_axis_rx_tdata;
						end	
						6'd61:begin	
							TF_8to512_out_reg[(63-61)*8+7:(63-61)*8]<= m_axis_rx_tdata;
						end
						6'd62:begin	
							TF_8to512_out_reg[(63-62)*8+7:(63-62)*8]<= m_axis_rx_tdata;
						end
						endcase
					end
				end
				else begin					
					current_state				<= save_s;
					TF_8to512_out			<= 520'b0;
					TF_8to512_out_wr		<= 1'b0;  
					TF_8to512_out_valid		<= 112'b0;
					TF_8to512_out_valid_wr	<= 1'b0; 					
				end
			end
			pkt_end_s:begin
				TF_8to512_out			<= {2'b01,~byte_cnt,TF_8to512_out_reg[511:0]};
			    TF_8to512_out_wr		<= 1'b1;
			    TF_8to512_out_valid 	<= {1'b1,1'b0,3'b0,byte64_cnt,{byte_cnt+1'b1},64'b0,32'b1};
			    TF_8to512_out_valid_wr	<= 1'b1;
				byte_cnt				<= 6'b0;
				byte64_cnt				<= 5'b0;
				TF_8to512_out_reg		<= 512'b0;
			    current_state			<= idle_s;
			end
			default:begin		
				current_state			<= idle_s;
				TF_8to512_out			<= 520'b0;
                TF_8to512_out_wr		<= 1'b0;  
                TF_8to512_out_valid 	<= 112'b0;
				TF_8to512_out_valid_wr	<= 1'b0; 
                byte_cnt				<= 6'b0;
				byte64_cnt				<= 5'b0;				
			end			
		endcase
	end
end						
endmodule
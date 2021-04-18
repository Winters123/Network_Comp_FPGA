// ****************************************************************************
// Copyright		: 	NUDT.
// ============================================================================
// FILE NAME		:	RESULT2CTRLPKT.v
// CREATE DATE		:	2020-6-30 
// AUTHOR			:	xiongzhiting
// AUTHOR'S EMAIL	:	
// AUTHOR'S TEL		:	
// ============================================================================
// RELEASE 	HISTORY		-------------------------------------------------------
// VERSION 			DATE				AUTHOR				DESCRIPTION
// WM0.0			2020-6-30			xiongzhiting		RESULT2CTRLPKT
// ============================================================================
// KEYWORDS 		: 	the nacp packet, result
// ----------------------------------------------------------------------------
// PURPOSE 			: 	change the result to nacp packet
// ----------------------------------------------------------------------------
// ============================================================================
// REUSE ISSUES
// Reset Strategy	:	Async clear,active low
// Clock Domains	:	clk
// Critical TiminG	:	N/A
// Instantiations	:	N/A
// Synthesizable	:	N/A
// Others			:	type==0x9001 is Ctrl-PKT.
//					 the definition of command: [63:61]: 101 head \ 111 body \ 110 tail \ 100 head&tail,
//					 [60]: 1 read/write succeed  \ 0  read/write failed,
//					 [59]: 1 the command is to write  \ 0 the command is to read
//					 [58:52]: the destination module ID of command 
//					 [51:32]: the address of command
//					 [31:0]: the wdata/rdata of command
// ****************************************************************************

module RESULT2CTRLPKT(
//===================================== ecc's & mbist for mem ====================================//

//=========================================== clk & rst ===========================================//
	input 						Clk								,//clock, this is synchronous clock
	input 						Reset_N							,//Reset the all signal, active high
//=========================================== frame to IFE ===========================================//
	output	reg		[519:0]		IFE_ctrlpkt_out					,//receive pkt
	output	reg					IFE_ctrlpkt_out_wr				,//receive pkt write singal
	output	reg		[255:0]		IFE_ctrlpkt_out_valid			,//receive metadata
	output	reg					IFE_ctrlpkt_out_valid_wr		,//receive metadata write signal 
	input						IFE_ctrlpkt_in_alf				,//output allmostfull
//======================================= command to the config path ==================================//
	input 		 				Result_wr						,//command write signal
	input 		 	[63:0] 		Result							,//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	output 						Result_alf						,//commadn almostful
//================================ sequence of command to Result2ctrlpkt ================================//
	input 						Sequence_wr						,//pkt sequence write
	input 		 	[255:0]		Sequence						,//pkt sequence
	output 						Sequence_alf					,//pkt allmostfull
//=================================== the MAC & IP in NACP ====================================//
	input		 	[47:0] 		FPGA_MAC						,//hard MAC address
//=================================== counter & debug ====================================//
	output	reg	 	[31:0] 		pkt_out_cnt						,//pkt output cnt
	output	reg		[31:0]		result_in_cnt					,//result in cnt
	output	wire	[31:0]		debug_current					 //debug signal
);
//======================================= internal reg&wire declarations =======================================//
	reg							Result_rd						;
	reg							Result_valid_rd					;
	reg							Sequence_rd						;
	reg				[5:0]		count							;
	
	reg				[5:0]		Result_valid					;
	reg							Result_valid_wr					;
	wire			[5:0]		Result_valid_q					;
	reg				[5:0]		Result_valid_q_reg				;
	wire						Result_valid_rdempty			;
	
	wire			[5:0]		Result_wrused					;
	wire			[5:0]		Sequence_wrusedw				;
	wire			[63:0]		Result_q						;
	wire			[255:0]		Sequence_q						;
	wire						Result_rdempty					;
//control signal	

	reg 			[1:0] 		current_state					;
	
	parameter		idle_s 			= 	2'b00,
					result_read_s	=	2'b01,
					result_write_s	=	2'b10;	
	
	
	assign	Result_alf				= (Result_wrused[5] == 1'b1		) 	? 1'b1 : 1'b0;
	assign	Sequence_alf			= (Sequence_wrusedw[5] == 1'b1	) 	? 1'b1 : 1'b0;

//counter the result	
always@(posedge Clk or negedge Reset_N)
	if (!Reset_N)begin
		Result_valid				<= 6'b0;
		Result_valid_wr				<= 1'b0;
	end
	else begin
		if (Result_wr == 1'b1)begin									//result is coming
			case(Result[63:61])										//judge the result head
			3'b101:begin											//the head of result
				if (Result[60] == 1'b1)
					Result_valid		<= 6'b1;
				else
					Result_valid		<= 6'b0;
				Result_valid_wr			<= 1'b0;
			end
			3'b111:begin											//the body of result
				if (Result[60] == 1'b1)
					Result_valid		<= Result_valid + 6'b1;
				else
					Result_valid		<= Result_valid;
				Result_valid_wr			<= 1'b0;
			end
			3'b110:begin											//the tail of result
				if (Result[60] == 1'b1)
					Result_valid		<= Result_valid + 6'b1;
				else
					Result_valid		<= Result_valid;
				Result_valid_wr			<= 1'b1;
			end
			default:begin											//the head&tail of result
				if (Result[60] == 1'b1)
					Result_valid		<= 6'b1;
				else
					Result_valid		<= 6'b0;
				Result_valid_wr			<= 1'b1;
			end
			endcase
		end
		else begin
			Result_valid				<= Result_valid;
			Result_valid_wr				<= 1'b0;
		end
	end

always@(posedge Clk or negedge Reset_N)
	if (!Reset_N)begin
		IFE_ctrlpkt_out											<= 520'b0;														//reset signal
		IFE_ctrlpkt_out_wr										<= 1'b0;														//reset signal
		IFE_ctrlpkt_out_valid									<= 256'b0;														//reset signal
		IFE_ctrlpkt_out_valid_wr								<= 1'b0;														//reset signal
		Result_rd												<= 1'b0;														//reset signal
		Result_valid_rd											<= 1'b0;														//reset signal
		Sequence_rd												<= 1'b0;														//reset signal
		count													<= 6'b0;														//reset signal
		Result_valid_q_reg										<= 6'b0;														//reset signal
		current_state											<= idle_s;														//reset signal
	end
	else begin
		case(current_state)
			idle_s:begin
				if (Result_valid_rdempty == 1'b0 && IFE_ctrlpkt_in_alf == 1'b0)begin											//result is coming
					Result_rd									<= 1'b1;														//read the result fifo
					Result_valid_rd								<= 1'b1;														//read the valid fifo
					Sequence_rd									<= 1'b1;														//read the sequence fifo
					IFE_ctrlpkt_out_wr							<= 1'b0;														//clear signal
					IFE_ctrlpkt_out_valid_wr					<= 1'b0;														//clear signal
					count										<= 6'b0;														//clear signal
					Result_valid_q_reg							<= Result_valid_q;												//record the valid
					if (Result_q[59] == 1'b1)begin																				//write flag
						IFE_ctrlpkt_out							<= {2'b11,6'd40,Sequence_q[255:208],FPGA_MAC,16'h9001,Sequence_q[175:160],8'h06,10'b0,Result_valid_q,8'b0,Sequence_q[207:176],320'b0};//store the MAC and Seq
						IFE_ctrlpkt_out_valid					<= {Sequence_q[255:80],16'd24,Sequence_q[63:0]};				//change the pkt length
						current_state							<= result_write_s;												//write ack
					end
					else begin																									//read flag
						IFE_ctrlpkt_out							<= {2'b10,6'd0,Sequence_q[255:208],FPGA_MAC,16'h9001,Sequence_q[175:160],8'h05,10'b0,Result_valid_q,8'b0,Sequence_q[207:176],320'b0};//store the MAC and Seq
						IFE_ctrlpkt_out_valid					<= {Sequence_q[255:80],16'd24 + {8'h0,Result_valid_q,2'h0},Sequence_q[63:0]};//change the pkt length
						current_state							<= result_read_s;												//read ack
					end
				end
				else begin																										//waiting result
					IFE_ctrlpkt_out								<= 520'b0;														//clear signal
					IFE_ctrlpkt_out_wr							<= 1'b0;														//clear signal
					IFE_ctrlpkt_out_valid						<= 256'b0;														//clear signal
					IFE_ctrlpkt_out_valid_wr					<= 1'b0;														//clear signal
					Result_rd									<= 1'b0;														//clear signal
					Result_valid_rd								<= 1'b0;														//clear signal
					Sequence_rd									<= 1'b0;														//clear signal
					count										<= 6'b0;														//clear signal
					current_state								<= idle_s;														//clear signal
				end
			end
			result_read_s:begin
				Sequence_rd										<= 1'b0;														//don't read the sequence fifo
				Result_valid_rd									<= 1'b0;														//don't read the valid fifo
				case(Result_q[63:61])
				3'b101:begin
					Result_rd									<= 1'b1;														//read result fifo
					IFE_ctrlpkt_out								<= {IFE_ctrlpkt_out[519:320],Result_q[31:0],IFE_ctrlpkt_out[287:0]};//store the read data
					IFE_ctrlpkt_out_wr							<= 1'b0;														//don't send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b0;														//don't send the valid
					current_state								<= result_read_s;												//counter the tag
					if (Result_q[60] == 1'b1)begin																				//writing is succeed
						count									<= count + 6'b1;												// add the counter
					end
				end
				3'b111:begin
					Result_rd									<= 1'b1;														//read result fifo
					IFE_ctrlpkt_out_wr							<= 1'b0;														//don't send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b0;														//don't send the valid
					current_state								<= result_read_s;												//counter the tag
					if (Result_q[60] == 1'b1)begin																				//writing is succeed
						count									<= count + 6'b1;												// add the counter
					end
					case (count[3:0])
						4'b0000: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:320],Result_q[31:0],IFE_ctrlpkt_out[287:0]};//store the read data
						4'b0001: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:288],Result_q[31:0],IFE_ctrlpkt_out[255:0]};//store the read data
						4'b0010: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:256],Result_q[31:0],IFE_ctrlpkt_out[223:0]};//store the read data
						4'b0011: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:224],Result_q[31:0],IFE_ctrlpkt_out[191:0]};//store the read data
						4'b0100: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:192],Result_q[31:0],IFE_ctrlpkt_out[159:0]};//store the read data
						4'b0101: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:160],Result_q[31:0],IFE_ctrlpkt_out[127:0]};//store the read data
						4'b0110: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:128],Result_q[31:0],IFE_ctrlpkt_out[95:0]};//store the read data
						4'b0111: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:96],Result_q[31:0],IFE_ctrlpkt_out[63:0]};//store the read data
						4'b1000: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:64],Result_q[31:0],IFE_ctrlpkt_out[31:0]};//store the read data
						4'b1001: begin
								 IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:32],Result_q[31:0]};						//store the read data
								 IFE_ctrlpkt_out_wr				<= 1'b1; 															//send the data
						end
						4'b1010: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:512],Result_q[31:0],IFE_ctrlpkt_out[479:0]};//store the read data
						4'b1011: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:480],Result_q[31:0],IFE_ctrlpkt_out[447:0]};//store the read data
						4'b1100: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:448],Result_q[31:0],IFE_ctrlpkt_out[415:0]};//store the read data
						4'b1101: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:416],Result_q[31:0],IFE_ctrlpkt_out[383:0]};//store the read data
						4'b1110: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:384],Result_q[31:0],IFE_ctrlpkt_out[351:0]};//store the read data
						4'b1111: IFE_ctrlpkt_out[517:0]			<= {IFE_ctrlpkt_out[517:352],Result_q[31:0],IFE_ctrlpkt_out[319:0]};//store the read data
					endcase
					if (Result_valid_q_reg <= 6'd10)begin																		//ctrlpkt tail
						IFE_ctrlpkt_out[519:518]				<= 2'b11;							
					end
					else if (Result_valid_q_reg > 6'd10 && count <= 6'd10)begin																	//ctrlpkt head
						IFE_ctrlpkt_out[519:518]				<= 2'b10;
					end
					else begin
						IFE_ctrlpkt_out[519:518]				<= 2'b00;
					end
				end
				3'b110:begin
					Result_rd									<= 1'b0;														//don't read result fifo
					IFE_ctrlpkt_out_wr							<= 1'b1;														//send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b1;														//send the valid
					current_state								<= idle_s;														//goto idle_s
					if (Result_q[60] == 1'b1)begin																				//writing is succeed
						count									<= count + 6'b1;												// add the counter
					end
					case (count[3:0])
						4'b0000: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:320],Result_q[31:0],IFE_ctrlpkt_out[287:0]};//store the read data
						4'b0001: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:288],Result_q[31:0],IFE_ctrlpkt_out[255:0]};//store the read data
						4'b0010: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:256],Result_q[31:0],IFE_ctrlpkt_out[223:0]};//store the read data
						4'b0011: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:224],Result_q[31:0],IFE_ctrlpkt_out[191:0]};//store the read data
						4'b0100: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:192],Result_q[31:0],IFE_ctrlpkt_out[159:0]};//store the read data
						4'b0101: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:160],Result_q[31:0],IFE_ctrlpkt_out[127:0]};//store the read data
						4'b0110: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:128],Result_q[31:0],IFE_ctrlpkt_out[95:0]};//store the read data
						4'b0111: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:96],Result_q[31:0],IFE_ctrlpkt_out[63:0]};//store the read data
						4'b1000: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:64],Result_q[31:0],IFE_ctrlpkt_out[31:0]};//store the read data
						4'b1001: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:32],Result_q[31:0]};						//store the read data
						4'b1010: IFE_ctrlpkt_out[511:0]			<= {Result_q[31:0],IFE_ctrlpkt_out[479:0]};							//store the read data
						4'b1011: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:480],Result_q[31:0],IFE_ctrlpkt_out[447:0]};//store the read data
						4'b1100: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:448],Result_q[31:0],IFE_ctrlpkt_out[415:0]};//store the read data
						4'b1101: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:416],Result_q[31:0],IFE_ctrlpkt_out[383:0]};//store the read data
						4'b1110: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:384],Result_q[31:0],IFE_ctrlpkt_out[351:0]};//store the read data
						4'b1111: IFE_ctrlpkt_out[511:0]			<= {IFE_ctrlpkt_out[511:352],Result_q[31:0],IFE_ctrlpkt_out[319:0]};//store the read data
					endcase
					if (Result_valid_q_reg <= 6'd10)begin																		//ctrlpkt tail
						IFE_ctrlpkt_out[519:518]				<= 2'b11;														//1 cycle
						case (count[3:0])
							4'b0000: IFE_ctrlpkt_out[517:512]			<= 6'd36;//unvalid_bytes
							4'b0001: IFE_ctrlpkt_out[517:512]			<= 6'd32;//unvalid_bytes
							4'b0010: IFE_ctrlpkt_out[517:512]			<= 6'd28;//unvalid_bytes
							4'b0011: IFE_ctrlpkt_out[517:512]			<= 6'd24;//unvalid_bytes
							4'b0100: IFE_ctrlpkt_out[517:512]			<= 6'd20;//unvalid_bytes
							4'b0101: IFE_ctrlpkt_out[517:512]			<= 6'd16;//unvalid_bytes
							4'b0110: IFE_ctrlpkt_out[517:512]			<= 6'd12;//unvalid_bytes
							4'b0111: IFE_ctrlpkt_out[517:512]			<= 6'd8;//unvalid_bytes
							4'b1000: IFE_ctrlpkt_out[517:512]			<= 6'd4;//unvalid_bytes
							4'b1001: IFE_ctrlpkt_out[517:512]			<= 6'd0;//unvalid_bytes
							4'b1010: IFE_ctrlpkt_out[517:512]			<= 6'd60;//unvalid_bytes
							4'b1011: IFE_ctrlpkt_out[517:512]			<= 6'd56;//unvalid_bytes
							4'b1100: IFE_ctrlpkt_out[517:512]			<= 6'd52;//unvalid_bytes
							4'b1101: IFE_ctrlpkt_out[517:512]			<= 6'd48;//unvalid_bytes
							4'b1110: IFE_ctrlpkt_out[517:512]			<= 6'd44;//unvalid_bytes
							4'b1111: IFE_ctrlpkt_out[517:512]			<= 6'd40;//unvalid_bytes
						endcase
					end
					else begin																									//ctrlpkt tail
						IFE_ctrlpkt_out[519:518]				<= 2'b01;
						case (count[3:0])
							4'b0000: IFE_ctrlpkt_out[517:512]			<= 6'd36;//unvalid_bytes
							4'b0001: IFE_ctrlpkt_out[517:512]			<= 6'd32;//unvalid_bytes
							4'b0010: IFE_ctrlpkt_out[517:512]			<= 6'd28;//unvalid_bytes
							4'b0011: IFE_ctrlpkt_out[517:512]			<= 6'd24;//unvalid_bytes
							4'b0100: IFE_ctrlpkt_out[517:512]			<= 6'd20;//unvalid_bytes
							4'b0101: IFE_ctrlpkt_out[517:512]			<= 6'd16;//unvalid_bytes
							4'b0110: IFE_ctrlpkt_out[517:512]			<= 6'd12;//unvalid_bytes
							4'b0111: IFE_ctrlpkt_out[517:512]			<= 6'd8;//unvalid_bytes
							4'b1000: IFE_ctrlpkt_out[517:512]			<= 6'd4;//unvalid_bytes
							4'b1001: IFE_ctrlpkt_out[517:512]			<= 6'd0;//unvalid_bytes
							4'b1010: IFE_ctrlpkt_out[517:512]			<= 6'd60;//unvalid_bytes
							4'b1011: IFE_ctrlpkt_out[517:512]			<= 6'd56;//unvalid_bytes
							4'b1100: IFE_ctrlpkt_out[517:512]			<= 6'd52;//unvalid_bytes
							4'b1101: IFE_ctrlpkt_out[517:512]			<= 6'd48;//unvalid_bytes
							4'b1110: IFE_ctrlpkt_out[517:512]			<= 6'd44;//unvalid_bytes
							4'b1111: IFE_ctrlpkt_out[517:512]			<= 6'd40;//unvalid_bytes
						endcase
					end
				end
				default:begin
					Result_rd									<= 1'b0;														//don't read result fifo
					IFE_ctrlpkt_out								<= {2'b11,6'd36,IFE_ctrlpkt_out[511:320],Result_q[31:0],IFE_ctrlpkt_out[287:0]};//replace the read ack head
					IFE_ctrlpkt_out_wr							<= 1'b1;														//send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b1;														//send the valid
					current_state								<= idle_s;														//goto idle_s
				end
				endcase
			end
			result_write_s:begin
				Sequence_rd										<= 1'b0;														//don't read the sequence fifo
				Result_valid_rd									<= 1'b0;														//don't read the valid fifo
				case(Result_q[63:61])
				3'b101:begin
					Result_rd									<= 1'b1;														//read result fifo
					IFE_ctrlpkt_out_wr							<= 1'b0;														//don't send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b0;														//don't send the valid
					current_state								<= result_write_s;												//counter the tag
				end
				3'b111:begin
					Result_rd									<= 1'b1;														//read result fifo
					IFE_ctrlpkt_out_wr							<= 1'b0;														//don't send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b0;														//don't send the valid
					current_state								<= result_write_s;												//counter the tag
				end
				3'b110:begin
					Result_rd									<= 1'b0;														//don't read result fifo
					IFE_ctrlpkt_out_wr							<= 1'b1;														//send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b1;														//send the valid
					current_state								<= idle_s;														//goto idle_s
				end
				default:begin
					Result_rd									<= 1'b0;														//don't read result fifo
					IFE_ctrlpkt_out_wr							<= 1'b1;														//send the ctrlpkt
					IFE_ctrlpkt_out_valid_wr					<= 1'b1;														//send the valid
					current_state								<= idle_s;														//goto idle_s
				end
				endcase
			end
			default:begin
				current_state									<= idle_s;														//go back idle_s
			end
		endcase
	end
//counter domain
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) pkt_out_cnt			<= 32'b0; else if (IFE_ctrlpkt_out_valid_wr == 1'b1	)	pkt_out_cnt 		<= pkt_out_cnt +1'b1; 			else pkt_out_cnt 		<= pkt_out_cnt;		//tmp is used to restore cnt
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) result_in_cnt		<= 32'b0; else if (Result_wr == 1'b1				)	result_in_cnt 		<= result_in_cnt +1'b1; 		else result_in_cnt 		<= result_in_cnt;		//tmp is used to restore cnt

//result buffer
//ecc's & mbist for mem
wire					w_result_onebit_err,w_result_twobit_err;
wire					w_result_valid_onebit_err,w_result_valid_twobit_err;
wire					w_sequence_onebit_err,w_sequence_twobit_err;
reg						result_onebit_err,result_twobit_err;
reg						result_valid_onebit_err,result_valid_twobit_err;
reg						sequence_onebit_err,sequence_twobit_err;
always @(posedge Clk or negedge Reset_N)begin
	if(!Reset_N)begin
		result_onebit_err <= 1'b0;
		result_twobit_err <= 1'b0;
		result_valid_onebit_err <= 1'b0;
		result_valid_twobit_err <= 1'b0;
		sequence_onebit_err <= 1'b0;
		sequence_twobit_err <= 1'b0;
	end
	else begin//ecc pulse locked
		if(w_result_onebit_err)begin result_onebit_err <= 1'b1; end else begin result_onebit_err <= result_onebit_err;end
		if(w_result_twobit_err)begin result_twobit_err <= 1'b1; end else begin result_twobit_err <= result_twobit_err;end
		if(w_result_valid_onebit_err)begin result_valid_onebit_err <= 1'b1; end else begin result_valid_onebit_err <= result_valid_onebit_err;end
		if(w_result_valid_twobit_err)begin result_valid_twobit_err <= 1'b1; end else begin result_valid_twobit_err <= result_valid_twobit_err;end
		if(w_sequence_onebit_err)begin sequence_onebit_err <= 1'b1; end else begin sequence_onebit_err <= sequence_onebit_err;end
		if(w_sequence_twobit_err)begin sequence_twobit_err <= 1'b1; end else begin sequence_twobit_err <= sequence_twobit_err;end
	end
end
	assign	debug_current			= {	result_onebit_err,result_twobit_err,result_valid_onebit_err,result_valid_twobit_err,sequence_onebit_err,sequence_twobit_err,
										Result_wrused,
										IFE_ctrlpkt_in_alf,Sequence_rd,count,
										Sequence_wr,Sequence_alf,Result_wr,Result_alf,
										current_state,IFE_ctrlpkt_out_valid_wr,IFE_ctrlpkt_out_wr,
										Result_rd,Result_valid_rd,Result_valid_wr,Result_valid_rdempty};

	SYNCFIFO_64x64 result_scfifo_64_64_FIFO(
			.e1a					(w_result_onebit_err			),	//port B: ECC onebit_err
			.e2a					(w_result_twobit_err			),	//port B: ECC twobit_err
			.aclr					(~Reset_N						),	//Reset the all signal, active high
			.data					(Result							),	//The Inport of data 
			.rdreq					(Result_rd						),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wrreq					(Result_wr						),	//active-high
			.q						(Result_q						),	//The Outport of data
			.wrusedw				(Result_wrused					),	//RAM wrusedword
			.rdusedw				(								)	//RAM rdusedword			
	);
//result valid buffer
	SYNCFIFO_64x6 result_valid_scfifo_6_64_FIFO(
			.e1a					(w_result_valid_onebit_err		),	//port B: ECC onebit_err
			.e2a					(w_result_valid_twobit_err		),	//port B: ECC twobit_err
			.aclr					(~Reset_N						),	//Reset the all signal, active high
			.data					(Result_valid					),	//The Inport of data 
			.rdreq					(Result_valid_rd				),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wrreq					(Result_valid_wr				),	//active-high
			.q						(Result_valid_q					),	//The Outport of data
			.rdempty				(Result_valid_rdempty			),	//active-high
			.wrusedw				(								),	//RAM wrusedword
			.rdusedw				(								)	//RAM rdusedword			
	);
//sequence buffer
	SYNCFIFO_64x256 sequence_scfifo_64_256_FIFO(
			.e1a					(w_sequence_onebit_err			),	//port B: ECC onebit_err
			.e2a					(w_sequence_twobit_err			),	//port B: ECC twobit_err
			.aclr					(~Reset_N						),	//Reset the all signal, active high
			.data					(Sequence						),	//The Inport of data 
			.rdreq					(Sequence_rd					),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wrreq					(Sequence_wr					),	//active-high
			.q						(Sequence_q						),	//The Outport of data
			.wrusedw				(Sequence_wrusedw				),	//active-high
			.rdusedw				(								)	//RAM rdusedword			
	);
	
endmodule

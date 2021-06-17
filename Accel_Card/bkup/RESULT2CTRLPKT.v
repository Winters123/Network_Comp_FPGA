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
	output	reg		[111:0]		IFE_ctrlpkt_out_valid			,//receive metadata
	output	reg					IFE_ctrlpkt_out_valid_wr		,//receive metadata write signal 
	input						IFE_ctrlpkt_in_alf				,//output allmostfull
//======================================= command to the config path ==================================//
	input 		 				Result_wr						,//command write signal
//================================ sequence of command to Result2ctrlpkt ================================//	input 						Sequence_wr						,//pkt sequence 	input 		 	[255:0]		Sequence						,//pkt sequence	output 						Sequence_alf					,//pkt allmostfull
//=================================== the MAC & IP in NACP ====================================//
	input			[519:0]		IFE_ctrlpkt_in					,//receive pkt
	input						IFE_ctrlpkt_in_wr				,//receive pkt write singal
	input			[255:0]		IFE_ctrlpkt_in_valid			,//receive metadata
	input						IFE_ctrlpkt_in_valid_wr			,//receive metadata write signal 
	output						IFE_ctrlpkt_out_alf				,
//=================================== counter & debug ====================================//
	output	reg	 	[31:0] 		pkt_out_cnt						,//pkt output cnt
	output	reg		[31:0]		result_in_cnt					//result in cnt						
);
//======================================= internal reg&wire declarations =======================================//
	reg 			[1:0] 		current_state					;
	reg							IFE_ctrlpkt_in_rd				;
	reg							IFE_ctrlpkt_in_valid_rd			;
	
	wire			[6:0]		IFE_ctrlpkt_wrusedwd			;
	wire			[519:0]		IFE_ctrlpkt_in_q				;
	wire			[255:0]		IFE_ctrlpkt_in_valid_q			;
	wire						IFE_ctrlpkt_in_valid_empty		;
	
	parameter		idle_s 		= 	2'b00,
					pkt_send	=	2'b01;	
	
	assign	IFE_ctrlpkt_out_alf		= (IFE_ctrlpkt_wrusedwd == 7'd120) ? 1'b1 : 1'b0;

always@(posedge Clk or negedge Reset_N)
	if (!Reset_N)begin
		IFE_ctrlpkt_out											<= 520'b0;														//reset signal
		IFE_ctrlpkt_out_wr										<= 1'b0;														//reset signal
		IFE_ctrlpkt_out_valid									<= 256'b0;														//reset signal
		IFE_ctrlpkt_out_valid_wr								<= 1'b0;														//reset signal
		IFE_ctrlpkt_in_rd		                                <= 1'b0;
		IFE_ctrlpkt_in_valid_rd	                                <= 1'b0;
		current_state											<= idle_s;														//reset signal
	end
	else begin
		case(current_state)
			idle_s:begin
				IFE_ctrlpkt_out											<= 520'b0;	
			    IFE_ctrlpkt_out_wr										<= 1'b0;	
			    IFE_ctrlpkt_out_valid									<= 256'b0;	
			    IFE_ctrlpkt_out_valid_wr								<= 1'b0;			
				if(!IFE_ctrlpkt_in_alf && Result_wr)begin	
					IFE_ctrlpkt_in_rd		                                <= 1'b1;
					IFE_ctrlpkt_in_valid_rd	                                <= 1'b1;
					current_state											<= pkt_send;	
				end
				else begin
					IFE_ctrlpkt_in_rd		                                <= 1'b0;
					IFE_ctrlpkt_in_valid_rd	                                <= 1'b0;
					current_state											<= idle_s;
				end
			end
			pkt_send:begin
				IFE_ctrlpkt_out												<= {IFE_ctrlpkt_in_q[519:512],IFE_ctrlpkt_in_q[463:416],IFE_ctrlpkt_in_q[511:464],IFE_ctrlpkt_in_q[415:0]};
			    IFE_ctrlpkt_out_wr											<= 1'b1;	
			    IFE_ctrlpkt_out_valid										<= {1'b1,1'b0,IFE_ctrlpkt_in_valid_q[79:64],IFE_ctrlpkt_in_valid_q[255:192],IFE_ctrlpkt_in_valid_q[31:0]};	
			    IFE_ctrlpkt_out_valid_wr									<= 1'b1;				
				if(IFE_ctrlpkt_in_alf && Result_wr)begin	
			    	IFE_ctrlpkt_in_rd		                                <= 1'b1;
			    	IFE_ctrlpkt_in_valid_rd	                                <= 1'b1;
			    	current_state											<= pkt_send;
			    end
				else begin
					IFE_ctrlpkt_in_rd		                                <= 1'b0;
					IFE_ctrlpkt_in_valid_rd	                                <= 1'b0;
					current_state											<= idle_s;
				end
			end			
			default:begin
				current_state									<= idle_s;														//go back idle_s
			end
		endcase
	end
//counter domain
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) pkt_out_cnt			<= 32'b0; else if (IFE_ctrlpkt_out_valid_wr == 1'b1	)	pkt_out_cnt 		<= pkt_out_cnt +1'b1; 			else pkt_out_cnt 		<= pkt_out_cnt;		//tmp is used to restore cnt
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) result_in_cnt		<= 32'b0; else if (Result_wr == 1'b1				)	result_in_cnt 		<= result_in_cnt +1'b1; 		else result_in_cnt 		<= result_in_cnt;		//tmp is used to restore cnt

	SYNCFIFO_128x520 scfifo_520_128_FIFO(
			.rst					(~Reset_N						),	//Reset the all signal, active high
			.din					(IFE_ctrlpkt_in					),	//The Inport of data 
			.rd_en					(IFE_ctrlpkt_in_rd				),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wr_en					(IFE_ctrlpkt_in_wr				),	//active-high
			.dout					(IFE_ctrlpkt_in_q				),	//The Outport of data
			.data_count				(IFE_ctrlpkt_wrusedwd			)	//RAM wrusedword		
	);
//metadata buffer
	SYNCFIFO_128x256 scfifo_256_128_FIFO(
			.rst					(~Reset_N						),	//Reset the all signal, active high
			.din					(IFE_ctrlpkt_in_valid			),	//The Inport of data 
			.rd_en					(IFE_ctrlpkt_in_valid_rd		),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wr_en					(IFE_ctrlpkt_in_valid_wr		),	//active-high
			.dout					(IFE_ctrlpkt_in_valid_q			),	//The Outport of data
			.empty					(IFE_ctrlpkt_in_valid_empty		)	//active-high		
	);
	
endmodule

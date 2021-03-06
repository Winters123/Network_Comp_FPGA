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

module RESULT2CTRLPKT#(	parameter					DMAC			= 48'h888888888888		,	//module ID is 60
													SMAC			= 48'h777777777777		
)
(
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
	input 		 	[63: 0]		Result							,//command write signal
	input 		 				Result_wr						,//command write signal
//================================ sequence of command to Result2ctrlpkt ================================//	input 						Sequence_wr						,//pkt sequence 	input 		 	[255:0]		Sequence						,//pkt sequence	output 						Sequence_alf					,//pkt allmostfull
//=================================== the MAC & IP in NACP ====================================//

//=================================== counter & debug ====================================//
	output	reg	 	[31:0] 		pkt_out_cnt						,//pkt output cnt
	output	reg		[31:0]		result_in_cnt					//result in cnt						
);
//======================================= internal reg&wire declarations =======================================//
always@(posedge Clk or negedge Reset_N)begin
	if (!Reset_N)begin
		IFE_ctrlpkt_out											<= 520'b0;														//reset signal
		IFE_ctrlpkt_out_wr										<= 1'b0;														//reset signal
		IFE_ctrlpkt_out_valid									<= 112'b0;														//reset signal
		IFE_ctrlpkt_out_valid_wr								<= 1'b0;														//reset signal											//reset signal
	end
	else begin
		if((!IFE_ctrlpkt_in_alf)&&(Result_wr))begin
			IFE_ctrlpkt_out											<= {2'b11,6'b0,DMAC,SMAC,32'hffffffff,16'h9000,307'b0,Result[60:0]};		
			IFE_ctrlpkt_out_wr										<= 1'b1;	
			IFE_ctrlpkt_out_valid									<= {1'b1,4'b0,11'd64,64'b0,32'b1};
			IFE_ctrlpkt_out_valid_wr								<= 1'b1;	
		end
		else begin
			IFE_ctrlpkt_out											<= 520'b0;	
		    IFE_ctrlpkt_out_wr										<= 1'b0;	
		    IFE_ctrlpkt_out_valid									<= 112'b0;	
			IFE_ctrlpkt_out_valid_wr								<= 1'b0;
		end
	end
end
	
//counter domain
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) pkt_out_cnt			<= 32'b0; else if (IFE_ctrlpkt_out_valid_wr == 1'b1	)	pkt_out_cnt 		<= pkt_out_cnt +1'b1; 			else pkt_out_cnt 		<= pkt_out_cnt;		//tmp is used to restore cnt
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) result_in_cnt		<= 32'b0; else if (Result_wr == 1'b1				)	result_in_cnt 		<= result_in_cnt +1'b1; 		else result_in_cnt 		<= result_in_cnt;		//tmp is used to restore cnt
endmodule

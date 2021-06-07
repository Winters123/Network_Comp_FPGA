// ****************************************************************************
// Copyright		: 	NUDT.
// ============================================================================
// FILE NAME		:	CTRLPKT2COMMAND.v
// CREATE DATE		:	2020-6-30 
// AUTHOR			:	xiongzhiting
// AUTHOR'S EMAIL	:	
// AUTHOR'S TEL		:	
// ============================================================================
// RELEASE 	HISTORY		-------------------------------------------------------
// VERSION 			DATE				AUTHOR				DESCRIPTION
// WM0.0			2020-6-30			xiongzhiting		CTRLPKT2COMMAND
// ============================================================================
// KEYWORDS 		: 	the nacp packet, command
// ----------------------------------------------------------------------------
// PURPOSE 			: 	change the nacp packet to command
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

module CTRLPKT2COMMAND(
//===================================== ecc's & mbist for mem ====================================//

//=========================================== clk & rst ===========================================//
	input 						Clk								,//clock, this is synchronous clock
	input 						Reset_N							,//Reset the all signal, active high
//=========================================== frame from IFE ===========================================//
	input			[519:0]		IFE_ctrlpkt_in					,//receive pkt
	input						IFE_ctrlpkt_in_wr				,//receive pkt write singal
	input			[255:0]		IFE_ctrlpkt_in_valid			,//receive metadata
	input						IFE_ctrlpkt_in_valid_wr			,//receive metadata write signal 
	output						IFE_ctrlpkt_out_alf				,//output allmostfull
//======================================= command to the config path ==================================//
	output 	reg 				Command_wr						,//command write signal
	output 	reg 	[63:0] 		Command							,//command [63:61] 101:frist 111:middle 110:end 100:frist&end [60]1:succeed 0:fail  [59] 0:read 1:write [58:52]MDID [51:32] address [31:0] data
	input 						Command_alf						,//commadn almostful
//=================================== counter & debug ====================================//
	output	reg	 	[31:0] 		pkt_in_cnt						,//pkt input cnt
	output	reg		[31:0]		com_out_cnt						//command out cnt
	
);
//======================================= internal reg&wire declarations =======================================//
	reg							IFE_ctrlpkt_in_rd				;
	reg							IFE_ctrlpkt_in_valid_rd			;
	wire			[6:0]		IFE_ctrlpkt_wrusedwd			;
	wire			[519:0]		IFE_ctrlpkt_in_q				;
	wire			[255:0]		IFE_ctrlpkt_in_valid_q			;
	wire						IFE_ctrlpkt_in_valid_empty		;
	reg             [1:0  ]     current_state  ;
	
	parameter		idle_s 			= 	2'b00,
					command_send_s	=	2'b01;
	assign	IFE_ctrlpkt_out_alf		= (IFE_ctrlpkt_wrusedwd == 7'd120) ? 1'b1 : 1'b0;
	
always@(posedge Clk or negedge Reset_N)
	if (!Reset_N)begin
		IFE_ctrlpkt_in_rd										<= 1'b0;		//reset signal
		IFE_ctrlpkt_in_valid_rd									<= 1'b0;		//reset signal
		Command_wr												<= 1'b0;		//reset signal
		Command													<= 64'b0;		//reset signal
		current_state											<= idle_s;		//reset signal
	end
	else begin
		case(current_state)
			idle_s:begin
				if (IFE_ctrlpkt_in_valid_empty == 1'b0 && Command_alf == 1'b0)begin	
				IFE_ctrlpkt_in_rd							<= 1'b1;	
                IFE_ctrlpkt_in_valid_rd						<= 1'b1;	
                Command_wr									<= 1'b0;	
                Command										<= 64'b0;					
				current_state									<= command_send_s;
				end
				else begin														//waiting pkt
					IFE_ctrlpkt_in_rd							<= 1'b0;		//clear signal
					IFE_ctrlpkt_in_valid_rd						<= 1'b0;		//clear signal
					Command_wr									<= 1'b0;		//clear signal
					Command										<= 64'b0;		//clear signal
					current_state								<= idle_s;		//clear signal
				end
			end
			command_send_s:begin
				Command				<=	{3'b100,IFE_ctrlpkt_in_q[60:0]};
				Command_wr			<= 1'b1;
				if(IFE_ctrlpkt_in_valid_empty&& Command_alf == 1'b0)begin
					current_state	<= command_send_s;
				end
				else begin
					current_state								<= idle_s;
					IFE_ctrlpkt_in_rd							<= 1'b0;
					IFE_ctrlpkt_in_valid_rd						<= 1'b0;
				end
			end				
			default:begin
				current_state									<= idle_s;		//clean signal
			end
		endcase
	end
//counter domain
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) pkt_in_cnt			<= 32'b0; else if (IFE_ctrlpkt_in_valid_wr == 1'b1	)	pkt_in_cnt 			<= pkt_in_cnt +1'b1; 			else pkt_in_cnt 		<= pkt_in_cnt;		//tmp is used to restore cnt
	always @(posedge Clk or negedge Reset_N) if (!Reset_N) com_out_cnt			<= 32'b0; else if (Command_wr == 1'b1				)	com_out_cnt 		<= com_out_cnt +1'b1; 			else com_out_cnt 		<= com_out_cnt;		//tmp is used to restore cnt

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
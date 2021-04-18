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
//================================ sequence of command to Result2ctrlpkt ================================//
	output 	reg					Sequence_wr						,//pkt sequence write
	output 	reg 	[255:0]		Sequence						,//pkt sequence
	input 						Sequence_alf					,//pkt allmostfull
//=================================== the MAC & IP in NACP ====================================//
	input		 	[47:0] 		FPGA_MAC						,//hard MAC address
//=================================== counter & debug ====================================//
	output	reg	 	[31:0] 		pkt_in_cnt						,//pkt input cnt
	output	reg		[31:0]		com_out_cnt						,//command out cnt
	output	wire	[31:0]		debug_current					 //debug signal
	
);

//======================================= internal reg&wire declarations =======================================//
	reg							IFE_ctrlpkt_in_rd				;
	reg							IFE_ctrlpkt_in_valid_rd			;
	wire			[6:0]		IFE_ctrlpkt_wrusedwd			;
	wire			[519:0]		IFE_ctrlpkt_in_q				;
	wire			[255:0]		IFE_ctrlpkt_in_valid_q			;
	wire						IFE_ctrlpkt_in_valid_empty		;
//control signal	
	reg							read_flag						;
	reg				[31:0]		head_addr						;
	reg				[7:0]		count							;
	reg				[7:0]		write_count						;
	reg				[519:0]		IFE_ctrlpkt_in_q_reg			;
	reg 			[1:0] 		current_state					;
	
	parameter		idle_s 			= 	2'b00,
					command_read_s	=	2'b01,
					command_write_s	=	2'b10,
					discard_s 		= 	2'b11;	
	assign	IFE_ctrlpkt_out_alf		= (IFE_ctrlpkt_wrusedwd == 7'd120) ? 1'b1 : 1'b0;
	
always@(posedge Clk or negedge Reset_N)
	if (!Reset_N)begin
		IFE_ctrlpkt_in_rd										<= 1'b0;		//reset signal
		IFE_ctrlpkt_in_valid_rd									<= 1'b0;		//reset signal
		read_flag												<= 1'b0;		//reset signal
		head_addr												<= 32'b0;		//reset signal
		count													<= 8'b0;		//reset signal
		write_count												<= 8'b0;		//reset signal
		IFE_ctrlpkt_in_q_reg									<= 520'b0;		//reset signal
		Command_wr												<= 1'b0;		//reset signal
		Command													<= 64'b0;		//reset signal
		Sequence_wr												<= 1'b0;		//reset signal
		Sequence												<= 256'b0;		//reset signal
		current_state											<= idle_s;		//reset signal
	end
	else begin
		case(current_state)
			idle_s:begin
				if (IFE_ctrlpkt_in_valid_empty == 1'b0 && Command_alf == 1'b0 && Sequence_alf == 1'b0)begin					//pkt is coming
					if (IFE_ctrlpkt_in_q[415:400] == 16'h9001 && IFE_ctrlpkt_in_q[511:464] == FPGA_MAC)begin	//this pkt is ctrl-pkt
						if (IFE_ctrlpkt_in_q[383:376] == 8'h03)begin											//read command
							IFE_ctrlpkt_in_rd					<= 1'b1;										//read ctrl-pkt fifo
							IFE_ctrlpkt_in_valid_rd				<= 1'b1;										//read ctrl-pkt-valid fifo
							read_flag							<= 1'b1;										//first read flag
							head_addr							<= IFE_ctrlpkt_in_q[351:320];					//The base address of read
							count								<= IFE_ctrlpkt_in_q[367:360];					//Burst the number of read 
							write_count							<= 8'b1;										//clear signal
							IFE_ctrlpkt_in_q_reg				<= IFE_ctrlpkt_in_q;							//store the ctrl-pkt
							Command_wr							<= 1'b0;										//don't send commmand
							Command								<= 64'b0;										//clear signal
							Sequence_wr							<= 1'b1;										//don't send sequence
							Sequence							<= {IFE_ctrlpkt_in_q[463:416],IFE_ctrlpkt_in_q[351:320],IFE_ctrlpkt_in_q[399:384],IFE_ctrlpkt_in_valid_q[159:88],8'hff,IFE_ctrlpkt_in_valid_q[79:64],IFE_ctrlpkt_in_valid_q[31:0],IFE_ctrlpkt_in_valid_q[31:0]};//record the SMAC Req_Seq InputBM, other is metadata 
							current_state						<= command_read_s;								//goto command_read_s
						end
						else if (IFE_ctrlpkt_in_q[383:376] == 8'h04)begin										//write command
							IFE_ctrlpkt_in_rd					<= 1'b1;										//read ctrl-pkt fifo
							IFE_ctrlpkt_in_valid_rd				<= 1'b1;										//read ctrl-pkt-valid fifo
							read_flag							<= 1'b0;										//first read flag
							head_addr							<= IFE_ctrlpkt_in_q[351:320];					//The base address of read
							count								<= IFE_ctrlpkt_in_q[367:360];					//Burst the number of read 
							write_count							<= 8'b1;										//clear signal
							IFE_ctrlpkt_in_q_reg				<= IFE_ctrlpkt_in_q;							//store the ctrl-pkt
							Command_wr							<= 1'b0;										//don't send commmand
							Command								<= 64'b0;										//clear signal
							Sequence_wr							<= 1'b1;										//don't send sequence
							Sequence							<={IFE_ctrlpkt_in_q[463:416],IFE_ctrlpkt_in_q[351:320],IFE_ctrlpkt_in_q[399:384],IFE_ctrlpkt_in_valid_q[159:88],8'hff,IFE_ctrlpkt_in_valid_q[79:64],IFE_ctrlpkt_in_valid_q[31:0],IFE_ctrlpkt_in_valid_q[31:0]};//record the SMAC Req_Seq InputBM, other is metadata 
							current_state						<= command_write_s;								//goto command_read_s
						end
						else begin																				//other command
							IFE_ctrlpkt_in_rd						<= 1'b1;									//read ctrl-pkt fifo
							IFE_ctrlpkt_in_valid_rd					<= 1'b1;									//read ctrl-pkt-valid fifo
							read_flag								<= 1'b0;									//clear signal
							head_addr								<= 32'b0;									//clear signal
							count									<= 8'b0;									//clear signal
							write_count								<= 8'b1;									//clear signal
							IFE_ctrlpkt_in_q_reg					<= 520'b0;									//clear signal
							Command_wr								<= 1'b0;									//clear signal
							Command									<= 64'b0;									//clear signal
							Sequence_wr								<= 1'b0;									//clear signal
							Sequence								<= 256'b0;									//clear signal
							current_state							<= discard_s;								//clean signal
						end
					end
					else begin													//discard the other pkt
						IFE_ctrlpkt_in_rd						<= 1'b1;		//read ctrl-pkt fifo
						IFE_ctrlpkt_in_valid_rd					<= 1'b1;		//read ctrl-pkt-valid fifo
						read_flag								<= 1'b0;		//clear signal
						head_addr								<= 32'b0;		//clear signal
						count									<= 8'b0;		//clear signal
						write_count								<= 8'b1;		//clear signal
						IFE_ctrlpkt_in_q_reg					<= 520'b0;		//clear signal
						Command_wr								<= 1'b0;		//clear signal
						Command									<= 64'b0;		//clear signal
						Sequence_wr								<= 1'b0;		//clear signal
						Sequence								<= 256'b0;		//clear signal
						current_state							<= discard_s;	//clean signal
					end
				end
				else begin														//waiting pkt
					IFE_ctrlpkt_in_rd							<= 1'b0;		//clear signal
					IFE_ctrlpkt_in_valid_rd						<= 1'b0;		//clear signal
					read_flag									<= 1'b0;		//clear signal
					head_addr									<= 32'b0;		//clear signal
					count										<= 8'b0;		//clear signal
					write_count									<= 8'b1;		//clear signal
					IFE_ctrlpkt_in_q_reg						<= 520'b0;		//clear signal
					Command_wr									<= 1'b0;		//clear signal
					Command										<= 64'b0;		//clear signal
					Sequence_wr									<= 1'b0;		//clear signal
					Sequence									<= 256'b0;		//clear signal
					current_state								<= idle_s;		//clear signal
				end
			end
			command_read_s:begin
				IFE_ctrlpkt_in_rd								<= 1'b0;										//don't read ctrl-pkt fifo
				IFE_ctrlpkt_in_valid_rd							<= 1'b0;										//don't read ctrl-pkt-valid fifo
				read_flag										<= 1'b0;										//First read-request commmad flag
				head_addr										<= head_addr + 1'b1;							//The base address of read
				Command_wr										<= 1'b1;										//send commmand
				Sequence_wr										<= 1'b0;										//don't send sequence
				if (count == 1'b1)begin																			//Last read-request commmad
					Command										<= {1'b1,~read_flag,1'b0,2'b0,head_addr[26:20],head_addr[19:0],32'b0};//read command
					current_state								<= idle_s;										//goto idle_s
				end 
				else begin
					Command										<= {1'b1,~read_flag,1'b1,2'b0,head_addr[26:20],head_addr[19:0],32'b0};//read command
					count										<= count - 1'b1;								//the read counter 
					current_state								<= command_read_s;								//send the read command
				end
			end
			command_write_s:begin
				head_addr										<= head_addr + 1'b1;							//The base address of write
				write_count										<= write_count + 1'b1;							//The write counter 
				Sequence_wr										<= 1'b0;										//don't send sequence
				Command_wr										<= 1'b1;										//send commmand
				IFE_ctrlpkt_in_rd								<= 1'b0;										//don't read ctrl-pkt fifo
				IFE_ctrlpkt_in_valid_rd							<= 1'b0;										//don't read ctrl-pkt-valid fifo
				case (write_count[3:0])
				4'h1:begin
					if (count == 1'b1)begin
						Command									<= {3'b100,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[319:288]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else if (write_count == 8'h1)begin
						Command									<= {3'b101,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[319:288]};//write command
						current_state							<= command_write_s;	
					end
					else if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[319:288]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[319:288]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h2:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[287:256]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[287:256]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h3:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[255:224]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[255:224]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h4:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[223:192]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[223:192]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h5:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[191:160]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[191:160]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h6:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[159:128]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[159:128]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h7:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[127:96]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[127:96]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h8:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[95:64]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[95:64]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h9:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[63:32]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[63:32]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'ha:begin
					IFE_ctrlpkt_in_rd							<= 1'b1;										//read ctrl-pkt fifo
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[31:0]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[31:0]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'hb:begin
					IFE_ctrlpkt_in_rd							<= 1'b0;										//read ctrl-pkt fifo
					IFE_ctrlpkt_in_q_reg						<= IFE_ctrlpkt_in_q;							//restore the data
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q[511:480]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q[511:480]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'hc:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[479:448]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[479:448]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'hd:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[447:416]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[447:416]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'he:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[415:384]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[415:384]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'hf:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[383:352]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[383:352]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				4'h0:begin
					if (write_count == count)begin
						Command									<= {3'b110,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[351:320]};//write command
						current_state							<= idle_s;										//goto idle_s
					end
					else begin
						Command									<= {3'b111,2'b01,head_addr[26:20],head_addr[19:0],IFE_ctrlpkt_in_q_reg[351:320]};//write command
						current_state							<= command_write_s;										//goto idle_s
					end
				end
				default:begin
					current_state								<= idle_s;
				end
				endcase
			end
			discard_s:begin
				if (IFE_ctrlpkt_in_q[518] == 1'b1)begin
					IFE_ctrlpkt_in_rd							<= 1'b0;		//clear signal
					IFE_ctrlpkt_in_valid_rd						<= 1'b0;		//clear signal
					read_flag									<= 1'b0;		//clear signal
					head_addr									<= 32'b0;		//clear signal
					count										<= 8'b0;		//clear signal
					write_count									<= 8'b0;		//clear signal
					IFE_ctrlpkt_in_q_reg						<= 520'b0;		//clear signal
					Command_wr									<= 1'b0;		//clear signal
					Command										<= 64'b0;		//clear signal
					Sequence_wr									<= 1'b0;		//clear signal
					Sequence									<= 256'b0;		//clear signal
					current_state								<= idle_s;		//clear signal
				end
				else begin
					IFE_ctrlpkt_in_rd							<= 1'b1;		//clear signal
					IFE_ctrlpkt_in_valid_rd						<= 1'b0;		//clear signal
					current_state								<= discard_s;	//clean signal
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

//Ctrl-PKT buffer
//ecc's & mbist for mem
wire					w_ctrl_pkt_onebit_err,w_ctrl_pkt_twobit_err;
wire					w_ctrl_meta_onebit_err,w_ctrl_meta_twobit_err;
reg						ctrl_pkt_onebit_err,ctrl_pkt_twobit_err;
reg						ctrl_meta_onebit_err,ctrl_meta_twobit_err;
always @(posedge Clk or negedge Reset_N)begin
	if(!Reset_N)begin
		ctrl_pkt_onebit_err <= 1'b0;
		ctrl_pkt_twobit_err <= 1'b0;
		ctrl_meta_onebit_err <= 1'b0;
		ctrl_meta_twobit_err <= 1'b0;
	end
	else begin//ecc pulse locked
		if(w_ctrl_pkt_onebit_err)begin ctrl_pkt_onebit_err <= 1'b1; end else begin ctrl_pkt_onebit_err <= ctrl_pkt_onebit_err;end
		if(w_ctrl_pkt_twobit_err)begin ctrl_pkt_twobit_err <= 1'b1; end else begin ctrl_pkt_twobit_err <= ctrl_pkt_twobit_err;end
		if(w_ctrl_meta_onebit_err)begin ctrl_meta_onebit_err <= 1'b1; end else begin ctrl_meta_onebit_err <= ctrl_meta_onebit_err;end
		if(w_ctrl_meta_twobit_err)begin ctrl_meta_twobit_err <= 1'b1; end else begin ctrl_meta_twobit_err <= ctrl_meta_twobit_err;end
	end
end
	assign	debug_current			= {	ctrl_pkt_onebit_err,ctrl_pkt_twobit_err,ctrl_meta_onebit_err,ctrl_meta_twobit_err,
										count,
										write_count,
										Sequence_wr,Sequence_alf,Command_wr,Command_alf,
										current_state,IFE_ctrlpkt_in_rd,IFE_ctrlpkt_in_wr,
										IFE_ctrlpkt_out_alf,IFE_ctrlpkt_in_valid_rd,IFE_ctrlpkt_in_valid_wr,IFE_ctrlpkt_in_valid_empty};
	SYNCFIFO_128x520 scfifo_520_128_FIFO(
			.e1a					(w_ctrl_pkt_onebit_err			),	//port B: ECC onebit_err
			.e2a					(w_ctrl_pkt_twobit_err			),	//port B: ECC twobit_err
			.aclr					(~Reset_N						),	//Reset the all signal, active high
			.data					(IFE_ctrlpkt_in					),	//The Inport of data 
			.rdreq					(IFE_ctrlpkt_in_rd				),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wrreq					(IFE_ctrlpkt_in_wr				),	//active-high
			.q						(IFE_ctrlpkt_in_q				),	//The Outport of data
			.wrusedw				(IFE_ctrlpkt_wrusedwd			),	//RAM wrusedword
			.rdusedw				(								)	//RAM rdusedword			
	);
//metadata buffer
	SYNCFIFO_128x256 scfifo_256_128_FIFO(
			.e1a					(w_ctrl_meta_onebit_err			),	//port B: ECC onebit_err
			.e2a					(w_ctrl_meta_twobit_err			),	//port B: ECC twobit_err
			.aclr					(~Reset_N						),	//Reset the all signal, active high
			.data					(IFE_ctrlpkt_in_valid			),	//The Inport of data 
			.rdreq					(IFE_ctrlpkt_in_valid_rd		),	//active-high
			.clk					(Clk							),	//ASYNC WriteClk, SYNC use wrclk
			.wrreq					(IFE_ctrlpkt_in_valid_wr		),	//active-high
			.q						(IFE_ctrlpkt_in_valid_q			),	//The Outport of data
			.rdempty				(IFE_ctrlpkt_in_valid_empty		),	//active-high
			.rdusedw				(								)	//RAM rdusedword			
	);

endmodule
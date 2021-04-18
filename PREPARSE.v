/*========================================================================================================*\
          Filename : PREPARSE.v
            Author : zc
       Description : 
	     Called by : 
  Revision History : 06/15/2020 Revision 1.0  zc
					 09/02/2020 Revision 1.1  zc
					 09/10/2020 Revision 1.2  zc add o_ari_t0/1/2/3_rfpul
					 11/24/2020 Revision 1.3  zc add discard pkt
					 01/25/2021 Revision 1.4  zc send the nacp_control_pkt which mac is not match_success as a data pkt
           Company : 662
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module PREPARSE
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  input     wire                i_sys_clk                       //system clk
 ,input     wire                i_sys_rst_n                     //rst of sys_clk
//=========================================== Input ARI  ==========================================//

//input pkt data form application(ARI)
,input     wire    [519:0]      i_ari_data                     	//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input     wire                 i_ari_data_en                  	//data enable
,input     wire    [111:0]      i_ari_info						//[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,input     wire                 i_ari_info_en                  	//info enable
,output    wire                 o_ari_fifo_alf                 	//fifo almostfull

//=========================================== control signal ===========================================//

,input     wire    [47:0]       i_nacpc_mac                     //the chip's MAC address of NACP control pkt

//=========================================== Output data pkt  ==========================================//
,output     reg     [519:0]     o_dpkt_data                     //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,output     reg                 o_dpkt_data_en                  //data enable
,output     reg     [111:0]     o_dpkt_meta                     //metadata
,output     reg                 o_dpkt_meta_en                  //meta enable
,input      wire                i_dpkt_fifo_alf                 //fifo almostfull

//=========================================== Output control pkt  ==========================================//
,output     reg     [519:0]     o_cpkt_data                 	//[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,output     reg                 o_cpkt_data_en               	//data enable
,output     reg     [255:0]     o_cpkt_meta                  	//metadata
,output     reg                 o_cpkt_meta_en               	//meta enable
,input      wire                i_cpkt_fifo_alf              	//fifo almostfull

//=========================================== debug signal ===========================================//

`ifdef DEBUG_LEVEL0
,output     reg				    o_ari_rfpul                     //the pulse of received frame,i_sys_clk
,output     reg				    o_ari_t0_rfpul                  //the pulse of received frame(type=0x9000),i_sys_clk
,output     reg				    o_ari_t1_rfpul                  //the pulse of received frame(type=0x9001),i_sys_clk
,output     reg				    o_ari_t2_rfpul                  //the pulse of received frame(type=0x9002),i_sys_clk
,output     reg				    o_ari_t3_rfpul                  //the pulse of received frame(type=else),i_sys_clk
,output     reg				    o_dpkt_tfpul                   	//the pulse of transmit data frame,i_sys_clk
,output     reg				    o_cpkt_tfpul                   	//the pulse of transmit control frame,i_sys_clk
`endif

`ifdef DEBUG_LEVEL0
,output     reg				    o_dpkt_dfpul                   	//the pulse of dropped data frame,i_sys_clk
,output     reg				    o_cpkt_dfpul                   	//the pulse of dropped control frame,i_sys_clk
`endif

`ifdef DEBUG_LEVEL2
,output     reg     [31:0]      o_ari_wrusedw					//[31:16]:info_fifo wrusedw,[15:0]:data_fifo wrusedw,i_sys_clk
`endif

`ifdef DEBUG_LEVEL3
,output     reg     [3:0]       o_preparse_cs                   // FSM declarations,i_sys_clk
`endif

,output		reg     [1:0]		e1a                             //active-high,one bit or two bit error is detected(ECC)
,output		reg     [1:0]		e2a                             //active-high,two or more bit error is detected(ECC)

);


//======================================= internal reg&wire declarations =======================================//
//declarations of ari_data_fifo

reg                         r_ari_data_rd                       ;       //rden
wire		[6:0]			w_ari_data_wrusedw                  ;       //wrusedw
wire		[519:0]			w_ari_data_q                        ;       //read data out
wire                        w_ari_data_rdempty                  ;       //rdempty

//declarations of ari_info_fifo

reg			                r_ari_info_rd                       ;       //rden
wire		[6:0]			w_ari_info_wrusedw                  ;       //wrusedw
wire		[111:0]			w_ari_info_q                        ;       //read data out
wire		                w_ari_info_rdempty                  ;       //rdempty
wire		                w_ari_info_rdalempty                ;       //rdalempty

reg			[519:0]         r_ari_data                          ;
reg			                r_first_flag                        ;

wire			            w_mac_match                         ;

//FSM declarations

reg         [3:0]           r_preparse_cs       ;

localparam	IDLE_PREPARSE       =	4'b0000     ,
            FIRST_PREPARSE      =	4'b0001     ,
            NACPD_PREPARSE      =	4'b0010     ,
            NACPDE_PREPARSE     =	4'b0011     ,
            NACPC_PREPARSE      =	4'b0100     ,
            META_PREPARSE       =	4'b0101     ,
            METAE_PREPARSE      =	4'b0110     ,
            SEND_PREPARSE       =	4'b0111     ,
            DISC_PREPARSE       =	4'b1000     ;

//=========================================== assign wire control ===========================================//

assign  o_ari_fifo_alf    =   w_ari_data_wrusedw[6]   ;

assign w_mac_match        =  (w_ari_data_q[511:464] == i_nacpc_mac)    ?  1'b1 :   1'b0  ;
//=========================================== function always block ========================================//

always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_dpkt_data        	<=  520'b0   		;
        o_dpkt_data_en     	<=  1'b0     		;
        o_dpkt_meta        	<=  112'b0   		;
        o_dpkt_meta_en     	<=  1'b0     		;

        o_cpkt_data      	<=  520'b0          ;
        o_cpkt_data_en   	<=  1'b0            ;
        o_cpkt_meta      	<=  256'b0          ;
        o_cpkt_meta_en   	<=  1'b0            ;

        r_ari_data_rd       <=  1'b0            ;
        r_ari_info_rd       <=  1'b0            ;

        r_ari_data          <=  520'b0          ;
        r_first_flag        <=  1'b0            ;

        r_preparse_cs       <=  IDLE_PREPARSE   ;
    end
    else begin
        r_ari_data          <=   w_ari_data_q   ;
        case(r_preparse_cs)
            IDLE_PREPARSE:begin
                o_dpkt_data    		<=  520'b0          ;
                o_dpkt_data_en 		<=  1'b0            ;
                o_dpkt_meta    		<=  112'b0          ;
                o_dpkt_meta_en 		<=  1'b0            ;

                o_cpkt_data      	<=  520'b0          ;
                o_cpkt_data_en   	<=  1'b0            ;
                o_cpkt_meta      	<=  256'b0          ;
                o_cpkt_meta_en   	<=  1'b0            ;

                r_first_flag        <=  1'b0            ;
				
				//info fifo is empty,so wait ...
                if(w_ari_info_rdempty)begin
                    r_ari_data_rd       <=  1'b0            ;
                    r_ari_info_rd       <=  1'b0            ;
                    r_preparse_cs       <=  IDLE_PREPARSE   ;
                end
                else begin
                    //info fifo is not empty, however, (the next frame is a data frame,but the dpkt_fifo is almostfull )  ||(the next frame is a control frame,but the cpkt_fifo is almostfull),so discard ...
                    if(((i_dpkt_fifo_alf == 1'b1) && (w_ari_data_q[383:368] != 16'h9001)) || ((i_cpkt_fifo_alf == 1'b1) && (w_ari_data_q[383:368] == 16'h9001)))begin
                        r_ari_data_rd       <=  1'b1            ;
                        r_ari_info_rd       <=  1'b1            ;
                        r_preparse_cs       <=  DISC_PREPARSE   ;
                    end
                    //start reading the fifo,ready to parse and transmit ...
                    else begin
                        r_ari_data_rd       <=  1'b1            ;
                        r_ari_info_rd       <=  1'b1            ;
                        r_preparse_cs       <=  FIRST_PREPARSE  ;
                    end
                end
            end
            FIRST_PREPARSE:begin
                r_first_flag        <=  1'b1                ;	// the sop flag of frame
                case(w_ari_data_q[383:368])	//the Type of frame
                    16'h9001:begin	//type == 0x9001:control frame(NACP)
                        if(w_mac_match)begin
                            o_dpkt_data          <=  520'b0                              ;
                            o_dpkt_data_en       <=  1'b0                                ;
                            o_dpkt_meta          <=  112'b0                              ;

                            o_cpkt_data      	 <=  w_ari_data_q                        ;          //transmit control frame directly
                            o_cpkt_data_en   	 <=  1'b1                                ;

						    o_cpkt_meta[255:192] <=  w_ari_info_q[95:32]				 ;			//the current timestamp of frame
						    o_cpkt_meta[191:160] <=  32'h0000_0000						 ;			//UD
						    o_cpkt_meta[159:144] <=  16'h0000							 ;			//type in meta
						    o_cpkt_meta[143:136] <=  8'h00               				 ;			//DMID
						    o_cpkt_meta[135:128] <=  8'h00               				 ;			//SMID
						    o_cpkt_meta[127:112] <=  16'h0000               			 ;			//AC
						    o_cpkt_meta[111:107] <=  5'h00               				 ;			//ctrl:rev
						    o_cpkt_meta[106] 	 <=  1'h0								 ; 			//ctrl:parse error flag
						    o_cpkt_meta[105:104] <=  2'h1               				 ;			//ctrl:NACP control frame flag
						    o_cpkt_meta[103: 88] <=  16'h0000               			 ;			//FID
						    o_cpkt_meta[ 87: 80] <=  8'h00               				 ;			//Priority
						    o_cpkt_meta[ 79: 78] <=  2'h0               				 ;			//PL:rev
						    o_cpkt_meta[ 77: 64] <=  w_ari_info_q[109: 96]				 ;			//PL:Pkt_len
						    o_cpkt_meta[ 63: 32] <=  w_ari_info_q[ 31:  0]       		 ;			//OutportBM
						    o_cpkt_meta[ 31:  0] <=  w_ari_info_q[ 31:  0]               ;			//InportBM
                        end
                        else begin
                            o_dpkt_data          <=  w_ari_data_q                        ;          //transmit control frame directly
                            o_dpkt_data_en       <=  1'b1                                ;

						    //o_dpkt_meta[255:192] <=  w_ari_info_q[95:32]				 ;			//the current timestamp of frame
						    //o_dpkt_meta[191:160] <=  32'h0000_0000						 ;			//UD
						    //o_dpkt_meta[159:144] <=  16'h0000							 ;			//type in meta
						    //o_dpkt_meta[143:136] <=  8'h00               				 ;			//DMID
						    //o_dpkt_meta[135:128] <=  8'h00               				 ;			//SMID
						    //o_dpkt_meta[127:112] <=  16'h0000               			 ;			//AC
						    //o_dpkt_meta[111:107] <=  5'h00               				 ;			//ctrl:rev
						    //o_dpkt_meta[106] 	 <=  1'h0								 ; 			//ctrl:parse error flag
						    //o_dpkt_meta[105:104] <=  2'h1               				 ;			//ctrl:NACP control frame flag
						    //o_dpkt_meta[103: 88] <=  16'h0000               			 ;			//FID
						    //o_dpkt_meta[ 87: 80] <=  8'h00               				 ;			//Priority
						    //o_dpkt_meta[ 79: 78] <=  2'h0               				 ;			//PL:rev
						    //o_dpkt_meta[ 77: 64] <=  w_ari_info_q[109: 96]				 ;			//PL:Pkt_len
						    //o_dpkt_meta[ 63: 32] <=  w_ari_info_q[ 31:  0]        		 ;			//OutportBM
						    //o_dpkt_meta[ 31:  0] <=  w_ari_info_q[ 31:  0]               ;			//InportBM
							o_dpkt_meta			 <= w_ari_info_q						;

                            o_cpkt_data      	 <=  520'b0                              ;
                            o_cpkt_data_en   	 <=  1'b0                                ;
                            o_cpkt_meta      	 <=  256'b0                              ;
                        end

                        if(w_ari_data_q[518])begin	//the end of frame(frame <= 64B),transmit current meta ...
                            o_cpkt_meta_en       	<=  w_mac_match         ;
                            o_dpkt_meta_en       	<=  ~w_mac_match        ;
                            if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdalempty)begin	//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                                r_preparse_cs       <=  IDLE_PREPARSE       ;
                                r_ari_data_rd       <=  1'b0                ;
                                r_ari_info_rd       <=  1'b0                ;
                            end
                            else begin	//reading the info&data fifo for next frame &  ready to parse and transmit ...
                                r_preparse_cs       <=  FIRST_PREPARSE      ;
                                r_ari_data_rd       <=  1'b1                ;
                                r_ari_info_rd       <=  1'b1                ;
                            end
                        end
                        else begin	// frame > 64B, reading the data fifo for current frame, and go to transmit the rest of frame data ...
                            o_cpkt_meta_en       	<=  1'b0                ;
                            o_dpkt_meta_en       	<=  1'b0                ;

                            r_ari_data_rd           <=  1'b1                ;
                            r_ari_info_rd           <=  1'b0                ;
                            r_preparse_cs           <=  (w_mac_match ? NACPC_PREPARSE : SEND_PREPARSE)  ;
                        end
                    end
                    default:begin	//other data frame
                        o_dpkt_data          <=  w_ari_data_q                        ;//transmit control frame directly
                        o_dpkt_data_en       <=  1'b1                                ;
						
						//o_dpkt_meta[255:192] <=  w_ari_info_q[95:32]				 ;			//the current timestamp of frame
						//o_dpkt_meta[191:160] <=  32'h0000_0000						 ;			//UD
						//o_dpkt_meta[159:144] <=  16'h0000							 ;			//type in meta
						//o_dpkt_meta[143:136] <=  8'h00               				 ;			//DMID
						//o_dpkt_meta[135:128] <=  8'h00               				 ;			//SMID
						//o_dpkt_meta[127:112] <=  16'h0000               			 ;			//AC
						//o_dpkt_meta[111:107] <=  5'h00               				 ;			//ctrl:rev
						//o_dpkt_meta[106] 	 <=  1'h0								 ; 			//ctrl:parse error flag
						//o_dpkt_meta[105:104] <=  2'h3               				 ;			//ctrl:other frame flag
						//o_dpkt_meta[103: 88] <=  16'h0000               			 ;			//FID
						//o_dpkt_meta[ 87: 80] <=  8'h00               				 ;			//Priority
						//o_dpkt_meta[ 79: 78] <=  2'h0               				 ;			//PL:rev
						//o_dpkt_meta[ 77: 64] <=  w_ari_info_q[109: 96]				 ;			//PL:Pkt_len
						//o_dpkt_meta[ 63: 32] <=  32'h8000_0000               		 ;			//OutportBM
						//o_dpkt_meta[ 31:  0] <=  w_ari_info_q[ 31:  0]               ;			//InportBM
						o_dpkt_meta				<= w_ari_info_q						 ;

                        o_cpkt_data      	 <=  520'b0          ;
                        o_cpkt_data_en   	 <=  1'b0            ;
                        o_cpkt_meta      	 <=  256'b0          ;
                        o_cpkt_meta_en   	 <=  1'b0            ;

                        if(w_ari_data_q[518])begin		//the end of frame(frame <= 64B),transmit current meta ..
                            o_dpkt_meta_en          <=  1'b1                ;
                            if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdalempty)begin	//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                                r_preparse_cs       <=  IDLE_PREPARSE       ;
                                r_ari_data_rd       <=  1'b0                ;
                                r_ari_info_rd       <=  1'b0                ;
                            end
                            else begin	//reading the info&data fifo for next frame &  ready to parse and transmit ...
                                r_preparse_cs       <=  FIRST_PREPARSE      ;
                                r_ari_data_rd       <=  1'b1                ;
                                r_ari_info_rd       <=  1'b1                ;
                            end
                        end
                        else begin	// frame > 64B, reading the data fifo for current frame, and go to transmit the rest of frame data ...
                            o_dpkt_meta_en       	<=  1'b0                ;

                            r_ari_data_rd           <=  1'b1                ;
                            r_ari_info_rd           <=  1'b0                ;
                            r_preparse_cs           <=  SEND_PREPARSE       ;
                        end
                    end
                endcase
            end
            NACPD_PREPARSE:begin
                o_dpkt_data[511:368] <=  r_ari_data[143:0]           	;//the low  18B of last cycle pkt_data
                o_dpkt_data[367:0]   <=  w_ari_data_q[511:144]       	;//the high 46B of current cycle pkt_data
                o_dpkt_meta          <=  o_dpkt_meta                  	;//meta buffer
                o_dpkt_data_en       <=  1'b1                        	;//transmit the 18B + 46B pkt_data

                o_cpkt_data      	 <=  520'b0                      ;
                o_cpkt_data_en   	 <=  1'b0                        ;
                o_cpkt_meta      	 <=  256'b0                      ;
                o_cpkt_meta_en   	 <=  1'b0                        ;

                r_first_flag         <=  1'b0                        ;// the sop flag of frame
                if(w_ari_data_q[518])begin	//the end of frame is read ..
                    if(w_ari_data_q[517:512] >= 6'h12)begin	//valid Bytes of current cycle pkt_data <=46B,so this transmission is the end of current frame
                        o_dpkt_data[519]     <=  r_first_flag                    ;// the sop flag of frame
                        o_dpkt_data[518]     <=  1'b1                            ;// the eop flag of frame
                        o_dpkt_data[517:512] <=  w_ari_data_q[517:512] - 6'h12   ;// Invalid Bytes of frame(-18B)
                        o_dpkt_meta_en       <=  1'b1                            ;//send the meta at the end of frame

                        if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                            r_ari_data_rd       <=  1'b0                        ;
                            r_ari_info_rd       <=  1'b0                        ;
                            r_preparse_cs       <=  IDLE_PREPARSE               ;
                        end
                        else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                            r_ari_data_rd       <=  1'b1                        ;
                            r_ari_info_rd       <=  1'b1                        ;
                            r_preparse_cs       <=  FIRST_PREPARSE              ;
                        end
                    end
                    else begin//valid Bytes of current cycle pkt_data >46B,so the next transmission is the end of current frame
                        o_dpkt_data[519]     <=  r_first_flag                    ;// the sop flag of frame
                        o_dpkt_data[518]     <=  1'b0                            ;// the eop flag of frame
                        o_dpkt_data[517:512] <=  6'h0                            ;// Invalid Bytes of frame(0B)
                        o_dpkt_meta_en       <=  1'b0                            ;//send the meta only at the end of frame

                        r_ari_data_rd       <=  1'b0                            ;//don't read the data FIFO for current frame
                        r_ari_info_rd       <=  1'b0                            ;
                        r_preparse_cs       <=  NACPDE_PREPARSE                 ;//go to send the eop of current frame
                    end
                end
                else begin //the body of frame is read ..
                    o_dpkt_data[519]     <=  r_first_flag            ;// the sop flag of frame
                    o_dpkt_data[518]     <=  1'b0                    ;// the eop flag of frame
                    o_dpkt_data[517:512] <=  6'h0                    ;// Invalid Bytes of frame(0B)
                    o_dpkt_meta_en       <=  1'b0                    ;//send the meta at the end of frame
                    r_ari_data_rd        <=  1'b1                    ;//read the data FIFO for current frame
                    r_ari_info_rd        <=  1'b0                    ;

                    r_preparse_cs        <=  NACPD_PREPARSE          ;//go to send the rest of current frame
                end
            end
            NACPDE_PREPARSE:begin
                o_dpkt_data[519]     <=  1'b0                        ;// the sop flag of frame
                o_dpkt_data[518]     <=  1'b1                        ;// the eop flag of frame
                o_dpkt_data[517:512] <=  r_ari_data[517:512] + 6'h2e ;// Invalid Bytes of frame(+46B)
                o_dpkt_data[511:368] <=  r_ari_data[143:0]           ;//the low of 18B of last cycle pkt_data
                o_dpkt_data[367:0]   <=  368'b0                      ;//the high 46B of current cycle pkt_data
                o_dpkt_meta          <=  o_dpkt_meta                 ;//meta buffer
                o_dpkt_data_en       <=  1'b1                        ;//transmit the 18B pkt_data
                o_dpkt_meta_en       <=  1'b1                        ;//transmit the meta at the end

                o_cpkt_data      <=  520'b0                      ;
                o_cpkt_data_en   <=  1'b0                        ;
                o_cpkt_meta      <=  256'b0                      ;
                o_cpkt_meta_en   <=  1'b0                        ;

                r_first_flag        <=  1'b0                        ;

                if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                    r_ari_data_rd       <=  1'b0                        ;
                    r_ari_info_rd       <=  1'b0                        ;
                    r_preparse_cs       <=  IDLE_PREPARSE               ;
                end
                else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                    r_ari_data_rd       <=  1'b1                        ;
                    r_ari_info_rd       <=  1'b1                        ;
                    r_preparse_cs       <=  FIRST_PREPARSE              ;
                end
            end
            NACPC_PREPARSE:begin
                o_dpkt_data          <=  520'b0                      ;
                o_dpkt_data_en       <=  1'b0                        ;
                o_dpkt_meta          <=  112'b0                      ;
                o_dpkt_meta_en       <=  1'b0                        ;

                o_cpkt_data      	 <=  w_ari_data_q                ;//transmit control frame directly
                o_cpkt_data_en   	 <=  1'b1                        ;
                o_cpkt_meta      	 <=  o_cpkt_meta              	 ;//meta buffer

                r_first_flag         <=  1'b0                        ;// the sop flag of frame

                if(w_ari_data_q[518])begin	//the end of frame is read ..
                    o_cpkt_meta_en   <=  1'b1                    ;//send the meta
                    if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                        r_ari_data_rd       <=  1'b0                        ;
                        r_ari_info_rd       <=  1'b0                        ;
                        r_preparse_cs       <=  IDLE_PREPARSE               ;
                    end
                    else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                        r_ari_data_rd       <=  1'b1                        ;
                        r_ari_info_rd       <=  1'b1                        ;
                        r_preparse_cs       <=  FIRST_PREPARSE              ;
                    end
                end
                else begin //the body of frame is read ..
                    o_cpkt_meta_en   	<=  1'b0                            ;
                    r_ari_data_rd       <=  1'b1                            ;
                    r_ari_info_rd       <=  1'b0                            ;
                    r_preparse_cs       <=  NACPC_PREPARSE                  ;
                end
            end
            META_PREPARSE:begin
                o_dpkt_data[511:256] <=  r_ari_data[255:0]           ;//the low  32B of last cycle pkt_data
                o_dpkt_data[255:0]   <=  w_ari_data_q[511:256]       ;//the high 32B of current cycle pkt_data
                o_dpkt_meta          <=  o_dpkt_meta                 ;//meta buffer
                o_dpkt_data_en       <=  1'b1                        ;//transmit the 32B + 32B pkt_data

                o_cpkt_data      <=  520'b0                      ;
                o_cpkt_data_en   <=  1'b0                        ;
                o_cpkt_meta      <=  256'b0                      ;
                o_cpkt_meta_en   <=  1'b0                        ;

                r_first_flag        <=  1'b0                        ;// the sop flag of frame

                if(w_ari_data_q[518])begin	//the end of frame is read ..
                    if(w_ari_data_q[517])begin//valid Bytes of current cycle pkt_data <=32B,so this transmission is the end of current frame
                        o_dpkt_data[519]     <=  r_first_flag                    ;// the sop flag of frame
                        o_dpkt_data[518]     <=  1'b1                            ;// the eop flag of frame
                        o_dpkt_data[517:512] <=  w_ari_data_q[517:512] - 6'h20   ;// Invalid Bytes of frame(-32B)
                        o_dpkt_meta_en       <=  1'b1                            ;//send the meta at the end of frame

                        if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                            r_ari_data_rd       <=  1'b0                        ;
                            r_ari_info_rd       <=  1'b0                        ;
                            r_preparse_cs       <=  IDLE_PREPARSE               ;
                        end
                        else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                            r_ari_data_rd       <=  1'b1                        ;
                            r_ari_info_rd       <=  1'b1                        ;
                            r_preparse_cs       <=  FIRST_PREPARSE              ;
                        end
                    end
                    else begin//valid Bytes of current cycle pkt_data >32B,so the next transmission is the end of current frame
                        o_dpkt_data[519]     <=  r_first_flag                    ;// the sop flag of frame
                        o_dpkt_data[518]     <=  1'b0                            ;// the eop flag of frame
                        o_dpkt_data[517:512] <=  6'h0                            ;// Invalid Bytes of frame(0B)
                        o_dpkt_meta_en       <=  1'b0                            ;//send the meta at the end of frame

                        r_ari_data_rd       <=  1'b0                            ;//don't read the data FIFO for current frame
                        r_ari_info_rd       <=  1'b0                            ;
                        r_preparse_cs       <=  METAE_PREPARSE                  ;//go to send the eop of current frame
                    end
                end
                else begin	//the body of frame is read ..
                    o_dpkt_data[519]     <=  r_first_flag            ;// the sop flag of frame
                    o_dpkt_data[518]     <=  1'b0                    ;// the eop flag of frame
                    o_dpkt_data[517:512] <=  6'h0                    ;// Invalid Bytes of frame(0B)
                    o_dpkt_meta_en       <=  1'b0                    ;//send the meta at the end of frame
                    r_ari_data_rd        <=  1'b1                    ;//read the data FIFO for current frame
                    r_ari_info_rd        <=  1'b0                    ;

                    r_preparse_cs        <=  META_PREPARSE           ;//go to send the rest of current frame
                end
            end
            METAE_PREPARSE:begin
                o_dpkt_data[519]     <=  1'b0                        ;// the sop flag of frame
                o_dpkt_data[518]     <=  1'b1                        ;// the eop flag of frame
                o_dpkt_data[517:512] <=  r_ari_data[517:512] + 6'h20 ;// Invalid Bytes of frame(+32B)
                o_dpkt_data[511:256] <=  r_ari_data[255:0]           ;//the low of 32B of last cycle pkt_data
                o_dpkt_data[255:0]   <=  256'b0                      ;//the high 32B of current cycle pkt_data
                o_dpkt_meta          <=  o_dpkt_meta                 ;//meta buffer
                o_dpkt_data_en       <=  1'b1                        ;//transmit the 32B pkt_data
                o_dpkt_meta_en       <=  1'b1                        ;//transmit the meta at the end

                o_cpkt_data      <=  520'b0                      ;
                o_cpkt_data_en   <=  1'b0                        ;
                o_cpkt_meta      <=  256'b0                      ;
                o_cpkt_meta_en   <=  1'b0                        ;

                r_first_flag        <=  1'b0                        ;// the sop flag of frame

                if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                    r_ari_data_rd       <=  1'b0                        ;
                    r_ari_info_rd       <=  1'b0                        ;
                    r_preparse_cs       <=  IDLE_PREPARSE               ;
                end
                else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                    r_ari_data_rd       <=  1'b1                        ;
                    r_ari_info_rd       <=  1'b1                        ;
                    r_preparse_cs       <=  FIRST_PREPARSE              ;
                end
            end
            SEND_PREPARSE:begin
                o_dpkt_data          <=  w_ari_data_q                ;//transmit other data frame directly
                o_dpkt_data_en       <=  1'b1                        ;
                o_dpkt_meta          <=  o_dpkt_meta                 ;//meta buffer
                
                o_cpkt_data      <=  520'b0                      ;
                o_cpkt_data_en   <=  1'b0                        ;
                o_cpkt_meta      <=  256'b0                      ;
                o_cpkt_meta_en   <=  1'b0                        ;

                r_first_flag        <=  1'b0                        ;// the sop flag of frame

                if(w_ari_data_q[518])begin	//the end of frame is read ..
                    o_dpkt_meta_en           <=  1'b1                    ;//send the meta
                    if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                        r_ari_data_rd       <=  1'b0                        ;
                        r_ari_info_rd       <=  1'b0                        ;
                        r_preparse_cs       <=  IDLE_PREPARSE               ;
                    end
                    else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                        r_ari_data_rd       <=  1'b1                        ;
                        r_ari_info_rd       <=  1'b1                        ;
                        r_preparse_cs       <=  FIRST_PREPARSE              ;
                    end
                end
                else begin//the body of frame is read ..
                    o_dpkt_meta_en      <=  1'b0                            ;
                    r_ari_data_rd       <=  1'b1                            ;
                    r_ari_info_rd       <=  1'b0                            ;
                    r_preparse_cs       <=  SEND_PREPARSE                   ;
                end
            end
            DISC_PREPARSE:begin
                o_dpkt_data        	<=  520'b0   		            ;
                o_dpkt_data_en     	<=  1'b0     		            ;
                o_dpkt_meta        	<=  112'b0   		            ;
                o_dpkt_meta_en     	<=  1'b0     		            ;
                
                o_cpkt_data         <=  520'b0                      ;
                o_cpkt_data_en      <=  1'b0                        ;
                o_cpkt_meta         <=  256'b0                      ;
                o_cpkt_meta_en      <=  1'b0                        ;

                r_first_flag        <=  1'b0                        ;// the sop flag of frame

                if(w_ari_data_q[518])begin	//the end of frame is read ..
                    if(i_dpkt_fifo_alf | i_cpkt_fifo_alf | w_ari_info_rdempty)begin//the dpkt_fifo or cpkt_fifo is almostfull or the info_fifo is alempty,go to wait ...
                        r_ari_data_rd       <=  1'b0                        ;
                        r_ari_info_rd       <=  1'b0                        ;
                        r_preparse_cs       <=  IDLE_PREPARSE               ;
                    end
                    else begin//reading the info&data fifo for next frame &  ready to parse and transmit ...
                        r_ari_data_rd       <=  1'b1                        ;
                        r_ari_info_rd       <=  1'b1                        ;
                        r_preparse_cs       <=  FIRST_PREPARSE              ;
                    end
                end
                else begin//the body of frame is read ..
                    r_ari_data_rd       <=  1'b1                        ;
                    r_ari_info_rd       <=  1'b0                        ;
                    r_preparse_cs       <=  DISC_PREPARSE               ;
                end
            end
            default:begin
                o_dpkt_data          <=  520'b0          ;
                o_dpkt_data_en       <=  1'b0            ;
                o_dpkt_meta          <=  112'b0          ;
                o_dpkt_meta_en       <=  1'b0            ;

                o_cpkt_data      <=  520'b0          ;
                o_cpkt_data_en   <=  1'b0            ;
                o_cpkt_meta      <=  256'b0          ;
                o_cpkt_meta_en   <=  1'b0            ;

                r_first_flag        <=  1'b0            ;
                r_ari_data_rd       <=  1'b1            ;
                r_ari_info_rd       <=  1'b0            ;
                r_preparse_cs       <=  IDLE_PREPARSE   ;
            end
        endcase
    end
end


//======================================= debug function always block =======================================//

`ifdef DEBUG_LEVEL0
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_ari_rfpul         <=  1'b0          	;
        o_dpkt_tfpul        <=  1'b0          	;
        o_cpkt_tfpul       	<=  1'b0          	;
    end
    else begin
        o_ari_rfpul     	<=  i_ari_info_en	;
        o_dpkt_tfpul   		<=  o_dpkt_meta_en 	;
        o_cpkt_tfpul   		<=  o_cpkt_meta_en 	;
    end
end

always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_ari_t0_rfpul      <=  1'b0          	;
        o_ari_t1_rfpul      <=  1'b0          	;
        o_ari_t2_rfpul      <=  1'b0          	;
        o_ari_t3_rfpul      <=  1'b0          	;
    end
    else begin
        if(r_preparse_cs == FIRST_PREPARSE)begin
            case(w_ari_data_q[415:400])
                16'h9000:begin
                    o_ari_t0_rfpul <= 1'b1;
                    o_ari_t1_rfpul <= 1'b0;
                    o_ari_t2_rfpul <= 1'b0;
                    o_ari_t3_rfpul <= 1'b0;
                end
                16'h9001:begin
                    o_ari_t0_rfpul <= 1'b0;
                    o_ari_t1_rfpul <= 1'b1;
                    o_ari_t2_rfpul <= 1'b0;
                    o_ari_t3_rfpul <= 1'b0;
                end
                16'h9002:begin
                    o_ari_t0_rfpul <= 1'b0;
                    o_ari_t1_rfpul <= 1'b0;
                    o_ari_t2_rfpul <= 1'b1;
                    o_ari_t3_rfpul <= 1'b0;
                end
                default:begin
                    o_ari_t0_rfpul <= 1'b0;
                    o_ari_t1_rfpul <= 1'b0;
                    o_ari_t2_rfpul <= 1'b0;
                    o_ari_t3_rfpul <= 1'b1;
                end
            endcase
        end
        else begin
            o_ari_t0_rfpul <= 1'b0;
            o_ari_t1_rfpul <= 1'b0;
            o_ari_t2_rfpul <= 1'b0;
            o_ari_t3_rfpul <= 1'b0;
        end
    end
end
`endif

`ifdef DEBUG_LEVEL0
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_dpkt_dfpul        <=  1'b0          	;
        o_cpkt_dfpul       	<=  1'b0          	;
    end
    else begin
        o_dpkt_dfpul   		<=  ((r_preparse_cs == DISC_PREPARSE) && (w_ari_data_q[519] == 1'b1) && (w_ari_data_q[383:368] != 16'h9001))    ;
        o_cpkt_dfpul   		<=  ((r_preparse_cs == DISC_PREPARSE) && (w_ari_data_q[519] == 1'b1) && (w_ari_data_q[383:368] == 16'h9001))    ;
    end
end
`endif

`ifdef DEBUG_LEVEL2
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_ari_wrusedw   <=  32'b0          ;
    end
    else begin
        o_ari_wrusedw   <=  {9'b0,w_ari_info_wrusedw,9'b0,w_ari_data_wrusedw};
    end
end
`endif

`ifdef DEBUG_LEVEL3
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_preparse_cs  <=  4'b0           ;
    end
    else begin
        o_preparse_cs  <=  r_preparse_cs  ;
    end
end
`endif

SYNCFIFO_128X520 ari_data_fifo(
			.srst				(~i_sys_rst_n					),
			.din				(i_ari_data 					),
			.rd_en				(r_ari_data_rd				    ),
			.clk				(i_sys_clk						),
			.wr_en				(i_ari_data_en  				),
			.dout				(w_ari_data_q   				),
			.empty				(w_ari_data_rdempty             ),
			.data_count			(w_ari_data_wrusedw             )
);

SYNCFIFO_128x112 ari_info_fifo(
			.srst				(~i_sys_rst_n					),
			.din				(i_ari_info					    ),
			.rd_en				(r_ari_info_rd				    ),
			.clk				(i_sys_clk						),
			.wr_en				(i_ari_info_en				    ),
			.dout				(w_ari_info_q				    ),
			.empty				(w_ari_info_rdempty             ),
            .almost_empty		(w_ari_info_rdalempty   		),
			.data_count			(w_ari_info_wrusedw             )			
);


endmodule

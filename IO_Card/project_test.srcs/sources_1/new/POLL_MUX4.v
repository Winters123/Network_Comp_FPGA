/*========================================================================================================*\
          Filename : POLL_MUX4.v
            Author : zc
       Description : 
	     Called by : 
  Revision History : 06/12/2020 Revision 1.0  zc
					 09/02/2020 Revision 1.1  zc
           Company : 662
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module POLL_MUX4
#(
parameter   poll_priority           =   1'b0    //priority_level: port0 > port1 > port2 > port3
)
(
    
//============================================== clk & rst ===========================================//

//system clock & resets
  input     wire                i_sys_clk                   //system clk
 ,input     wire                i_sys_rst_n                 //rst of sys_clk
//=========================================== Input ARI*4  ==========================================//

//input pkt data form ARI
,input     wire    [519:0]     i_ari_0_data                   //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input     wire                i_ari_0_data_en                //data enable
,input     wire    [111:0]     i_ari_0_info                   //[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,input     wire                i_ari_0_info_en                //info enable
,output    wire                o_ari_0_fifo_alf               //fifo almostfull

,input     wire    [519:0]     i_ari_1_data                   //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input     wire                i_ari_1_data_en                //data enable
,input     wire    [111:0]     i_ari_1_info                   //[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,input     wire                i_ari_1_info_en                //info enable
,output    wire                o_ari_1_fifo_alf               //fifo almostfull

,input     wire    [519:0]     i_ari_2_data                   //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input     wire                i_ari_2_data_en                //data enable
,input     wire    [111:0]     i_ari_2_info                   //[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,input     wire                i_ari_2_info_en                //info enable
,output    wire                o_ari_2_fifo_alf               //fifo almostfull

,input     wire    [519:0]     i_ari_3_data                   //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,input     wire                i_ari_3_data_en                //data enable
,input     wire    [111:0]     i_ari_3_info                   //[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,input     wire                i_ari_3_info_en                //info enable
,output    wire                o_ari_3_fifo_alf               //fifo almostfull

//=========================================== Output ARI  ==========================================//
,output     reg     [519:0]     o_ari_data                   //[519:518]:10 head \ 00 body \ 01 tail\,[517:512]:invalid bytes,[511:0],data
,output     reg                 o_ari_data_en                //data enable
,output     reg     [111:0]     o_ari_info                   //[111]:pkt valid,[110]:rev,[109:96]:PL,[95:32]:TSM,[31:0]:InportBM
,output     reg                 o_ari_info_en                //info enable
,input      wire                i_ari_fifo_alf               //fifo almostfull
//=========================================== debug signal ===========================================//

`ifdef DEBUG_LEVEL0
,output     reg				    o_ari_0_rfpul                 //the pulse of received frame,i_sys_clk
,output     reg				    o_ari_1_rfpul                 //the pulse of received frame,i_sys_clk
,output     reg				    o_ari_2_rfpul                 //the pulse of received frame,i_sys_clk
,output     reg				    o_ari_3_rfpul                 //the pulse of received frame,i_sys_clk

,output     reg				    o_ari_tfpul                   //the pulse of transmit frame,i_sys_clk
`endif

`ifdef DEBUG_LEVEL2
,output     reg     [31:0]      o_ari_0_wrusedw               //[31:16]:o_ari_info wrusedw,[15:0]:ari_data_fifo wrusedw,i_sys_clk
,output     reg     [31:0]      o_ari_1_wrusedw               //[31:16]:o_ari_info wrusedw,[15:0]:ari_data_fifo wrusedw,i_sys_clk
,output     reg     [31:0]      o_ari_2_wrusedw               //[31:16]:o_ari_info wrusedw,[15:0]:ari_data_fifo wrusedw,i_sys_clk
,output     reg     [31:0]      o_ari_3_wrusedw               //[31:16]:o_ari_info wrusedw,[15:0]:ari_data_fifo wrusedw,i_sys_clk
`endif

`ifdef DEBUG_LEVEL3
,output     reg     [0:0]       o_poll_mux4_cs					// FSM declarations,i_sys_clk
`endif

,output		reg     [7:0]		e1a                             //active-high,one bit or two bit error is detected(ECC)
,output		reg     [7:0]		e2a                             //active-high,two or more bit error is detected(ECC)

);

//======================================= internal reg&wire declarations =======================================//
//declarations of ari_data_fifo

reg         [3:0]           r_ari_data_rd                		;       //rden
wire		[6:0]			w_ari_data_wrusedw 		[3:0]		;       //wrusedw
wire		[519:0]			w_ari_data_q       		[3:0]		;       //read data out
wire        [3:0]           w_ari_data_rdempty           		;       //rdempty

//declarations of ari_info_fifo

reg			[3:0]           r_ari_info_rd                     	;       //rden
wire		[6:0]			w_ari_info_wrusedw      [3:0]     	;       //wrusedw
wire		[111:0]			w_ari_info_q            [3:0]     	;       //read data out
wire		[3:0]           w_ari_info_rdempty                	;       //rdempty
wire		[3:0]           w_ari_info_rdalempty              	;       //rdalempty


wire		[3:0]           w_port_vbm							;       //port valid bitmap
reg		    [3:0]           r_mask_be                         	;       //mask bitenable
reg         [3:0]           r_poll_bm                         	;       //poll bitmap
reg         [3:0]           rr_poll_bm                        	;       //poll bitmap reg


//FSM declarations

reg         [0:0]           r_poll_mux4_cs      ;

localparam	IDLE_POLL_MUX4      =	1'b0        ,
            SEND_POLL_MUX4      =	1'b1        ;

//=========================================== assign wire control ===========================================//

assign  o_ari_0_fifo_alf    =   w_ari_data_wrusedw[0][6]   ;		//4KB
assign  o_ari_1_fifo_alf    =   w_ari_data_wrusedw[1][6]   ;		//4KB
assign  o_ari_2_fifo_alf    =   w_ari_data_wrusedw[2][6]   ;		//4KB
assign  o_ari_3_fifo_alf    =   w_ari_data_wrusedw[3][6]   ;		//4KB

assign w_port_vbm			=   (~w_ari_info_rdempty) & (~r_mask_be)    ;	//port valid bitmap

always @(*)  begin
    if(poll_priority)begin									//SP
        r_poll_bm   =   ~w_ari_info_rdempty ;
    end
    else begin												//RR
        if(|w_port_vbm)begin
            r_poll_bm       =   w_port_vbm				;
        end
        else begin
            r_poll_bm       =   ~w_ari_info_rdempty     ;
        end
    end
end


//=========================================== function always block ==========================================//

always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_ari_data          <=  520'b0          ;
        o_ari_data_en       <=  1'b0            ;
        o_ari_info          <=  112'b0          ;
        o_ari_info_en       <=  1'b0            ;

        r_ari_data_rd       <=  4'b0            ;
        r_ari_info_rd       <=  4'b0            ;

        r_mask_be           <=  4'b0            ;
        rr_poll_bm          <=  4'b0            ;

        r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
    end
    else begin
        case(r_poll_mux4_cs)
            IDLE_POLL_MUX4:begin
                o_ari_data          <=  520'b0          ;
                o_ari_data_en       <=  1'b0            ;
                o_ari_info          <=  112'b0          ;
                o_ari_info_en       <=  1'b0            ;

                rr_poll_bm          <=  r_poll_bm       ;

                if(i_ari_fifo_alf)begin//fifo almostfull,wait
                    r_ari_data_rd       <=  4'b0000         ;
                    r_ari_info_rd       <=  4'b0000         ;
                    r_mask_be           <=  r_mask_be       ;
                    r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                end
                else begin
                    case(r_poll_bm)//priority_level: port0 > port1 > port2 > port3
                        4'b0001,4'b0011,4'b0101,4'b0111,4'b1001,4'b1011,4'b1101,4'b1111:begin
                            r_ari_data_rd       <=  4'b0001         ;
                            r_ari_info_rd       <=  4'b0001         ;
                            r_mask_be           <=  4'b0001         ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                        4'b0010,4'b0110,4'b1010,4'b1110:begin
                            r_ari_data_rd       <=  4'b0010         ;
                            r_ari_info_rd       <=  4'b0010         ;
                            r_mask_be           <=  4'b0011         ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                        4'b0100,4'b1100:begin
                            r_ari_data_rd       <=  4'b0100         ;
                            r_ari_info_rd       <=  4'b0100         ;
                            r_mask_be           <=  4'b0111         ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                        4'b1000:begin
                            r_ari_data_rd       <=  4'b1000         ;
                            r_ari_info_rd       <=  4'b1000         ;
                            r_mask_be           <=  4'b1111         ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                        default:begin
                            r_ari_data_rd       <=  4'b0000         ;
                            r_ari_info_rd       <=  4'b0000         ;
                            r_mask_be           <=  4'b0000         ;
                            r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                        end
                    endcase
                end
            end
            SEND_POLL_MUX4:begin
                case(rr_poll_bm)//priority_level: port0 > port1 > port2 > port3
                    4'b0001,4'b0011,4'b0101,4'b0111,4'b1001,4'b1011,4'b1101,4'b1111:begin
                        o_ari_data          <=  w_ari_data_q[0] ;
                        o_ari_data_en       <=  1'b1            ;

                        if(r_ari_info_rd[0])begin//info buffer
                            o_ari_info          <=  w_ari_info_q[0]             ;
                        end
                        else begin
                            o_ari_info          <=  o_ari_info                  ;
                        end

                        if(w_ari_data_q[0][518])begin//the end of frame
                            o_ari_info_en       <=  1'b1            ;//transmit the info of frame
                            rr_poll_bm          <=  r_poll_bm       ;
                            if(i_ari_fifo_alf)begin
                                r_ari_data_rd       <=  4'b0000         ;
                                r_ari_info_rd       <=  4'b0000         ;
                                r_mask_be           <=  r_mask_be       ;
                                r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                            end
                            else begin
                                case(r_poll_bm)
                                    4'b0001,4'b0011,4'b0101,4'b0111,4'b1001,4'b1011,4'b1101,4'b1111:begin
                                        if(w_ari_info_rdalempty[0] & w_ari_data_q[0][519])begin//the current frame <=64B && the next and current frame are from the same FIFO && rdalempty,so go to DILE
                                            r_ari_data_rd       <=  4'b0000         ;
                                            r_ari_info_rd       <=  4'b0000         ;
                                            r_mask_be           <=  r_mask_be       ;
                                            r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                        end
                                        else begin
                                            r_ari_data_rd       <=  4'b0001         ;
                                            r_ari_info_rd       <=  4'b0001         ;
                                            r_mask_be           <=  4'b0001         ;
                                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                        end
                                    end
                                    4'b0010,4'b0110,4'b1010,4'b1110:begin
                                        r_ari_data_rd       <=  4'b0010         ;
                                        r_ari_info_rd       <=  4'b0010         ;
                                        r_mask_be           <=  4'b0011         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b0100,4'b1100:begin
                                        r_ari_data_rd       <=  4'b0100         ;
                                        r_ari_info_rd       <=  4'b0100         ;
                                        r_mask_be           <=  4'b0111         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b1000:begin
                                        r_ari_data_rd       <=  4'b1000         ;
                                        r_ari_info_rd       <=  4'b1000         ;
                                        r_mask_be           <=  4'b1111         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    default:begin
                                        r_ari_data_rd       <=  4'b0000         ;
                                        r_ari_info_rd       <=  4'b0000         ;
                                        r_mask_be           <=  4'b0000         ;
                                        r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                    end
                                endcase
                            end
                        end
                        else begin
                            o_ari_info_en       <=  1'b0            ;
                            r_ari_data_rd       <=  r_ari_data_rd   ;
                            r_ari_info_rd       <=  4'b0000         ;
                            r_mask_be           <=  r_mask_be       ;
                            rr_poll_bm          <=  rr_poll_bm      ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                    end
                    4'b0010,4'b0110,4'b1010,4'b1110:begin
                        o_ari_data          <=  w_ari_data_q[1] ;
                        o_ari_data_en       <=  1'b1            ;

                        if(r_ari_info_rd[1])begin
                            o_ari_info          <=  w_ari_info_q[1]             ;
                        end
                        else begin
                            o_ari_info          <=  o_ari_info                  ;
                        end

                        if(w_ari_data_q[1][518])begin
                            o_ari_info_en       <=  1'b1            ;
                            rr_poll_bm          <=  r_poll_bm       ;
                            if(i_ari_fifo_alf)begin
                                r_ari_data_rd       <=  4'b0000         ;
                                r_ari_info_rd       <=  4'b0000         ;
                                r_mask_be           <=  r_mask_be       ;
                                r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                            end
                            else begin
                                case(r_poll_bm)
                                    4'b0001,4'b0011,4'b0101,4'b0111,4'b1001,4'b1011,4'b1101,4'b1111:begin
                                        r_ari_data_rd       <=  4'b0001         ;
                                        r_ari_info_rd       <=  4'b0001         ;
                                        r_mask_be           <=  4'b0001         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b0010,4'b0110,4'b1010,4'b1110:begin
                                        if(w_ari_info_rdalempty[1] & w_ari_data_q[1][519])begin//the current frame <=64B && the next and current frame are from the same FIFO && rdalempty,so go to DILE
                                            r_ari_data_rd       <=  4'b0000         ;
                                            r_ari_info_rd       <=  4'b0000         ;
                                            r_mask_be           <=  r_mask_be       ;
                                            r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                        end
                                        else begin
                                            r_ari_data_rd       <=  4'b0010         ;
                                            r_ari_info_rd       <=  4'b0010         ;
                                            r_mask_be           <=  4'b0011         ;
                                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                        end
                                    end
                                    4'b0100,4'b1100:begin
                                        r_ari_data_rd       <=  4'b0100         ;
                                        r_ari_info_rd       <=  4'b0100         ;
                                        r_mask_be           <=  4'b0111         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b1000:begin
                                        r_ari_data_rd       <=  4'b1000         ;
                                        r_ari_info_rd       <=  4'b1000         ;
                                        r_mask_be           <=  4'b1111         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    default:begin
                                        r_ari_data_rd       <=  4'b0000         ;
                                        r_ari_info_rd       <=  4'b0000         ;
                                        r_mask_be           <=  4'b0000         ;
                                        r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                    end
                                endcase
                            end
                        end
                        else begin
                            o_ari_info_en       <=  1'b0            ;
                            r_ari_data_rd       <=  r_ari_data_rd   ;
                            r_ari_info_rd       <=  4'b0000         ;
                            r_mask_be           <=  r_mask_be       ;
                            rr_poll_bm          <=  rr_poll_bm      ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                    end
                   4'b0100,4'b1100:begin
                        o_ari_data          <=  w_ari_data_q[2] ;
                        o_ari_data_en       <=  1'b1            ;

                        if( r_ari_info_rd[2])begin
                            o_ari_info          <=  w_ari_info_q[2]             ;
                        end
                        else begin
                            o_ari_info          <=  o_ari_info                  ;
                        end

                        if(w_ari_data_q[2][518])begin
                            o_ari_info_en       <=  1'b1            ;
                            rr_poll_bm          <=  r_poll_bm       ;
                            if(i_ari_fifo_alf)begin
                                r_ari_data_rd       <=  4'b0000         ;
                                r_ari_info_rd       <=  4'b0000         ;
                                r_mask_be           <=  r_mask_be       ;
                                r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                            end
                            else begin
                                case(r_poll_bm)
                                    4'b0001,4'b0011,4'b0101,4'b0111,4'b1001,4'b1011,4'b1101,4'b1111:begin
                                        r_ari_data_rd       <=  4'b0001         ;
                                        r_ari_info_rd       <=  4'b0001         ;
                                        r_mask_be           <=  4'b0001         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b0010,4'b0110,4'b1010,4'b1110:begin
                                        r_ari_data_rd       <=  4'b0010         ;
                                        r_ari_info_rd       <=  4'b0010         ;
                                        r_mask_be           <=  4'b0011         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b0100,4'b1100:begin
                                        if(w_ari_info_rdalempty[2] & w_ari_data_q[2][519])begin//the current frame <=64B && the next and current frame are from the same FIFO && rdalempty,so go to DILE
                                            r_ari_data_rd       <=  4'b0000         ;
                                            r_ari_info_rd       <=  4'b0000         ;
                                            r_mask_be           <=  r_mask_be       ;
                                            r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                        end
                                        else begin
                                            r_ari_data_rd       <=  4'b0100         ;
                                            r_ari_info_rd       <=  4'b0100         ;
                                            r_mask_be           <=  4'b0111         ;
                                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                        end
                                    end
                                    4'b1000:begin
                                        r_ari_data_rd       <=  4'b1000         ;
                                        r_ari_info_rd       <=  4'b1000         ;
                                        r_mask_be           <=  4'b1111         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    default:begin
                                        r_ari_data_rd       <=  4'b0000         ;
                                        r_ari_info_rd       <=  4'b0000         ;
                                        r_mask_be           <=  4'b0000         ;
                                        r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                    end
                                endcase
                            end
                        end
                        else begin
                            o_ari_info_en       <=  1'b0            ;
                            r_ari_data_rd       <=  r_ari_data_rd   ;
                            r_ari_info_rd       <=  4'b0000         ;
                            r_mask_be           <=  r_mask_be       ;
                            rr_poll_bm          <=  rr_poll_bm      ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                    end
                    4'b1000:begin
                        o_ari_data          <=  w_ari_data_q[3] ;
                        o_ari_data_en       <=  1'b1            ;

                        if(r_ari_info_rd[3])begin
                            o_ari_info          <=  w_ari_info_q[3]             ;
                        end
                        else begin
                            o_ari_info          <=  o_ari_info                  ;
                        end

                        if(w_ari_data_q[3][518])begin
                            o_ari_info_en       <=  1'b1            ;
                            rr_poll_bm          <=  r_poll_bm       ;
                            if(i_ari_fifo_alf)begin
                                r_ari_data_rd       <=  4'b0000         ;
                                r_ari_info_rd       <=  4'b0000         ;
                                r_mask_be           <=  r_mask_be       ;
                                r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                            end
                            else begin
                                case(r_poll_bm)
                                    4'b0001,4'b0011,4'b0101,4'b0111,4'b1001,4'b1011,4'b1101,4'b1111:begin
                                        r_ari_data_rd       <=  4'b0001         ;
                                        r_ari_info_rd       <=  4'b0001         ;
                                        r_mask_be           <=  4'b0001         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b0010,4'b0110,4'b1010,4'b1110:begin
                                        r_ari_data_rd       <=  4'b0010         ;
                                        r_ari_info_rd       <=  4'b0010         ;
                                        r_mask_be           <=  4'b0011         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b0100,4'b1100:begin
                                        r_ari_data_rd       <=  4'b0100         ;
                                        r_ari_info_rd       <=  4'b0100         ;
                                        r_mask_be           <=  4'b0111         ;
                                        r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                    end
                                    4'b1000:begin
                                        if(w_ari_info_rdalempty[3] & w_ari_data_q[3][519])begin//the current frame <=64B && the next and current frame are from the same FIFO && rdalempty,so go to DILE
                                            r_ari_data_rd       <=  4'b0000         ;
                                            r_ari_info_rd       <=  4'b0000         ;
                                            r_mask_be           <=  r_mask_be       ;
                                            r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                        end
                                        else begin
                                            r_ari_data_rd       <=  4'b1000         ;
                                            r_ari_info_rd       <=  4'b1000         ;
                                            r_mask_be           <=  4'b1111         ;
                                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                                        end
                                    end
                                    default:begin
                                        r_ari_data_rd       <=  4'b0000         ;
                                        r_ari_info_rd       <=  4'b0000         ;
                                        r_mask_be           <=  4'b0000         ;
                                        r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                                    end
                                endcase
                            end
                        end
                        else begin
                            o_ari_info_en       <=  1'b0            ;
                            r_ari_data_rd       <=  r_ari_data_rd   ;
                            r_ari_info_rd       <=  4'b0000         ;
                            r_mask_be           <=  r_mask_be       ;
                            rr_poll_bm          <=  rr_poll_bm      ;
                            r_poll_mux4_cs      <=  SEND_POLL_MUX4  ;
                        end
                    end
                    default:begin														//error
                        o_ari_data          <=  520'b0          ;
                        o_ari_data_en       <=  1'b0            ;
                        o_ari_info          <=  112'b0          ;
                        o_ari_info_en       <=  1'b0            ;

                        r_ari_data_rd       <=  4'b0000         ;
                        r_ari_info_rd       <=  4'b0000         ;
                        r_mask_be           <=  4'b0000         ;
                        rr_poll_bm          <=  r_poll_bm       ;
                        r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
                    end
                endcase
            end
            default:begin
                o_ari_data          <=  520'b0          ;
                o_ari_data_en       <=  1'b0            ;
                o_ari_info          <=  112'b0          ;
                o_ari_info_en       <=  1'b0            ;

                r_ari_data_rd       <=  4'b0000         ;
                r_ari_info_rd       <=  4'b0000         ;
                r_mask_be           <=  4'b0000         ;
                rr_poll_bm          <=  r_poll_bm       ;
                r_poll_mux4_cs      <=  IDLE_POLL_MUX4  ;
            end
        endcase
    end
end




//======================================= debug function always block =======================================//

`ifdef DEBUG_LEVEL0
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_ari_0_rfpul           <=  1'b0          	;
        o_ari_1_rfpul           <=  1'b0          	;
        o_ari_2_rfpul           <=  1'b0          	;
        o_ari_3_rfpul           <=  1'b0          	;
        o_ari_tfpul             <=  1'b0          	;
    end
    else begin
        o_ari_0_rfpul   		<=  i_ari_0_info_en	;
        o_ari_1_rfpul   		<=  i_ari_1_info_en	;
        o_ari_2_rfpul   		<=  i_ari_2_info_en	;
        o_ari_3_rfpul   		<=  i_ari_3_info_en	;
        o_ari_tfpul     		<=  o_ari_info_en	;
    end
end
`endif

`ifdef DEBUG_LEVEL2
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_ari_0_wrusedw        <=  32'b0          ;
        o_ari_1_wrusedw        <=  32'b0          ;
        o_ari_2_wrusedw        <=  32'b0          ;
        o_ari_3_wrusedw        <=  32'b0          ;
    end
    else begin
        o_ari_0_wrusedw <=  {9'b0,w_ari_info_wrusedw[0],9'b0,w_ari_data_wrusedw[0]};
        o_ari_1_wrusedw <=  {9'b0,w_ari_info_wrusedw[1],9'b0,w_ari_data_wrusedw[1]};
        o_ari_2_wrusedw <=  {9'b0,w_ari_info_wrusedw[2],9'b0,w_ari_data_wrusedw[2]};
        o_ari_3_wrusedw <=  {9'b0,w_ari_info_wrusedw[3],9'b0,w_ari_data_wrusedw[3]};
    end
end
`endif

`ifdef DEBUG_LEVEL3
always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        o_poll_mux4_cs  <=  1'b0            ;
    end
    else begin
        o_poll_mux4_cs  <=  r_poll_mux4_cs  ;
    end
end
`endif

//=========================================== fifo instantiations ==========================================//

wire        [519:0]     w_ari_data        [3:0]     ;
wire        [3:0]       w_ari_data_en          		;
wire        [111:0]     w_ari_info        [3:0]     ;
wire        [3:0]		w_ari_info_en				;

assign  w_ari_data[0]       =   i_ari_0_data        ;
assign  w_ari_data[1]       =   i_ari_1_data        ;
assign  w_ari_data[2]       =   i_ari_2_data        ;
assign  w_ari_data[3]       =   i_ari_3_data        ;

assign  w_ari_data_en[0]    =   i_ari_0_data_en     ;
assign  w_ari_data_en[1]    =   i_ari_1_data_en     ;
assign  w_ari_data_en[2]    =   i_ari_2_data_en     ;
assign  w_ari_data_en[3]    =   i_ari_3_data_en     ;

assign  w_ari_info[0]       =   i_ari_0_info        ;
assign  w_ari_info[1]       =   i_ari_1_info        ;
assign  w_ari_info[2]       =   i_ari_2_info        ;
assign  w_ari_info[3]       =   i_ari_3_info        ;

assign  w_ari_info_en[0]    =   i_ari_0_info_en     ;
assign  w_ari_info_en[1]    =   i_ari_1_info_en     ;
assign  w_ari_info_en[2]    =   i_ari_2_info_en     ;
assign  w_ari_info_en[3]    =   i_ari_3_info_en     ;

wire		[3:0]		w_data_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		[3:0]		w_data_e2a      			;           //active-high,two or more bit error is detected(ECC)

wire		[3:0]		w_info_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		[3:0]		w_info_e2a      			;           //active-high,two or more bit error is detected(ECC)

always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        e1a   <=  8'b0            ;
        e2a   <=  8'b0            ;
    end
    else begin
        e1a[0]    <=  w_data_e1a[0]   ?   1'b1    :   e1a[0];
        e1a[1]    <=  w_data_e1a[1]   ?   1'b1    :   e1a[1];
        e1a[2]    <=  w_data_e1a[2]   ?   1'b1    :   e1a[2];
        e1a[3]    <=  w_data_e1a[3]   ?   1'b1    :   e1a[3];
        e1a[4]    <=  w_info_e1a[0]   ?   1'b1    :   e1a[4];
        e1a[5]    <=  w_info_e1a[1]   ?   1'b1    :   e1a[5];
        e1a[6]    <=  w_info_e1a[2]   ?   1'b1    :   e1a[6];
        e1a[7]    <=  w_info_e1a[3]   ?   1'b1    :   e1a[7];

        e2a[0]    <=  w_data_e2a[0]   ?   1'b1    :   e2a[0];
        e2a[1]    <=  w_data_e2a[1]   ?   1'b1    :   e2a[1];
        e2a[2]    <=  w_data_e2a[2]   ?   1'b1    :   e2a[2];
        e2a[3]    <=  w_data_e2a[3]   ?   1'b1    :   e2a[3];
        e2a[4]    <=  w_info_e2a[0]   ?   1'b1    :   e2a[4];
        e2a[5]    <=  w_info_e2a[1]   ?   1'b1    :   e2a[5];
        e2a[6]    <=  w_info_e2a[2]   ?   1'b1    :   e2a[6];
        e2a[7]    <=  w_info_e2a[3]   ?   1'b1    :   e2a[7];
    end
end

genvar i;
generate for(i = 0; i<=3; i = i + 1) begin:ARI_FIFO_GROUP
SYNCFIFO_128x520 ari_data_fifo(
			.e1a                (w_data_e1a[i]                  ),
			.e2a                (w_data_e2a[i]                  ),
			.aclr				(~i_sys_rst_n					),
			.data				(w_ari_data[i]					),
			.rdreq				(r_ari_data_rd[i]				),
			.clk				(i_sys_clk						),
			.wrreq				(w_ari_data_en[i]				),
			.q					(w_ari_data_q[i]				),
            .wrfull             (                               ),
	        .wralfull           (                               ),
	        .wrempty            (                               ),
	        .wralempty          (                               ),
	        .rdfull             (                               ),
	        .rdalfull           (                               ),
			.rdempty			(w_ari_data_rdempty[i]          ),
			.rdalempty          (							    ),
			.wrusedw			(w_ari_data_wrusedw[i]          ),
			.rdusedw			(							    )
);

SYNCFIFO_128x112 ari_info_fifo(
			.e1a                (w_info_e1a[i]                  ),
			.e2a        		(w_info_e2a[i]                  ),
			.aclr				(~i_sys_rst_n					),
			.data				(w_ari_info[i]					),
			.rdreq				(r_ari_info_rd[i]				),
			.clk				(i_sys_clk						),
			.wrreq				(w_ari_info_en[i]				),
			.q					(w_ari_info_q[i]				),
            .wrfull             (                               ),
	        .wralfull           (                               ),
	        .wrempty            (                               ),
	        .wralempty          (                               ),
	        .rdfull             (                               ),
	        .rdalfull           (                               ),
			.rdempty			(w_ari_info_rdempty[i]          ),
            .rdalempty			(w_ari_info_rdalempty[i]		),
			.wrusedw			(w_ari_info_wrusedw[i]          ),
			.rdusedw			(                               )
);
end
endgenerate


endmodule

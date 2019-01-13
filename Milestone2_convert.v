
`timescale 1ns/100ps
`default_nettype none


`include "define_state.h"

module Milestone2_convert (
	input  logic          Clock,
    input  logic          Resetn,
		
	input logic           Enable,
	input logic   [15:0]  SRAM_read_data,
	input logic           redo,
	output logic          SRAM_we_n,
	output logic  [17:0]  SRAM_address,
	output logic  [15:0]  SRAM_write_data,
	output logic          Finish
);







//---------------------------------------------------------------------------------------------------------------------   FSM S_M2_state
S_M2_state_type S_M2_state;



//---------------------------------------------------------------------------------------------------------------------   M3 Subsystem



logic M2_SRAM_we_n;
logic [17:0] M2_SRAM_address;
logic [17:0] M3_advance_SRAM_address;
logic [15:0] Matrix_Q_data_a,Matrix_Q_data_b;
logic [11:0] Matrix_nbr_R;

logic [7:0] stepCounter,stepCounter_read;

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=================================   Milestone3 convert module
logic M3_Convert_request;// convert or read
logic M3_convert_finish;
logic [17:0] M3_SRAM_address;
logic M3_redo;


Milestone3_convert Milestone3_unit(
	.Clock(Clock),
	.Resetn(Resetn), 
	
	
	
	.M3_advance_SRAM_address(M3_advance_SRAM_address),
	.SRAM_address(M3_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
	
	.Convert_request(M3_Convert_request),
	
	.DPRAM_Q_read_ref(stepCounter_read),
	.DPRAM_output_a(Matrix_Q_data_a),
	.DPRAM_output_b(Matrix_Q_data_b),
	
	
	.Finish(M3_convert_finish),
	
	.redo(M3_redo)
);


assign M3_redo = redo;

assign
	SRAM_address = ((S_M2_state == S_M2_Leadin_CQ) || (S_M2_state == S_M2_CommonCase_1)) ? M3_SRAM_address : M2_SRAM_address,
	SRAM_we_n = ((S_M2_state == S_M2_Leadin_CQ) || (S_M2_state == S_M2_CommonCase_1)) ? 1'd1 : M2_SRAM_we_n;








//---------------------------------------------------------------------------------------------------------------------   3 DP-RAMs

//<<<<<<<<<<<<<<<============== intermediate Matrix T                      dual_port_RAM_T
logic [6:0] address_T_a;
logic [6:0] address_T_b;
logic [31:0] write_data_T_a;
logic [31:0] write_data_T_b;
logic write_enable_T_a;
logic write_enable_T_b;
logic [31:0] read_data_T_a;
logic [31:0] read_data_T_b;


dual_port_RAM_T dual_port_RAM_inst0 (
	.address_a ( address_T_a ),
	.address_b ( address_T_b ),
	.clock ( Clock ),
	.data_a ( write_data_T_a ),
	.data_b ( write_data_T_b ),
	.wren_a ( write_enable_T_a ),
	.wren_b ( write_enable_T_b ),
	.q_a ( read_data_T_a ),
	.q_b ( read_data_T_b )
);

//<<<<<<<<<<<<<<<============== Coefficient Matrix C                        dual_port_RAM_C
logic [6:0] address_C_a;
logic [6:0] address_C_b;

logic [31:0] read_data_C_a;
logic [31:0] read_data_C_b;

logic [31:0] write_data_C_a;
logic [31:0] write_data_C_b;
logic write_enable_C_a;
logic write_enable_C_b;
assign 
	write_enable_C_a = 1'b0,
	write_data_C_a = 32'b0,
	write_enable_C_b = 1'b0,
	write_data_C_b = 32'b0;
	
dual_port_RAM_C dual_port_RAM_inst1 (
	.address_a ( address_C_a ),
	.address_b ( address_C_b ),
	.clock ( Clock ),
	.data_a ( write_data_C_a ),//.data_a ( 32'd0 ),//
	.data_b ( write_data_C_b ),//.data_b ( 32'd0 ),//
	.wren_a ( write_enable_C_a ),//.wren_a ( 1'b0 ),//
	.wren_b ( write_enable_C_b ),//.wren_b ( 1'b0 ),//
	.q_a ( read_data_C_a ),
	.q_b ( read_data_C_b )
);

//<<<<<<<<<<<<<<<============== Result Matrix S & raw data Matrix S'         dual_port_RAM_S
logic [6:0] address_S_a;
logic [6:0] address_S_b;
logic [31:0] write_data_S_a;
logic [31:0] write_data_S_b;
logic write_enable_S_a;
logic write_enable_S_b;
logic [31:0] read_data_S_a;
logic [31:0] read_data_S_b;


dual_port_RAM_S dual_port_RAM_inst2 (
	.address_a ( address_S_a ),
	.address_b ( address_S_b ),
	.clock ( Clock ),
	.data_a ( write_data_S_a ),
	.data_b ( write_data_S_b ),
	.wren_a ( write_enable_S_a ),
	.wren_b ( write_enable_S_b ),
	.q_a ( read_data_S_a ),
	.q_b ( read_data_S_b )
);


//-----------------------------------------------------------------------------------------------------     computation logic M1, M2, M3, M4
logic [31:0] oprand1,oprand2,oprand3,oprand4,oprand5,oprand6,oprand7,oprand8;
logic [15:0] oprand_row_1,oprand_row_2,oprand_row_3,oprand_row_4;
logic [15:0] oprand_col_1,oprand_col_2,oprand_col_3,oprand_col_4;
logic [31:0] oprand_col_T1,oprand_col_T2;
logic [31:0] M1,M2,M3,M4;
logic [63:0] M1_long,M2_long,M3_long,M4_long;
assign
	M1_long = oprand1*oprand2,
	M2_long = oprand3*oprand4,
	M3_long = oprand5*oprand6,
	M4_long = oprand7*oprand8,
	M1 = M1_long[31:0],
	M2 = M2_long[31:0],
	M3 = M3_long[31:0],
	M4 = M4_long[31:0];
	
always_comb begin
//define oprand for multiplier
	//default 1
	oprand_row_1 = 16'd0;
	oprand_row_2 = 16'd0;
	oprand_row_3 = 16'd0;
	oprand_row_4 = 16'd0;
	
	oprand_col_1 = 16'd0;
	oprand_col_2 = 16'd0;
	oprand_col_3 = 16'd0;
	oprand_col_4 = 16'd0;
	
	oprand_col_T1 = 32'd0;
	oprand_col_T2 = 32'd0;
	case (S_M2_state)
		S_M2_Leadin_CT: begin//CT
			oprand_row_1 = Matrix_Q_data_a;
			oprand_row_2 = Matrix_Q_data_b;
			
			oprand_col_1 = read_data_C_a[31:16];
			oprand_col_2 = read_data_C_a[15:0];
			oprand_col_3 = read_data_C_b[31:16];
			oprand_col_4 = read_data_C_b[15:0];
		end
		S_M2_CommonCase_1: begin//CS
			oprand_col_T1 = read_data_T_a;
			oprand_col_T2 = read_data_T_b;
			
			oprand_row_1 = read_data_C_a[31:16];
			oprand_row_2 = read_data_C_a[15:0];
			oprand_row_3 = read_data_C_b[31:16];
			oprand_row_4 = read_data_C_b[15:0];
		end
		S_M2_CommonCase_2: begin//CT
			oprand_row_1 = Matrix_Q_data_a;
			oprand_row_2 = Matrix_Q_data_b;
			
			oprand_col_1 = read_data_C_a[31:16];
			oprand_col_2 = read_data_C_a[15:0];
			oprand_col_3 = read_data_C_b[31:16];
			oprand_col_4 = read_data_C_b[15:0];
		end
		S_M2_Leadout_CS: begin//CS
			oprand_col_T1 = read_data_T_a;
			oprand_col_T2 = read_data_T_b;
			
			oprand_row_1 = read_data_C_a[31:16];
			oprand_row_2 = read_data_C_a[15:0];
			oprand_row_3 = read_data_C_b[31:16];
			oprand_row_4 = read_data_C_b[15:0];
		end
	endcase
	if ( (S_M2_state == S_M2_Leadin_CT) || (S_M2_state == S_M2_CommonCase_2) ) begin
		oprand1 = {{16{oprand_row_1[15]}},oprand_row_1};
		oprand2 = {{16{oprand_col_1[15]}},oprand_col_1};
		
		oprand3 = {{16{oprand_row_2[15]}},oprand_row_2};
		oprand4 = {{16{oprand_col_2[15]}},oprand_col_2};
		
		oprand5 = {{16{oprand_row_1[15]}},oprand_row_1};
		oprand6 = {{16{oprand_col_3[15]}},oprand_col_3};
		
		oprand7 = {{16{oprand_row_2[15]}},oprand_row_2};
		oprand8 = {{16{oprand_col_4[15]}},oprand_col_4};
	end else begin
		oprand1 = oprand_col_T1;
		oprand2 = {{16{oprand_row_1[15]}},oprand_row_1};
		
		oprand3 = oprand_col_T2;
		oprand4 = {{16{oprand_row_2[15]}},oprand_row_2};
		
		oprand5 = oprand_col_T1;
		oprand6 = {{16{oprand_row_3[15]}},oprand_row_3};
		
		oprand7 = oprand_col_T2;
		oprand8 = {{16{oprand_row_4[15]}},oprand_row_4};
	end
end

//---------------------------------------------------------------------------------------------------------------   M2  Main  FSM

logic [7:0] S_buf_0,S_buf_1;
logic [31:0] result_0,result_1;
logic [31:0] mealy_result_0,mealy_result_1;
logic [6:0] address_S_ref_R,address_S_ref_W,address_WS_ref;
logic [17:0]SRAM_addr_ref_R,SRAM_addr_ref_W;
logic [15:0] S_MSB_0,S_MSB_1,S_rest_0,S_rest_1;
logic [7:0] T_sign_0,T_sign_1;
logic [31:0] S0_intermediate,S1_intermediate;
logic [7:0] S0,S1;

assign
	T_sign_0 = {8{mealy_result_0[31]}},
	T_sign_1 = {8{mealy_result_1[31]}};
assign
	mealy_result_0 = result_0 + M1 + M2,
	mealy_result_1 = result_1 + M3 + M4;
assign
	S_MSB_0 = {16{mealy_result_0[31]}},
	S_rest_0 = mealy_result_0[31:16],
	S_MSB_1 = {16{mealy_result_1[31]}},
	S_rest_1 = mealy_result_1[31:16],
	S0_intermediate = {S_MSB_0,S_rest_0},
	S1_intermediate = {S_MSB_1,S_rest_1},
	S0 = ($signed(S0_intermediate) < $signed('d0)) ? 8'd0 : (($signed(S0_intermediate) > $signed('d255)) ? 8'd255 : S0_intermediate[7:0]),
	S1 = ($signed(S1_intermediate) < $signed('d0)) ? 8'd0 : (($signed(S1_intermediate) > $signed('d255)) ? 8'd255 : S1_intermediate[7:0]);

// address reference based on Step counter


logic [6:0] addr_T_read_ref,addr_T_write_ref,addr_C_read_ref,addr_S_write_ref;
assign
	addr_T_read_ref = {1'd0,stepCounter_read[1:0],4'd0} + {4'd0,stepCounter_read[4:2]},  //T2 = T1+8
	addr_T_write_ref = {1'd0,stepCounter[4:2],3'd0} + {4'd0,stepCounter[6:5],1'd0},//T2 = T1+1
	
	addr_C_read_ref = {5'd0,stepCounter_read[1:0]} + {2'd0,stepCounter_read[6:5],3'd0},//C2 = C1+4
	
	
	addr_S_write_ref = {5'd0,stepCounter[4:3]} + {2'd0,stepCounter[6:5],3'd0} + 7'd32;

always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		write_enable_S_a <= 1'b0;
		write_enable_S_b <= 1'b0;
		
		write_enable_T_a <= 1'b0;
		write_enable_T_b <= 1'b0;
		
		write_data_S_a <= 32'd0;
		write_data_S_b <= 32'd0;
		write_data_T_a <= 32'd0;
		write_data_T_b <= 32'd0;
		
		address_C_a <= 7'd0;
		address_C_b <= 7'd4;
		
		address_T_a <= 7'd0;
		address_T_b <= 7'd0;
		
		address_S_a <= 7'd0;
		address_S_b <= 7'd0;
		
		address_S_ref_R <= 7'd0;
		address_S_ref_W <= 7'd0;
		address_WS_ref <= 7'd32;
		
		stepCounter <= 8'd0;
		stepCounter_read <= 8'd0;
		
		M2_SRAM_address <= 18'd0;
		M2_SRAM_we_n <= 1'd1;
		SRAM_write_data <= 15'd0;
		

		S_buf_0 <= 8'd0;
		S_buf_1 <= 8'd0;
		
		result_0 <= 32'd0;
		result_1 <= 32'd0;
		
		Matrix_nbr_R <= 12'd0;
		M3_Convert_request <= 1'd0;
		S_M2_state <= S_M2_convert_IDLE;
		Finish <= 1'b0;
	end else begin
		case (S_M2_state)
		S_M2_convert_IDLE: begin
			if (Finish != 1'b1) begin
				if (Enable == 1'b1) begin
					S_M2_state <= S_M2_Leadin_CQ;
					stepCounter <= 8'd0;
					stepCounter_read <= 8'd0;
					M3_Convert_request <= 1'd1;
				end
				
			end else begin
				if (redo == 1'b1) begin
					write_enable_S_a <= 1'b0;
					write_enable_S_b <= 1'b0;
					
					write_enable_T_a <= 1'b0;
					write_enable_T_b <= 1'b0;
					
					write_data_S_a <= 32'd0;
					write_data_S_b <= 32'd0;
					write_data_T_a <= 32'd0;
					write_data_T_b <= 32'd0;
					
					address_C_a <= 7'd0;
					address_C_b <= 7'd4;
					
					address_T_a <= 7'd0;
					address_T_b <= 7'd0;
					
					address_S_a <= 7'd0;
					address_S_b <= 7'd0;
					
					address_S_ref_R <= 7'd0;
					address_S_ref_W <= 7'd0;
					address_WS_ref <= 7'd32;
					
					stepCounter <= 8'd0;
					stepCounter_read <= 8'd0;
					
					M2_SRAM_address <= 18'd0;
					M2_SRAM_we_n <= 1'd1;
					SRAM_write_data <= 15'd0;
					
					S_buf_0 <= 8'd0;
					S_buf_1 <= 8'd0;
					
					result_0 <= 32'd0;
					result_1 <= 32'd0;
					
					Matrix_nbr_R <= 12'd0;
					S_M2_state <= S_M2_convert_IDLE;
					Finish <= 1'b0;
				end
			end
		end
		S_M2_Leadin_CQ: begin//burst read
			M3_Convert_request <= 1'd0;
			M2_SRAM_we_n <= 1'b1;
			if (M3_convert_finish == 1'd1)begin
				stepCounter_read <= stepCounter_read + 8'd1;
				if (stepCounter_read == 8'd1) begin
					S_M2_state <= S_M2_Leadin_CT;
					address_C_a <= addr_C_read_ref;
					address_C_b <= addr_C_read_ref + 7'd4;
					Matrix_nbr_R <= Matrix_nbr_R + 12'd1;
				end
			end
		end	

		S_M2_Leadin_CT: begin//same as common case 2 : CT
			stepCounter <= stepCounter + 8'd1;
			stepCounter_read <= stepCounter_read + 8'd1;
			
			if (stepCounter < 8'd128)begin
				write_enable_T_a <= 1'b0;
				write_enable_T_b <= 1'b0;
				
				address_S_a <= {2'd0,{stepCounter_read[4:0]}};
				address_C_a <= addr_C_read_ref;
				address_C_b <= addr_C_read_ref + 7'd4;
				
				result_0 <= result_0 + M1 + M2;
				result_1 <= result_1 + M3 + M4;
				
				if (stepCounter[1:0] == 2'b11) begin
					result_0 <= 32'd0;
					result_1 <= 32'd0;
					write_enable_T_a <= 1'b1;
					write_enable_T_b <= 1'b1;
					address_T_a <= addr_T_write_ref;
					address_T_b <= addr_T_write_ref + 7'd1;
					
					write_data_T_a <= {T_sign_0,mealy_result_0[31:8]};
					write_data_T_b <= {T_sign_1,mealy_result_1[31:8]};
				end
			end else begin
				stepCounter_read <= 8'd1;
				S_M2_state <= S_M2_load_T1;
				M3_Convert_request <= 1'd1;//------------------------------------- request for C Q
				M2_SRAM_address <= M3_advance_SRAM_address;
				
				write_enable_T_a <= 1'b0;
				write_enable_T_b <= 1'b0;
				address_C_a <= 7'd0;
				address_C_b <= 7'd4;
				
				address_T_a <= 7'd0;
				address_T_b <= 7'd8;
			end
		end
		
		S_M2_load_T1: begin//2 clock cycles earlier than CS to prepare T on time    stepCounter_read == 0 at this cycle
			address_S_ref_W <= 7'd0;
			
			M3_Convert_request <= 1'd0;
			if (Matrix_nbr_R < 12'd2400) begin
				
				S_M2_state <= S_M2_CommonCase_1;
				stepCounter_read <= stepCounter_read + 8'd1;
				stepCounter <= 8'd0;
				
				address_T_a <= addr_T_read_ref;
				address_T_b <= addr_T_read_ref + 7'd8;
				address_C_a <= addr_C_read_ref;
				address_C_b <= addr_C_read_ref + 7'd4;
			end else begin
				S_M2_state <= S_M2_Leadout_CS;
				stepCounter_read <= stepCounter_read + 8'd1;
				stepCounter <= 8'd0;
				
				address_T_a <= addr_T_read_ref;
				address_T_b <= addr_T_read_ref + 7'd8;
				address_C_a <= addr_C_read_ref;
				address_C_b <= addr_C_read_ref + 7'd4;
			end
		end
		
		
		S_M2_CommonCase_1: begin//common case 1 : CS CQ
			stepCounter <= stepCounter + 8'd1;
			stepCounter_read <= stepCounter_read + 8'd1;
			
			if (stepCounter < 8'd128) begin
				S_M2_state <= S_M2_CommonCase_1;
				
				write_enable_S_a <= 1'd0;
				write_enable_S_b <= 1'd0;
				write_enable_T_a <= 1'b0;
				write_enable_T_b <= 1'b0;
				
				address_T_a <= addr_T_read_ref;
				address_T_b <= addr_T_read_ref + 7'd8;
				address_C_a <= addr_C_read_ref;
				address_C_b <= addr_C_read_ref + 7'd4;
				
				result_0 <= result_0 + M1 + M2;
				result_1 <= result_1 + M3 + M4;
				
				if (stepCounter[1:0] == 2'b11) begin
					result_0 <= 32'd0;
					result_1 <= 32'd0;
					
					if(stepCounter[2:0] == 3'b111) begin
						write_enable_S_a <= 1'd1;
						write_enable_S_b <= 1'd1;
						address_S_a <= addr_S_write_ref;
						address_S_b <= addr_S_write_ref + 7'd4;
						
						write_data_S_a <= {16'd0,S_buf_0,S0};//16+8+8 = 32bits data
						write_data_S_b <= {16'd0,S_buf_1,S1};
					end else begin
						S_buf_0 <= S0;
						S_buf_1 <= S1;
					end
				end
				
				if (stepCounter == 8'd127) begin
					stepCounter_read <= 8'd0;
				end
			end else begin
				Matrix_nbr_R <= Matrix_nbr_R + 12'd1;
				S_M2_state <= S_M2_load_S_prime1;
				write_enable_S_b <= 1'b0;
				stepCounter_read <= 8'd1;
				
				write_enable_S_a <= 1'b0;
				address_S_a <= 7'd0;

				address_C_a <= 7'd0;
				address_C_b <= 7'd4;
			end
		end
		
		S_M2_load_S_prime1: begin//finish writing S to DP-RAM ,    2 port of DP-RAM_S used in this cycle, so cannot start reading
			S_M2_state <= S_M2_CommonCase_2;
			stepCounter_read <= stepCounter_read + 8'd1;
			stepCounter <= 8'd0;
				
			
			address_C_a <= addr_C_read_ref;
			address_C_b <= addr_C_read_ref + 7'd4;
		end
		
		
		S_M2_CommonCase_2: begin//common case 2 : CT WS
			stepCounter <= stepCounter + 8'd1;
			stepCounter_read <= stepCounter_read + 8'd1;
			
			if (stepCounter < 8'd128)begin
				
				write_enable_T_a <= 1'b0;
				write_enable_T_b <= 1'b0;
				
				address_S_a <= {2'd0,{stepCounter_read[4:0]}};
				address_C_a <= addr_C_read_ref;
				address_C_b <= addr_C_read_ref + 7'd4;
				
				result_0 <= result_0 + M1 + M2;
				result_1 <= result_1 + M3 + M4;
				
				
				if (stepCounter[1:0] == 2'b11) begin
					result_0 <= 32'd0;
					result_1 <= 32'd0;
					write_enable_T_a <= 1'b1;
					write_enable_T_b <= 1'b1;
					address_T_a <= addr_T_write_ref;
					address_T_b <= addr_T_write_ref + 7'd1;
					write_data_T_a <= {T_sign_0,mealy_result_0[31:8]};
					write_data_T_b <= {T_sign_1,mealy_result_1[31:8]};
				end
				
				//=======================================  WS part =================================
				M2_SRAM_we_n <= 1'b1;
				if (stepCounter[2:0] == 3'b000) begin
					address_S_b <= address_WS_ref;
					address_WS_ref <= address_WS_ref + 7'd1;
				end else begin
					if (stepCounter[2:0] == 3'b001) begin
						address_S_b <= address_WS_ref;
						address_WS_ref <= address_WS_ref + 7'd1;
					end else begin
						if (stepCounter[2:0] == 3'b010) begin
							M2_SRAM_we_n <= 1'b0;
							M2_SRAM_address <= SRAM_addr_ref_W;
							SRAM_write_data  <= read_data_S_b[15:0];
						end else begin
							if (stepCounter[2:0] == 3'b011) begin
								M2_SRAM_we_n <= 1'b0;
								M2_SRAM_address <= SRAM_addr_ref_W;
								SRAM_write_data  <= read_data_S_b[15:0];
							end
						end
					end
				end
				
			end else begin
				stepCounter_read <= 8'd1;
				S_M2_state <= S_M2_load_T1;
				M3_Convert_request <= 1'd1;//------------------------------------- request for C Q
				M2_SRAM_address <= M3_advance_SRAM_address;
				

				
				address_WS_ref <= 7'd32;
				write_enable_T_a <= 1'b0;
				write_enable_T_b <= 1'b0;
				address_C_a <= 7'd0;
				address_C_b <= 7'd4;
				
				address_T_a <= 7'd0;
				address_T_b <= 7'd8;
			end
		end

		S_M2_Leadout_CS: begin//same as common case 1 : CS
			stepCounter <= stepCounter + 8'd1;
			stepCounter_read <= stepCounter_read + 8'd1;
			
			if (stepCounter < 8'd128) begin
				S_M2_state <= S_M2_Leadout_CS;
				
				write_enable_S_a <= 1'd0;
				write_enable_S_b <= 1'd0;
				write_enable_T_a <= 1'b0;
				write_enable_T_b <= 1'b0;
				
				address_T_a <= addr_T_read_ref;
				address_T_b <= addr_T_read_ref + 7'd8;
				address_C_a <= addr_C_read_ref;
				address_C_b <= addr_C_read_ref + 7'd4;
				
				result_0 <= result_0 + M1 + M2;
				result_1 <= result_1 + M3 + M4;
				
				if (stepCounter[1:0] == 2'b11) begin
					result_0 <= 32'd0;
					result_1 <= 32'd0;
					
					if(stepCounter[2:0] == 3'b111) begin
						write_enable_S_a <= 1'd1;
						write_enable_S_b <= 1'd1;
						
						address_S_a <= addr_S_write_ref;
						address_S_b <= addr_S_write_ref + 7'd4;
						write_data_S_a <= {16'd0,S_buf_0,S0};//16+8+8 = 32bits data
						write_data_S_b <= {16'd0,S_buf_1,S1};
					end else begin
						S_buf_0 <= S0;
						S_buf_1 <= S1;
					end
				end
			end else begin
				if (stepCounter == 8'd128) begin
					address_S_b <= 7'd32;
					address_WS_ref <= 7'd33;
					write_enable_S_a <= 1'd0;
					write_enable_S_b <= 1'd0;
					
					S_M2_state <= S_M2_Leadout_CS;
				end else begin
					address_S_b <= address_WS_ref;
					address_WS_ref <= address_WS_ref + 7'd1;
					S_M2_state <= S_M2_Leadout_WS;
					
					stepCounter <= 8'd0;
					stepCounter_read <= 8'd0;
				end
			end
		end
		S_M2_Leadout_WS: begin//burst write
			stepCounter <= stepCounter + 8'd1;
			if (stepCounter <= 8'd31) begin
				address_S_b <= address_WS_ref;
				address_WS_ref <= address_WS_ref + 7'd1;
				
				M2_SRAM_we_n <= 1'b0;
				M2_SRAM_address <= SRAM_addr_ref_W;
				SRAM_write_data  <= read_data_S_b[15:0];
			end else begin
				M2_SRAM_we_n <= 1'b1;
				Finish <= 1'b1;
				S_M2_state <= S_M2_convert_IDLE;
			end
			
		end
		
		default: S_M2_state <= S_M2_convert_IDLE;
		endcase
	end
end


//-----------------------------------------------------------------------------------------------------------------     SRAM address counter
logic [5:0] sample_counter;
logic [2:0] sample_row_W;
logic [1:0] sample_col_W;
logic [5:0] block_col_W;
logic [4:0] block_row_W;
logic [17:0] SRAM_base_addr_W;
logic [5:0] end_of_row_W;
logic [7:0] Col_addr_W;
logic [7:0] Row_addr_W;

assign 
	sample_col_W = sample_counter[1:0],
	sample_row_W = sample_counter[4:2],
	Col_addr_W = {block_col_W,sample_col_W},//1 bit less than read
	Row_addr_W = {block_row_W,sample_row_W},
														
	SRAM_addr_ref_W = (SRAM_base_addr_W == 18'd0) ? ({3'd0,Row_addr_W,7'd0} + {5'd0,Row_addr_W,5'd0} + {10'd0,Col_addr_W} + SRAM_base_addr_W) : 
													({4'd0,Row_addr_W,6'd0} + {6'd0,Row_addr_W,4'd0} + {10'd0,Col_addr_W} + SRAM_base_addr_W) ,
													

	end_of_row_W = (SRAM_base_addr_W == 18'd0) ? 6'd39 : 6'd19;

	
always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin

		block_col_W <= 6'd0;
		block_row_W <= 5'd0;
		sample_counter <= 6'd0;
		
		SRAM_base_addr_W <= 18'd0;
		//sample counter = step counter/2
	end else begin
		if (redo == 1'b1)begin

			block_col_W <= 6'd0;
			block_row_W <= 5'd0;
			sample_counter <= 6'd0;
			
			SRAM_base_addr_W <= 18'd0;
		end
		if  ( ((S_M2_state == S_M2_CommonCase_2) && ((stepCounter[2:0] == 3'b010) || (stepCounter[2:0] == 3'b011))) || (S_M2_state == S_M2_Leadout_WS) )begin
			sample_counter <= sample_counter + 6'd1;
			if (sample_counter == 6'd31) begin
				sample_counter <=  6'd0;
				if (block_col_W < end_of_row_W) begin
					block_col_W <= block_col_W + 6'd1;
				end else begin
					block_col_W <= 6'd0;
					block_row_W <= block_row_W + 5'd1;
					if (block_row_W == 5'd29) begin
						SRAM_base_addr_W <= (SRAM_base_addr_W == 18'd38400) ? 18'd57600 : 18'd38400 ;
						block_row_W <= 5'd0;
						sample_counter <= 6'd0;
					end
				end
			end
		end
	end
end

endmodule

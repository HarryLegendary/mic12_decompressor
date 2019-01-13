`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module Milestone1_convert (
	input  logic          Clock,
    input  logic           Resetn,  
	//input logic   [3:0]   PUSH_BUTTON_I,           // pushbuttons ( may be used )
	
	input logic           Enable,
	input logic   [15:0]  SRAM_read_data,
	input logic           redo,
	output logic          SRAM_we_n,
	output logic  [17:0]  SRAM_address,
	output logic  [15:0]  SRAM_write_data,
	output logic          Finish
);

S_M1_convert_state_type S_M1_convert_state;

enum logic [2:0] {
	mode_normal_R,
	mode_normal_GB,
	mode_R_R_extra,
	mode_R_Y_extra,
	mode_extra_GB
} RGB_mode;

//<<<<<<<<<<<<<<<<<<<<<<==========================  address pointer
logic [17:0] SRAM_address_Y;
logic [17:0] SRAM_address_U;
logic [17:0] SRAM_address_V;
logic [17:0] SRAM_address_RGB;

//<<<<<<<<<<<<<<<<<<<<<<==========================  buffer
logic[15:0] VGA_sram_data_Y;

logic[7:0] red_buffer,red_buffer_extra;
logic[7:0] blue_buffer;

logic signed [31:0] U_upsampled[3:0];
logic signed [31:0] V_upsampled[3:0];
logic signed [31:0] Y_upsampled[3:0];

logic [31:0] Y_temp,Y_temp_extra;

logic [7:0] Y_shift_reg[3:0];
logic [7:0] U_shift_reg[7:0];
logic [7:0] V_shift_reg[7:0];

//<<<<<<<<<<<<<<<<<<<<<<==========================  <mode> for control 

logic multiplier_mode;
//logic [2:0] RGB_mode;
logic UV_mode;

logic quick_v_mode;

logic [17:0]end_of_row;

//<<<<<<<<<<<<<<<<<<============================================ debug flag
logic [8:0] row_nbr;
logic [17:0] pixel_nbr;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<======================   computation logic here

//  intermediate node for passing value (result from multiplier block)
logic [7:0] R,R_extra;
logic [7:0] G;
logic [7:0] B;
logic [31:0] result;
logic [31:0] result_intermediate;

logic signed [63:0] M1_long,M2_long,M3_long;
logic signed [31:0] M1,M2,M3;
logic signed [31:0] oprand1,oprand2,oprand3,oprand4,oprand5,oprand6;
logic signed [31:0] Y_to_use,Y_extra_to_use;
logic signed [31:0] R_intermediate,R_extra_intermediate,G_intermediate,B_intermediate;
logic signed [31:0] R_signed,R_extra_signed,B_signed,G_signed;


//3 multiplier
assign
	M1_long = oprand1*oprand2,
	M2_long = oprand3*oprand4,
	M3_long = oprand5*oprand6,
	M1 = M1_long[31:0],
	M2 = M2_long[31:0],
	M3 = M3_long[31:0];

always_comb begin
	//begin: compute_U_V_RGB

	oprand1 = 32'd0;
	oprand2 = 32'd0;
	oprand3 = 32'd0;
	oprand4 = 32'd0;
	oprand5 = 32'd0;
	oprand6 = 32'd0;
	if (multiplier_mode == 1'b0) begin//0/1: RGB0,1 / U,V
		case (RGB_mode)
		mode_normal_R: begin
			oprand1 = 32'd76284;
			oprand2 = Y_upsampled[0]-32'd16;//y0
			
			oprand3 = 32'd104595;
			oprand4 = V_upsampled[0]-32'd128;
			
			oprand5 = 32'd1;//don't care
			oprand6 = 32'd1;//don't care
		end
		mode_normal_GB: begin
			oprand1 = -32'd25624;
			oprand2 = U_upsampled[0]-32'd128;
			
			oprand3 = -32'd53281;
			oprand4 = V_upsampled[0]-32'd128;
			
			oprand5 = 32'd132251;
			oprand6 = U_upsampled[0]-32'd128;
		end
		mode_R_R_extra: begin
			oprand1 = 32'd76284;
			oprand2 = Y_upsampled[0]-32'd16;//y0
			
			oprand3 = 32'd104595;
			oprand4 = V_upsampled[0]-32'd128;
			
			oprand5 = 32'd104595;//--------------------------
			oprand6 = V_upsampled[1]-32'd128;//--------------------
		end
		mode_R_Y_extra: begin
			oprand1 = 32'd76284;
			oprand2 = Y_upsampled[0]-32'd16;//y0
			
			oprand3 = 32'd104595;
			oprand4 = V_upsampled[0]-32'd128;
			
			oprand5 = 32'd76284;//======================
			oprand6 = Y_upsampled[2]-32'd16;//=================
		end
		mode_extra_GB: begin
			oprand1 = -32'd25624;
			oprand2 = U_upsampled[0]-32'd128;
			
			oprand3 = -32'd53281;
			oprand4 = V_upsampled[0]-32'd128;
			
			oprand5 = 32'd132251;
			oprand6 = U_upsampled[0]-32'd128;
		end
		//default: RGB_mode = mode_normal_R;
		endcase
	end else begin
		if (UV_mode == 1'b0) begin
			oprand1 = 32'd21;
			oprand2 = {24'd0,{U_shift_reg[0]}}+{24'd0,{U_shift_reg[5]}};
			
			oprand3 = -32'd52;
			oprand4 = {24'd0,{U_shift_reg[1]}}+{24'd0,{U_shift_reg[4]}};
			
			oprand5 = 32'd159;
			oprand6 = {24'd0,{U_shift_reg[2]}}+{24'd0,{U_shift_reg[3]}};
		
		end else begin
			oprand1 = 32'd21;
			oprand2 = {24'd0,{V_shift_reg[0]}}+{24'd0,{V_shift_reg[5]}};
			
			oprand3 = -32'd52;
			oprand4 = {24'd0,{V_shift_reg[1]}}+{24'd0,{V_shift_reg[4]}};
			
			oprand5 = 32'd159;
			oprand6 = {24'd0,{V_shift_reg[2]}}+{24'd0,{V_shift_reg[3]}};
		end
	end
	
	//================================================== assign ===================================
	R_intermediate = 32'd0;
	R_extra_intermediate = 32'd0;
	G_intermediate = 32'd0;
	B_intermediate = 32'd0;
	result = 32'd0;
	result_intermediate = 32'd0;
	R = 8'd0;
	R_extra = 8'd0;
	G =  8'd0;
	B =  8'd0;
	R_signed = 32'd0;
	R_extra_signed = 32'd0;
	G_signed = 32'd0;
	B_signed = 32'd0;
	Y_to_use = 32'd0;
	Y_extra_to_use = 32'd0;
	// modify result of multiplier
	if (multiplier_mode == 1'b0) begin
		case (RGB_mode)
		mode_normal_R: begin
			R_signed = M1 + M2;
			R_intermediate = {{16{R_signed[31]}},{R_signed[31:16]}};
			Y_to_use = M1;//load to FF, used in next cycle

			R = ($signed(R_intermediate) < $signed('d0)) ? 8'd0 : (($signed(R_intermediate) > $signed('d255)) ? 8'd255 : R_intermediate[7:0]);
		end
		mode_normal_GB: begin
			G_signed = (Y_temp + M1 + M2);
			G_intermediate = {{16{G_signed[31]}},{G_signed[31:16]}};
			G = ($signed(G_intermediate) < $signed('d0)) ? 8'd0 : (($signed(G_intermediate) > $signed('d255)) ? 8'd255 : G_intermediate[7:0]);
			
			B_signed = (Y_temp + M3);
			B_intermediate = {{16{B_signed[31]}},{B_signed[31:16]}};
			B = ($signed(B_intermediate) < $signed('d0)) ? 8'd0 : (($signed(B_intermediate) > $signed('d255)) ? 8'd255 : B_intermediate[7:0]);
		end
		mode_R_R_extra: begin
			R_signed = M1 + M2;
			R_intermediate = {{16{R_signed[31]}},{R_signed[31:16]}};
			Y_to_use = M1;//load to FF, used in next cycle
			R = ($signed(R_intermediate) < $signed('d0)) ? 8'd0 : (($signed(R_intermediate) > $signed('d255)) ? 8'd255 : R_intermediate[7:0]);
			
			R_extra_signed = Y_temp_extra + M3;//first got Y for pixel 2
			R_extra_intermediate = {{16{R_extra_signed[31]}},{R_extra_signed[31:16]}};
			R_extra = ($signed(R_extra_intermediate) < $signed('d0)) ? 8'd0 : (($signed(R_extra_intermediate) > $signed('d255)) ? 8'd255 : R_extra_intermediate[7:0]);
			
		end
		mode_R_Y_extra: begin
			R_signed = M1 + M2;
			R_intermediate = {{16{R_signed[31]}},{R_signed[31:16]}};
			Y_to_use = M1;//load to FF, used in next cycle
			Y_extra_to_use = M3;//first got Y for pixel 2

			R = ($signed(R_intermediate) < $signed('d0)) ? 8'd0 : (($signed(R_intermediate) > $signed('d255)) ? 8'd255 : R_intermediate[7:0]);
		end
		mode_extra_GB: begin
			G_signed = (Y_temp_extra + M1 + M2);
			G_intermediate = {{16{G_signed[31]}},{G_signed[31:16]}};
			G = ($signed(G_intermediate) < $signed('d0)) ? 8'd0 : (($signed(G_intermediate) > $signed('d255)) ? 8'd255 : G_intermediate[7:0]);
			
			B_signed = (Y_temp_extra + M3);
			B_intermediate = {{16{B_signed[31]}},{B_signed[31:16]}};
			B = ($signed(B_intermediate) < $signed('d0)) ? 8'd0 : (($signed(B_intermediate) > $signed('d255)) ? 8'd255 : B_intermediate[7:0]);
		end
		endcase
	end else begin
		result_intermediate = M1+M2+M3+32'd128;
		result = {{8{result_intermediate[31]}},{result_intermediate[31:8]}};
	end
end	

always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		S_M1_convert_state <= S_M1_convert_IDLE;
		
		SRAM_we_n <= 1'b1;
		SRAM_address <= 18'd0;
		SRAM_address_Y <= 18'd0;
		SRAM_address_U <= 18'd38400;
		SRAM_address_V <= 18'd57600;
		SRAM_address_RGB <= 18'd146944;
		
		Y_upsampled[0] <= 32'd0;
		Y_upsampled[1] <= 32'd0;
		Y_upsampled[2] <= 32'd0;
		Y_upsampled[3] <= 32'd0;
		
		U_upsampled[0] <= 32'd0;
		U_upsampled[1] <= 32'd0;
		U_upsampled[2] <= 32'd0;
		U_upsampled[3] <= 32'd0;
		
		V_upsampled[0] <= 32'd0;
		V_upsampled[1] <= 32'd0;
		V_upsampled[2] <= 32'd0;
		V_upsampled[3] <= 32'd0;
		
		
		Y_shift_reg[0] <= 8'd0;
		Y_shift_reg[1] <= 8'd0;
		Y_shift_reg[2] <= 8'd0;
		Y_shift_reg[3] <= 8'd0;
		
		U_shift_reg[0] <= 8'd0;
		U_shift_reg[1] <= 8'd0;
		U_shift_reg[2] <= 8'd0;
		U_shift_reg[3] <= 8'd0;
		U_shift_reg[4] <= 8'd0;
		U_shift_reg[5] <= 8'd0;
		U_shift_reg[6] <= 8'd0;
		U_shift_reg[7] <= 8'd0;
		
		V_shift_reg[0] <= 8'd0;
		V_shift_reg[1] <= 8'd0;
		V_shift_reg[2] <= 8'd0;
		V_shift_reg[3] <= 8'd0;
		V_shift_reg[4] <= 8'd0;
		V_shift_reg[5] <= 8'd0;
		V_shift_reg[6] <= 8'd0;
		V_shift_reg[7] <= 8'd0;
		
		multiplier_mode <= 1'b0;
		RGB_mode <= mode_normal_R;
		UV_mode <= 1'b0;
		Finish <= 1'b0;
		
		red_buffer <= 8'd0;
		red_buffer_extra <= 8'd0;
		blue_buffer <= 8'd0;
		
		end_of_row <= 18'd318;//------------------------------------
		
		SRAM_write_data <= 16'd0;
		row_nbr <= 9'd0;
		pixel_nbr <= 18'd0;
	end else begin
		case (S_M1_convert_state)
		S_M1_convert_IDLE: begin
			SRAM_we_n <= 1'b1;
			if (Finish == 1'b1) begin
				SRAM_we_n <= 1'b1;// keep reading for safety
				//do nothing ( or enable displaying)
				if (redo == 1'b1) begin
					Finish <= 1'b0;
					SRAM_we_n <= 1'b1;
					SRAM_address <= 18'd0;
					SRAM_address_Y <= 18'd0;
					SRAM_address_U <= 18'd38400;
					SRAM_address_V <= 18'd57600;
					SRAM_address_RGB <= 18'd146944;
					
					
					multiplier_mode <= 1'b0;
					RGB_mode <= mode_normal_R;
					UV_mode <= 1'b0;
					
					
					red_buffer <= 8'd0;
					red_buffer_extra <= 8'd0;
					blue_buffer <= 8'd0;
					
					end_of_row <= 18'd318;//------------------------------------
					
					SRAM_write_data <= 16'd0;
					row_nbr <= 9'd0;
					pixel_nbr <= 18'd0;
				end
			end else begin
				if (Enable == 1'b1) begin
					
					S_M1_convert_state <= S_M1_convert_Leadin_0;
				end
			end
		end
		S_M1_convert_Leadin_0: begin
			SRAM_address <= SRAM_address_Y;
			SRAM_address_Y <= 18'd1 + SRAM_address_Y;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			S_M1_convert_state <= S_M1_convert_Leadin_1;
		end
		S_M1_convert_Leadin_1: begin
			SRAM_address <= SRAM_address_U;
			SRAM_address_U <= 18'd1 + SRAM_address_U;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			S_M1_convert_state <= S_M1_convert_Leadin_2;
		end
		S_M1_convert_Leadin_2: begin
			SRAM_address <= SRAM_address_V;
			SRAM_address_V <= 18'd1 + SRAM_address_V;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			S_M1_convert_state <= S_M1_convert_Leadin_3;
			
		end
		S_M1_convert_Leadin_3: begin
			SRAM_address <= SRAM_address_U;
			SRAM_address_U <= 18'd1 + SRAM_address_U;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			
			Y_shift_reg[0] <= SRAM_read_data[15:8];
			Y_shift_reg[1] <= SRAM_read_data[7:0];
			
			S_M1_convert_state <= S_M1_convert_Leadin_4;
			
		end
		S_M1_convert_Leadin_4: begin
			SRAM_address <= SRAM_address_V;
			SRAM_address_V <= 18'd1 + SRAM_address_V;
			SRAM_we_n <= 1'b1;// read (along with address)

			U_shift_reg[3] <= SRAM_read_data[7:0];//SRAM_read_data:[U1,U0] put: U0 U0 U0 U1 X X 
			U_shift_reg[2] <= SRAM_read_data[15:8];//
			U_shift_reg[1] <= SRAM_read_data[15:8];//
			U_shift_reg[0] <= SRAM_read_data[15:8];
			
			S_M1_convert_state <= S_M1_convert_Leadin_5;
		end
		S_M1_convert_Leadin_5: begin
			SRAM_address <= SRAM_address_Y;
			SRAM_address_Y <= 18'd1 + SRAM_address_Y;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			V_shift_reg[3] <= SRAM_read_data[7:0];//SRAM_read_data:[U1,U0] put: U0 U0 U0 U1 X X 
			V_shift_reg[2] <= SRAM_read_data[15:8];
			V_shift_reg[1] <= SRAM_read_data[15:8];
			V_shift_reg[0] <= SRAM_read_data[15:8];
			
			
			S_M1_convert_state <= S_M1_convert_Leadin_6;
			

		end
		//delay state here
		//
		S_M1_convert_Leadin_6: begin
			SRAM_address <= SRAM_address_U;
			SRAM_address_U <= 18'd1 + SRAM_address_U;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			U_shift_reg[4] <= SRAM_read_data[15:8];//SRAM_read_data:[U2,U3] by this time in U_shift_register : U0 U0 U0 U1 U2 U3
			U_shift_reg[5] <= SRAM_read_data[7:0];

			S_M1_convert_state <= S_M1_convert_Leadin_7;

		end
		S_M1_convert_Leadin_7: begin
			SRAM_address <= SRAM_address_V;
			SRAM_address_V <= 18'd1 + SRAM_address_V;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			V_shift_reg[5] <= SRAM_read_data[7:0];
			V_shift_reg[4] <= SRAM_read_data[15:8];//same as U : V0 V0 V0 V1 V2 V3

			S_M1_convert_state <= S_M1_convert_Leadin_8;

		end
		S_M1_convert_Leadin_8: begin
			
			Y_shift_reg[2] <= SRAM_read_data[15:8];
			Y_shift_reg[3] <= SRAM_read_data[7:0];
			
			S_M1_convert_state <= S_M1_convert_Leadin_9;

		end
		S_M1_convert_Leadin_9: begin
			
			U_shift_reg[6] <= SRAM_read_data[15:8];
			U_shift_reg[7] <= SRAM_read_data[7:0];

			S_M1_convert_state <= S_M1_convert_Leadin_10;

		end
		S_M1_convert_Leadin_10: begin
			Y_upsampled[0] <= {{24{Y_shift_reg[0][15]}},Y_shift_reg[0]};
			Y_upsampled[1] <= {{24{Y_shift_reg[1][15]}},Y_shift_reg[1]};
			Y_upsampled[2] <= {{24{Y_shift_reg[2][15]}},Y_shift_reg[2]};
			Y_upsampled[3] <= {{24{Y_shift_reg[3][15]}},Y_shift_reg[3]};
			
			V_shift_reg[6] <= SRAM_read_data[15:8];
			V_shift_reg[7] <= SRAM_read_data[7:0];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_0;
			
			multiplier_mode <= 1'b1;
			UV_mode <= 1'b0;
		end

		//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  main duplicated state
		S_M1_convert_CommonCase_0: begin
			SRAM_address <= SRAM_address_U;
			SRAM_address_U <= 18'd1 + SRAM_address_U;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			U_shift_reg[0] <= U_shift_reg[1];
			U_shift_reg[1] <= U_shift_reg[2];
			U_shift_reg[2] <= U_shift_reg[3];
			U_shift_reg[3] <= U_shift_reg[4];
			U_shift_reg[4] <= U_shift_reg[5];
			U_shift_reg[5] <= U_shift_reg[6];
			U_shift_reg[6] <= U_shift_reg[7];
			
			U_upsampled[1] <= result;
			U_upsampled[0] <= U_shift_reg[2];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_1;
			
			UV_mode <= 1'b1;

		end
		S_M1_convert_CommonCase_1: begin
			SRAM_address <= SRAM_address_V;
			SRAM_address_V <= 18'd1 + SRAM_address_V;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			V_shift_reg[0] <= V_shift_reg[1];
			V_shift_reg[1] <= V_shift_reg[2];
			V_shift_reg[2] <= V_shift_reg[3];
			V_shift_reg[3] <= V_shift_reg[4];
			V_shift_reg[4] <= V_shift_reg[5];
			V_shift_reg[5] <= V_shift_reg[6];
			V_shift_reg[6] <= V_shift_reg[7];
			
			V_upsampled[1] <= result;
			V_upsampled[0] <= V_shift_reg[2];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_2;
			
			UV_mode <= 1'b0;
		end
		S_M1_convert_CommonCase_2: begin
			SRAM_address <= SRAM_address_Y;
			SRAM_address_Y <= 18'd1 + SRAM_address_Y;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			U_shift_reg[0] <= U_shift_reg[1];
			U_shift_reg[1] <= U_shift_reg[2];
			U_shift_reg[2] <= U_shift_reg[3];
			U_shift_reg[3] <= U_shift_reg[4];
			U_shift_reg[4] <= U_shift_reg[5];
			U_shift_reg[5] <= U_shift_reg[6];
			
			U_upsampled[3] <= result;
			U_upsampled[2] <= U_shift_reg[2];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_3;
			
			UV_mode <= 1'b1;
		end
		S_M1_convert_CommonCase_3: begin
			SRAM_address <= SRAM_address_Y;
			SRAM_address_Y <= 18'd1 + SRAM_address_Y;
			SRAM_we_n <= 1'b1;// read (along with address)
			
			U_shift_reg[6] <= SRAM_read_data[15:8];
			U_shift_reg[7] <= SRAM_read_data[7:0];
			
			V_shift_reg[0] <= V_shift_reg[1];
			V_shift_reg[1] <= V_shift_reg[2];
			V_shift_reg[2] <= V_shift_reg[3];
			V_shift_reg[3] <= V_shift_reg[4];
			V_shift_reg[4] <= V_shift_reg[5];
			V_shift_reg[5] <= V_shift_reg[6];
			
			V_upsampled[3] <= result;
			V_upsampled[2] <= V_shift_reg[2];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_4;
			
			multiplier_mode <= 1'b0;
			RGB_mode <= mode_R_Y_extra;
			
		end
		S_M1_convert_CommonCase_4: begin	
			V_shift_reg[6] <= SRAM_read_data[15:8];
			V_shift_reg[7] <= SRAM_read_data[7:0];
			
			red_buffer <= R;
			Y_temp <= Y_to_use;
			
			Y_temp_extra <= Y_extra_to_use;
			
			S_M1_convert_state <= S_M1_convert_CommonCase_5;
			
			RGB_mode <= mode_normal_GB;
		end
		S_M1_convert_CommonCase_5: begin
			SRAM_address <= SRAM_address_RGB;
			SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
			SRAM_we_n <= 1'b0;// write(along with address)
			SRAM_write_data <= {red_buffer,G};
			
			blue_buffer <= B;
			
			Y_shift_reg[0] <= SRAM_read_data[15:8];
			Y_shift_reg[1] <= SRAM_read_data[7:0];
			
			Y_upsampled[0] <= Y_upsampled[1];
			Y_upsampled[1] <= Y_upsampled[2];
			Y_upsampled[2] <= Y_upsampled[3];
			
			U_upsampled[0] <= U_upsampled[1];
			U_upsampled[1] <= U_upsampled[2];
			U_upsampled[2] <= U_upsampled[3];
			
			V_upsampled[0] <= V_upsampled[1];
			V_upsampled[1] <= V_upsampled[2];
			V_upsampled[2] <= V_upsampled[3];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_6;
			
			RGB_mode <= mode_R_R_extra;
		end
		S_M1_convert_CommonCase_6: begin
			SRAM_address <= SRAM_address_RGB;
			SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
			SRAM_we_n <= 1'b0;// write(along with address)
			SRAM_write_data <= {blue_buffer,R};
			
			Y_shift_reg[2] <= SRAM_read_data[15:8];
			Y_shift_reg[3] <= SRAM_read_data[7:0];
			
			pixel_nbr <= pixel_nbr + 18'd1;
			
			Y_temp <= Y_to_use;
			
			red_buffer_extra <= R_extra;
			
			S_M1_convert_state <= S_M1_convert_CommonCase_7;
			
			RGB_mode <= mode_normal_GB;
		end
		S_M1_convert_CommonCase_7: begin
			SRAM_address <= SRAM_address_RGB;
			SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
			SRAM_we_n <= 1'b0;// write(along with address)
			SRAM_write_data <= {G,B};
			
			pixel_nbr <= pixel_nbr + 18'd1;
			
			Y_upsampled[0] <= Y_upsampled[1];
			Y_upsampled[1] <= Y_upsampled[2];
			
			U_upsampled[0] <= U_upsampled[1];
			U_upsampled[1] <= U_upsampled[2];
			
			V_upsampled[0] <= V_upsampled[1];
			V_upsampled[1] <= V_upsampled[2];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_8;
			
			RGB_mode <= mode_extra_GB;
		end
		S_M1_convert_CommonCase_8: begin
			SRAM_address <= SRAM_address_RGB;
			SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
			SRAM_we_n <= 1'b0;// write(along with address)
			SRAM_write_data <= {red_buffer_extra,G};
			
			blue_buffer <= B;
			
			Y_upsampled[0] <= Y_upsampled[1];
			
			U_upsampled[0] <= U_upsampled[1];
			
			V_upsampled[0] <= V_upsampled[1];
			
			S_M1_convert_state <= S_M1_convert_CommonCase_9;
			
			RGB_mode <= mode_normal_R;
		end
		S_M1_convert_CommonCase_9: begin
			SRAM_address <= SRAM_address_RGB;
			SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
			SRAM_we_n <= 1'b0;// write(along with address)
			SRAM_write_data <= {blue_buffer,R};
			
			Y_temp <= Y_to_use;
			
			pixel_nbr <= pixel_nbr + 18'd1;
			
			S_M1_convert_state <= S_M1_convert_CommonCase_10;
			
			RGB_mode <= mode_normal_GB;
		end
		S_M1_convert_CommonCase_10: begin
			if (pixel_nbr < end_of_row) begin
				if (pixel_nbr < end_of_row - 18'd8) begin
					SRAM_address <= SRAM_address_RGB;
					SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
					SRAM_we_n <= 1'b0;// write(along with address)
					SRAM_write_data <= {G,B};
					
					pixel_nbr <= pixel_nbr + 18'd1;
					
					Y_upsampled[0] <= {24'd0,Y_shift_reg[0]};
					Y_upsampled[1] <= {24'd0,Y_shift_reg[1]};
					Y_upsampled[2] <= {24'd0,Y_shift_reg[2]};
					Y_upsampled[3] <= {24'd0,Y_shift_reg[3]};
					
					S_M1_convert_state <= S_M1_convert_CommonCase_0;
					
					multiplier_mode <= 1'b1;
					UV_mode <= 1'b0;	
				end else begin
					SRAM_address <= SRAM_address_RGB;
					SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
					SRAM_we_n <= 1'b0;// write(along with address)
					SRAM_write_data <= {G,B};
					
					pixel_nbr <= pixel_nbr + 18'd1;
					
					Y_upsampled[0] <= {24'd0,Y_shift_reg[0]};
					Y_upsampled[1] <= {24'd0,Y_shift_reg[1]};
					Y_upsampled[2] <= {24'd0,Y_shift_reg[2]};
					Y_upsampled[3] <= {24'd0,Y_shift_reg[3]};
					
					U_shift_reg[6] <= U_shift_reg[5];
					U_shift_reg[7] <= U_shift_reg[5];
					V_shift_reg[6] <= V_shift_reg[5];
					V_shift_reg[7] <= V_shift_reg[5];
					
					S_M1_convert_state <= S_M1_convert_CommonCase_0;
					
					multiplier_mode <= 1'b1;
					UV_mode <= 1'b0;
				end
			end else begin
				SRAM_address_Y <= SRAM_address_Y - 18'd2;
				SRAM_address_U <= SRAM_address_U - 18'd3;
				SRAM_address_V <= SRAM_address_V - 18'd3;
				
				row_nbr <= row_nbr + 9'd1;
				
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= 18'd1 + SRAM_address_RGB;
				SRAM_we_n <= 1'b0;// write(along with address)
				SRAM_write_data <= {G,B};
				
				pixel_nbr <= pixel_nbr + 18'd1;
				
				if (SRAM_address_Y < 17'd38399) begin
					S_M1_convert_state <= S_M1_convert_Leadin_0;
					end_of_row <= end_of_row + 18'd320;
				end else begin
					
					SRAM_address <= SRAM_address_RGB;
					SRAM_we_n <= 1'b0;// write(along with address)
					SRAM_write_data <= {G,B};
					
					Finish <= 1'b1;
					S_M1_convert_state <= S_M1_convert_IDLE;
				end
			end
		end
		default: S_M1_convert_state <= S_M1_convert_IDLE;
		endcase
	end
end


endmodule
		

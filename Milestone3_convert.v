
`timescale 1ns/100ps
`default_nettype none


`include "define_state.h"

module Milestone3_convert (
	input  logic          Clock,
    input  logic          Resetn,
	input logic           Convert_request,
	input logic   [7:0]   DPRAM_Q_read_ref,
	
	output logic  [17:0]  M3_advance_SRAM_address,
	input logic   [15:0]  SRAM_read_data,
	input logic           redo,
	//output logic          SRAM_we_n,
	output logic  [17:0]  SRAM_address,
	//output logic  [15:0]  SRAM_write_data,
	output logic  [15:0]  DPRAM_output_a,
	output logic  [15:0]  DPRAM_output_b,
	output logic          Finish
);








//---------------------------------------------------------------------------------------------------------------------   FSM S_M2_state
S_M3_state_type S_M3_state;
//---------------------------------------------------------------------------------------------------------------------   DP-RAMs



//<<<<<<<<<<<<<<<============== bitstream to matrix K          dual_port_RAM_Q

logic [7:0] address_Q_a;
logic [7:0] address_Q_b;
logic [15:0] write_data_Q_a;
logic [15:0] write_data_Q_b;
logic write_enable_Q_a;
logic write_enable_Q_b;
logic [15:0] read_data_Q_a;
logic [15:0] read_data_Q_b;

logic [7:0] port_b_addr;

dual_port_RAM_Q dual_port_RAM_inst0 (
	.address_a ( address_Q_a ),
	.address_b ( address_Q_b ),
	.clock ( Clock ),
	.data_a ( write_data_Q_a ),
	.data_b ( write_data_Q_b ),
	.wren_a ( write_enable_Q_a ),
	.wren_b ( write_enable_Q_b ),
	.q_a ( read_data_Q_a ),
	.q_b ( read_data_Q_b )
);


assign
	DPRAM_output_a = read_data_Q_a,
	DPRAM_output_b = read_data_Q_b;


logic debug_work;

//---------------------------------------------------------------------------------------------------------------   M2  Main  FSM
logic quantization_choice;

logic [15:0] loadwhat;


logic [5:0] remain,remain_Comb;
logic [6:0] step_counter,element_counter;
logic [7:0] address_Q_ref;
logic [15:0] write_data_temp;
logic [17:0] SRAM_addr_ref_R;
logic [31:0] SRAM_data_buf;
logic [1:0] first_2_bit_code;

logic [2:0] zero_counter,zero_counter_Comb;

always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		step_counter <= 7'd0;
		element_counter <= 7'd0;
		
		quantization_choice <= 1'd0;
		remain <= 6'd0;
		
		
		address_Q_a <= 8'd0;
		write_data_Q_a <= 16'd0;
		write_enable_Q_a <= 1'b0;
		write_enable_Q_b <= 1'b0;
		
		SRAM_address <= 18'd0;
		SRAM_data_buf <= 32'd0;
		SRAM_addr_ref_R <= 18'd76800;
		
		
		loadwhat <= 16'd0;
		
		S_M3_state <= S_M3_convert_IDLE;
		Finish <= 1'b0;
	end else begin
		write_enable_Q_a <= 1'b0;
		write_enable_Q_b <= 1'b0;
		
		
		
		case (S_M3_state)
		S_M3_convert_IDLE: begin
			if (Convert_request == 1'b1) begin
				S_M3_state <= S_M3_Leadin;
			end
				
		end
		S_M3_Leadin: begin//burst read
			step_counter <= step_counter + 7'd1;
			
			if (step_counter <= 7'd6) begin
				SRAM_address <= SRAM_addr_ref_R;
				SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
			end
			if (step_counter == 7'd5) begin
				quantization_choice <= SRAM_read_data[15];
			end
			if (step_counter == 7'd7) begin
				SRAM_data_buf[31:16] <= SRAM_read_data;
				remain <= remain + 6'd16;
			end
			if (step_counter == 7'd8) begin
				SRAM_data_buf[15:0] <= SRAM_read_data;
				remain <= remain + 6'd16;

				S_M3_state <= S_M3_read_2_leadin;
			end
		end
		S_M3_read_2_leadin: begin//decide which branch to go
			first_2_bit_code = SRAM_data_buf[31:30];
			write_data_temp = 16'd0;
			case(first_2_bit_code)
			2'b00: begin
				write_data_temp = {{13{SRAM_data_buf[29]}},{SRAM_data_buf[29:27]}};
				case(read_data_Q_b)
				16'd1 : write_data_Q_a <= {{write_data_temp[14:0]},1'd0};
				16'd2 : write_data_Q_a <= {{write_data_temp[13:0]},2'd0};
				16'd3 : write_data_Q_a <= {{write_data_temp[12:0]},3'd0};
				16'd4 : write_data_Q_a <= {{write_data_temp[11:0]},4'd0};
				16'd5 : write_data_Q_a <= {{write_data_temp[10:0]},5'd0};
				16'd6 : write_data_Q_a <= {{write_data_temp[9:0]},6'd0};
				endcase
				address_Q_a <= address_Q_ref;
				write_enable_Q_a <= 1'b1;
				
				element_counter <= element_counter + 6'd1;
				
				S_M3_state <= S_M3_00_R3W1_delay;
			end
			2'b01: begin
				write_data_temp = {{13{SRAM_data_buf[29]}},{SRAM_data_buf[29:27]}};
				case(read_data_Q_b)
				16'd1 : write_data_Q_a <= {{write_data_temp[14:0]},1'd0};
				16'd2 : write_data_Q_a <= {{write_data_temp[13:0]},2'd0};
				16'd3 : write_data_Q_a <= {{write_data_temp[12:0]},3'd0};
				16'd4 : write_data_Q_a <= {{write_data_temp[11:0]},4'd0};
				16'd5 : write_data_Q_a <= {{write_data_temp[10:0]},5'd0};
				16'd6 : write_data_Q_a <= {{write_data_temp[9:0]},6'd0};
				endcase
				address_Q_a <= address_Q_ref;
				write_enable_Q_a <= 1'b1;
				remain_Comb = remain - 6'd5;
				if (remain_Comb <= 6'd16) begin
					SRAM_address <= SRAM_addr_ref_R;
					SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
				end
				remain <= remain_Comb;
				SRAM_data_buf <= {{SRAM_data_buf[26:0]},5'd0};
				
				element_counter <= element_counter + 6'd1;

				S_M3_state <= S_M3_wait;
			end
			2'b10: begin
				if (SRAM_data_buf[29] == 1'd0) begin
					write_data_temp = {{10{SRAM_data_buf[28]}},{SRAM_data_buf[28:23]}};
					case(read_data_Q_b)
					16'd1 : write_data_Q_a <= {{write_data_temp[14:0]},1'd0};
					16'd2 : write_data_Q_a <= {{write_data_temp[13:0]},2'd0};
					16'd3 : write_data_Q_a <= {{write_data_temp[12:0]},3'd0};
					16'd4 : write_data_Q_a <= {{write_data_temp[11:0]},4'd0};
					16'd5 : write_data_Q_a <= {{write_data_temp[10:0]},5'd0};
					16'd6 : write_data_Q_a <= {{write_data_temp[9:0]},6'd0};
					endcase
					address_Q_a <= address_Q_ref;
					write_enable_Q_a <= 1'b1;
					remain_Comb = remain - 6'd9;
					if (remain_Comb <= 6'd16) begin
						SRAM_address <= SRAM_addr_ref_R;
						SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
					end
					remain <= remain_Comb;
					SRAM_data_buf <= {{SRAM_data_buf[22:0]},9'd0};
					
					element_counter <= element_counter + 6'd1;
					
					S_M3_state <= S_M3_wait;
				end else begin
					if (SRAM_data_buf[28] == 1'd0) begin
						write_data_Q_a <= 16'd0;
						address_Q_a <= address_Q_ref;
						write_enable_Q_a <= 1'b1;
						remain_Comb = remain - 6'd4;
						if (remain_Comb <= 6'd16) begin
							SRAM_address <= SRAM_addr_ref_R;
							SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
						end
						remain <= remain_Comb;
						SRAM_data_buf <= {{SRAM_data_buf[27:0]},4'd0};
						
						element_counter <= element_counter + 6'd1;
						if (element_counter < 6'd63) begin
							S_M3_state <= S_M3_10_10_ZeroRun;
						end else begin
							S_M3_state <= S_M3_wait;
						end
					end else begin
						write_data_temp = {{7{SRAM_data_buf[27]}},{SRAM_data_buf[27:19]}};
						case(read_data_Q_b)
						16'd1 : write_data_Q_a <= {{write_data_temp[14:0]},1'd0};
						16'd2 : write_data_Q_a <= {{write_data_temp[13:0]},2'd0};
						16'd3 : write_data_Q_a <= {{write_data_temp[12:0]},3'd0};
						16'd4 : write_data_Q_a <= {{write_data_temp[11:0]},4'd0};
						16'd5 : write_data_Q_a <= {{write_data_temp[10:0]},5'd0};
						16'd6 : write_data_Q_a <= {{write_data_temp[9:0]},6'd0};
						endcase
						address_Q_a <= address_Q_ref;
						write_enable_Q_a <= 1'b1;
						remain_Comb = remain - 6'd13;
						if (remain_Comb <= 6'd16) begin
							SRAM_address <= SRAM_addr_ref_R;
							SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
						end
						remain <= remain_Comb;
						SRAM_data_buf <= {{SRAM_data_buf[18:0]},13'd0};
						
						element_counter <= element_counter + 6'd1;
						
						S_M3_state <= S_M3_wait;
					end
				end	
			end
			2'b11: begin
				if ({SRAM_data_buf[29:27]} == 3'd0) begin
					write_data_Q_a <= 16'd0;
					address_Q_a <= address_Q_ref;
					write_enable_Q_a <= 1'b1;
					zero_counter <= 3'd7;
					remain_Comb = remain - 6'd5;
					if (remain_Comb <= 6'd16) begin
						SRAM_address <= SRAM_addr_ref_R;
						SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
					end
					remain <= remain_Comb;
					SRAM_data_buf <= {{SRAM_data_buf[26:0]},5'd0};
					
					element_counter <= element_counter + 6'd1;
					
					S_M3_state <= S_M3_11_fillZero;
				end else begin
					write_data_Q_a <= 16'd0;
					address_Q_a <= address_Q_ref;
					write_enable_Q_a <= 1'b1;
					zero_counter_Comb = {SRAM_data_buf[29:27]} - 3'd1;
					zero_counter <= zero_counter_Comb;
					remain_Comb = remain - 6'd5;
					if (remain_Comb <= 6'd16) begin
						SRAM_address <= SRAM_addr_ref_R;
						SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
					end
					remain <= remain_Comb;
					SRAM_data_buf <= {{SRAM_data_buf[26:0]},5'd0};
					
					element_counter <= element_counter + 6'd1;
					
					if (zero_counter_Comb == 3'd0) begin
						S_M3_state <= S_M3_wait;
					end else begin
						S_M3_state <= S_M3_11_fillZero;
					end
				end
			end
			endcase
		end
		S_M3_00_R3W1_delay: begin
			S_M3_state <= S_M3_00_R3W1;//delay 1 cycle : wait read_data_Q_b change
		end
		S_M3_00_R3W1: begin
			write_data_temp = {{13{SRAM_data_buf[26]}},{SRAM_data_buf[26:24]}};
			case(read_data_Q_b)
			16'd1 : write_data_Q_a <= {{write_data_temp[14:0]},1'd0};
			16'd2 : write_data_Q_a <= {{write_data_temp[13:0]},2'd0};
			16'd3 : write_data_Q_a <= {{write_data_temp[12:0]},3'd0};
			16'd4 : write_data_Q_a <= {{write_data_temp[11:0]},4'd0};
			16'd5 : write_data_Q_a <= {{write_data_temp[10:0]},5'd0};
			16'd6 : write_data_Q_a <= {{write_data_temp[9:0]},6'd0};
			endcase
			address_Q_a <= address_Q_ref;
			write_enable_Q_a <= 1'b1;
			remain_Comb = remain - 6'd8;
			if (remain_Comb <= 6'd16) begin
				SRAM_address <= SRAM_addr_ref_R;
				SRAM_addr_ref_R <= SRAM_addr_ref_R + 18'd1;
			end
			remain <= remain_Comb;
			SRAM_data_buf <= {{SRAM_data_buf[23:0]},8'd0};
			
			element_counter <= element_counter + 7'd1;
			S_M3_state <= S_M3_wait;
		end
		S_M3_10_10_ZeroRun: begin
			if (element_counter < 7'd63) begin
				write_data_Q_a <= 16'd0;
				address_Q_a <= address_Q_ref;
				write_enable_Q_a <= 1'b1;
				
				element_counter <= element_counter + 7'd1;
			end else begin
				write_data_Q_a <= 16'd0;
				address_Q_a <= address_Q_ref;
				write_enable_Q_a <= 1'b1;
				element_counter <= element_counter + 7'd1;
				S_M3_state <= S_M3_wait;
			end
			
			if ((remain <= 6'd16)) begin
				remain <= remain +6'd16;
				
				loadwhat <= SRAM_read_data;
				
				case(remain)
				6'd16 : SRAM_data_buf[15:0] <= SRAM_read_data;
				6'd15 : SRAM_data_buf[16:1] <= SRAM_read_data;
				6'd14 : SRAM_data_buf[17:2] <= SRAM_read_data;
				6'd13 : SRAM_data_buf[18:3] <= SRAM_read_data;
				6'd12 : SRAM_data_buf[19:4] <= SRAM_read_data;
				6'd11 : SRAM_data_buf[20:5] <= SRAM_read_data;
				6'd10 : SRAM_data_buf[21:6] <= SRAM_read_data;
				6'd9  : SRAM_data_buf[22:7] <= SRAM_read_data;
				6'd8  : SRAM_data_buf[23:8] <= SRAM_read_data;
				6'd7  : SRAM_data_buf[24:9] <= SRAM_read_data;
				6'd6  : SRAM_data_buf[25:10] <= SRAM_read_data;
				6'd5  : SRAM_data_buf[26:11] <= SRAM_read_data;
				6'd4  : SRAM_data_buf[27:12] <= SRAM_read_data;
				6'd3  : SRAM_data_buf[28:13] <= SRAM_read_data;
				6'd2  : SRAM_data_buf[29:14] <= SRAM_read_data;
				6'd1  : SRAM_data_buf[30:15] <= SRAM_read_data;
				6'd0  : SRAM_data_buf[31:16] <= SRAM_read_data;
				endcase
			end	
			
		end
		S_M3_11_fillZero: begin
			if (zero_counter > 3'd0) begin
				write_data_Q_a <= 16'd0;
				address_Q_a <= address_Q_ref;
				write_enable_Q_a <= 1'b1;
				zero_counter <= zero_counter - 3'd1;
				element_counter <= element_counter + 7'd1;
			end else begin
				S_M3_state <= S_M3_wait;
			end
			
			if ((remain <= 6'd16)) begin
				remain <= remain +6'd16;
				
				
				loadwhat <= SRAM_read_data;
				
				case(remain)
				6'd16 : SRAM_data_buf[15:0] <= SRAM_read_data;
				6'd15 : SRAM_data_buf[16:1] <= SRAM_read_data;
				6'd14 : SRAM_data_buf[17:2] <= SRAM_read_data;
				6'd13 : SRAM_data_buf[18:3] <= SRAM_read_data;
				6'd12 : SRAM_data_buf[19:4] <= SRAM_read_data;
				6'd11 : SRAM_data_buf[20:5] <= SRAM_read_data;
				6'd10 : SRAM_data_buf[21:6] <= SRAM_read_data;
				6'd9  : SRAM_data_buf[22:7] <= SRAM_read_data;
				6'd8  : SRAM_data_buf[23:8] <= SRAM_read_data;
				6'd7  : SRAM_data_buf[24:9] <= SRAM_read_data;
				6'd6  : SRAM_data_buf[25:10] <= SRAM_read_data;
				6'd5  : SRAM_data_buf[26:11] <= SRAM_read_data;
				6'd4  : SRAM_data_buf[27:12] <= SRAM_read_data;
				6'd3  : SRAM_data_buf[28:13] <= SRAM_read_data;
				6'd2  : SRAM_data_buf[29:14] <= SRAM_read_data;
				6'd1  : SRAM_data_buf[30:15] <= SRAM_read_data;
				6'd0  : SRAM_data_buf[31:16] <= SRAM_read_data;
				endcase
			end
			
			
		end
		S_M3_wait: begin
		
			if ((remain <= 6'd16)) begin
				remain <= remain +6'd16;
					
				loadwhat <= SRAM_read_data;
				
				case(remain)
				6'd16 : SRAM_data_buf[15:0] <= SRAM_read_data;
				6'd15 : SRAM_data_buf[16:1] <= SRAM_read_data;
				6'd14 : SRAM_data_buf[17:2] <= SRAM_read_data;
				6'd13 : SRAM_data_buf[18:3] <= SRAM_read_data;
				6'd12 : SRAM_data_buf[19:4] <= SRAM_read_data;
				6'd11 : SRAM_data_buf[20:5] <= SRAM_read_data;
				6'd10 : SRAM_data_buf[21:6] <= SRAM_read_data;
				6'd9  : SRAM_data_buf[22:7] <= SRAM_read_data;
				6'd8  : SRAM_data_buf[23:8] <= SRAM_read_data;
				6'd7  : SRAM_data_buf[24:9] <= SRAM_read_data;
				6'd6  : SRAM_data_buf[25:10] <= SRAM_read_data;
				6'd5  : SRAM_data_buf[26:11] <= SRAM_read_data;
				6'd4  : SRAM_data_buf[27:12] <= SRAM_read_data;
				6'd3  : SRAM_data_buf[28:13] <= SRAM_read_data;
				6'd2  : SRAM_data_buf[29:14] <= SRAM_read_data;
				6'd1  : SRAM_data_buf[30:15] <= SRAM_read_data;
				6'd0  : SRAM_data_buf[31:16] <= SRAM_read_data;
				endcase
			end
		
		
			if (element_counter < 7'd64) begin
				S_M3_state <= S_M3_read_2_leadin;
				
			end else begin
				element_counter <= 7'd0;
				S_M3_state <= S_M3_read;
				Finish <= 1'd1;//finish Leadin Compute Q
				address_Q_a <= {2'd0,{DPRAM_Q_read_ref[4:0]},1'd0};
				port_b_addr <= {2'd0,{DPRAM_Q_read_ref[4:0]},1'd0} + 8'd1;
				write_enable_Q_a <= 1'b0;
				write_enable_Q_b <= 1'b0;
			end 
		end
		S_M3_read: begin
			address_Q_a <= {2'd0,{DPRAM_Q_read_ref[4:0]},1'd0};
			port_b_addr <= {2'd0,{DPRAM_Q_read_ref[4:0]},1'd0} + 8'd1;
			write_enable_Q_a <= 1'b0;
			write_enable_Q_b <= 1'b0;
			
			if (Convert_request == 1'd1) begin
				S_M3_state <= S_M3_wait_Qb_update;
			end
			
			if (redo == 1'd1) begin
				step_counter <= 7'd0;
				element_counter <= 7'd0;
				
				quantization_choice <= 1'd0;
				remain <= 6'd0;
				
				
				address_Q_a <= 8'd0;
				write_data_Q_a <= 16'd0;
				write_enable_Q_a <= 1'b0;
				write_enable_Q_b <= 1'b0;
				
				SRAM_address <= 18'd0;
				SRAM_data_buf <= 32'd0;
				SRAM_addr_ref_R <= 18'd76800;
				
				S_M3_state <= S_M3_convert_IDLE;
				Finish <= 1'b0;
			end
		end
		S_M3_wait_Qb_update: begin
			S_M3_state <= S_M3_read_2_leadin;
		end
		default: S_M3_state <= S_M3_convert_IDLE;
		endcase
	end
end
//---------------------------------------------------------------------------------------------------------------    target address reference
assign 	M3_advance_SRAM_address = SRAM_addr_ref_R - 18'd1;
assign address_Q_b = (S_M3_state == S_M3_read)? port_b_addr : (quantization_choice == 1'd0) ? address_Q_ref + 8'd64 : address_Q_ref + 8'd128;
always_comb begin
	address_Q_ref = 8'd0;

	case(element_counter)
		6'd0 :begin
			address_Q_ref = 8'd0;
		end
		6'd1 :begin
			address_Q_ref = 8'd1;
		end
		6'd2 :begin
			address_Q_ref = 8'd8;
		end
		6'd3 :begin
			address_Q_ref = 8'd16;
		end
		6'd4 :begin
			address_Q_ref = 8'd9;
		end
		6'd5 :begin
			address_Q_ref = 8'd2;
		end
		6'd6 :begin
			address_Q_ref = 8'd3;
		end
		6'd7 :begin
			address_Q_ref = 8'd10;
		end
		6'd8 :begin
			address_Q_ref = 8'd17;
		end
		6'd9 :begin
			address_Q_ref = 8'd24;
		end
		6'd10 :begin
			address_Q_ref = 8'd32;
		end
		6'd11 :begin
			address_Q_ref = 8'd25;
		end
		6'd12 :begin
			address_Q_ref = 8'd18;
		end
		6'd13 :begin
			address_Q_ref = 8'd11;
		end
		6'd14 :begin
			address_Q_ref = 8'd4;
		end
		6'd15 :begin
			address_Q_ref = 8'd5;
		end
		6'd16 :begin
			address_Q_ref = 8'd12;
		end
		6'd17 :begin
			address_Q_ref = 8'd19;
		end
		6'd18 :begin
			address_Q_ref = 8'd26;
		end
		6'd19 :begin
			address_Q_ref = 8'd33;
		end
		6'd20 :begin
			address_Q_ref = 8'd40;
		end
		6'd21 :begin
			address_Q_ref = 8'd48;
		end
		6'd22 :begin
			address_Q_ref = 8'd41;
		end
		6'd23 :begin
			address_Q_ref = 8'd34;
		end
		6'd24 :begin
			address_Q_ref = 8'd27;
		end
		6'd25 :begin
			address_Q_ref = 8'd20;
		end
		6'd26 :begin
			address_Q_ref = 8'd13;
		end
		6'd27 :begin
			address_Q_ref = 8'd6;
		end
		6'd28 :begin
			address_Q_ref = 8'd7;
		end
		6'd29 :begin
			address_Q_ref = 8'd14;
		end
		6'd30 :begin
			address_Q_ref = 8'd21;
		end
		6'd31 :begin
			address_Q_ref = 8'd28;
		end
		6'd32 :begin
			address_Q_ref = 8'd35;
		end
		6'd33 :begin
			address_Q_ref = 8'd42;
		end
		6'd34 :begin
			address_Q_ref = 8'd49;
		end
		6'd35 :begin
			address_Q_ref = 8'd56;
		end
		6'd36 :begin
			address_Q_ref = 8'd57;
		end
		6'd37 :begin
			address_Q_ref = 8'd50;
		end
		6'd38 :begin
			address_Q_ref = 8'd43;
		end
		6'd39 :begin
			address_Q_ref = 8'd36;
		end
		6'd40 :begin
			address_Q_ref = 8'd29;
		end
		6'd41 :begin
			address_Q_ref = 8'd22;
		end
		6'd42 :begin
			address_Q_ref = 8'd15;
		end
		6'd43 :begin
			address_Q_ref = 8'd23;
		end
		6'd44 :begin
			address_Q_ref = 8'd30;
		end
		6'd45 :begin
			address_Q_ref = 8'd37;
		end
		6'd46 :begin
			address_Q_ref = 8'd44;
		end
		6'd47 :begin
			address_Q_ref = 8'd51;
		end
		6'd48 :begin
			address_Q_ref = 8'd58;
		end
		6'd49 :begin
			address_Q_ref = 8'd59;
		end
		6'd50 :begin
			address_Q_ref = 8'd52;
		end
		6'd51 :begin
			address_Q_ref = 8'd45;
		end
		6'd52 :begin
			address_Q_ref = 8'd38;
		end
		6'd53 :begin
			address_Q_ref = 8'd31;
		end
		6'd54 :begin
			address_Q_ref = 8'd39;
		end
		6'd55 :begin
			address_Q_ref = 8'd46;
		end
		6'd56 :begin
			address_Q_ref = 8'd53;
		end
		6'd57 :begin
			address_Q_ref = 8'd60;
		end
		6'd58 :begin
			address_Q_ref = 8'd61;
		end
		6'd59 :begin
			address_Q_ref = 8'd54;
		end
		6'd60 :begin
			address_Q_ref = 8'd47;
		end
		6'd61 :begin
			address_Q_ref = 8'd55;
		end
		6'd62 :begin
			address_Q_ref = 8'd62;
		end
		6'd63 :begin
			address_Q_ref = 8'd63;
		end
	endcase
end



endmodule

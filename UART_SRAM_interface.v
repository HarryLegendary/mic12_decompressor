//Hengli Zhu & Tianyi Lee  Delete Header Filter

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// This module monitors the data from UART
// It also assembles and writes the data into the SRAM
module UART_SRAM_interface (
   input  logic            Clock,
   input  logic            Resetn, 

   input  logic            UART_RX_I,
   input  logic            Initialize,
   input  logic            Enable,
   
   output logic   [17:0]   SRAM_address,
   output logic   [15:0]   SRAM_write_data,
   output logic            SRAM_we_n,
   output logic [3:0]	   Frame_error
);

UART_SRAM_state_type UART_SRAM_state;

logic UART_rx_unload_data;
logic UART_rx_empty;
logic UART_rx_enable;
logic [7:0] UART_rx_data;


// UART_Receiver
UART_Receive_Controller UART_RX (
	.Clock_50(Clock),
	.Resetn(Resetn),
	
	.Enable(UART_rx_enable),
	.Unload_data(UART_rx_unload_data),
	.RX_data(UART_rx_data),
	.Empty(UART_rx_empty),
	.Overrun(),
	.Frame_error(Frame_error),
	
	// UART pin
	.UART_RX_I(UART_RX_I)
);

// Receive data from UART
always_ff @ (posedge Clock or negedge Resetn) begin
	if (~Resetn) begin
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		
		UART_rx_enable <= 1'b0;
		UART_rx_unload_data <= 1'b0;
		
		
		UART_SRAM_state <= S_US_IDLE;
	end else begin
		if (Initialize == 1'b1) begin
			UART_rx_enable <= 1'b0;
			UART_rx_unload_data <= 1'b0;
			
			SRAM_we_n <= 1'b1;
			SRAM_write_data <= 16'd0;
			SRAM_address <= 18'd76800;

			
			UART_SRAM_state <= S_US_IDLE;						
		end else begin
			case (UART_SRAM_state)
			S_US_IDLE: begin
				if (Enable == 1'b1) begin
					// Start receiving data from UART
					UART_SRAM_state <= S_US_START_FIRST_BYTE_RECEIVE;
					UART_rx_enable <= 1'b1;
					SRAM_address <= 18'd76800;				
				end
			end

			S_US_START_FIRST_BYTE_RECEIVE: begin
				if (UART_rx_empty == 1'b0) begin
					// a byte of data is available
					UART_rx_unload_data <= 1'b1;

					// Assemble the first byte of data
					SRAM_write_data[15:8] <= UART_rx_data;
					
					UART_SRAM_state <= S_US_WRITE_FIRST_BYTE;				
				end
			end
			S_US_WRITE_FIRST_BYTE: begin
				if (UART_rx_empty == 1'b1) begin
					// Clear the unload flag
					UART_rx_unload_data <= 1'b0;

					UART_SRAM_state <= S_US_START_SECOND_BYTE_RECEIVE;				
				end				
			end
			S_US_START_SECOND_BYTE_RECEIVE: begin
				if (UART_rx_empty == 1'b0) begin
					// a byte of data is available
					UART_rx_unload_data <= 1'b1;

					// Assemble the second byte of data
					SRAM_write_data[7:0] <= UART_rx_data;
					
					// Write the data into the RAM
					SRAM_we_n <= 1'b0;
					
					UART_SRAM_state <= S_US_WRITE_SECOND_BYTE;				
				end
			end
			S_US_WRITE_SECOND_BYTE: begin
				if (UART_rx_empty == 1'b1) begin
					// Clear the unload flag
					UART_rx_unload_data <= 1'b0;
					
					SRAM_we_n <= 1'b1;					
					
					if (SRAM_address < 18'h3FFFF) begin
						SRAM_address <= SRAM_address + 9'd1;
						
						UART_SRAM_state <= S_US_START_FIRST_BYTE_RECEIVE;
					end else begin
						// Only receive at most 512 KB of data
						// That's the capacity of the SRAM
						UART_SRAM_state <= S_US_IDLE;
						
						SRAM_address <= 18'h3FFFF;
						
						UART_rx_enable <= 1'b0;					
					end
				end
			end
			default: UART_SRAM_state <= S_US_IDLE;
			endcase
		end
	end
end

endmodule

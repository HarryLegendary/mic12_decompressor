`ifndef DEFINE_STATE

// This defines the states
typedef enum logic [3:0] {
	S_TOP_IDLE,
	S_TOP_ENABLE_UART_RX,
	S_TOP_WAIT_UART_RX,
	S_burst_read,
	S_M3_TOP_converting,
	S_M2_TOP_converting,
	S_M1_TOP_converting,
	S_VGA
} TOP_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [5:0] {
	S_M1_convert_IDLE,
	
	S_M1_convert_Leadin_0,
	S_M1_convert_Leadin_1,
	S_M1_convert_Leadin_2,
	S_M1_convert_Leadin_3,
	S_M1_convert_Leadin_4,
	S_M1_convert_Leadin_5,
	S_M1_convert_Leadin_6,
	S_M1_convert_Leadin_7,
	S_M1_convert_Leadin_8,
	S_M1_convert_Leadin_9,
	S_M1_convert_Leadin_10,

	S_M1_convert_CommonCase_0,
	S_M1_convert_CommonCase_1,
	S_M1_convert_CommonCase_2,
	S_M1_convert_CommonCase_3,
	S_M1_convert_CommonCase_4,
	S_M1_convert_CommonCase_5,
	S_M1_convert_CommonCase_6,
	S_M1_convert_CommonCase_7,
	S_M1_convert_CommonCase_8,
	S_M1_convert_CommonCase_9,
	S_M1_convert_CommonCase_10

} S_M1_convert_state_type;

typedef enum logic [3:0] {
	S_M2_Leadin_CQ,
	S_M2_Leadin_CT,
	S_M2_load_T1,
	S_M2_CommonCase_1,
	S_M2_load_S_prime1,
	S_M2_CommonCase_2,
	S_M2_Leadout_CS,
	S_M2_Leadout_WS,
	S_M2_convert_IDLE
} S_M2_state_type;

typedef enum logic [3:0] {
	S_M3_Leadin,
	S_M3_read_2_leadin,
	S_M3_00_R3W1,
	S_M3_00_R3W1_delay,
	S_M3_10_10_ZeroRun,
	S_M3_wait_Qb_update,
	S_M3_11_fillZero,
	S_M3_wait,
	S_M3_read,
	S_M3_convert_IDLE
} S_M3_state_type;


`define DEFINE_STATE 1
`endif

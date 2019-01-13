onbreak {resume}
transcript on

set PrefMain(saveLines) 50000
.main clear

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# load designs
vlog -sv -svinputport=var -work rtl_work convert_hex_to_seven_segment.v
vlog -sv -svinputport=var -work rtl_work VGA_Controller.v
vlog -sv -svinputport=var -work rtl_work PB_Controller.v
vlog -sv -svinputport=var -work rtl_work +define+SIMULATION SRAM_Controller.v
vlog -sv -svinputport=var -work rtl_work tb_SRAM_Emulator.v
vlog -sv -svinputport=var -work rtl_work +define+SIMULATION UART_Receive_Controller.v
vlog -sv -svinputport=var -work rtl_work VGA_SRAM_interface.v
vlog -sv -svinputport=var -work rtl_work UART_SRAM_interface.v
vlog -sv -svinputport=var -work rtl_work Clock_100_PLL.v
vlog -sv -svinputport=var -work rtl_work +define+SIMULATION project_Group26.v

vlog -sv -svinputport=var -work rtl_work Milestone1_convert.v
vlog -sv -svinputport=var -work rtl_work Milestone2_convert.v
vlog -sv -svinputport=var -work rtl_work Milestone3_convert.v

vlog -sv -svinputport=var -work rtl_work dual_port_RAM_T.v
vlog -sv -svinputport=var -work rtl_work dual_port_RAM_S.v
vlog -sv -svinputport=var -work rtl_work dual_port_RAM_C.v
vlog -sv -svinputport=var -work rtl_work dual_port_RAM_Q.v

vlog -sv -svinputport=var -work rtl_work tb_project_Group26.v

# specify library for simulation
vsim -t 100ps -L altera_mf_ver -lib rtl_work tb_project_Group26

# Clear previous simulation
restart -f

# activate waveform simulation
view wave

# add signals to waveform


#add wave uut/top_state


add wave Clock_50

add wave uut/top_state
add wave uut/Milestone2_unit/Milestone3_unit/S_M3_state
add wave uut/Milestone2_unit/S_M2_state
add wave uut/Milestone1_unit/S_M1_convert_state
add wave -unsigned uut/Milestone2_unit/stepCounter_read

add wave uut/Milestone2_unit/Milestone3_unit/Convert_request
add wave uut/Milestone2_unit/Milestone3_unit/Finish


add wave -hex uut/Milestone2_unit/Milestone3_unit/SRAM_read_data
add wave -hex uut/Milestone2_unit/Milestone3_unit/SRAM_data_buf
add wave -unsigned uut/Milestone2_unit/Milestone3_unit/element_counter

add wave -hex uut/SRAM_read_data
add wave -hex uut/Milestone2_unit/Milestone3_unit/loadwhat

add wave -unsigned uut/Milestone2_unit/Milestone3_unit/address_Q_b
add wave -unsigned uut/Milestone2_unit/Milestone3_unit/element_counter
add wave -hex uut/Milestone2_unit/Milestone3_unit/read_data_Q_b

add wave -hex uut/Milestone2_unit/write_data_S_a
add wave -hex uut/Milestone2_unit/write_data_S_b

add wave uut/SRAM_we_n
add wave -hex uut/SRAM_address
add wave -hex uut/VGA_SRAM_address
add wave -hex uut/SRAM_write_data
add wave -hex uut/SRAM_read_data

add wave -hex uut/Milestone2_unit/SRAM_addr_ref_W
add wave -hex uut/Milestone2_unit/M2_SRAM_address
add wave -hex uut/Milestone2_unit/M3_SRAM_address




add wave -hex uut/Milestone2_unit/oprand1
add wave -hex uut/Milestone2_unit/oprand2
add wave -hex uut/Milestone2_unit/oprand3
add wave -hex uut/Milestone2_unit/oprand4
add wave -hex uut/Milestone2_unit/oprand5
add wave -hex uut/Milestone2_unit/oprand6
add wave -hex uut/Milestone2_unit/oprand7
add wave -hex uut/Milestone2_unit/oprand8
# format signal names in waveform
configure wave -signalnamewidth 1

# run complete simulation
run -all

# save the SRAM content for inspection
mem save -o SRAM.mem -f mti -data hex -addr hex -startaddress 0 -endaddress 262143 -wordsperline 8 /tb_project_Group26/SRAM_component/SRAM_data

simstats
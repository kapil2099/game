# This script is designed to be run from the Tcl console
# within an existing Vivado project for the Zybo Z7-20.
#
# It will:
# 1. Package the custom UART IP.
# 2. Create a block design.
# 3. Add and configure the Zynq PS7 using board presets.
# 4. Add the custom UART IP and ILA debugger.
# 5. Connect all components automatically.
# 6. Add the constraints file.

puts "INFO: Starting block design creation script..."

# --- Setup Paths ---
set proj_dir [get_property DIRECTORY [current_project]]
set ip_repo_path "${proj_dir}/[get_property NAME [current_project]].srcs/sources_1/ip"

# Get the script's directory to resolve relative paths cleanly
set script_dir [file dirname [file normalize [info script]]]

# --- Package the custom IP ---
puts "INFO: Packaging custom AXI UART IP..."
file mkdir ${ip_repo_path}
set_property ip_repo_paths ${ip_repo_path} [current_project]
update_ip_catalog

# Create a new IP core definition using the correct positional syntax
ipx::create_core user.org user uart_axilite_wrapper 1.1

# Set all metadata using separate, robust set_property commands
set_property display_name "AXI Lite UART with ILA" [ipx::current_core]
set_property description "AXI Lite UART with loopback test and ILA debug signals" [ipx::current_core]
set_property taxonomy /User [ipx::current_core]

# Add source files to the new IP core
ipx::add_file_group {Verilog Source} [ipx::current_core]
ipx::add_file "${script_dir}/../ip/uart_tx.v" [ipx::get_file_groups {Verilog Source} -of_objects [ipx::current_core]]
ipx::add_file "${script_dir}/../ip/uart_rx.v" [ipx::get_file_groups {Verilog Source} -of_objects [ipx::current_core]]
ipx::add_file "${script_dir}/../ip/uart_axilite_wrapper.v" [ipx::get_file_groups {Verilog Source} -of_objects [ipx::current_core]]

# Update the compile order to ensure the top module is identified
ipx::update_compile_order [ipx::current_core]

# Infer interfaces and save the IP
ipx::infer_bus_interface s_axi_aclk s_axi_aclk [ipx::current_core]
ipx::infer_bus_interface s_axi_aresetn s_axi_aresetn [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog

# --- Create Block Design ---
puts "INFO: Creating new block design 'design_1'..."
create_bd_design "design_1"

# Add Zynq PS
puts "INFO: Adding and configuring Zynq PS7..."
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_board_preset "ZYNQ7_PS" [get_bd_cells processing_system7_0]

# Add custom UART IP
puts "INFO: Adding custom UART IP to block design..."
create_bd_cell -type ip -vlnv user.org:user:uart_axilite_wrapper:1.1 uart_axilite_wrapper_0

# Connect AXI interface
puts "INFO: Connecting AXI interfaces..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {Master "Processing System 7" Clk "Auto"} [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Slave "/uart_axilite_wrapper_0/s_axi" Clk "Auto" Connect "Auto"} [get_bd_intf_pins uart_axilite_wrapper_0/s_axi]

# Make UART pins external
make_bd_pins_external [get_bd_pins uart_axilite_wrapper_0/i_rxd]
make_bd_pins_external [get_bd_pins uart_axilite_wrapper_0/o_txd]

# Connect interrupt
puts "INFO: Connecting interrupt..."
create_bd_port -dir I -type intr interrupt
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/interrupt] [get_bd_ports interrupt]
set_property -dict [list CONFIG.SENSITIVITY {LEVEL_HIGH}] [get_bd_ports interrupt]
connect_bd_net [get_bd_ports interrupt] [get_bd_pins processing_system7_0/IRQ_F2P]

# Add ILA for Debugging
puts "INFO: Adding ILA for debugging..."
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {4} CONFIG.C_PROBE0_WIDTH {1} CONFIG.C_PROBE1_WIDTH {1} CONFIG.C_PROBE2_WIDTH {1} CONFIG.C_PROBE3_WIDTH {8}] [get_bd_cells ila_0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins ila_0/clk]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_tx_active] [get_bd_pins ila_0/probe0]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_tx_dv] [get_bd_pins ila_0/probe1]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_rx_dv] [get_bd_pins ila_0/probe2]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_rx_byte] [get_bd_pins ila_0/probe3]

# --- Finalize Block Design ---
puts "INFO: Finalizing block design..."
regenerate_bd_layout
validate_bd_design
make_wrapper -files [get_files [current_bd_design]] -top
add_files -norecurse "${proj_dir}/[get_property NAME [current_project]].gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"

# --- Add Constraints ---
puts "INFO: Adding constraints file..."
add_files -fileset constrs_1 -norecurse "${script_dir}/../hw/constraints.xdc"
set_property target_constrs_file "${script_dir}/../hw/constraints.xdc" [current_fileset -constrset]

puts "INFO: Script finished successfully."
puts "INFO: Next steps: Generate Bitstream."
```

# This script creates a Vivado project for the Zybo Z7-20 board,
# adds the custom UART IP, and creates a block design.

# --- Project Setup ---
set project_name "zybo_z7_20_uart"
set board_part "digilentinc.com:zybo-z7-20:part0:1.1"
set project_dir "./${project_name}"

create_project ${project_name} ${project_dir} -part ${board_part}

# --- Add RTL sources ---
add_files -norecurse {
    ../ip/uart_tx.v
    ../ip/uart_rx.v
    ../ip/uart_axilite_wrapper.v
}

# --- Package the custom IP ---
set ip_repo_path "${project_dir}/${project_name}.srcs/sources_1/ip"
file mkdir ${ip_repo_path}
set_property ip_repo_paths ${ip_repo_path} [current_project]
update_ip_catalog

# Get the script's directory to resolve relative paths cleanly
set script_dir [file dirname [file normalize [info script]]]

# Create and package the IP. This approach is more robust.
ipx::package_project -module_name uart_axilite_wrapper -display_name "AXI Lite UART with ILA" -root_dir ${ip_repo_path}/uart_axilite_1.1 -vendor user.org -library user -taxonomy /User -force

# Add files to a new file group. This fixes the 'file_group' error.
ipx::add_file_group {Verilog Source} [ipx::current_core]
ipx::add_file "${script_dir}/../ip/uart_tx.v" [ipx::get_file_groups {Verilog Source} -of_objects [ipx::current_core]]
ipx::add_file "${script_dir}/../ip/uart_rx.v" [ipx::get_file_groups {Verilog Source} -of_objects [ipx::current_core]]
ipx::add_file "${script_dir}/../ip/uart_axilite_wrapper.v" [ipx::get_file_groups {Verilog Source} -of_objects [ipx::current_core]]

# Set top file, infer interfaces, and save
set_property top_file {uart_axilite_wrapper.v} [ipx::current_core]
ipx::infer_bus_interface s_axi_aclk s_axi_aclk [ipx::current_core]
ipx::infer_bus_interface s_axi_aresetn s_axi_aresetn [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

update_ip_catalog

# --- Create Block Design ---
create_bd_design "design_1"

# Add Zynq PS
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_board_preset "ZYNQ7_PS" [get_bd_cells processing_system7_0]

# Add custom UART IP
create_bd_cell -type ip -vlnv user.org:user:uart_axilite_wrapper:1.1 uart_axilite_wrapper_0

# Connect AXI interface
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
    Master "Processing System 7"
    Clk "Auto"
} [get_bd_intf_pins processing_system7_0/M_AXI_GP0]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
    Master "/processing_system7_0/M_AXI_GP0"
    Slave "/uart_axilite_wrapper_0/s_axi"
    Clk "Auto"
    Connect "Auto"
} [get_bd_intf_pins uart_axilite_wrapper_0/s_axi]

# Make UART pins external
make_bd_pins_external [get_bd_pins uart_axilite_wrapper_0/i_rxd]
make_bd_pins_external [get_bd_pins uart_axilite_wrapper_0/o_txd]

# Connect interrupt
create_bd_port -dir I -type intr interrupt
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/interrupt] [get_bd_ports interrupt]
set_property -dict [list CONFIG.SENSITIVITY {LEVEL_HIGH}] [get_bd_ports interrupt]
connect_bd_net [get_bd_ports interrupt] [get_bd_pins processing_system7_0/IRQ_F2P]

# --- Add ILA for Debugging ---
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {4} CONFIG.C_PROBE0_WIDTH {1} CONFIG.C_PROBE1_WIDTH {1} CONFIG.C_PROBE2_WIDTH {1} CONFIG.C_PROBE3_WIDTH {8}] [get_bd_cells ila_0]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins ila_0/clk]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_tx_active] [get_bd_pins ila_0/probe0]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_tx_dv] [get_bd_pins ila_0/probe1]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_rx_dv] [get_bd_pins ila_0/probe2]
connect_bd_net [get_bd_pins uart_axilite_wrapper_0/debug_rx_byte] [get_bd_pins ila_0/probe3]

# --- Finalize Block Design ---
regenerate_bd_layout
validate_bd_design
make_wrapper -files [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse ${project_dir}/${project_name}.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v

# --- Add Constraints ---
add_files -fileset constrs_1 -norecurse ../hw/constraints.xdc

puts "Project created successfully. Open ${project_dir}/${project_name}.xpr"

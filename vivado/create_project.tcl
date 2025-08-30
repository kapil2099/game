# Define project settings
set project_name "spi_test"
set project_dir "./${project_name}"
set board_part "digilentinc.com:zybo-z7-20:part0:1.1"
set hdl_dir "../hdl"
set top_module_name "axi_lite_spi_master"

# Create project
create_project ${project_name} ${project_dir} -part [get_parts -board_part ${board_part}] -force

# Add HDL files
add_files -norecurse "${hdl_dir}/spi_master.v"
add_files -norecurse "${hdl_dir}/axi_lite_spi_master.v"

# Add constraints file
add_files -fileset constrs_1 -norecurse "./constraints.xdc"

# Create block design
create_bd_design "design_1"

# Add Zynq Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

# Add AXI-Lite SPI Master
create_bd_cell -type module -reference ${top_module_name} axi_lite_spi_master_0

# Connect AXI interfaces
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "Auto" Clk "Auto"} [get_bd_intf_pins axi_lite_spi_master_0/S_AXI]

# Connect SPI ports
make_bd_pins_external [get_bd_pins axi_lite_spi_master_0/spi_sclk]
make_bd_pins_external [get_bd_pins axi_lite_spi_master_0/spi_mosi]
make_bd_pins_external [get_bd_pins axi_lite_spi_master_0/spi_miso]
make_bd_pins_external [get_bd_pins axi_lite_spi_master_0/spi_ss_n]

# Regenerate layout
regenerate_bd_layout

# Validate the design
validate_bd_design

# Create HDL wrapper
make_wrapper -files [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse ${project_dir}/${project_name}.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v

# Synthesize, implement, and generate bitstream
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Export hardware for Vitis
write_hw_platform -fixed -force -file ${project_dir}/${project_name}.xsa

puts "Vivado project created successfully."
puts "Hardware platform exported to ${project_dir}/${project_name}.xsa"

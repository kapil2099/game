# Define settings
set workspace_dir "./vitis_workspace"
set xsa_file "../vivado/spi_test/spi_test.xsa"
set platform_name "spi_test_platform"
set app_name "spi_test_app"
set src_dir "./src"

# Set up workspace
setws ${workspace_dir}

# Create platform project
platform create -name ${platform_name} -hw ${xsa_file}
platform write

# Create application project
app create -name ${app_name} -platform ${platform_name} -domain ps7_cortexa9_0 -template {Empty Application}
importsources -name ${app_name} -path ${src_dir}

# Build the application
app build -name ${app_name}

puts "Vitis project created and built successfully."
puts "To run on hardware, use the Vitis GUI to create a debug configuration or program the flash with the generated BOOT.BIN file."

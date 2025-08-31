# Custom UART IP Project for Zybo Z7-20

This project demonstrates how to integrate a custom AXI-Lite UART IP into a Zynq-7000 design on a Zybo Z7-20 board. It includes the RTL for the UART, a Vivado project creation script, and a bare-metal C application for a loopback test.

## Prerequisites

1.  **Xilinx Vivado** (tested with 2022.2, but other versions should work)
2.  **Xilinx Vitis** (matching your Vivado version)
3.  **Digilent Board Files** for Vivado. Follow the instructions [here](https://digilent.com/reference/programmable-logic/guides/installing-vivado-and-vitis-and-digilent-board-files) to install them.

## Project Structure

- `ip/`: Contains the Verilog source files for the custom UART IP.
- `hw/`: Contains the Vivado project creation script (`create_project.tcl`) and the constraints file (`constraints.xdc`).
- `sw/`: Contains the C source code (`main.c`) and linker script (`lscript.ld`) for the Vitis application.
- `README.md`: This file.
- `HOW_IT_WAS_MADE.md`: A description of how this project was generated.

---

## Part 1: Hardware Generation in Vivado (GUI Workflow)

This section provides a complete, step-by-step guide to creating the hardware platform using only the Vivado Graphical User Interface (GUI). This avoids all scripting issues.

### Step 1: Create a New Project

1.  Launch Vivado.
2.  From the welcome screen, select **Create Project**.
3.  Click **Next**. Give your project a name (e.g., `zybo_z7_uart_gui`) and choose a location. Click **Next**.
4.  Select **RTL Project** and check "Do not specify sources at this time". Click **Next**.
5.  On the "Default Part" screen, select the **Boards** tab. Find and select `Zybo Z7-20`. Click **Next**.
6.  Review the summary and click **Finish**. An empty Vivado project will be created.

### Step 2: Package the Custom UART as an IP Core

1.  In the Vivado menu, go to **Tools -> Create and Package New IP**.
2.  Click **Next**. Select **Package a specified directory**. Click **Next**.
3.  For "IP Location", browse to the `ip` folder within this project directory (`zybo_z7_20_uart_project/ip`). Click **Next**.
4.  Vivado will create a new temporary project to manage the packaging. Click **Finish**.
5.  A new Vivado project window will open for the IP. In the "Package IP" tab at the bottom, you will see several steps.
6.  Go to the **File Groups** section. Vivado should have automatically added the Verilog files.
7.  Go to the **Customization Parameters** section. Nothing needs to be done here.
8.  Go to the **Ports and Interfaces** section. Vivado will analyze the top-level file (`uart_axilite_wrapper.v`) and identify the ports. It should automatically infer the AXI-Lite interface (`s_axi`), the clock (`s_axi_aclk`), and the reset (`s_axi_aresetn`).
9.  Click **Review and Package**. In the final "Package IP" screen, click **Package IP**. The packager project will close, and you will be returned to your main project. Your new IP is now in the project's IP repository.

### Step 3: Create the Block Design

1.  In the main project window, under the "IP Integrator" section of the Flow Navigator, click **Create Block Design**.
2.  Give it a name (e.g., `design_1`) and click **OK**.
3.  A blank block design canvas will open. Click the **+** button to add IP.
4.  Search for and add the **Zynq7 Processing System**.
5.  A green bar will appear at the top of the canvas. Click **Run Block Automation**. In the dialog, check "Apply Board Preset" and click **OK**. This configures the Zynq processor for the Zybo board.
6.  Click the **+** button again. Search for your custom IP, `uart_axilite_wrapper`, and add it to the design.
7.  Click the **+** button again. Search for and add the **ILA (Integrated Logic Analyzer)** IP.
8.  Another green bar will appear for "Connection Automation". Click it. Vivado will automatically connect the AXI-Lite interface from the Zynq processor to your custom UART IP. Check the boxes and click **OK**.
9.  Manually connect the debug signals:
    -   Hover over the `debug_tx_active` port on the `uart_axilite_wrapper` block and click-and-drag a wire to the `probe0` input of the `ila_0` block.
    -   Repeat this for the other debug signals (`debug_tx_dv` to `probe1`, `debug_rx_dv` to `probe2`, `debug_rx_byte` to `probe3`).
10. Manually connect the UART pins and interrupt:
    -   Right-click on the `i_rxd` pin of your UART IP and select **Create Port**. Name it `i_rxd`.
    -   Right-click on the `o_txd` pin and select **Create Port**. Name it `o_txd`.
    -   Drag a wire from the `interrupt` pin of your UART to the `IRQ_F2P[0:0]` pin on the Zynq processor block.

### Step 4: Validate and Create HDL Wrapper

1.  Click the "Validate Design" button (the checkmark icon). You should get a message that validation was successful.
2.  In the "Sources" panel, right-click on your block design file (`design_1.bd`) and select **Create HDL Wrapper**. Let Vivado manage the wrapper.

### Step 5: Add Constraints

1.  In the "Sources" panel, make sure the "Hierarchy" tab is selected.
2.  Expand the "Constraints" folder. Right-click on `constrs_1` and select **Add Sources**.
3.  Choose "Add or create constraints". Click **Next**.
4.  Click **Add Files**. Navigate to the `hw` folder of this project and select `constraints.xdc`. Click **OK**, then **Finish**.

### Step 6: Build the Hardware Platform

1.  Open the newly created project in Vivado:
    ```
    vivado ./zybo_z7_20_uart/zybo_z7_20_uart.xpr
    ```
2.  In the Flow Navigator on the left, click **Generate Bitstream**. Vivado will synthesize and implement the design. This will take some time.
3.  After the bitstream is successfully generated, you need to export the hardware platform for Vitis.
    - Go to **File -> Export -> Export Hardware**.
    - In the wizard, select **Include bitstream** and click **Next**.
    - Keep the default name and location for the XSA file (it will be saved in the `zybo_z7_20_uart` directory). Click **Next**, then **Finish**.

---

## Part 2: Software Application in Vitis

### Step 1: Create a Vitis Workspace

1.  Launch Vitis.
2.  Select a directory for your Vitis workspace. This can be anywhere on your computer (e.g., `zybo_z7_20_uart_project/vitis_workspace`).

### Step 2: Create the Platform Project

1.  In Vitis, go to **File -> New -> Platform Project**.
2.  Name your platform project (e.g., `zybo_z7_20_platform`).
3.  In the "Create a new platform from hardware (XSA)" tab, click **Browse** and select the `.xsa` file you exported from Vivado.
4.  Click **Finish**.

### Step 3: Create the Application Project

1.  Go to **File -> New -> Application Project**.
2.  Select the platform project you just created.
3.  Name your application project (e.g., `uart_loopback_test`).
4.  In the "Domain" section, select `ps7_cortexa9_0`.
5.  Click **Next**.
6.  On the "Templates" page, select **Empty Application** and click **Finish**.

### Step 4: Import the Source Code

1.  In the Vitis Explorer, expand your application project (`uart_loopback_test`).
2.  Right-click on the `src` folder and select **Import Sources**.
3.  In the "From directory" field, browse to the `sw` directory of this project (`zybo_z7_20_uart_project/sw`).
4.  Select `main.c` and `lscript.ld` from the list.
5.  Click **Finish**.

### Step 5: Build the Project

1.  Right-click on the application project (`uart_loopback_test`) and select **Build Project**. This will compile the C code.

---

## Part 3: Running the Test on the Zybo Z7-20

### Step 1: Physical Setup

1.  **Connect the Loopback:** On the Zybo Z7-20 board, find the **Pmod JA** connector. Use a jumper wire to connect pin 1 (`JA1`) to pin 2 (`JA2`). The `o_txd` signal is on `JA1` and `i_rxd` is on `JA2`.
2.  **Connect USB/Power:** Connect your computer to the **JTAG/UART** micro-USB port on the Zybo board. This provides power and a serial connection for the standard output.
3.  Power on the board.

### Step 2: Program and Run

1.  In Vitis, open a serial terminal to see the output from the Zynq's default UART.
    - Go to **Window -> Show View -> Terminal**.
    - In the Terminal view, click the "Open a new terminal" icon.
    - Select **Serial Terminal**. Choose the correct COM port for your Zybo board and set the baud rate to `115200`.
2.  Right-click on your application project (`uart_loopback_test`) and select **Run As -> Launch on Hardware (Single Application Debug)**.
3.  Vitis will program the FPGA with the bitstream and run the ARM application.
4.  In the serial terminal, you should see the following output:
    ```
    --- Custom UART Loopback Test ---
    Sent: Hello, Custom UART!

    --- Loopback Test Successful! ---
    ```
If you see this message, the test has passed! If not, check your wiring and ensure you have followed all the steps correctly.

---

## Part 4: Debugging with the ILA

This project includes an Integrated Logic Analyzer (ILA) to monitor the internal signals of the custom UART.

### Step 1: Open Hardware Manager

1.  After generating the bitstream in Vivado (Part 1, Step 2), in the Flow Navigator, click **Open Hardware Manager**.
2.  Click **Open Target** and select **Auto Connect**. Vivado will connect to your Zybo board.

### Step 2: Program the Device

1.  Click **Program Device**. The bitstream from your project should already be selected. Click **Program**.

### Step 3: Set up the ILA Trigger

1.  After programming, a window showing the ILA core (`hw_ila_1`) and its probes will appear.
2.  You can set up a trigger to capture data at a specific moment. For example, let's trigger on the start of a transmission.
    - Find the `debug_tx_dv_0` signal in the trigger setup window.
    - Set its value to `1` (or `R` for rising edge). This will make the ILA trigger whenever a character is about to be transmitted.
3.  Arm the trigger by clicking the "Run Trigger" button (the one with the arrow icon).

### Step 4: Capture and View Waveforms

1.  With the ILA armed, run the software test from Vitis (Part 3, Step 2).
2.  When the trigger condition is met, the ILA will capture the signal data and a waveform window will appear in Vivado.
3.  You can now analyze the waveforms of the `debug_tx_active`, `debug_tx_dv`, `debug_rx_dv`, and `debug_rx_byte` signals to see your UART in action.
```

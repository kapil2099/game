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

## Part 1: Hardware Generation in Vivado

### Step 1: Create the Vivado Project

1.  Open a terminal or command prompt.
2.  Navigate to the `hw` directory inside the project folder:
    ```bash
    cd zybo_z7_20_uart_project/hw
    ```
3.  Run the following command to have Vivado create the project automatically. This may take a few minutes.
    ```bash
    vivado -mode batch -source create_project.tcl
    ```
    This will create a new Vivado project in the `hw/zybo_z7_20_uart` directory.

### Step 2: Build the Hardware Platform

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

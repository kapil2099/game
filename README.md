# Zybo Z7-20 SPI Master Test Project

## 1. Project Overview

This project provides a complete and synthesizable framework for testing a custom SPI master IP on a Xilinx Zynq-7000 device, specifically targeting the Digilent Zybo Z7-20 board.

The main components are:
*   **RTL SPI Master (`spi_master.v`):** A Verilog module for a simple SPI master that operates in Mode 0 (CPOL=0, CPHA=0).
*   **AXI-Lite Wrapper (`axi_lite_spi_master.v`):** An AXI-Lite slave wrapper that exposes the SPI master's functionality to the Zynq Processing System (PS) as a set of memory-mapped registers.
*   **Vivado Project (`vivado/`):** A Tcl script (`create_project.tcl`) that automates the creation of the entire hardware design, from block design to bitstream generation and hardware export.
*   **Vitis Application (`vitis/`):** A 'C' application and a Tcl script to create, build, and run a software test on the ARM processor to verify the SPI IP.

## 2. The Loopback Test Explained

The test implemented in this project is a **hardware loopback test**. It's a simple yet effective method to verify the core functionality of the SPI master (i.e., its ability to send and receive data simultaneously).

Here's how it works:
1.  The C code running on the processor uses the AXI bus to configure the SPI master (sets clock speed, word length, etc.).
2.  It then writes a known data pattern (e.g., `0x12345678`) to the SPI master's transmit register.
3.  The SPI master serializes this data and sends it out, bit-by-bit, on its `spi_mosi` (Master Out, Slave In) pin.
4.  Because we physically connect the `spi_mosi` pin to the `spi_miso` (Master In, Slave Out) pin, the data being sent out is immediately "looped back" into the master's receive line.
5.  The SPI master simultaneously captures this incoming data and stores it in its receive register.
6.  The C code waits for the transaction to complete, then reads the data from the receive register.
7.  Finally, it compares the received data with the original data. If they match, the test passes.

## 3. Hardware Setup: Pin Connections

To run the loopback test, you must make **one physical connection** on your Zybo Z7-20 board. The project is configured to use **Pmod JA**.

You need to connect the **MOSI** pin to the **MISO** pin using a single jumper wire.

| Signal   | Pmod Pin | Board Pin | Connect To |
|----------|----------|-----------|------------|
| `spi_miso` | JA1      | G17       | JA2 (`spi_mosi`) |
| `spi_mosi` | JA2      | G19       | JA1 (`spi_miso`) |
| `spi_sclk` | JA3      | N18       | (No Connection Needed) |
| `spi_ss_n[0]`| JA4      | L18       | (No Connection Needed) |

**Connect a jumper wire between Pin 1 and Pin 2 of the Pmod JA connector.**

## 4. Build and Verification Flow

Follow these steps to build the project. After each major step, there is a verification check to ensure it completed successfully.

### Step 1: Create the Vivado Project

1.  Open the **Vivado Tcl Shell** on Windows.
2.  Navigate to the `vivado` directory within this project's folder:
    ```sh
    cd path/to/project/vivado
    ```
3.  Run the Tcl script:
    ```sh
    vivado -mode batch -source create_project.tcl
    ```
**Verification:**
*   Look for the message `Vivado project created successfully.` in the console.
*   Check that the hardware platform file has been created at this path: `vivado/spi_test/spi_test.xsa`. This file is essential for the next step.

### Step 2: Create the Vitis Project

1.  Open the **Xilinx Software Command-line Tool (xsct)**.
2.  Navigate to the `vitis` directory:
    ```sh
    cd path/to/project/vitis
    ```
3.  Run the Tcl script:
    ```sh
    xsct create_vitis_project.tcl
    ```
**Verification:**
*   Look for the message `Vitis project created and built successfully.` in the console.
*   Check that the application executable has been created at this path: `vitis/vitis_workspace/spi_test_app/Debug/spi_test_app.elf`.

## 5. Running the Test on Hardware

1.  Connect your Zybo Z7-20 board to your computer via the USB JTAG port.
2.  Open the **Vitis Unified Software Platform** IDE.
3.  Select the workspace created by the script: `path/to/project/vitis/vitis_workspace`.
4.  In the Explorer view, right-click on the `spi_test_app` project and select **Run As > Launch on Hardware (Single Application Debug)**.
5.  Vitis will program the FPGA and load the C application onto the ARM core.
6.  In the Vitis IDE, open the **Vitis Serial Terminal** (usually appears at the bottom). Configure it for the correct COM port and a baud rate of 115200.
7.  You should see the test results printed in the terminal, indicating whether the loopback test passed or failed.

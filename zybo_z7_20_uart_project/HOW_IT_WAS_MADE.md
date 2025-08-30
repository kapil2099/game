# How This Project Was Created

This document describes the process and design decisions made to generate the `zybo_z7_20_uart_project`.

## 1. Initial Request & Understanding the Goal

The initial request was to create a Vivado project to integrate a custom UART IP with an ARM core on a Zybo Z7-20 board. The user provided a specific list of ports for a UART with a Wishbone bus interface and requested a C code loopback test.

## 2. Adapting to User-Provided RTL

Shortly after the initial planning, the user provided their own RTL code for the UART, which consisted of separate `uart_tx` and `uart_rx` modules with simple I/O signals, not a Wishbone interface.

To accommodate this, the plan was revised. Instead of writing a UART from scratch, I would use the user's provided modules. To connect them to the processor, I decided to create a wrapper module that would contain the `uart_tx` and `uart_rx` instances and present a bus interface to the Zynq processor.

## 3. Design Decision: AXI-Lite over Wishbone

The original request specified a Wishbone interface. However, the standard bus protocol for peripherals in the Xilinx/Zynq ecosystem is AXI (specifically AXI-Lite for simple control/data registers). Connecting a Wishbone peripheral to the Zynq's AXI bus would require an AXI-to-Wishbone bridge. While possible, this adds unnecessary complexity to the design.

For a more robust, standard, and maintainable solution, I made the engineering decision to use an AXI-Lite interface for the wrapper module. This has several advantages:
- **Simplified Block Design:** The custom IP can connect directly to the Zynq's AXI master port without any bridge.
- **Better Tool Integration:** Vivado's automation tools work seamlessly with AXI interfaces, making connections trivial.
- **Standardization:** It follows the recommended design patterns for Zynq-based systems.

An AXI-Lite wrapper, `uart_axilite_wrapper.v`, was created. It has a simple register map:
- `0x00`: Write-only register to send a byte.
- `0x04`: Read-only register to read a received byte.
- `0x08`: Read-only status register (`TX_BUSY`, `RX_VALID`).

## 4. Hardware Implementation (`hw/`)

- **Vivado Automation (`create_project.tcl`):** A Tcl script was written to automate the entire Vivado project creation. This script is powerful because it ensures repeatability and documents the whole process in code. It performs the following steps:
    1.  Creates a project for the Zybo Z7-20.
    2.  Packages the Verilog files (`uart_tx.v`, `uart_rx.v`, `uart_axilite_wrapper.v`) into a reusable IP core. This makes it appear in the Vivado IP Catalog.
    3.  Creates a block design, instantiates the Zynq PS7 and the custom UART IP.
    4.  Uses Vivado's connection automation to connect the AXI interface, clocks, and resets.
    5.  Connects the UART's interrupt output to the Zynq's fabric interrupt input (`IRQ_F2P`).
    6.  Makes the UART TX and RX pins external to be connected to the board's physical pins.
    7.  Creates the top-level HDL wrapper.

- **Constraints (`constraints.xdc`):** A constraints file was created to map the external UART pins to the **Pmod JA** connector. Pins `JA1` (`Y18`) and `JA2` (`Y19`) were chosen for the `o_txd` and `i_rxd` signals, respectively. This allows for a simple loopback test by connecting a wire between these two pins.

## 5. Software Implementation (`sw/`)

- **Loopback Test (`main.c`):** A bare-metal C application was written to test the custom UART. It performs the following actions:
    1.  Defines the memory-mapped address of the UART IP (`0x43C00000`, the default for the first slave on the M_AXI_GP0 port).
    2.  Sends a test string byte-by-byte to the UART's transmit register.
    3.  Polls the status register and reads the received bytes from the receive register.
    4.  Compares the sent and received data.
    5.  Prints a success or failure message to the main Zynq UART console (the one connected over the USB-JTAG port).

- **Linker Script (`lscript.ld`):** A standard linker script for a Zynq-7000 device was included to ensure the Vitis toolchain can correctly build the application and place it in DDR memory.

## 6. Documentation

Finally, the `README.md` and this `HOW_IT_WAS_MADE.md` file were created to provide clear instructions and context for the user. The `README.md` is a step-by-step guide, while this document provides the "why" behind the implementation details.

#include <stdio.h>
#include "xil_io.h"
#include "xparameters.h"

// SPI IP AXI-Lite Register Offsets
#define SPI_BASE_ADDR      XPAR_AXI_LITE_SPI_MASTER_0_S_AXI_BASEADDR
#define CONTROL_REG_OFFSET 0x00
#define CLK_DIVIDER_REG_OFFSET 0x04
#define TX_DATA_REG_OFFSET 0x08
#define RX_DATA_REG_OFFSET 0x0C
#define STATUS_REG_OFFSET  0x10

// Control Register Bits
#define ENABLE_BIT        (1 << 0)
#define SPI_MODE_0        (0 << 1)
#define WORD_LENGTH_32BIT (2 << 3)
#define SLAVE_SELECT_0    (0 << 5)

// Status Register Bits
#define BUSY_BIT          (1 << 0)
#define TX_READY_BIT      (1 << 1)
#define RX_VALID_BIT      (1 << 2)

void spi_write_reg(UINTPTR base_addr, u32 offset, u32 data) {
    Xil_Out32(base_addr + offset, data);
}

u32 spi_read_reg(UINTPTR base_addr, u32 offset) {
    return Xil_In32(base_addr + offset);
}

int main() {
    printf("SPI Test Application\n");

    // Configure SPI: Mode 0, 32-bit words, slave 0, clock divider 10
    u32 control_val = SPI_MODE_0 | WORD_LENGTH_32BIT | SLAVE_SELECT_0;
    spi_write_reg(SPI_BASE_ADDR, CONTROL_REG_OFFSET, control_val);
    spi_write_reg(SPI_BASE_ADDR, CLK_DIVIDER_REG_OFFSET, 10);

    // Enable SPI
    control_val |= ENABLE_BIT;
    spi_write_reg(SPI_BASE_ADDR, CONTROL_REG_OFFSET, control_val);

    // Data to send
    u32 tx_data = 0x12345678;
    printf("Sending data: 0x%08X\n", tx_data);

    // Wait for TX ready
    while (!(spi_read_reg(SPI_BASE_ADDR, STATUS_REG_OFFSET) & TX_READY_BIT));

    // Send data
    spi_write_reg(SPI_BASE_ADDR, TX_DATA_REG_OFFSET, tx_data);

    // Wait for RX valid
    while (!(spi_read_reg(SPI_BASE_ADDR, STATUS_REG_OFFSET) & RX_VALID_BIT));

    // Read received data
    u32 rx_data = spi_read_reg(SPI_BASE_ADDR, RX_DATA_REG_OFFSET);
    printf("Received data: 0x%08X\n", rx_data);

    if (tx_data == rx_data) {
        printf("SPI Loopback Test Passed!\n");
    } else {
        printf("SPI Loopback Test Failed!\n");
    }

    // Disable SPI
    control_val &= ~ENABLE_BIT;
    spi_write_reg(SPI_BASE_ADDR, CONTROL_REG_OFFSET, control_val);

    return 0;
}

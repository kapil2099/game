#include "xil_printf.h"
#include "xil_io.h"

// Base address of the custom UART IP
#define UART_LITE_BASE_ADDR 0x43C00000

// Register offsets
#define UART_TX_DATA_REG_OFFSET 0x00
#define UART_RX_DATA_REG_OFFSET 0x04
#define UART_STATUS_REG_OFFSET  0x08

// Status register bits
#define STATUS_RX_VALID_BIT 0x01
#define STATUS_TX_BUSY_BIT  0x02

void uart_write(u32 base_addr, u8 data) {
    // Wait until TX is not busy
    while (Xil_In32(base_addr + UART_STATUS_REG_OFFSET) & STATUS_TX_BUSY_BIT);
    Xil_Out32(base_addr + UART_TX_DATA_REG_OFFSET, data);
}

u8 uart_read(u32 base_addr) {
    // Wait until RX is valid
    while (!(Xil_In32(base_addr + UART_STATUS_REG_OFFSET) & STATUS_RX_VALID_BIT));
    return (u8)Xil_In32(base_addr + UART_RX_DATA_REG_OFFSET);
}

int main() {
    char *test_str = "Hello, Custom UART!\n";
    char received_char;
    int i = 0;
    int errors = 0;

    xil_printf("--- Custom UART Loopback Test ---\n");

    // Send the test string
    while (test_str[i] != '\0') {
        uart_write(UART_LITE_BASE_ADDR, test_str[i]);
        i++;
    }

    xil_printf("Sent: %s", test_str);

    // Receive and verify the test string
    i = 0;
    while (test_str[i] != '\0') {
        received_char = uart_read(UART_LITE_BASE_ADDR);
        if (received_char != test_str[i]) {
            errors++;
            xil_printf("Error! Expected '%c', got '%c'\n", test_str[i], received_char);
        }
        i++;
    }

    if (errors == 0) {
        xil_printf("\n--- Loopback Test Successful! ---\n");
    } else {
        xil_printf("\n--- Loopback Test Failed with %d errors! ---\n", errors);
    }

    return 0;
}

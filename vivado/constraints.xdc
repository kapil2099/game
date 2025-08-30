## Pmod JA - SPI Interface
#
# The following constraints map the external SPI ports of the design to the
# physical pins of the Pmod JA connector on the Zybo Z7-20 board.
#
# For the loopback test, you will need to connect MOSI (JA2) to MISO (JA1).

set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports spi_sclk]
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports spi_mosi]
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports spi_miso]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {spi_ss_n[0]}]

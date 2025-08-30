## Pmod Header JA
## Note: For loopback test, connect a wire between JA1 and JA2 (Y18 and Y19)
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports {o_txd_0}]; # JA1
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports {i_rxd_0}]; # JA2

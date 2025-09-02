## Pmod Header JA
## Note: For loopback test, connect a wire between JA1 (N15) and JA2 (L14)
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports {o_txd_0}]; # JA1
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports {i_rxd_0}]; # JA2

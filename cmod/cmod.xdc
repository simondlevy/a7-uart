## 12 MHz Clock Signal
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; # Sch=gclk
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports { clk }];

## USB-UART Bridge
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { RsTx }]; # Sch=uart_rxd_out
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { RsRx }]; # Sch=uart_txd_in

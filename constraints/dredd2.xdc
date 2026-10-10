# DREDD: ARTY A7-100T FINAL CONSTRAINTS (DUAL-PC SETUP)

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports { clk }];

set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { reset_btn }];

set_property -dict { PACKAGE_PIN C9    IOSTANDARD LVCMOS33 } [get_ports { flush_btn }];

set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led_active }];

set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];

set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];

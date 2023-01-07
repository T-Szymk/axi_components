create_clock -period 10.000 -name clk -waveform {0.000 5.000} -add [get_ports clk_i]

set_false_path -from [get_ports rst_i]

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_i]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports rstn_i]

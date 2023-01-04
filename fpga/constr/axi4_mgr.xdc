create_clock -period 8.000 -name clk -waveform {0.000 4.000} -add [get_ports clk125_i]

set_false_path -from [get_ports rst_i]

set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk125_i]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports rst_i]

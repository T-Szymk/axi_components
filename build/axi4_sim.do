add log -r sim:/tb_axi4_mgr/*

add wave -noupdate -group top         sim:/tb_axi4_mgr/*
add wave -noupdate -group dut         sim:/tb_axi4_mgr/i_dut/*
add wave -noupdate -group dut_if      sim:/tb_axi4_mgr/dut_if/*
add wave -noupdate -group axi_s_tb_if sim:/tb_axi4_mgr/axi_s_tb_if/*
add wave -noupdate -group wr_fifo     sim:/tb_axi4_mgr/i_wr_fifo/*
add wave -noupdate -group rd_fifo     sim:/tb_axi4_mgr/i_rd_fifo/*

quietly wave cursor active 1
configure wave -namecolwidth 189
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update

set RunLength 1us

run -all

wave zoom full

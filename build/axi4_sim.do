onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group top    sim:/tb_axi4_mgr/*
add wave -noupdate -expand -group dut    sim:/tb_axi4_mgr/i_dut/*
add wave -noupdate -expand -group dut_if sim:/tb_axi4_mgr/dut_if/*

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

run 500us

wave zoom full

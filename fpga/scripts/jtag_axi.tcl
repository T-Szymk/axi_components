##### WRITES ########

reset_hw_axi [get_hw_axis hw_axi_1]

# set enable
create_hw_axi_txn write_txn0 [get_hw_axis hw_axi_1] -type write -address 00000000 -len 1 -data {0000_0001}

# set wr_addr
create_hw_axi_txn write_txn1 [get_hw_axis hw_axi_1] -type write -address 0000000C -len 1 -data {C000_0000}

# set FIFO data
create_hw_axi_txn write_txn2 [get_hw_axis hw_axi_1] -type write -address 00000020 -len 1 -data {BEEF_0000}
# push to FIFO
create_hw_axi_txn write_txn3 [get_hw_axis hw_axi_1] -type write -address 00000028 -len 1 -data {0000_0001}
# set FIFO data
create_hw_axi_txn write_txn4 [get_hw_axis hw_axi_1] -type write -address 00000020 -len 1 -data {BEEF_0001}
# push to FIFO
create_hw_axi_txn write_txn5 [get_hw_axis hw_axi_1] -type write -address 00000028 -len 1 -data {0000_0001}
# set FIFO data
create_hw_axi_txn write_txn6 [get_hw_axis hw_axi_1] -type write -address 00000020 -len 1 -data {BEEF_0002}
# push to FIFO
create_hw_axi_txn write_txn7 [get_hw_axis hw_axi_1] -type write -address 00000028 -len 1 -data {0000_0001}

# start write
create_hw_axi_txn write_txn8 [get_hw_axis hw_axi_1] -type write -address 00000004 -len 1 -data {0000_0001}
create_hw_axi_txn write_txn9 [get_hw_axis hw_axi_1] -type write -address 00000004 -len 1 -data {0000_0000}

# set rd_addr
create_hw_axi_txn write_txn10 [get_hw_axis hw_axi_1] -type write -address 00000010 -len 1 -data {C000_0000}
# set rd count
create_hw_axi_txn write_txn11 [get_hw_axis hw_axi_1] -type write -address 00000014 -len 1 -data {0000_0003}

# start read
create_hw_axi_txn write_txn12 [get_hw_axis hw_axi_1] -type write -address 00000004 -len 1 -data {0000_0002}
create_hw_axi_txn write_txn13 [get_hw_axis hw_axi_1] -type write -address 00000004 -len 1 -data {0000_0000}

# setup and initiate writes
run_hw_axi [get_hw_axi_txns write_txn0]
run_hw_axi [get_hw_axi_txns write_txn1]
run_hw_axi [get_hw_axi_txns write_txn2]
run_hw_axi [get_hw_axi_txns write_txn3]
run_hw_axi [get_hw_axi_txns write_txn4]
run_hw_axi [get_hw_axi_txns write_txn5]
run_hw_axi [get_hw_axi_txns write_txn6]
run_hw_axi [get_hw_axi_txns write_txn7]
run_hw_axi [get_hw_axi_txns write_txn8]
run_hw_axi [get_hw_axi_txns write_txn9]

# setup and initiate read
run_hw_axi [get_hw_axi_txns write_txn10] 
run_hw_axi [get_hw_axi_txns write_txn11] 
run_hw_axi [get_hw_axi_txns write_txn12] 
run_hw_axi [get_hw_axi_txns write_txn13]

##### READS ########

# check WR usage

create_hw_axi_txn read_txn0 [get_hw_axis hw_axi_1] -type read -address 0000002C -len 1
run_hw_axi [get_hw_axi_txns read_txn0]


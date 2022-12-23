# Paths
BUILD_DIR          := $(PWD)
RTL_DIR            := $(BUILD_DIR)/../rtl
TB_DIR             := $(BUILD_DIR)/../tb
IP_DIR             := $(BUILD_DIR)/../ip
AXI_IP_DIR         := $(IP_DIR)/pulp_axi
COMMON_CELL_IP_DIR := $(IP_DIR)/pulp_common_cells
COMMON_VER_IP_DIR  := $(IP_DIR)/pulp_common_verification

# List all source files for synthesis
SRC_FILES  :=  $(AXI_IP_DIR)/src/axi_pkg.sv \
               $(AXI_IP_DIR)/src/axi_intf.sv \
               $(RTL_DIR)/axi4_mgr.sv

TB_FILES   := $(COMMON_VER_IP_DIR)/src/rand_id_queue.sv \
              $(AXI_IP_DIR)/src/axi_test.sv \
			        $(TB_DIR)/tb_axi4_mgr.sv


# List all testbench files

# Compilation options
INCLUDES   ?= +incdir+$(AXI_IP_DIR)/include
VLOG_SUPP  ?= -suppress vlog-13262
VLOG_FLAGS ?= -sv $(INCLUDES) -pedanticerrors -warnrbw -fsmverbose -fsm=imrsx -lint
VOPT_FLAGS ?= "+acc=npr" -fsmverbose -fsm=imrsx

TOP_DESIGN ?= tb_axi4_mgr

init:
	cd .. & git submodule update --init --recursive
	vlib axi_lib

compile:
	vlog -work axi_lib $(VLOG_SUPP) $(VLOG_FLAGS) $(SRC_FILES) $(TB_FILES)

elaborate:
	vopt -work axi_lib $(VOPT_FLAGS) $(TOP_DESIGN) -o $(TOP_DESIGN)_opt

sim_cli:
	vsim -work axi_lib -c -onfinish stop -do "run 0us;" $(TOP_DESIGN)_opt

clean:
	@rm -rf axi_lib
	@rm -rf modelsim.ini
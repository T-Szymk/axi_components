# Paths
BUILD_DIR          := $(PWD)
RTL_DIR            := $(BUILD_DIR)/../rtl
TB_DIR             := $(BUILD_DIR)/../tb
IP_DIR             := $(BUILD_DIR)/../ip
AXI_IP_DIR         := $(IP_DIR)/pulp_axi
COMMON_CELL_IP_DIR := $(IP_DIR)/pulp_common_cells
COMMON_VER_IP_DIR  := $(IP_DIR)/pulp_common_verification

# List all source files for synthesis
SRC_FILES  :=  $(RTL_DIR)/axi_interfaces.sv \
               $(RTL_DIR)/axi4_mgr.sv

TB_FILES   :=  $(TB_DIR)/axi4_test_pkg.svh \
               $(TB_DIR)/tb_axi4_mgr.sv


# List all testbench files

# Compilation options
INCLUDES   ?= +incdir+$(TB_DIR)
VLOG_SUPP  ?= -suppress vlog-13262
VLOG_FLAGS ?= -sv $(INCLUDES) -pedanticerrors -warnrbw -fsmverbose -fsm=imrsx -lint
VOPT_FLAGS ?= "+acc=npr" -fsmverbose -fsm=imrsx
DO_FILE    ?= $(BUILD_DIR)/axi4_sim.do

TOP_DESIGN ?= tb_axi4_mgr

init:
	cd .. & git submodule update --init --recursive

lib:
	vlib axi_lib

compile:
	vlog -work axi_lib $(VLOG_SUPP) $(VLOG_FLAGS) $(SRC_FILES) $(TB_FILES)

elaborate:
	vopt -work axi_lib $(VOPT_FLAGS) $(TOP_DESIGN) -o $(TOP_DESIGN)_opt

sim_cli:
	vsim -work axi_lib -c -onfinish stop -do "run 0us;" $(TOP_DESIGN)_opt

sim:
	vsim -work axi_lib -onfinish stop -do $(DO_FILE) $(TOP_DESIGN)_opt

clean:
	@rm -rf axi_lib
	@rm -rf modelsim.ini
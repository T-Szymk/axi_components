/*******************************************************************************
-- Title      : AXI4 Mgr FPGA Wrapper for Block Designer
-- Project    : T-Szymk
********************************************************************************
-- File       : fpga_axi4_mgr_wrapper_bd.v
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-30
-- Design     : fpga_axi4_mgr_wrapper_bd
-- Platform   : -
-- Standard   : Verilog 2001
********************************************************************************
-- Description: Wrapper to contain FPGA implementation of AXI4 Manager (block 
                designer compatible wrapper)
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-30  1.0      TZS     Created
*******************************************************************************/

module fpga_axi4_mgr_wrapper_bd #(
  parameter integer AXI4_ADDR_WIDTH   =          32,
  parameter integer AXI4_DATA_WIDTH   =          64,
  parameter integer AXIL_ADDR_WIDTH   =          32,
  parameter integer AXIL_DATA_WIDTH   =          32,
  parameter integer AXI_ID_WIDTH      =           3,
  parameter integer AXI_USER_WIDTH    =           8,
  parameter integer FIFO_DEPTH        =          32,
  parameter integer AXI_XSIZE         =        (AXI4_DATA_WIDTH / 8),
  parameter integer REG_BASE_ADDR     =         'h0,
  parameter integer DATA_COUNT_WIDTH  =           8,
  parameter integer AXILSizeBytes     = (AXIL_DATA_WIDTH / 8),
  parameter integer AXI4SizeBytes     = (AXI4_DATA_WIDTH / 8)
) (
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_i CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF axi4_mgr : axi_lite_sub, ASSOCIATED_RESET rstn_i" *)
  input  wire                        clk_i,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn_i RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire                        rstn_i,
  // AXI4
  // AW
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWID" *)
  // Uncomment the following to set interface specific parameter on the bus interface.
  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN clk_i,MAX_BURST_LENGTH 256,NUM_WRITE_OUTSTANDING 0,NUM_READ_OUTSTANDING 0,SUPPORTS_NARROW_BURST 0,READ_WRITE_MODE READ_WRITE,BUSER_WIDTH 8,RUSER_WIDTH 8,WUSER_WIDTH 8,ARUSER_WIDTH 8,AWUSER_WIDTH 8,ADDR_WIDTH 32,ID_WIDTH 3,PROTOCOL AXI4,DATA_WIDTH 64,HAS_BURST 1,HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 0,HAS_BRESP 1,HAS_RRESP 1" *)
  output wire [    AXI_ID_WIDTH-1:0] axi4_mgr_aw_id_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWADDR" *)
  output wire [ AXI4_ADDR_WIDTH-1:0] axi4_mgr_aw_addr_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWLEN" *)
  output wire [               8-1:0] axi4_mgr_aw_len_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWSIZE" *)
  output wire [               3-1:0] axi4_mgr_aw_size_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWBURST" *)
  output wire [               2-1:0] axi4_mgr_aw_burst_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWLOCK" *)
  output wire                        axi4_mgr_aw_lock_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWCACHE" *)
  output wire [               4-1:0] axi4_mgr_aw_cache_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWPROT" *)
  output wire [               3-1:0] axi4_mgr_aw_prot_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWQOS" *)
  output wire [               4-1:0] axi4_mgr_aw_qos_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWREGION" *)
  output wire [               4-1:0] axi4_mgr_aw_region_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWUSER" *)
  output wire [  AXI_USER_WIDTH-1:0] axi4_mgr_aw_user_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWVALID" *)
  output wire                        axi4_mgr_aw_valid_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr AWREADY" *)
  input  wire                        axi4_mgr_aw_ready_i,
  // W
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr WDATA" *)
  output wire [ AXI4_DATA_WIDTH-1:0] axi4_mgr_w_data_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr WSTRB" *)
  output wire [       AXI_XSIZE-1:0] axi4_mgr_w_strb_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr WLAST" *)
  output wire                        axi4_mgr_w_last_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr WUSER" *)
  output wire [  AXI_USER_WIDTH-1:0] axi4_mgr_w_user_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr WVALID" *)
  output wire                        axi4_mgr_w_valid_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr WREADY" *)
  input  wire                        axi4_mgr_w_ready_i,
  // B
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr BID" *)
  input  wire [    AXI_ID_WIDTH-1:0] axi4_mgr_b_id_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr BRESP" *)
  input  wire [               2-1:0] axi4_mgr_b_resp_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr BUSER" *)
  input  wire [  AXI_USER_WIDTH-1:0] axi4_mgr_b_user_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr BVALID" *)
  input  wire                        axi4_mgr_b_valid_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr BREADY" *)
  output wire                        axi4_mgr_b_ready_o,
  // AR
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARID" *)
  output wire [    AXI_ID_WIDTH-1:0] axi4_mgr_ar_id_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARADDR" *)
  output wire [ AXI4_ADDR_WIDTH-1:0] axi4_mgr_ar_addr_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARLEN" *)
  output wire [               8-1:0] axi4_mgr_ar_len_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARSIZE" *)
  output wire [               3-1:0] axi4_mgr_ar_size_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARBURST" *)
  output wire [               2-1:0] axi4_mgr_ar_burst_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARLOCK" *)
  output wire                        axi4_mgr_ar_lock_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARCACHE" *)
  output wire [               4-1:0] axi4_mgr_ar_cache_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARPROT" *)
  output wire [               3-1:0] axi4_mgr_ar_prot_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARREGION" *)
  output wire [               4-1:0] axi4_mgr_ar_region_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARQOS" *)
  output wire [               4-1:0] axi4_mgr_ar_qos_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARUSER" *)
  output wire [  AXI_USER_WIDTH-1:0] axi4_mgr_ar_user_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARVALID" *)
  output wire                        axi4_mgr_ar_valid_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr ARREADY" *)
  input  wire                        axi4_mgr_ar_ready_i,
  // R
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RID" *)
  input  wire [    AXI_ID_WIDTH-1:0] axi4_mgr_r_id_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RDATA" *)
  input  wire [ AXI4_DATA_WIDTH-1:0] axi4_mgr_r_data_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RRESP" *)
  input  wire [               2-1:0] axi4_mgr_r_resp_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RLAST" *)
  input  wire                        axi4_mgr_r_last_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RUSER" *)
  input  wire [  AXI_USER_WIDTH-1:0] axi4_mgr_r_user_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RVALID" *)
  input  wire                        axi4_mgr_r_valid_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi4_mgr RREADY" *)
  output wire                        axi4_mgr_r_ready_o,
  // AXI-LITE Signals
  // AW
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub AWADDR" *)
  // Uncomment the following to set interface specific parameter on the bus interface.
  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN clk_i,READ_WRITE_MODE READ_WRITE,ADDR_WIDTH 32,ID_WIDTH 3,PROTOCOL AXI4,DATA_WIDTH 32" *)                                                             
  input  wire [ AXIL_ADDR_WIDTH-1:0] axil_sub_aw_addr_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub AWPROT" *)
  input  wire [               3-1:0] axil_sub_aw_prot_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub AWVALID" *)
  input  wire                        axil_sub_aw_valid_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub AWREADY" *)
  output wire                        axil_sub_aw_ready_o,
  // W                                                                   
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub WDATA" *)
  input  wire [ AXIL_DATA_WIDTH-1:0] axil_sub_w_data_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub WSTRB" *)
  input  wire [   AXILSizeBytes-1:0] axil_sub_w_strb_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub WVALID" *)
  input  wire                        axil_sub_w_valid_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub WREADY" *)
  output wire                        axil_sub_w_ready_o,
  // B   
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub BRESP" *)                     
  output wire [               2-1:0] axil_sub_b_resp_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub BVALID" *)
  output wire                        axil_sub_b_valid_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub BREADY" *)
  input  wire                        axil_sub_b_ready_i,
  // AR                                                  
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub ARADDR" *)                  
  input  wire [ AXIL_ADDR_WIDTH-1:0] axil_sub_ar_addr_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub ARPROT" *)
  input  wire [               3-1:0] axil_sub_ar_prot_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub ARVALID" *)
  input  wire                        axil_sub_ar_valid_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub ARREADY" *)
  output wire                        axil_sub_ar_ready_o,
  // R 
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub RDATA" *)
  output  wire [AXIL_DATA_WIDTH-1:0] axil_sub_r_data_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub RRESP" *)
  output  wire [              2-1:0] axil_sub_r_resp_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub RVALID" *)
  output  wire                       axil_sub_r_valid_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_lite_sub RREADY" *)
  input   wire                       axil_sub_r_ready_i
);

  fpga_axi4_mgr_wrapper #(
    .AXI4_ADDR_WIDTH  ( AXI4_ADDR_WIDTH  ),
    .AXI4_DATA_WIDTH  ( AXI4_DATA_WIDTH  ),
    .AXIL_ADDR_WIDTH  ( AXIL_ADDR_WIDTH  ),
    .AXIL_DATA_WIDTH  ( AXIL_DATA_WIDTH  ),
    .AXI_ID_WIDTH     ( AXI_ID_WIDTH     ),
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH   ),
    .FIFO_DEPTH       ( FIFO_DEPTH       ),
    .AXI_XSIZE        ( AXI_XSIZE        ),
    .REG_BASE_ADDR    ( REG_BASE_ADDR    ),
    .DATA_COUNT_WIDTH ( DATA_COUNT_WIDTH )
  ) i_fpga_axi4_mgr_wrapper (
    .clk_i                ( clk_i                ),
    .rstn_i               ( rstn_i               ),
    // AXI4
    .axi4_mgr_aw_id_o     ( axi4_mgr_aw_id_o     ),
    .axi4_mgr_aw_addr_o   ( axi4_mgr_aw_addr_o   ),
    .axi4_mgr_aw_len_o    ( axi4_mgr_aw_len_o    ),
    .axi4_mgr_aw_size_o   ( axi4_mgr_aw_size_o   ),
    .axi4_mgr_aw_burst_o  ( axi4_mgr_aw_burst_o  ),
    .axi4_mgr_aw_lock_o   ( axi4_mgr_aw_lock_o   ),
    .axi4_mgr_aw_cache_o  ( axi4_mgr_aw_cache_o  ),
    .axi4_mgr_aw_prot_o   ( axi4_mgr_aw_prot_o   ),
    .axi4_mgr_aw_qos_o    ( axi4_mgr_aw_qos_o    ),
    .axi4_mgr_aw_region_o ( axi4_mgr_aw_region_o ),
    .axi4_mgr_aw_user_o   ( axi4_mgr_aw_user_o   ),
    .axi4_mgr_aw_valid_o  ( axi4_mgr_aw_valid_o  ),
    .axi4_mgr_aw_ready_i  ( axi4_mgr_aw_ready_i  ),
    .axi4_mgr_w_data_o    ( axi4_mgr_w_data_o    ),
    .axi4_mgr_w_strb_o    ( axi4_mgr_w_strb_o    ),
    .axi4_mgr_w_last_o    ( axi4_mgr_w_last_o    ),
    .axi4_mgr_w_user_o    ( axi4_mgr_w_user_o    ),
    .axi4_mgr_w_valid_o   ( axi4_mgr_w_valid_o   ),
    .axi4_mgr_w_ready_i   ( axi4_mgr_w_ready_i   ),
    .axi4_mgr_b_id_i      ( axi4_mgr_b_id_i      ),
    .axi4_mgr_b_resp_i    ( axi4_mgr_b_resp_i    ),
    .axi4_mgr_b_user_i    ( axi4_mgr_b_user_i    ),
    .axi4_mgr_b_valid_i   ( axi4_mgr_b_valid_i   ),
    .axi4_mgr_b_ready_o   ( axi4_mgr_b_ready_o   ),
    .axi4_mgr_ar_id_o     ( axi4_mgr_ar_id_o     ),
    .axi4_mgr_ar_addr_o   ( axi4_mgr_ar_addr_o   ),
    .axi4_mgr_ar_len_o    ( axi4_mgr_ar_len_o    ),
    .axi4_mgr_ar_size_o   ( axi4_mgr_ar_size_o   ),
    .axi4_mgr_ar_burst_o  ( axi4_mgr_ar_burst_o  ),
    .axi4_mgr_ar_lock_o   ( axi4_mgr_ar_lock_o   ),
    .axi4_mgr_ar_cache_o  ( axi4_mgr_ar_cache_o  ),
    .axi4_mgr_ar_prot_o   ( axi4_mgr_ar_prot_o   ),
    .axi4_mgr_ar_region_o ( axi4_mgr_ar_region_o ),
    .axi4_mgr_ar_qos_o    ( axi4_mgr_ar_qos_o    ),
    .axi4_mgr_ar_user_o   ( axi4_mgr_ar_user_o   ),
    .axi4_mgr_ar_valid_o  ( axi4_mgr_ar_valid_o  ),
    .axi4_mgr_ar_ready_i  ( axi4_mgr_ar_ready_i  ),
    .axi4_mgr_r_id_i      ( axi4_mgr_r_id_i      ),
    .axi4_mgr_r_data_i    ( axi4_mgr_r_data_i    ),
    .axi4_mgr_r_resp_i    ( axi4_mgr_r_resp_i    ),
    .axi4_mgr_r_last_i    ( axi4_mgr_r_last_i    ),
    .axi4_mgr_r_user_i    ( axi4_mgr_r_user_i    ),
    .axi4_mgr_r_valid_i   ( axi4_mgr_r_valid_i   ),
    .axi4_mgr_r_ready_o   ( axi4_mgr_r_ready_o   ),
    // AXI-LITE
    .axil_sub_aw_addr_i   ( axil_sub_aw_addr_i   ),
    .axil_sub_aw_prot_i   ( axil_sub_aw_prot_i   ),
    .axil_sub_aw_valid_i  ( axil_sub_aw_valid_i  ),
    .axil_sub_aw_ready_o  ( axil_sub_aw_ready_o  ),
    .axil_sub_w_data_i    ( axil_sub_w_data_i    ),
    .axil_sub_w_strb_i    ( axil_sub_w_strb_i    ),
    .axil_sub_w_valid_i   ( axil_sub_w_valid_i   ),
    .axil_sub_w_ready_o   ( axil_sub_w_ready_o   ),
    .axil_sub_b_resp_o    ( axil_sub_b_resp_o    ),
    .axil_sub_b_valid_o   ( axil_sub_b_valid_o   ),
    .axil_sub_b_ready_i   ( axil_sub_b_ready_i   ),
    .axil_sub_ar_addr_i   ( axil_sub_ar_addr_i   ),
    .axil_sub_ar_prot_i   ( axil_sub_ar_prot_i   ),
    .axil_sub_ar_valid_i  ( axil_sub_ar_valid_i  ),
    .axil_sub_ar_ready_o  ( axil_sub_ar_ready_o  ),
    .axil_sub_r_data_o    ( axil_sub_r_data_o    ),
    .axil_sub_r_resp_o    ( axil_sub_r_resp_o    ),
    .axil_sub_r_valid_o   ( axil_sub_r_valid_o   ),
    .axil_sub_r_ready_i   ( axil_sub_r_ready_i   ) 
  );

endmodule // fpga_axi4_mgr_wrapper

/*******************************************************************************
-- Title      : Testbench for AXI-Lite register interface
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_axi_lite_registers.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2023-01-04
-- Design     : tb_axi_lite_registers
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Testbench for the AXI-Lite registers used to control the 
--              AXI4 Manager interface.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2023-01-04  1.0      TZS     Created
*******************************************************************************/

module tb_axi_lite_registers #( 
  parameter time     CLK_PERIOD_NS    =   10,
  parameter unsigned AXI4_ADDR_WIDTH  =   32,
  parameter unsigned AXI4_DATA_WIDTH  =   64,
  parameter unsigned AXIL_ADDR_WIDTH  =   32,
  parameter unsigned AXIL_DATA_WIDTH  =   32,
  parameter unsigned AXI_ID_WIDTH     =    4,
  parameter unsigned AXI_USER_WIDTH   =    5,
  parameter unsigned FIFO_DEPTH       = 1024,
  parameter integer AXI_XSIZE         = (AXI4_DATA_WIDTH / 8),
  parameter integer REG_BASE_ADDR     =  'h0,
  parameter integer DATA_COUNT_WIDTH  =    8,
  parameter unsigned SIM_TIME         =    1ms
);
  
  timeunit 1ns/1ps;

  /* LOCAL PARAMS/VARS/CONST/INTF DECLARATIONS ********************************/

  localparam integer unsigned AXILSizeBytes  = (AXIL_DATA_WIDTH/8);
  localparam integer unsigned AXI4SizeBytes  = (AXI4_DATA_WIDTH/8);
  localparam integer unsigned DataCountWidth = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1;

  typedef struct {
    logic [ AXIL_ADDR_WIDTH-1:0] axi_aw_addr_o;
    logic                        axi_aw_valid_o;
    logic                        axi_aw_ready_i;
    logic [ AXIL_DATA_WIDTH-1:0] axi_w_data_o;
    logic [   AXILSizeBytes-1:0] axi_w_strb_o;
    logic                        axi_w_valid_o;
    logic                        axi_w_ready_i;
    logic                        axi_b_valid_i;
    logic                        axi_b_ready_o;  
  } axi_write_t;

  typedef struct {
    logic [ AXIL_ADDR_WIDTH-1:0] axi_ar_addr_o;
    logic                        axi_ar_valid_o;
    logic                        axi_ar_ready_i;
    logic [ AXIL_DATA_WIDTH-1:0] axi_r_data_i;
    logic                        axi_r_valid_i;
    logic                        axi_r_ready_o;
  } axi_read_t;

  axi_write_t axi_write_signals_s;
  axi_read_t  axi_read_signals_s;

  logic clk, rstn;

  logic [    AXI_ID_WIDTH-1:0] axi4_mgr_aw_id_s;
  logic [ AXI4_ADDR_WIDTH-1:0] axi4_mgr_aw_addr_s;
  logic [               8-1:0] axi4_mgr_aw_len_s;
  logic [               3-1:0] axi4_mgr_aw_size_s;
  logic [               2-1:0] axi4_mgr_aw_burst_s;
  logic                        axi4_mgr_aw_lock_s;
  logic [               4-1:0] axi4_mgr_aw_cache_s;
  logic [               3-1:0] axi4_mgr_aw_prot_s;
  logic [               4-1:0] axi4_mgr_aw_qos_s;
  logic [               4-1:0] axi4_mgr_aw_region_s;
  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_aw_user_s;
  logic                        axi4_mgr_aw_valid_s;
  logic                        axi4_mgr_aw_ready_s;
  // W
  logic [ AXI4_DATA_WIDTH-1:0] axi4_mgr_w_data_s;
  logic [       AXI_XSIZE-1:0] axi4_mgr_w_strb_s;
  logic                        axi4_mgr_w_last_s;
  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_w_user_s;
  logic                        axi4_mgr_w_valid_s;
  logic                        axi4_mgr_w_ready_s;
  // B
  logic [    AXI_ID_WIDTH-1:0] axi4_mgr_b_id_s;
  logic [               2-1:0] axi4_mgr_b_resp_s;
  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_b_user_s = '0;
  logic                        axi4_mgr_b_valid_s;
  logic                        axi4_mgr_b_ready_s;
  // AR
  logic [    AXI_ID_WIDTH-1:0] axi4_mgr_ar_id_s;
  logic [ AXI4_ADDR_WIDTH-1:0] axi4_mgr_ar_addr_s;
  logic [               8-1:0] axi4_mgr_ar_len_s;
  logic [               3-1:0] axi4_mgr_ar_size_s;
  logic [               2-1:0] axi4_mgr_ar_burst_s;
  logic                        axi4_mgr_ar_lock_s;
  logic [               4-1:0] axi4_mgr_ar_cache_s;
  logic [               3-1:0] axi4_mgr_ar_prot_s;
  logic [               4-1:0] axi4_mgr_ar_region_s;
  logic [               4-1:0] axi4_mgr_ar_qos_s;
  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_ar_user_s;
  logic                        axi4_mgr_ar_valid_s;
  logic                        axi4_mgr_ar_ready_s;
  // R
  logic [    AXI_ID_WIDTH-1:0] axi4_mgr_r_id_s;
  logic [ AXI4_DATA_WIDTH-1:0] axi4_mgr_r_data_s;
  logic [               2-1:0] axi4_mgr_r_resp_s;
  logic                        axi4_mgr_r_last_s;
  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_r_user_s = '0;
  logic                        axi4_mgr_r_valid_s;
  logic                        axi4_mgr_r_ready_s;

  // AXI-LITE Signals
  // AW                                                                  
  logic [ AXIL_ADDR_WIDTH-1:0] axil_sub_aw_addr_s;
  logic [               3-1:0] axil_sub_aw_prot_s;
  logic                        axil_sub_aw_valid_s;
  logic                        axil_sub_aw_ready_s;
  // W                                                                     
  logic [ AXIL_DATA_WIDTH-1:0] axil_sub_w_data_s;
  logic [   AXILSizeBytes-1:0] axil_sub_w_strb_s;
  logic                        axil_sub_w_valid_s;
  logic                        axil_sub_w_ready_s;
  // B                                                                     
  logic [               2-1:0] axil_sub_b_resp_s;
  logic                        axil_sub_b_valid_s;
  logic                        axil_sub_b_ready_s;
  // AR                                                                     
  logic [ AXIL_ADDR_WIDTH-1:0] axil_sub_ar_addr_s;
  logic [               3-1:0] axil_sub_ar_prot_s;
  logic                        axil_sub_ar_valid_s;
  logic                        axil_sub_ar_ready_s;
  // R 
  logic [ AXIL_DATA_WIDTH-1:0] axil_sub_r_data_s;
  logic [               2-1:0] axil_sub_r_resp_s;
  logic                        axil_sub_r_valid_s;
  logic                        axil_sub_r_ready_s;

  logic [ AXIL_DATA_WIDTH-1:0] read_data_s;
  logic [ AXI4_DATA_WIDTH-1:0] write_data_s [$];

  logic [ AXIL_ADDR_WIDTH-1:0] ENABLE             = 'h00;
  logic [ AXIL_ADDR_WIDTH-1:0] REQUEST            = 'h04;
  logic [ AXIL_ADDR_WIDTH-1:0] RESPONSE           = 'h08;
  logic [ AXIL_ADDR_WIDTH-1:0] AXI_WR_ADDR        = 'h0C;
  logic [ AXIL_ADDR_WIDTH-1:0] AXI_RD_ADDR        = 'h10;
  logic [ AXIL_ADDR_WIDTH-1:0] AXI_RD_COUNT       = 'h14;
  logic [ AXIL_ADDR_WIDTH-1:0] RD_ERR             = 'h18; 
  logic [ AXIL_ADDR_WIDTH-1:0] WR_ERR             = 'h1C;
  logic [ AXIL_ADDR_WIDTH-1:0] WR_FIFO_DATA_IN_L  = 'h20;
  logic [ AXIL_ADDR_WIDTH-1:0] WR_FIFO_DATA_IN_H  = 'h24;
  logic [ AXIL_ADDR_WIDTH-1:0] WR_FIFO_PUSH       = 'h28; 
  logic [ AXIL_ADDR_WIDTH-1:0] WR_FIFO_USAGE      = 'h2C;
  logic [ AXIL_ADDR_WIDTH-1:0] WR_FIFO_STATUS     = 'h30;
  logic [ AXIL_ADDR_WIDTH-1:0] RD_FIFO_DATA_OUT_L = 'h34;
  logic [ AXIL_ADDR_WIDTH-1:0] RD_FIFO_DATA_OUT_H = 'h38;
  logic [ AXIL_ADDR_WIDTH-1:0] RD_FIFO_POP        = 'h3C;
  logic [ AXIL_ADDR_WIDTH-1:0] RD_FIFO_USAGE      = 'h40;
  logic [ AXIL_ADDR_WIDTH-1:0] RD_FIFO_STATUS     = 'h44;

  /* ASSIGNMENTS **************************************************************/

  assign axil_sub_aw_addr_s                 = axi_write_signals_s.axi_aw_addr_o;
  assign axil_sub_aw_valid_s                = axi_write_signals_s.axi_aw_valid_o;
  assign axi_write_signals_s.axi_aw_ready_i = axil_sub_aw_ready_s;
  assign axil_sub_w_data_s                  = axi_write_signals_s.axi_w_data_o;
  assign axil_sub_w_strb_s                  = axi_write_signals_s.axi_w_strb_o;
  assign axil_sub_w_valid_s                 = axi_write_signals_s.axi_w_valid_o;
  assign axi_write_signals_s.axi_w_ready_i  = axil_sub_w_ready_s;
  assign axi_write_signals_s.axi_b_valid_i  = axil_sub_b_valid_s;
  assign axil_sub_b_ready_s                 = axi_write_signals_s.axi_b_ready_o;

  assign axil_sub_ar_addr_s                =  axi_read_signals_s.axi_ar_addr_o; 
  assign axil_sub_ar_valid_s               =  axi_read_signals_s.axi_ar_valid_o; 
  assign axi_read_signals_s.axi_ar_ready_i =  axil_sub_ar_ready_s;
  assign axi_read_signals_s.axi_r_data_i   =  axil_sub_r_data_s;
  assign axi_read_signals_s.axi_r_valid_i  =  axil_sub_r_valid_s;
  assign axil_sub_r_ready_s                =  axi_read_signals_s.axi_r_ready_o; 


  /* COMPONENT DECLARATION ****************************************************/

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
  ) i_dut (
    .clk_i                ( clk                  ),
    .rstn_i               ( rstn                 ),
    // AXI4
    .axi4_mgr_aw_id_o     ( axi4_mgr_aw_id_s     ),
    .axi4_mgr_aw_addr_o   ( axi4_mgr_aw_addr_s   ),
    .axi4_mgr_aw_len_o    ( axi4_mgr_aw_len_s    ),
    .axi4_mgr_aw_size_o   ( axi4_mgr_aw_size_s   ),
    .axi4_mgr_aw_burst_o  ( axi4_mgr_aw_burst_s  ),
    .axi4_mgr_aw_lock_o   ( axi4_mgr_aw_lock_s   ),
    .axi4_mgr_aw_cache_o  ( axi4_mgr_aw_cache_s  ),
    .axi4_mgr_aw_prot_o   ( axi4_mgr_aw_prot_s   ),
    .axi4_mgr_aw_qos_o    ( axi4_mgr_aw_qos_s    ),
    .axi4_mgr_aw_region_o ( axi4_mgr_aw_region_s ),
    .axi4_mgr_aw_user_o   ( axi4_mgr_aw_user_s   ),
    .axi4_mgr_aw_valid_o  ( axi4_mgr_aw_valid_s  ),
    .axi4_mgr_aw_ready_i  ( axi4_mgr_aw_ready_s  ),
    .axi4_mgr_w_data_o    ( axi4_mgr_w_data_s    ),
    .axi4_mgr_w_strb_o    ( axi4_mgr_w_strb_s    ),
    .axi4_mgr_w_last_o    ( axi4_mgr_w_last_s    ),
    .axi4_mgr_w_user_o    ( axi4_mgr_w_user_s    ),
    .axi4_mgr_w_valid_o   ( axi4_mgr_w_valid_s   ),
    .axi4_mgr_w_ready_i   ( axi4_mgr_w_ready_s   ),
    .axi4_mgr_b_id_i      ( axi4_mgr_b_id_s      ),
    .axi4_mgr_b_resp_i    ( axi4_mgr_b_resp_s    ),
    .axi4_mgr_b_user_i    ( axi4_mgr_b_user_s    ),
    .axi4_mgr_b_valid_i   ( axi4_mgr_b_valid_s   ),
    .axi4_mgr_b_ready_o   ( axi4_mgr_b_ready_s   ),
    .axi4_mgr_ar_id_o     ( axi4_mgr_ar_id_s     ),
    .axi4_mgr_ar_addr_o   ( axi4_mgr_ar_addr_s   ),
    .axi4_mgr_ar_len_o    ( axi4_mgr_ar_len_s    ),
    .axi4_mgr_ar_size_o   ( axi4_mgr_ar_size_s   ),
    .axi4_mgr_ar_burst_o  ( axi4_mgr_ar_burst_s  ),
    .axi4_mgr_ar_lock_o   ( axi4_mgr_ar_lock_s   ),
    .axi4_mgr_ar_cache_o  ( axi4_mgr_ar_cache_s  ),
    .axi4_mgr_ar_prot_o   ( axi4_mgr_ar_prot_s   ),
    .axi4_mgr_ar_region_o ( axi4_mgr_ar_region_s ),
    .axi4_mgr_ar_qos_o    ( axi4_mgr_ar_qos_s    ),
    .axi4_mgr_ar_user_o   ( axi4_mgr_ar_user_s   ),
    .axi4_mgr_ar_valid_o  ( axi4_mgr_ar_valid_s  ),
    .axi4_mgr_ar_ready_i  ( axi4_mgr_ar_ready_s  ),
    .axi4_mgr_r_id_i      ( axi4_mgr_r_id_s      ),
    .axi4_mgr_r_data_i    ( axi4_mgr_r_data_s    ),
    .axi4_mgr_r_resp_i    ( axi4_mgr_r_resp_s    ),
    .axi4_mgr_r_last_i    ( axi4_mgr_r_last_s    ),
    .axi4_mgr_r_user_i    ( axi4_mgr_r_user_s    ),
    .axi4_mgr_r_valid_i   ( axi4_mgr_r_valid_s   ),
    .axi4_mgr_r_ready_o   ( axi4_mgr_r_ready_s   ),
    // AXI-LITE
    .axil_sub_aw_addr_i   ( axil_sub_aw_addr_s   ),
    .axil_sub_aw_prot_i   ( axil_sub_aw_prot_s   ),
    .axil_sub_aw_valid_i  ( axil_sub_aw_valid_s  ),
    .axil_sub_aw_ready_o  ( axil_sub_aw_ready_s  ),
    .axil_sub_w_data_i    ( axil_sub_w_data_s    ),
    .axil_sub_w_strb_i    ( axil_sub_w_strb_s    ),
    .axil_sub_w_valid_i   ( axil_sub_w_valid_s   ),
    .axil_sub_w_ready_o   ( axil_sub_w_ready_s   ),
    .axil_sub_b_resp_o    ( axil_sub_b_resp_s    ),
    .axil_sub_b_valid_o   ( axil_sub_b_valid_s   ),
    .axil_sub_b_ready_i   ( axil_sub_b_ready_s   ),
    .axil_sub_ar_addr_i   ( axil_sub_ar_addr_s   ),
    .axil_sub_ar_prot_i   ( axil_sub_ar_prot_s   ),
    .axil_sub_ar_valid_i  ( axil_sub_ar_valid_s  ),
    .axil_sub_ar_ready_o  ( axil_sub_ar_ready_s  ),
    .axil_sub_r_data_o    ( axil_sub_r_data_s    ),
    .axil_sub_r_resp_o    ( axil_sub_r_resp_s    ),
    .axil_sub_r_valid_o   ( axil_sub_r_valid_s   ),
    .axil_sub_r_ready_i   ( axil_sub_r_ready_s   ) 
  );

  // AXI4 BRAM 64b wide, 512 deep
  blk_mem_gen_0 i_test_axi_mem (
    .s_aclk        ( clk             ), // input  wire s_aclk
    .s_aresetn     ( rstn            ), // input  wire s_aresetn
    .s_axi_awid    ( axi4_mgr_aw_id_s    ), // input  wire [3 : 0] s_axi_awid
    .s_axi_awaddr  ( axi4_mgr_aw_addr_s  ), // input  wire [31 : 0] s_axi_awaddr
    .s_axi_awlen   ( axi4_mgr_aw_len_s   ), // input  wire [7 : 0] s_axi_awlen
    .s_axi_awsize  ( axi4_mgr_aw_size_s  ), // input  wire [2 : 0] s_axi_awsize
    .s_axi_awburst ( axi4_mgr_aw_burst_s ), // input  wire [1 : 0] s_axi_awburst
    .s_axi_awvalid ( axi4_mgr_aw_valid_s ), // input  wire s_axi_awvalid
    .s_axi_awready ( axi4_mgr_aw_ready_s ), // output wire s_axi_awready
    .s_axi_wdata   ( axi4_mgr_w_data_s   ), // input  wire [63 : 0] s_axi_wdata
    .s_axi_wstrb   ( axi4_mgr_w_strb_s   ), // input  wire [7 : 0] s_axi_wstrb
    .s_axi_wlast   ( axi4_mgr_w_last_s   ), // input  wire s_axi_wlast
    .s_axi_wvalid  ( axi4_mgr_w_valid_s  ), // input  wire s_axi_wvalid
    .s_axi_wready  ( axi4_mgr_w_ready_s  ), // output wire s_axi_wready
    .s_axi_bid     ( axi4_mgr_b_id_s     ), // output wire [3 : 0] s_axi_bid
    .s_axi_bresp   ( axi4_mgr_b_resp_s   ), // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid  ( axi4_mgr_b_valid_s  ), // output wire s_axi_bvalid
    .s_axi_bready  ( axi4_mgr_b_ready_s  ), // input  wire s_axi_bready
    .s_axi_arid    ( axi4_mgr_ar_id_s    ), // input  wire [3 : 0] s_axi_arid
    .s_axi_araddr  ( axi4_mgr_ar_addr_s  ), // input  wire [31 : 0] s_axi_araddr
    .s_axi_arlen   ( axi4_mgr_ar_len_s   ), // input  wire [7 : 0] s_axi_arlen
    .s_axi_arsize  ( axi4_mgr_ar_size_s  ), // input  wire [2 : 0] s_axi_arsize
    .s_axi_arburst ( axi4_mgr_ar_burst_s ), // input  wire [1 : 0] s_axi_arburst
    .s_axi_arvalid ( axi4_mgr_ar_valid_s ), // input  wire s_axi_arvalid
    .s_axi_arready ( axi4_mgr_ar_ready_s ), // output wire s_axi_arready
    .s_axi_rid     ( axi4_mgr_r_id_s     ), // output wire [3 : 0] s_axi_rid
    .s_axi_rdata   ( axi4_mgr_r_data_s   ), // output wire [63 : 0] s_axi_rdata
    .s_axi_rresp   ( axi4_mgr_r_resp_s   ), // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast   ( axi4_mgr_r_last_s   ), // output wire s_axi_rlast
    .s_axi_rvalid  ( axi4_mgr_r_valid_s  ), // output wire s_axi_rvalid
    .s_axi_rready  ( axi4_mgr_r_ready_s  )  // input  wire s_axi_rready
  );



/* TEST LOGIC *****************************************************************/

  initial begin : clock_generation /*******************************************/
    forever begin
      clk = 1'b0;
      #(CLK_PERIOD_NS/2);
      clk = 1'b1;
      #(CLK_PERIOD_NS/2);
    end
  end /************************************************************************/

  initial begin : tb_logic /***************************************************/

    $timeformat(-9,0,"ns");

    write_data_s = {
      64'hDEAD_BEEF_DA7A_0000,
      64'hABBA_DABA_DA7A_0001,
      64'hDEAD_BEEF_DA7A_0002,
      64'hABBA_DABA_DA7A_0003,
      64'hDEAD_BEEF_DA7A_0004,
      64'hABBA_DABA_DA7A_0005,
      64'hDEAD_BEEF_DA7A_0006,
      64'hABBA_DABA_DA7A_0007,
      64'hDEAD_BEEF_DA7A_0008,
      64'hABBA_DABA_DA7A_0009,
      64'hDEAD_BEEF_DA7A_000A,
      64'hABBA_DABA_DA7A_000B,
      64'hDEAD_BEEF_DA7A_000C,
      64'hABBA_DABA_DA7A_000D,
      64'hDEAD_BEEF_DA7A_000E,
      64'hABBA_DABA_DA7A_000F
    };
    
    rstn = '0;

    read_data_s = '0;

    axi_write_signals_s.axi_aw_addr_o  = '0;       
    axil_sub_aw_prot_s                 = '0;       
    axi_write_signals_s.axi_aw_valid_o = '0;                
    axi_write_signals_s.axi_w_data_o   = '0;      
    axi_write_signals_s.axi_w_strb_o   = '0;      
    axi_write_signals_s.axi_w_valid_o  = '0;       
    axi_write_signals_s.axi_b_ready_o  = '0; 
    axi_read_signals_s.axi_ar_valid_o  = '0;      
    axi_read_signals_s.axi_ar_addr_o   = '0;    
    axi_read_signals_s.axi_r_ready_o   = '0;   
    axil_sub_ar_prot_s                 = '0;       
    
    #(CLK_PERIOD_NS*2) rstn = 1'b1;    
   
    // set enable
    write_address( ENABLE, "ENABLE", '1, clk, axi_write_signals_s);    
    
    // test wr fifo status
    read_address( RD_FIFO_STATUS, "RD_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    read_address( WR_FIFO_STATUS, "WR_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    
    // test wr fifo usage
    populate_wr_fifo(write_data_s);

    // set rd and wr address
    write_address( AXI_WR_ADDR, "AXI_WR_ADDR", '0, clk, axi_write_signals_s);
    write_address( AXI_RD_ADDR, "AXI_RD_ADDR", '0, clk, axi_write_signals_s);
    
    // init wr xfer
    write_address( REQUEST, "REQUEST", '1, clk, axi_write_signals_s);
    write_address( REQUEST, "REQUEST", '0, clk, axi_write_signals_s);

    // loop until writes are completed
    read_data_s = '0;
    while(read_data_s[1] != 1'b1) 
      read_address( RESPONSE, "RESPONSE", read_data_s, clk, axi_read_signals_s);

    // clear response
    write_address( RESPONSE, "RESPONSE", 'b1, clk, axi_write_signals_s);

    // set number of AXI reads
    write_address( AXI_RD_COUNT, "AXI_RD_COUNT", 'd7, clk, axi_write_signals_s);

    // init rd xfer
    write_address( REQUEST, "REQUEST", 'b10, clk, axi_write_signals_s);
    write_address( REQUEST, "REQUEST", '0, clk, axi_write_signals_s);

    // loop until writes are completed
    read_data_s = '0;
    while(read_data_s[2] != 1'b1) 
      read_address( RESPONSE, "RESPONSE", read_data_s, clk, axi_read_signals_s);

    // clear response
    write_address( RESPONSE, "RESPONSE", 'b1, clk, axi_write_signals_s);

    // test rd fifo usage
    read_address( RD_FIFO_USAGE, "RD_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);

    // test reading data from FIFO
    repeat (7) begin
      read_address( RD_FIFO_DATA_OUT_H, "RD_FIFO_DATA_OUT_H", read_data_s, clk, axi_read_signals_s);
      read_address( RD_FIFO_DATA_OUT_L, "RD_FIFO_DATA_OUT_L", read_data_s, clk, axi_read_signals_s);
      write_address( RD_FIFO_POP, "RD_FIFO_POP", '1, clk, axi_write_signals_s );
    end

    read_address( RD_FIFO_USAGE, "RD_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);
    
    // disable subsystem
    write_address( ENABLE, "ENABLE", '0, clk, axi_write_signals_s);
    
    repeat (100)
      @(posedge clk);

    $finish;     

  end /************************************************************************/

/* SUBROUTINES ****************************************************************/

  /* 
  Task to write data to register address and print result. 
  The data to be written is passed to the data parameter. The address to write
  should be passed to the addr parameter.
  The reg_id parameter is merely a label to be used within the printed messages 
  and therefore has no functional impact.
  */
  task automatic write_address(
    input logic [ AXIL_ADDR_WIDTH-1:0] addr,
    input string                       reg_id,
    input logic [ AXIL_DATA_WIDTH-1:0] data,

    ref   logic                        clk,

    ref   axi_write_t                  axi_write_signals
  );
  
    axi_write_signals.axi_aw_addr_o  = '0;   
    axi_write_signals.axi_aw_valid_o = '0;     
    axi_write_signals.axi_w_data_o   = '0;   
    axi_write_signals.axi_w_strb_o   = '0;   
    axi_write_signals.axi_w_valid_o  = '0;    
    axi_write_signals.axi_b_ready_o  = '0; 
  
    @(negedge clk); // update vals on negedge
  
    axi_write_signals.axi_aw_valid_o = 1'b1;
    axi_write_signals.axi_aw_addr_o  = addr;
    
    @(posedge clk); // check vals on posedge
    

    while (~axi_write_signals.axi_aw_ready_i) begin
      @(posedge clk); 
    end    

    @(negedge clk);
  
    axi_write_signals.axi_aw_valid_o = 1'b0;
    axi_write_signals.axi_aw_addr_o  =   '0;
    axi_write_signals.axi_w_data_o   = data;   
    axi_write_signals.axi_w_strb_o   =  'hF;   
    axi_write_signals.axi_w_valid_o  = 1'b1;

    @(posedge clk);    
    
    while (~axi_write_signals.axi_w_ready_i) begin
      @(posedge clk); 
    end     

    @(negedge clk);
  
    axi_write_signals.axi_w_data_o   =   '0;   
    axi_write_signals.axi_w_strb_o   =   '0;   
    axi_write_signals.axi_w_valid_o  =   '0;
    axi_write_signals.axi_b_ready_o  = 1'b1;

    @(posedge clk);       
  
    while (~axi_write_signals.axi_b_valid_i) begin
      @(posedge clk);    
    end 

    @(negedge clk);
    
    axi_write_signals.axi_b_ready_o  = 1'b0;
  
    @(posedge clk);  

    $display("%10t: AXI-Lite write of DATA: 0x%8h to   ADDR: %2d (0x%2h) '%s' complete.", 
             $time, data, addr, addr, reg_id);
  
  endtask
  /* 
  Task to read register address and print result. Data is stored within the argument
  passed as the data parameter. The address to write
  should be passed to the addr parameter.
  The reg_id parameter is merely a label to be used within the printed messages 
  and therefore has no functional impact.
  */
  task automatic read_address(
    input  logic [ AXIL_ADDR_WIDTH-1:0] addr,
    input  string                       reg_id,
    output logic [ AXIL_DATA_WIDTH-1:0] data,

    ref    logic                        clk,
    
    ref    axi_read_t                   axi_read_signals
  );
  
    axi_read_signals.axi_ar_addr_o  = '0;    
    axi_read_signals.axi_ar_valid_o = '0;  
    axi_read_signals.axi_r_ready_o  = '0;        
  
    @(negedge clk);
  
    axi_read_signals.axi_ar_valid_o = 1'b1;
    axi_read_signals.axi_ar_addr_o  = addr;
    
    @(posedge clk);    

    while (~axi_read_signals.axi_ar_ready_i) begin
      @(posedge clk);   
    end    

    @(negedge clk);
  
    axi_read_signals.axi_ar_valid_o = 1'b0;
    axi_read_signals.axi_ar_addr_o  =   '0;
    axi_read_signals.axi_r_ready_o  = 1'b1; 

    @(posedge clk);    
    
    while (~axi_read_signals.axi_r_valid_i) begin
      @(posedge clk);    
    end 

    data = axi_read_signals.axi_r_data_i; 

    @(negedge clk);
        
    axi_read_signals.axi_r_ready_o = '0;
  
    @(posedge clk);    

    $display("%10t: AXI-Lite read  of DATA: 0x%8h from ADDR: %2d (0x%2h) '%s' complete.", 
             $time, data, addr, addr, reg_id);
  
  endtask

  /* 
    Task to populate write FIFO using a pre-populated queue. Currently, a limitation
    exists which means that the width of each queue element must be 2x the width of the 
    FIFO entries i.e. (AXI4_DATA_WIDTH must be 2x the size of AXI4_DATA_WIDTH).
    Total contents of queue passed as data_i parameter will be written to the FIFO
    and the usage will be reported before and after reading for information.
  */
  task automatic populate_wr_fifo(
    input logic [AXI4_DATA_WIDTH-1:0] data_i [$]    
  );

    automatic logic [AXI4_DATA_WIDTH-1:0] tmp_wr_data;
    automatic logic [AXIL_DATA_WIDTH-1:0] tmp_rd_data;
    
    read_address( WR_FIFO_USAGE, "WR_FIFO_USAGE", tmp_rd_data, clk, axi_read_signals_s);

    repeat (data_i.size()) begin
      tmp_wr_data = data_i.pop_front();
      write_address( WR_FIFO_DATA_IN_L, "WR_FIFO_DATA_IN_L", tmp_wr_data[AXIL_DATA_WIDTH-1:0], clk, axi_write_signals_s );
      write_address( WR_FIFO_DATA_IN_H, "WR_FIFO_DATA_IN_H", tmp_wr_data[AXI4_DATA_WIDTH-1:AXIL_DATA_WIDTH], clk, axi_write_signals_s );
      write_address( WR_FIFO_PUSH, "WR_FIFO_PUSH", '1, clk, axi_write_signals_s );    
    end

    read_address( WR_FIFO_USAGE, "WR_FIFO_USAGE", tmp_rd_data, clk, axi_read_signals_s);

  endtask

endmodule // tb_axi_lite_registers

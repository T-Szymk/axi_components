/*******************************************************************************
-- Title      : AXI4 Mgr Testbench
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-28
-- Design     : tb_axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Testbench for generic AXI4 manager.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-28  1.0      TZS     Created
*******************************************************************************/

module tb_axi4_mgr #(
  parameter time     CLK_PERIOD_NS   = 10,
  parameter unsigned AXI_ADDR_WIDTH  = 32,
  parameter unsigned AXI_DATA_WIDTH  = 64,
  parameter unsigned AXI_ID_WIDTH    =  9,
  parameter unsigned AXI_USER_WIDTH  =  5,
  parameter unsigned WORD_SIZE_BYTES =  4
);

  timeunit 1ns/1ps;

  localparam int AXISize        = (AXI_DATA_WIDTH/8);
  localparam int DataCountWidth = 9; // 256 max

  logic       clk;
  logic       rstn;
  logic [1:0] req_s;
  logic [1:0] rsp_s;

  logic [DataCountWidth-1:0] wr_data_count_s;
  logic [DataCountWidth-1:0] rd_data_count_s;
  logic [             2-1:0] dut_wr_err_s;
  logic [             2-1:0] dut_rd_err_s;
  logic [AXI_DATA_WIDTH-1:0] axi_wr_data_s;
  logic [AXI_DATA_WIDTH-1:0] axi_rd_data_s;
  logic [AXI_ADDR_WIDTH-1:0] axi_wr_addr_s;
  logic [AXI_ADDR_WIDTH-1:0] axi_rd_addr_s;

  axi4_bus_test_if #(
    .ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .ID_WIDTH   ( AXI_ID_WIDTH   ),
    .USER_WIDTH ( AXI_USER_WIDTH )
  ) axi_s_tb_if ( clk );

  axi4_bus_if #(
    .ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .ID_WIDTH   ( AXI_ID_WIDTH   ),
    .USER_WIDTH ( AXI_USER_WIDTH )
  ) dut_if ();

  axi4_test_pkg::SubAXI4 #(
    .ID_WIDTH     ( AXI_ID_WIDTH   ),     
    .ADDR_WIDTH   ( AXI_ADDR_WIDTH ),       
    .DATA_WIDTH   ( AXI_DATA_WIDTH ),       
    .USER_WIDTH   ( AXI_USER_WIDTH ),       
    .ASSIGN_DELAY ( 0ps            ),         
    .EXEC_DELAY   ( 500ps          ) 
  ) tb_axi4_sub = new(axi_s_tb_if);

  /* AXI Interface Assignments */
  assign axi_s_tb_if.aw_id     = dut_if.aw_id;
  assign axi_s_tb_if.aw_addr   = dut_if.aw_addr;
  assign axi_s_tb_if.aw_len    = dut_if.aw_len;
  assign axi_s_tb_if.aw_size   = dut_if.aw_size;
  assign axi_s_tb_if.aw_burst  = dut_if.aw_burst;
  assign axi_s_tb_if.aw_lock   = dut_if.aw_lock;
  assign axi_s_tb_if.aw_cache  = dut_if.aw_cache;
  assign axi_s_tb_if.aw_prot   = dut_if.aw_prot;
  assign axi_s_tb_if.aw_qos    = dut_if.aw_qos;
  assign axi_s_tb_if.aw_region = dut_if.aw_region;
  assign axi_s_tb_if.aw_atop   = dut_if.aw_atop;
  assign axi_s_tb_if.aw_user   = dut_if.aw_user;
  assign axi_s_tb_if.aw_valid  = dut_if.aw_valid;
  assign dut_if.aw_ready       = axi_s_tb_if.aw_ready;

  assign axi_s_tb_if.w_data  = dut_if.w_data;
  assign axi_s_tb_if.w_strb  = dut_if.w_strb;
  assign axi_s_tb_if.w_last  = dut_if.w_last;
  assign axi_s_tb_if.w_user  = dut_if.w_user;
  assign axi_s_tb_if.w_valid = dut_if.w_valid;
  assign dut_if.w_ready      = axi_s_tb_if.w_ready;

  assign dut_if.b_id         = axi_s_tb_if.b_id;    
  assign dut_if.b_resp       = axi_s_tb_if.b_resp;      
  assign dut_if.b_user       = axi_s_tb_if.b_user;      
  assign dut_if.b_valid      = axi_s_tb_if.b_valid;        
  assign axi_s_tb_if.b_ready = dut_if.b_ready;

  assign axi_s_tb_if.ar_id     = dut_if.ar_id;
  assign axi_s_tb_if.ar_addr   = dut_if.ar_addr;
  assign axi_s_tb_if.ar_len    = dut_if.ar_len;
  assign axi_s_tb_if.ar_size   = dut_if.ar_size;
  assign axi_s_tb_if.ar_burst  = dut_if.ar_burst;
  assign axi_s_tb_if.ar_lock   = dut_if.ar_lock;
  assign axi_s_tb_if.ar_cache  = dut_if.ar_cache;
  assign axi_s_tb_if.ar_prot   = dut_if.ar_prot;
  assign axi_s_tb_if.ar_qos    = dut_if.ar_qos;
  assign axi_s_tb_if.ar_region = dut_if.ar_region;
  assign axi_s_tb_if.ar_user   = dut_if.ar_user;
  assign axi_s_tb_if.ar_valid  = dut_if.ar_valid;
  assign dut_if.ar_ready       = axi_s_tb_if.ar_ready;
  
  assign dut_if.r_id         = axi_s_tb_if.r_id;      
  assign dut_if.r_data       = axi_s_tb_if.r_data;        
  assign dut_if.r_resp       = axi_s_tb_if.r_resp;        
  assign dut_if.r_last       = axi_s_tb_if.r_last;        
  assign dut_if.r_user       = axi_s_tb_if.r_user;        
  assign dut_if.r_valid      = axi_s_tb_if.r_valid;        
  assign axi_s_tb_if.r_ready = dut_if.r_ready;
  /* AXI Interface Assignments */


  assign axi_wr_data_s = 'hDEADBEEF0B501E7E;
  assign axi_wr_addr_s = 'h5000;
  assign axi_rd_addr_s = 'h6000;

  initial begin
    forever begin
      #(CLK_PERIOD_NS/2) clk = 1'b0;
      #(CLK_PERIOD_NS/2) clk = 1'b1;
    end
  end

  /* COMPONENT AND DUT INSTANTIATIONS */

  // TODO: add fifo_v3

  axi4_mgr #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH  ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH  ),
    .AXI_XSIZE        ( AXISize         ),         
    .DATA_COUNT_WIDTH ( DataCountWidth  ),
    .WORD_SIZE_BYTES  ( WORD_SIZE_BYTES )                
  ) i_dut (
    .clk_i           ( clk              ),      
    .rstn_i          ( rstn             ),       
    .req_i           ( req_s            ),      
    .axi_wr_addr_i   ( axi_wr_addr_s    ),              
    .axi_rd_addr_i   ( axi_rd_addr_s    ),              
    .axi_data_i      ( axi_wr_data_s    ),           
    .wr_data_count_i ( wr_data_count_s  ),                
    .rd_data_count_i ( rd_data_count_s  ),                
    .rsp_o           ( rsp_s            ),      
    .wr_err_o        ( dut_wr_err_s     ),         
    .rd_err_o        ( dut_rd_err_s     ),         
    .axi_data_o      ( axi_rd_data_s    ),           
    .axi_mgr_if      ( dut_if           )           
  );

  initial begin

    $monitor("Write Error change detected. New value: %d", dut_wr_err_s);
    $monitor("Read Error change detected. New value: %d", dut_rd_err_s);

    rstn  = 1'b0;
    req_s = 2'b00;
    wr_data_count_s = 256; // start with single beats
    rd_data_count_s = 255; // start with single beats

    #(2*CLK_PERIOD_NS) rstn = 1'b1;
    tb_axi4_sub.reset();
    #(2*CLK_PERIOD_NS);

    req_s = 2'b11; // start read and write trans
    tb_axi4_sub.run();
    // infinite loop
    forever @(posedge clk);

    $finish;
  end

endmodule // tb_axi4_mgr

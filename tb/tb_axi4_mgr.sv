/*******************************************************************************
-- Title      : AXI4 Mgr Testbench
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-23
-- Design     : tb_axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Testbench for generic AXI4 manager.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-23  1.0      TZS     Created
*******************************************************************************/

`include "../ip/pulp_axi/include/axi/assign.svh"
`include "../ip/pulp_axi/include/axi/typedef.svh"

module tb_axi4_mgr
import axi_test::*;
#(
  parameter time     CLK_PERIOD_NS   = 10,
  parameter unsigned AXI_ADDR_WIDTH  = 32,
  parameter unsigned AXI_DATA_WIDTH  = 64,
  parameter unsigned AXI_ID_WIDTH    =  9,
  parameter unsigned AXI_USER_WIDTH  =  5,
  parameter unsigned WORD_SIZE_BYTES =  4
);

  timeunit 1ns/1ps;

  localparam int AXISize        = (AXI_DATA_WIDTH/8);
  localparam int DataCountWidth = 8;

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

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH )
  ) axi_s_tb_if ( clk );

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH )
  ) dut_if ();

  axi_rand_slave #(
    .AW ( AXI_ADDR_WIDTH ),
    .DW ( AXI_DATA_WIDTH ),
    .IW ( AXI_ID_WIDTH   ),
    .UW ( AXI_USER_WIDTH ),
    .TT ( 500ps          )
  ) tb_axi4_sub = new(axi_s_tb_if);

  `AXI_ASSIGN( axi_s_tb_if, dut_if )

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
    wr_data_count_s = 7; // start with single beats
    rd_data_count_s = 7; // start with single beats

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

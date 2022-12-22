/*******************************************************************************
-- Title      : AXI-Lite Mgr Testbench 
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_axi_lite_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-22
-- Design     : tb_axi_lite_mgr
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Testbench for AXI-Lite manager.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-22  1.0      TZS     Created
*******************************************************************************/

`include "../ips/headsail-common-ips/ips/axi/include/axi/assign.svh"
//`include "../ips/headsail-common-ips/ips/axi/src/axi_test.sv"

module tb_axi_lite_mgr
import axi_test::*;
#(
  parameter CLK_PERIOD_NS  = 10,
  parameter AXI_ADDR_WIDTH = 16,
  parameter AXI_DATA_WIDTH = 32
);
  
  timeunit 1ns/1ps;
  
  logic       clk; 
  logic       rstn;
  logic [1:0] req_s; 
  logic [1:0] rsp_s;

  logic [AXI_DATA_WIDTH-1:0] dla_data_s;
  logic [AXI_DATA_WIDTH-1:0] pp_data_s;
  logic [AXI_ADDR_WIDTH-1:0] axi_wr_addr_s;
  logic [AXI_ADDR_WIDTH-1:0] axi_rd_addr_s;

  AXI_LITE_DV #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH )
  ) axi_lite_tb ( clk );

  AXI_LITE #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH )
  ) pp_if ();
  
  axi_lite_rand_slave #(
    .AW(AXI_ADDR_WIDTH), 
    .DW(AXI_DATA_WIDTH)
  ) axi_lite_sub_s = new(axi_lite_tb, "tb_axi_lite_sub_sub");

  `AXI_LITE_ASSIGN( axi_lite_tb, pp_if )

  assign pp_data_s     = 'hDEADBEEF;
  assign axi_wr_addr_s = 'h5000;
  assign axi_rd_addr_s = 'h6000;

  initial begin 
    forever begin
      #(CLK_PERIOD_NS/2) clk = 1'b0;
      #(CLK_PERIOD_NS/2) clk = 1'b1;
    end 
  end

  dla_axi_lite_m #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH )
  ) i_dut (
    .clk_i         ( clk           ),           
    .rstn_i        ( rstn          ),            
    .req_i         ( req_s         ),           
    .axi_wr_addr_i ( axi_wr_addr_s ),                   
    .axi_rd_addr_i ( axi_rd_addr_s ),                   
    .pp_data_i     ( pp_data_s     ),               
    .rsp_o         ( rsp_s         ),           
    .dla_data_o    ( dla_data_s    ),                
    .pp_if         ( pp_if         )          
  );

  initial begin 

    rstn  = 1'b0;
    req_s = 2'b00;
    #(2*CLK_PERIOD_NS) rstn = 1'b1;
    axi_lite_sub_s.reset();
    #(2*CLK_PERIOD_NS);
    req_s = 2'b11; // start read and write trans
    axi_lite_sub_s.run();
    forever @(posedge clk);
    
    $finish;
  end 

endmodule // tb_axi_lite_mgr

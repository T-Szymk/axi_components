/*******************************************************************************
-- Title      : AXI4 Mgr Testbench
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_dla_axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-22
-- Design     : tb_dla_axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Testbench for generic AXI4 manager.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-22  1.0      TZS     Created
*******************************************************************************/

`include "../ips/headsail-common-ips/ips/axi/include/axi/assign.svh"
//`include "../ips/headsail-common-ips/ips/axi/src/axi_test.sv"

module tb_dla_axi4_mgr
import axi_test::*;
#(
  parameter CLK_PERIOD_NS  = 10,
  parameter AXI_ADDR_WIDTH = 32,
  parameter AXI_DATA_WIDTH = 64,
  parameter AXI_ID_WIDTH   =  9,
  parameter AXI_USER_WIDTH =  5
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
  ) pp_if ();
  
  axi_rand_slave #(
    .AW ( AXI_ADDR_WIDTH ), 
    .DW ( AXI_DATA_WIDTH ),
    .IW ( AXI_ID_WIDTH   ),
    .UW ( AXI_USER_WIDTH ),
    .TT ( 500ps          )
  ) tb_axi4_sub = new(axi_s_tb_if);

  `AXI_ASSIGN( axi_s_tb_if, pp_if )

  assign pp_data_s     = 'hDEADBEEF0B501E7E;
  assign axi_wr_addr_s = 'h5000;
  assign axi_rd_addr_s = 'h6000;

  initial begin 
    forever begin
      #(CLK_PERIOD_NS/2) clk = 1'b0;
      #(CLK_PERIOD_NS/2) clk = 1'b1;
    end 
  end

  dla_axi4_m #(
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
    tb_axi4_sub.reset();
    #(2*CLK_PERIOD_NS);
    req_s = 2'b11; // start read and write trans
    tb_axi4_sub.run();
    forever @(posedge clk);
    
    $finish;
  end 

endmodule // tb_dla_axi4_mgr

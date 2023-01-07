/*******************************************************************************
-- Title      : AXI Components - FPGA FIFO Testbench
-- Project    : AXI Components
********************************************************************************
-- File       : tb_fpga_fifo_v3.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-01-07
-- Design     : tb_fpga_fifo_v3
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Testbench for FPGA adaptation of PULP fifo_v3.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2023-01-07  1.0      TZS     Created
*******************************************************************************/

module tb_fpga_fifo_v3 #(
  parameter time CLK_PERIOD_NS        = 10,
  parameter int unsigned DATA_WIDTH   = 32,   // default data width if the fifo is of type logic
  parameter int unsigned DEPTH        = 16    // depth can be arbitrary from 0 to 2**32
);

  timeunit 1ns/1ps;

  localparam integer unsigned AddrDepth   = (DEPTH > 1) ? $clog2(DEPTH) : 1;

  logic clk, rstn;
  logic flush_s = '0;
  logic testmode_s = '0;
  logic full_s, empty_s, push_s, pop_s;

  logic [DATA_WIDTH-1:0] data_in_s;
  logic [   AddrDepth:0] usage_s;  
  logic [DATA_WIDTH-1:0] data_out_s;

  logic [DATA_WIDTH-1:0] test_data_s [$];

  fpga_fifo_v3 #(       
    .DATA_WIDTH   ( DATA_WIDTH   ),       
    .DEPTH        ( DEPTH        )  
  ) i_dut (
    .clk_i      ( clk        ),  
    .rst_ni     ( rstn       ),   
    .flush_i    ( flush_s    ),    
    .testmode_i ( testmode_s ),       
    .full_o     ( full_s     ),   
    .empty_o    ( empty_s    ),    
    .usage_o    ( usage_s    ), 
    .data_i     ( data_in_s  ),   
    .push_i     ( push_s     ),  
    .data_o     ( data_out_s ),   
    .pop_i      ( pop_s      )  
  );

  initial begin : clock_generation /*******************************************/
    forever begin
      clk = 1'b0;
      #(CLK_PERIOD_NS/2);
      clk = 1'b1;
      #(CLK_PERIOD_NS/2);
    end
  end /************************************************************************/

  initial begin : test_logic /*************************************************/

    rstn       = '0;
    flush_s    = '0;
    testmode_s = '0;    
    push_s     = '0;       
    pop_s      = '0;     
    data_in_s  = '0;

    test_data_s = {
      'hA0,
      'hA1,
      'hA2,
      'hA3,
      'hA4,
      'hA5,
      'hA6,
      'hA7,
      'hA8,
      'hA9,
      'hAA,
      'hAB,
      'hAC,
      'hAD,
      'hAE,
      'hAF
    };

    @(negedge clk);
    @(negedge clk);

    rstn = 1'b1;

    @(negedge clk);
    @(negedge clk);
    
    // write until full
    repeat (test_data_s.size()) begin 
      data_in_s = test_data_s.pop_front();
      push_s    = 1'b1;
      @(negedge clk);
    end

    push_s = 1'b0;

    @(negedge clk);
    // read until empty
    repeat (usage_s) begin
      pop_s = 1'b1;
      test_data_s.push_back(data_out_s);
      @(negedge clk);
    end

    pop_s = 1'b0;

    @(negedge clk);
    @(negedge clk);

    // write once
    data_in_s = test_data_s.pop_front();
    push_s    = 1'b1;
    @(negedge clk);

    // write and read same time until data structure is empty
    repeat (test_data_s.size()) begin 
      data_in_s = test_data_s.pop_front();
      push_s    = 1'b1;
      pop_s     = 1'b1;
      test_data_s.push_back(data_out_s);
      @(negedge clk);
    end

    push_s = 1'b0;

    @(negedge clk);
    pop_s     = 1'b0;
    test_data_s.push_back(data_out_s);
    @(negedge clk);

    $finish;

  end /************************************************************************/

endmodule // tb_fpga_fifo_v3

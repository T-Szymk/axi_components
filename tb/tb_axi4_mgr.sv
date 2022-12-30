/*******************************************************************************
-- Title      : AXI4 Mgr Testbench
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-29
-- Design     : tb_axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Testbench for generic AXI4 manager.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-29  1.0      TZS     Created
*******************************************************************************/

module tb_axi4_mgr #(
  parameter time     CLK_PERIOD_NS   =   10,
  parameter unsigned AXI_ADDR_WIDTH  =   32,
  parameter unsigned AXI_DATA_WIDTH  =   64,
  parameter unsigned AXI_ID_WIDTH    =    9,
  parameter unsigned AXI_USER_WIDTH  =    5,
  parameter unsigned FIFO_DEPTH      = 1024,
  parameter unsigned SIM_TIME        =    1ms
);

  timeunit 1ns/1ps;

  localparam int AXISize        = (AXI_DATA_WIDTH/8);
  localparam int DataCountWidth = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1; 

  logic       clk;
  logic       rstn, dut_rstn;

  logic       wr_fifo_pop_s,   rd_fifo_pop_s;
  logic       wr_fifo_push_s,  rd_fifo_push_s;
  logic       wr_fifo_full_s,  rd_fifo_full_s;
  logic       wr_fifo_empty_s, rd_fifo_empty_s;  

  logic [1:0] req_s;
  logic [1:0] rsp_s;

  logic [DataCountWidth-1:0] wr_data_count_s;
  logic [DataCountWidth-1:0] rd_data_count_s;
  logic [             2-1:0] dut_wr_err_s, dut_rd_err_s;
  logic [AXI_DATA_WIDTH-1:0] dut_data_s;
  logic [AXI_DATA_WIDTH-1:0] axi_wr_data_s, axi_rd_data_s;
  logic [AXI_ADDR_WIDTH-1:0] axi_wr_addr_s, axi_rd_addr_s;

  int unsigned fifo_write_count;

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

  /* Other Assignments */

  assign axi_wr_addr_s = 'h5000;
  assign axi_rd_addr_s = 'h6000;

  initial begin
    forever begin
      clk = 1'b0;
      #(CLK_PERIOD_NS/2);
      clk = 1'b1;
      #(CLK_PERIOD_NS/2);
    end
  end

  /* COMPONENT AND DUT INSTANTIATIONS */

  // Write data is read from this FIFO
  fifo_v3 #(
    .FALL_THROUGH ( 0                          ),                         
    .DATA_WIDTH   ( AXI_DATA_WIDTH             ),                       
    .DEPTH        ( FIFO_DEPTH                 ),                  
    .dtype        ( logic [AXI_DATA_WIDTH-1:0] )
  ) i_wr_fifo (
    .clk_i      ( clk             ),      
    .rst_ni     ( rstn            ),       
    .flush_i    ( '0              ),        
    .testmode_i ( '0              ),           
    .full_o     ( wr_fifo_full_s  ),       
    .empty_o    ( wr_fifo_empty_s ),        
    .usage_o    ( wr_data_count_s ),        
    .data_i     ( dut_data_s      ),       
    .push_i     ( wr_fifo_push_s  ),       
    .data_o     ( axi_wr_data_s   ),       
    .pop_i      ( wr_fifo_pop_s   )     
  );
  
  // Read data is written to the following FIFO
  fifo_v3 #(
    .FALL_THROUGH ( 0                          ),                         
    .DATA_WIDTH   ( AXI_DATA_WIDTH             ),                       
    .DEPTH        ( FIFO_DEPTH                 ),                  
    .dtype        ( logic [AXI_DATA_WIDTH-1:0] )                      
  ) i_rd_fifo (
    .clk_i      ( clk             ),                  
    .rst_ni     ( rstn            ),                   
    .flush_i    ( '0              ),                    
    .testmode_i ( '0              ),                       
    .full_o     ( rd_fifo_full_s  ),       
    .empty_o    ( rd_fifo_empty_s ),        
    .usage_o    ( /* NC */        ),                    
    .data_i     ( axi_rd_data_s   ),       
    .push_i     ( rd_fifo_push_s  ),       
    .data_o     ( /* NC */        ),                   
    .pop_i      ( rd_fifo_pop_s   )     
  );

  axi4_mgr #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH  ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH  ),
    .AXI_XSIZE        ( AXISize         ),         
    .DATA_COUNT_WIDTH ( DataCountWidth  )           
  ) i_dut (
    .clk_i           ( clk              ),      
    .rstn_i          ( dut_rstn         ),       
    .req_i           ( req_s            ),      
    .axi_wr_addr_i   ( axi_wr_addr_s    ),              
    .axi_rd_addr_i   ( axi_rd_addr_s    ),
    .wr_fifo_gnt_i   ( ~wr_fifo_empty_s ),
    .rd_fifo_req_i   ( ~rd_fifo_full_s  ),              
    .wr_fifo_data_i  ( axi_wr_data_s    ),           
    .wr_data_count_i ( wr_data_count_s  ),                
    .rd_data_count_i ( rd_data_count_s  ),                
    .rsp_o           ( rsp_s            ),      
    .wr_err_o        ( dut_wr_err_s     ),         
    .rd_err_o        ( dut_rd_err_s     ),
    .wr_fifo_req_o   ( wr_fifo_pop_s    ),
    .rd_fifo_gnt_o   ( rd_fifo_push_s   ),         
    .rd_fifo_data_o  ( axi_rd_data_s    ),           
    .axi_mgr_if      ( dut_if           )           
  );

  task automatic fill_FIFO ( /*************************************************/
    ref    logic                      clk,
    ref    logic                      full,
    ref    logic [DataCountWidth-1:0] count,
    input  integer unsigned           count_max_i,
    ref    logic                      push_o,
    ref    logic [AXI_DATA_WIDTH-1:0] data_o    
  );

    logic [AXI_DATA_WIDTH-1:0] tmp_data = '0;

    $display("%0t: Filling write FIFO", $time);

    push_o   = 1'b0;
    data_o   = tmp_data;

    @(negedge clk);
    #(500ps);

    while (count != count_max_i && !full) begin 
            
      data_o   = tmp_data;
      tmp_data = tmp_data + 1;
      push_o   = 1'b1;
      @(negedge clk);
      #(500ps);      

    end

    push_o   = 1'b0;

    $display("%0t: Write FIFO filled with %d entries", $time, tmp_data);

    @(negedge clk);

  endtask /********************************************************************/

  task automatic complete_transfer ( /*****************************************/
    ref logic       clk,
    ref logic [1:0] req,
    ref logic [1:0] rsp
  );
    
    @(negedge clk);
    $display("%0t: Initiating write request.", $time);
    req = 2'b01;
    @(negedge clk);
    req = 2'b00;

    while(rsp[0] == 1'b0) begin 
      @(negedge clk);
    end

    $display("%0t: Write request completed.", $time);

    @(negedge clk);

  endtask /********************************************************************/

  initial begin /**************************************************************/

    $timeformat(-9,0,"ns");

    rstn            = 1'b0;
    dut_rstn        = 1'b0;
    req_s           = 2'b00;  
    rd_fifo_pop_s   = 1'b0; 
    rd_data_count_s = '0; 
    dut_data_s      = '0;
    wr_fifo_push_s  = '0;

    fifo_write_count = 1;
    
    tb_axi4_sub.reset();

    #(2*CLK_PERIOD_NS) rstn = 1'b1;
    #(2*CLK_PERIOD_NS) dut_rstn = 1'b1;
    
    fork 
      
      begin 
        tb_axi4_sub.run();
      end 

      begin
        while (fifo_write_count < FIFO_DEPTH) begin
    
          fill_FIFO(clk, wr_fifo_full_s, wr_data_count_s, fifo_write_count, wr_fifo_push_s, dut_data_s);
          complete_transfer(clk, req_s, rsp_s);
      
          fifo_write_count = fifo_write_count + 4;
    
        end
      end

    join

  end /************************************************************************/

  initial begin /**************************************************************/
    
    #(SIM_TIME);
    $display("%10t: Simulation Complete.", $time);
    $finish;

  end /************************************************************************/

endmodule // tb_axi4_mgr

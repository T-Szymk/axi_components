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

  logic                        enable_s;
  logic                        rd_fifo_pop_s;
  logic                        wr_fifo_push_s;
  logic [               2-1:0] req_s;
  logic [ AXIL_ADDR_WIDTH-1:0] axi_wr_addr_s;
  logic [ AXIL_ADDR_WIDTH-1:0] axi_rd_addr_s;
  logic [  DataCountWidth-1:0] rd_data_count_s;
  logic [ AXI4_DATA_WIDTH-1:0] wr_fifo_data_s;
  logic [ AXI4_DATA_WIDTH-1:0] rd_fifo_data_s;
  logic [  DataCountWidth-1:0] wr_fifo_usage_s;
  logic [  DataCountWidth-1:0] rd_fifo_usage_s;
  logic                        wr_fifo_full_s;  
  logic                        rd_fifo_full_s;
  logic                        wr_fifo_empty_s; 
  logic                        rd_fifo_empty_s;
  logic [               2-1:0] rsp_s;     // bit 1: rd, bit 0: wr
  logic [               2-1:0] wr_err_s;  // bresp
  logic [               2-1:0] rd_err_s;  // rresp

  logic [ AXIL_DATA_WIDTH-1:0] read_data_s;

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

  axi_lite_registers #(
    .AXI4_ADDR_WIDTH  ( AXI4_ADDR_WIDTH  ),           
    .AXI4_DATA_WIDTH  ( AXI4_DATA_WIDTH  ),           
    .AXIL_ADDR_WIDTH  ( AXIL_ADDR_WIDTH  ),           
    .AXIL_DATA_WIDTH  ( AXIL_DATA_WIDTH  ),           
    .AXI_ID_WIDTH     ( AXI_ID_WIDTH     ),        
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH   ),          
    .BASE_ADDR        ( 'h0              ),     
    .DATA_COUNT_WIDTH ( DataCountWidth   )           
  ) i_dut (
    .clk_i           ( clk                 ),       
    .rstn_i          ( rstn                ),        
    .aw_addr_i       ( axil_sub_aw_addr_s  ),           
    .aw_prot_i       ( axil_sub_aw_prot_s  ),           
    .aw_valid_i      ( axil_sub_aw_valid_s ),            
    .aw_ready_o      ( axil_sub_aw_ready_s ),            
    .w_data_i        ( axil_sub_w_data_s   ),          
    .w_strb_i        ( axil_sub_w_strb_s   ),          
    .w_valid_i       ( axil_sub_w_valid_s  ),           
    .w_ready_o       ( axil_sub_w_ready_s  ),           
    .b_resp_o        ( axil_sub_b_resp_s   ),          
    .b_valid_o       ( axil_sub_b_valid_s  ),           
    .b_ready_i       ( axil_sub_b_ready_s  ),           
    .ar_addr_i       ( axil_sub_ar_addr_s  ),           
    .ar_prot_i       ( axil_sub_ar_prot_s  ),           
    .ar_valid_i      ( axil_sub_ar_valid_s ),            
    .ar_ready_o      ( axil_sub_ar_ready_s ),            
    .r_data_o        ( axil_sub_r_data_s   ),          
    .r_resp_o        ( axil_sub_r_resp_s   ),          
    .r_valid_o       ( axil_sub_r_valid_s  ),           
    .r_ready_i       ( axil_sub_r_ready_s  ),
    .enable_o        ( enable_s            ),           
    .rd_fifo_pop_o   ( rd_fifo_pop_s       ),               
    .wr_fifo_push_o  ( wr_fifo_push_s      ),                
    .req_o           ( req_s               ),       
    .axi_wr_addr_o   ( axi_wr_addr_s       ),               
    .axi_rd_addr_o   ( axi_rd_addr_s       ),               
    .rd_data_count_o ( rd_data_count_s     ),                 
    .wr_fifo_data_o  ( wr_fifo_data_s      ),                
    .rd_fifo_data_i  ( rd_fifo_data_s      ),                
    .wr_fifo_usage_i ( wr_fifo_usage_s     ),                 
    .rd_fifo_usage_i ( rd_fifo_usage_s     ),                 
    .wr_fifo_full_i  ( wr_fifo_full_s      ),                
    .rd_fifo_full_i  ( rd_fifo_full_s      ),                
    .wr_fifo_empty_i ( wr_fifo_empty_s     ),                 
    .rd_fifo_empty_i ( rd_fifo_empty_s     ),                 
    .rsp_i           ( rsp_s               ),       
    .wr_err_i        ( wr_err_s            ),          
    .rd_err_i        ( rd_err_s            )          
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
    
    rstn                = '0;
    
    rd_fifo_data_s      = '0;                 
    wr_fifo_usage_s     = '0;                  
    rd_fifo_usage_s     = '0;                  
    wr_fifo_full_s      = '0;                 
    rd_fifo_full_s      = '0;                 
    wr_fifo_empty_s     = '0;                  
    rd_fifo_empty_s     = '0;                  
    rsp_s               = '0;        
    wr_err_s            = '0;           
    rd_err_s            = '0; 

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
    read_address( WR_FIFO_STATUS, "WR_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Setting wr_fifo_full_s...", $time);
    wr_fifo_full_s = 1'b1;

    read_address( WR_FIFO_STATUS, "WR_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Setting wr_fifo_empty_s...", $time);
    
    wr_fifo_empty_s = 1'b1;
    
    read_address( WR_FIFO_STATUS, "WR_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Clearing wr_fifo_full_s and wr_fifo_empty_s...", $time);
    wr_fifo_full_s  = '0;
    wr_fifo_empty_s = '0;
    
    // test wr fifo usage
    read_address( WR_FIFO_USAGE, "WR_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Setting wr_fifo_usage_s to all ones...", $time);
    wr_fifo_usage_s = '1;
    
    read_address( WR_FIFO_USAGE, "WR_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Clearing wr_fifo_usage_s...", $time);
    wr_fifo_usage_s = '0;
    
    read_address( WR_FIFO_USAGE, "WR_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);
    
    // test writing data to FIFO
    write_address( WR_FIFO_DATA_IN_L, "WR_FIFO_DATA_IN_L", 'hBEEF, clk, axi_write_signals_s );
    write_address( WR_FIFO_DATA_IN_H, "WR_FIFO_DATA_IN_L", 'hDEAD, clk, axi_write_signals_s );

    $display("%10t: read value of 0x%0h from wr_fifo_data_s", $time, wr_fifo_data_s);

    repeat (4)
      write_address( WR_FIFO_PUSH, "WR_FIFO_PUSH", '1, clk, axi_write_signals_s );
    
    // set wr address
    write_address( AXI_WR_ADDR, "AXI_WR_ADDR", 'hDEADBEEF, clk, axi_write_signals_s);
    read_address( AXI_WR_ADDR, "AXI_WR_ADDR", read_data_s, clk, axi_read_signals_s);
    
    // init xfer
    write_address( REQUEST, "REQUEST", '1, clk, axi_write_signals_s);
    write_address( REQUEST, "REQUEST", '0, clk, axi_write_signals_s);
   
    // set rsp for a cycle
    @(posedge clk);
    $display("\n%10t: Setting rsp to all ones...", $time);
    rsp_s = '1;
    @(posedge clk);
    @(negedge clk); 
    $display("%10t: Clearing rsp...expecting bit1 and bit2 to latch...", $time);
    rsp_s = '0;
    @(negedge clk); 
    
    read_address( RESPONSE, "RESPONSE", read_data_s, clk, axi_read_signals_s);
    write_address( RESPONSE, "RESPONSE", 'h1, clk, axi_write_signals_s);
    read_address( RESPONSE, "RESPONSE", read_data_s, clk, axi_read_signals_s);

    // test rd fifo status
    read_address( RD_FIFO_STATUS, "RD_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Setting rd_fifo_full_s...", $time);
    rd_fifo_full_s = 1'b1;

    read_address( RD_FIFO_STATUS, "RD_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);

    $display("\n%10t: Setting rd_fifo_empty_s...", $time);
    
    rd_fifo_empty_s = 1'b1;
    
    read_address( RD_FIFO_STATUS, "RD_FIFO_STATUS", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Clearing rd_fifo_full_s and rd_fifo_empty_s...", $time);
    rd_fifo_full_s  = '0;
    rd_fifo_empty_s = '0;

    // test rd fifo usage
    read_address( RD_FIFO_USAGE, "RD_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Setting rd_fifo_usage_s to all ones...", $time);
    rd_fifo_usage_s = '1;
    
    read_address( RD_FIFO_USAGE, "RD_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Clearing rd_fifo_usage_s...", $time);
    rd_fifo_usage_s = '0;

    read_address( RD_FIFO_USAGE, "RD_FIFO_USAGE", read_data_s, clk, axi_read_signals_s);

    // test reading data from FIFO
    read_address( RD_FIFO_DATA_OUT_H, "RD_FIFO_DATA_OUT_H", read_data_s, clk, axi_read_signals_s);
    read_address( RD_FIFO_DATA_OUT_L, "RD_FIFO_DATA_OUT_L", read_data_s, clk, axi_read_signals_s);
    
    rd_fifo_data_s = 'hDEADBEEFABBADABA;
    $display("\n%10t: Setting rd_fifo_data_s to pattern: 0x%0h", $time, rd_fifo_data_s);

    read_address( RD_FIFO_DATA_OUT_H, "RD_FIFO_DATA_OUT_H", read_data_s, clk, axi_read_signals_s);
    read_address( RD_FIFO_DATA_OUT_L, "RD_FIFO_DATA_OUT_L", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: clearing rd_fifo_data_s...", $time);
    rd_fifo_data_s = '0;

    repeat (4)
      write_address( RD_FIFO_POP, "RD_FIFO_POP", '1, clk, axi_write_signals_s );

    // set rd address
    write_address( AXI_RD_ADDR, "AXI_RD_ADDR", 'hDEADBEEF, clk, axi_write_signals_s);
    read_address( AXI_RD_ADDR, "AXI_RD_ADDR", read_data_s, clk, axi_read_signals_s);

    // test error generation
    read_address( WR_ERR, "WR_ERR", read_data_s, clk, axi_read_signals_s);
    read_address( RD_ERR, "RD_ERR", read_data_s, clk, axi_read_signals_s);
    
    $display("\n%10t: Setting rd_err and wr_err to all 1's ...", $time);
    wr_err_s = '1;
    rd_err_s = '1;

    read_address( WR_ERR, "WR_ERR", read_data_s, clk, axi_read_signals_s);
    read_address( RD_ERR, "RD_ERR", read_data_s, clk, axi_read_signals_s);

    $display("\n%10t: Clearing rd_err and wr_err...", $time);
    wr_err_s = '0;
    rd_err_s = '0;

    read_address( WR_ERR, "WR_ERR", read_data_s, clk, axi_read_signals_s);
    read_address( RD_ERR, "RD_ERR", read_data_s, clk, axi_read_signals_s);

    // disable subsystem
    write_address( ENABLE, "ENABLE", '0, clk, axi_write_signals_s);
    
    repeat (10)
      @(posedge clk);

    $finish;     

  end /************************************************************************/

/* SUBROUTINES ****************************************************************/

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

endmodule // tb_axi_lite_registers

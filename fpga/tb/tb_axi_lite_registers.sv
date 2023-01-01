/*******************************************************************************
-- Title      : Testbench for AXI-Lite register interface
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_axi_lite_registers.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2023-01-01
-- Design     : tb_axi_lite_registers
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Testbench for the AXI-Lite registers used to control the 
--              AXI4 Manager interface.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2023-01-01  1.0      TZS     Created
*******************************************************************************/

module tb_axi_lite_registers #(
  parameter time     CLK_PERIOD_NS   =   10,
  parameter unsigned AXI4_ADDR_WIDTH  =  32,
  parameter unsigned AXI4_DATA_WIDTH  =  64,
  parameter unsigned AXIL_ADDR_WIDTH  =  32,
  parameter unsigned AXIL_DATA_WIDTH  =  32,
  parameter unsigned AXI_ID_WIDTH    =    4,
  parameter unsigned AXI_USER_WIDTH  =    5,
  parameter unsigned FIFO_DEPTH      = 1024,
  parameter unsigned SIM_TIME        =    1ms
);
  
  timeunit 1ns/1ps;

  /* LOCAL PARAMS/VARS/CONST/INTF DECLARATIONS ********************************/

  localparam integer unsigned AXISize        = (AXIL_DATA_WIDTH/8);
  localparam integer unsigned DataCountWidth = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1;
  localparam integer unsigned TestDataCount  = 420;

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
  logic [DATA_COUNT_WIDTH-1:0] rd_data_count_s;
  logic [ AXI4_DATA_WIDTH-1:0] wr_fifo_data_s;
  logic [ AXI4_DATA_WIDTH-1:0] rd_fifo_data_s;
  logic [DATA_COUNT_WIDTH-1:0] wr_fifo_usage_s;
  logic [DATA_COUNT_WIDTH-1:0] rd_fifo_usage_s;
  logic                        wr_fifo_full_s;  
  logic                        rd_fifo_full_s;
  logic                        wr_fifo_empty_s; 
  logic                        rd_fifo_empty_s;
  logic [               2-1:0] rsp_s;     // bit 1: rd, bit 0: wr
  logic [               2-1:0] wr_err_s;  // bresp
  logic [               2-1:0] rd_err_s;  // rresp

  logic [ AXIL_DATA_WIDTH-1:0] read_data_s,

  /* ASSIGNMENTS **************************************************************/
                                                                                                                                  

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

    axil_sub_aw_addr_s  = '0;       
    axil_sub_aw_prot_s  = '0;       
    axil_sub_aw_valid_s = '0;        
    axil_sub_w_data_s   = '0;      
    axil_sub_w_strb_s   = '0;      
    axil_sub_w_valid_s  = '0;       
    axil_sub_b_ready_s  = '0;       
    axil_sub_ar_addr_s  = '0;       
    axil_sub_ar_prot_s  = '0;       
    axil_sub_ar_valid_s = '0;        
    axil_sub_r_ready_s  = '0;       

    write_address( 'hC, 
                   'hDEADBEEF, 
                   clk, 
                   axil_sub_aw_addr_s,
                   axil_sub_aw_valid_s,
                   axil_sub_aw_ready_s,
                   axil_sub_w_data_s,
                   axil_sub_w_strb_s,
                   axil_sub_w_valid_s,
                   axil_sub_w_ready_s,
                   axil_sub_b_valid_s,
                   axil_sub_b_ready_s
                 );    
    read_address( 'hC,
                  read_data_s,
                  clk,
                  axil_sub_ar_addr_s,
                  axil_sub_ar_valid_s,
                  axil_sub_ar_ready_s,
                  axil_sub_r_data_s,
                  axil_sub_r_valid_s,
                  axil_sub_r_ready_s,
    );

    $finish;     

  end /************************************************************************/

/* SUBROUTINES ****************************************************************/

  task automatic write_address(
    input logic [ AXIL_ADDR_WIDTH-1:0] addr,
    input logic [ AXIL_DATA_WIDTH-1:0] data,

    ref   logic                        clk,

    ref   logic [ AXIL_ADDR_WIDTH-1:0] axi_aw_addr_o,
    ref   logic                        axi_aw_valid_o,
    ref   logic                        axi_aw_ready_i,
  
    ref   logic [ AXIL_DATA_WIDTH-1:0] axi_w_data_o,
    ref   logic [   AXILSizeBytes-1:0] axi_w_strb_o,
    ref   logic                        axi_w_valid_o,
    ref   logic                        axi_w_ready_i,
  
    ref   logic                        axi_b_valid_i,
    ref   logic                        axi_b_ready_o
  );
  
    axi_aw_addr_o  = '0;   
    axi_aw_valid_o = '0;     
    axi_w_data_o   = '0;   
    axi_w_strb_o   = '0;   
    axi_w_valid_o  = '0;    
    axi_b_valid_o  = '0; 
  
    @(negedge clk);
  
    axi_aw_valid_o = 1'b1;
    axi_aw_addr_o  = addr;
    
    while (~axi_aw_ready_i) begin
      @(negedge clk); 
    end
  
    axi_aw_valid_o = 1'b0;
    axi_aw_addr_o  =   '0;
    axi_w_data_o   = data;   
    axi_w_strb_o   =  'hF;   
    axi_w_valid_o  = 1'b1;
    
    while (~axi_w_ready_i) begin
      @(negedge clk); 
    end 
  
    axi_w_data_o   =   '0;   
    axi_w_strb_o   =   '0;   
    axi_w_valid_o  =   '0;
    axi_b_ready_o  = 1'b1;
  
    while (~axi_b_valid_i) begin
      @(negedge clk); 
    end 
    
    axi_b_ready_o  = 1'b0;
  
    @(negedge clk);  
    $display("%0t: AXI-Lite write of DATA: 0x%h to ADDR: 0x%h complete.", $time, data, addr);
  
  endtask

  task automatic read_address(
    input  logic [ AXIL_ADDR_WIDTH-1:0] addr,
    output logic [ AXIL_DATA_WIDTH-1:0] data,

    ref    logic                        clk,
    
    ref    logic [ AXIL_ADDR_WIDTH-1:0] axi_ar_addr_o,
    ref    logic                        axi_ar_valid_o,
    ref    logic                        axi_ar_ready_i,
  
    ref    logic [ AXIL_DATA_WIDTH-1:0] axi_r_data_i,
    ref    logic                        axi_r_valid_i,
    ref    logic                        axi_r_ready_o
  );
  
    axi_ar_addr_o  = '0;    
    axi_ar_valid_o = '0;  
    axi_i_ready_o  = '0;        
  
    @(negedge clk);
  
    axi_ar_valid_o = 1'b1;
    axi_ar_addr_o  = addr;
    
    while (~axi_ar_ready_i) begin
      @(negedge clk); 
    end
  
    axi_ar_valid_o = 1'b0;
    axi_ar_addr_o  =   '0;
    axi_r_ready_o  = 1'b1; 
    
    while (~axi_r_valid_i) begin
      @(negedge clk); 
    end 
  
    data          = axi_r_data_i;   
    axi_r_ready_o = '0;
  
    @(negedge clk);  
    $display("%0t: AXI-Lite read of DATA: 0x%h from ADDR: 0x%h complete.", $time, data, addr);
  
  endtask

endmodule // tb_axi_lite_registers

/*******************************************************************************
-- Title      : Testbench for AXI4 Mgr FPGA Implementation
-- Project    : T-Szymk
********************************************************************************
-- File       : tb_fpga_axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-30
-- Design     : tb_fpga_axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Testbench for the FPGA implementation of AXI4 Manager
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-30  1.0      TZS     Created
*******************************************************************************/

module tb_fpga_axi4_mgr #(
  parameter time     CLK_PERIOD_NS   =   10,
  parameter unsigned AXI_ADDR_WIDTH  =   32,
  parameter unsigned AXI_DATA_WIDTH  =   64,
  parameter unsigned AXI_ID_WIDTH    =    4,
  parameter unsigned AXI_USER_WIDTH  =    5,
  parameter unsigned FIFO_DEPTH      = 1024,
  parameter unsigned SIM_TIME        =    1ms
);
  
  timeunit 1ns/1ps;

  /* LOCAL PARAMS/VARS/CONST/INTF DECLARATIONS ********************************/

  localparam integer unsigned AXISize        = (AXI_DATA_WIDTH/8);
  localparam integer unsigned DataCountWidth = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1;
  localparam integer unsigned TestDataCount  = 420;

  axi4_bus_if #(
    .ADDR_WIDTH ( AXI_ADDR_WIDTH ),        
    .DATA_WIDTH ( AXI_DATA_WIDTH ),        
    .ID_WIDTH   ( AXI_ID_WIDTH   ),      
    .USER_WIDTH ( AXI_USER_WIDTH )        
  ) axi4_if ();

  logic clk;
  logic rstn;
  
  logic rd_fifo_pop_s, wr_fifo_push_s;
  logic wr_fifo_full_s, rd_fifo_full_s;
  logic wr_fifo_empty_s, rd_fifo_empty_s;

  logic [             2-1:0] req_s, rsp_s;
  logic [DataCountWidth-1:0] rd_data_count_s;
  logic [DataCountWidth-1:0] wr_fifo_usage_s, rd_fifo_usage_s;
  logic [AXI_ADDR_WIDTH-1:0] axi_wr_addr_s, axi_rd_addr_s;
  logic [             2-1:0] dut_wr_err_s, dut_rd_err_s;
  logic [AXI_DATA_WIDTH-1:0] wr_fifo_data_in_s, rd_fifo_data_out_s;
  
  // AXI4 manager signals                                                     
  // AW                                                                  
  logic [  AXI_ID_WIDTH-1:0] m_axi_aw_id_s;
  logic [AXI_ADDR_WIDTH-1:0] m_axi_aw_addr_s;
  logic [             8-1:0] m_axi_aw_len_s;
  logic [             3-1:0] m_axi_aw_size_s;
  logic [             2-1:0] m_axi_aw_burst_s;
  logic                      m_axi_aw_lock_s;
  logic [             4-1:0] m_axi_aw_cache_s;
  logic [             3-1:0] m_axi_aw_prot_s;
  logic [             4-1:0] m_axi_aw_qos_s;
  logic [             4-1:0] m_axi_aw_region_s;
  logic [             4-1:0] m_axi_aw_atop_s;
  logic [AXI_USER_WIDTH-1:0] m_axi_aw_user_s;
  logic                      m_axi_aw_valid_s;
  logic                      m_axi_aw_ready_s;                                             
  logic [AXI_DATA_WIDTH-1:0] m_axi_w_data_s;
  logic [       AXISize-1:0] m_axi_w_strb_s;
  logic                      m_axi_w_last_s;
  logic [AXI_USER_WIDTH-1:0] m_axi_w_user_s;
  logic                      m_axi_w_valid_s;
  logic                      m_axi_w_ready_s;    
  logic [  AXI_ID_WIDTH-1:0] m_axi_b_id_s;
  logic [             2-1:0] m_axi_b_resp_s;
  logic [AXI_USER_WIDTH-1:0] m_axi_b_user_s;
  logic                      m_axi_b_valid_s;
  logic                      m_axi_b_ready_s;                                        
  logic [  AXI_ID_WIDTH-1:0] m_axi_ar_id_s;
  logic [AXI_ADDR_WIDTH-1:0] m_axi_ar_addr_s;
  logic [             8-1:0] m_axi_ar_len_s;
  logic [             3-1:0] m_axi_ar_size_s;
  logic [             2-1:0] m_axi_ar_burst_s;
  logic                      m_axi_ar_lock_s;
  logic [             4-1:0] m_axi_ar_cache_s;
  logic [             3-1:0] m_axi_ar_prot_s;
  logic [             4-1:0] m_axi_ar_qos_s;
  logic [             4-1:0] m_axi_ar_region_s;
  logic [AXI_USER_WIDTH-1:0] m_axi_ar_user_s;
  logic                      m_axi_ar_valid_s;
  logic                      m_axi_ar_ready_s;
  logic [  AXI_ID_WIDTH-1:0] m_axi_r_id_s;
  logic [AXI_DATA_WIDTH-1:0] m_axi_r_data_s;
  logic [             2-1:0] m_axi_r_resp_s;
  logic                      m_axi_r_last_s;
  logic [AXI_USER_WIDTH-1:0] m_axi_r_user_s;
  logic                      m_axi_r_valid_s;
  logic                      m_axi_r_ready_s;  
  // AXI4 Sub signals
  logic [               3:0] s_axi_awid_s;
  logic [              31:0] s_axi_awaddr_s;
  logic [               7:0] s_axi_awlen_s;
  logic [               2:0] s_axi_awsize_s;
  logic [               1:0] s_axi_awburst_s;
  logic                      s_axi_awvalid_s;
  logic                      s_axi_awready_s; 
  logic [              63:0] s_axi_wdata_s;
  logic [               7:0] s_axi_wstrb_s;
  logic                      s_axi_wlast_s;
  logic                      s_axi_wvalid_s;
  logic                      s_axi_wready_s;
  logic [               3:0] s_axi_bid_s;
  logic [               1:0] s_axi_bresp_s;
  logic                      s_axi_bvalid_s;
  logic                      s_axi_bready_s;
  logic [              3 :0] s_axi_arid_s;
  logic [              31:0] s_axi_araddr_s;
  logic [              7 :0] s_axi_arlen_s;
  logic [              2 :0] s_axi_arsize_s;
  logic [              1 :0] s_axi_arburst_s;
  logic                      s_axi_arvalid_s;
  logic                      s_axi_arready_s;
  logic [              3 :0] s_axi_rid_s;
  logic [              63:0] s_axi_rdata_s;
  logic [              1 :0] s_axi_rresp_s;
  logic                      s_axi_rlast_s;
  logic                      s_axi_rvalid_s;
  logic                      s_axi_rready_s;

  logic [AXI_DATA_WIDTH-1:0] ref_queue [$];

  /* ASSIGNMENTS **************************************************************/

  assign s_axi_arid_s     = m_axi_ar_id_s;      
  assign s_axi_araddr_s   = m_axi_ar_addr_s;        
  assign s_axi_arlen_s    = m_axi_ar_len_s;       
  assign s_axi_arsize_s   = m_axi_ar_size_s;        
  assign s_axi_arburst_s  = m_axi_ar_burst_s;         
  assign s_axi_arvalid_s  = m_axi_ar_valid_s;         

  assign m_axi_ar_ready_s = s_axi_arready_s;

  assign s_axi_rready_s   = m_axi_r_ready_s;

  assign m_axi_r_id_s     = s_axi_rid_s;
  assign m_axi_r_data_s   = s_axi_rdata_s;
  assign m_axi_r_resp_s   = s_axi_rresp_s;
  assign m_axi_r_last_s   = s_axi_rlast_s;
  assign m_axi_r_valid_s  = s_axi_rvalid_s;

  assign s_axi_awid_s     = m_axi_aw_id_s;  
  assign s_axi_awaddr_s   = m_axi_aw_addr_s;    
  assign s_axi_awlen_s    = m_axi_aw_len_s;   
  assign s_axi_awsize_s   = m_axi_aw_size_s;    
  assign s_axi_awburst_s  = m_axi_aw_burst_s;     
  assign s_axi_awvalid_s  = m_axi_aw_valid_s;     

  assign m_axi_aw_ready_s = s_axi_awready_s;

  assign s_axi_wdata_s    = m_axi_w_data_s;    
  assign s_axi_wstrb_s    = m_axi_w_strb_s;    
  assign s_axi_wlast_s    = m_axi_w_last_s;    
  assign s_axi_wvalid_s   = m_axi_w_valid_s;     

  assign m_axi_w_ready_s  = s_axi_wready_s;

  assign s_axi_bready_s   = m_axi_b_ready_s;     

  assign m_axi_b_id_s     = s_axi_bid_s;
  assign m_axi_b_resp_s   = s_axi_bresp_s;
  assign m_axi_b_valid_s  = s_axi_bvalid_s;

  assign m_axi_b_user_s   = '0;
  assign m_axi_r_user_s   = '0;

  /* COMPONENT DECLARATION ****************************************************/

  fpga_axi4_mgr_wrapper # (       
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH ),            
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH ),            
    .AXI_ID_WIDTH     ( AXI_ID_WIDTH   ),          
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH ),            
    .FIFO_DEPTH       ( FIFO_DEPTH     ),        
    .AXI_XSIZE        ( AXISize        ),       
    .DATA_COUNT_WIDTH ( DataCountWidth )            
  ) i_dut (
    .clk_i           ( clk                ),      
    .rstn_i          ( rstn               ),       
    .rd_fifo_pop_i   ( rd_fifo_pop_s      ),              
    .wr_fifo_push_i  ( wr_fifo_push_s     ),               
    .req_i           ( req_s              ),      
    .axi_wr_addr_i   ( axi_wr_addr_s      ),              
    .axi_rd_addr_i   ( axi_rd_addr_s      ),              
    .rd_data_count_i ( rd_data_count_s    ),                
    .wr_fifo_data_i  ( wr_fifo_data_in_s  ),               
    .rd_fifo_data_o  ( rd_fifo_data_out_s ),               
    .wr_fifo_usage_o ( wr_fifo_usage_s    ),                
    .rd_fifo_usage_o ( rd_fifo_usage_s    ),                
    .wr_fifo_full_o  ( wr_fifo_full_s     ),               
    .rd_fifo_full_o  ( rd_fifo_full_s     ),               
    .wr_fifo_empty_o ( wr_fifo_empty_s    ),                
    .rd_fifo_empty_o ( rd_fifo_empty_s    ),                
    .rsp_o           ( rsp_s              ),      
    .wr_err_o        ( dut_wr_err_s       ),         
    .rd_err_o        ( dut_rd_err_s       ),         
    .aw_id_o         ( m_axi_aw_id_s      ),                           
    .aw_addr_o       ( m_axi_aw_addr_s    ),                             
    .aw_len_o        ( m_axi_aw_len_s     ),                            
    .aw_size_o       ( m_axi_aw_size_s    ),                             
    .aw_burst_o      ( m_axi_aw_burst_s   ),                              
    .aw_lock_o       ( m_axi_aw_lock_s    ),                             
    .aw_cache_o      ( m_axi_aw_cache_s   ),                              
    .aw_prot_o       ( m_axi_aw_prot_s    ),                             
    .aw_qos_o        ( m_axi_aw_qos_s     ),                            
    .aw_region_o     ( m_axi_aw_region_s  ),                               
    .aw_atop_o       ( m_axi_aw_atop_s    ),                             
    .aw_user_o       ( m_axi_aw_user_s    ),                             
    .aw_valid_o      ( m_axi_aw_valid_s   ),                              
    .aw_ready_i      ( m_axi_aw_ready_s   ),                              
    .w_data_o        ( m_axi_w_data_s     ),                            
    .w_strb_o        ( m_axi_w_strb_s     ),                            
    .w_last_o        ( m_axi_w_last_s     ),                            
    .w_user_o        ( m_axi_w_user_s     ),                            
    .w_valid_o       ( m_axi_w_valid_s    ),                             
    .w_ready_i       ( m_axi_w_ready_s    ),                             
    .b_id_i          ( m_axi_b_id_s       ),                          
    .b_resp_i        ( m_axi_b_resp_s     ),                            
    .b_user_i        ( m_axi_b_user_s     ),                            
    .b_valid_i       ( m_axi_b_valid_s    ),                             
    .b_ready_o       ( m_axi_b_ready_s    ),                             
    .ar_id_o         ( m_axi_ar_id_s      ),                           
    .ar_addr_o       ( m_axi_ar_addr_s    ),                             
    .ar_len_o        ( m_axi_ar_len_s     ),                            
    .ar_size_o       ( m_axi_ar_size_s    ),                             
    .ar_burst_o      ( m_axi_ar_burst_s   ),                              
    .ar_lock_o       ( m_axi_ar_lock_s    ),                             
    .ar_cache_o      ( m_axi_ar_cache_s   ),                              
    .ar_prot_o       ( m_axi_ar_prot_s    ),                             
    .ar_qos_o        ( m_axi_ar_qos_s     ),                            
    .ar_region_o     ( m_axi_ar_region_s  ),                               
    .ar_user_o       ( m_axi_ar_user_s    ),                             
    .ar_valid_o      ( m_axi_ar_valid_s   ),                              
    .ar_ready_i      ( m_axi_ar_ready_s   ),                              
    .r_id_i          ( m_axi_r_id_s       ),                          
    .r_data_i        ( m_axi_r_data_s     ),                            
    .r_resp_i        ( m_axi_r_resp_s     ),                            
    .r_last_i        ( m_axi_r_last_s     ),                            
    .r_user_i        ( m_axi_r_user_s     ),                            
    .r_valid_i       ( m_axi_r_valid_s    ),                             
    .r_ready_o       ( m_axi_r_ready_s    )                                     
  );
  
  // AXI4 BRAM 64b wide, 512 deep
  blk_mem_gen_0 i_test_axi_mem (
    .s_aclk        ( clk             ), // input  wire s_aclk
    .s_aresetn     ( rstn            ), // input  wire s_aresetn
    .s_axi_awid    ( s_axi_awid_s    ), // input  wire [3 : 0] s_axi_awid
    .s_axi_awaddr  ( s_axi_awaddr_s  ), // input  wire [31 : 0] s_axi_awaddr
    .s_axi_awlen   ( s_axi_awlen_s   ), // input  wire [7 : 0] s_axi_awlen
    .s_axi_awsize  ( s_axi_awsize_s  ), // input  wire [2 : 0] s_axi_awsize
    .s_axi_awburst ( s_axi_awburst_s ), // input  wire [1 : 0] s_axi_awburst
    .s_axi_awvalid ( s_axi_awvalid_s ), // input  wire s_axi_awvalid
    .s_axi_awready ( s_axi_awready_s ), // output wire s_axi_awready
    .s_axi_wdata   ( s_axi_wdata_s   ), // input  wire [63 : 0] s_axi_wdata
    .s_axi_wstrb   ( s_axi_wstrb_s   ), // input  wire [7 : 0] s_axi_wstrb
    .s_axi_wlast   ( s_axi_wlast_s   ), // input  wire s_axi_wlast
    .s_axi_wvalid  ( s_axi_wvalid_s  ), // input  wire s_axi_wvalid
    .s_axi_wready  ( s_axi_wready_s  ), // output wire s_axi_wready
    .s_axi_bid     ( s_axi_bid_s     ), // output wire [3 : 0] s_axi_bid
    .s_axi_bresp   ( s_axi_bresp_s   ), // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid  ( s_axi_bvalid_s  ), // output wire s_axi_bvalid
    .s_axi_bready  ( s_axi_bready_s  ), // input  wire s_axi_bready
    .s_axi_arid    ( s_axi_arid_s    ), // input  wire [3 : 0] s_axi_arid
    .s_axi_araddr  ( s_axi_araddr_s  ), // input  wire [31 : 0] s_axi_araddr
    .s_axi_arlen   ( s_axi_arlen_s   ), // input  wire [7 : 0] s_axi_arlen
    .s_axi_arsize  ( s_axi_arsize_s  ), // input  wire [2 : 0] s_axi_arsize
    .s_axi_arburst ( s_axi_arburst_s ), // input  wire [1 : 0] s_axi_arburst
    .s_axi_arvalid ( s_axi_arvalid_s ), // input  wire s_axi_arvalid
    .s_axi_arready ( s_axi_arready_s ), // output wire s_axi_arready
    .s_axi_rid     ( s_axi_rid_s     ), // output wire [3 : 0] s_axi_rid
    .s_axi_rdata   ( s_axi_rdata_s   ), // output wire [63 : 0] s_axi_rdata
    .s_axi_rresp   ( s_axi_rresp_s   ), // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast   ( s_axi_rlast_s   ), // output wire s_axi_rlast
    .s_axi_rvalid  ( s_axi_rvalid_s  ), // output wire s_axi_rvalid
    .s_axi_rready  ( s_axi_rready_s  )  // input  wire s_axi_rready
  );

/* SUBROUTINES ****************************************************************/

  task automatic fill_FIFO ( /*************************************************/
    ref    logic                      clk,
    ref    logic [DataCountWidth-1:0] count,
    input  integer unsigned           count_max_i,
    ref    logic                      push_o,
    ref    logic [AXI_DATA_WIDTH-1:0] data_o,
    output logic [AXI_DATA_WIDTH-1:0] ref_queue_o [$]   
  );
  
    logic [AXI_DATA_WIDTH-1:0] tmp_data = '0;
    
    $display("%0t: Filling write FIFO", $time);
    
    push_o   = 1'b0;
    data_o   = tmp_data; 
    
    @(negedge clk);
    
    while (count != count_max_i) begin 
            
      data_o   = tmp_data;
      ref_queue_o.push_back(tmp_data);   
      tmp_data = tmp_data + 1;
      push_o   = 1'b1;
      @(negedge clk);
      #(500ps);      
    
    end
  
    push_o = 1'b0;
    
    $display("%0t: Write FIFO filled with %d entries", $time, tmp_data);
    
    @(negedge clk);
    
  endtask /********************************************************************/

  task automatic empty_FIFO ( /************************************************/
    ref    logic                      clk,
    input  integer unsigned           count_max_i,
    input  logic [AXI_DATA_WIDTH-1:0] ref_queue_i [$],
    ref    logic                      pop_o,
    ref    logic [AXI_DATA_WIDTH-1:0] data_i
  );

    logic [AXI_DATA_WIDTH-1:0] tmp_read_val = '0;
    
    $display("%0t: Emptying read FIFO", $time);
    
    pop_o = 1'b0;
    
    @(negedge clk);
    
    repeat (count_max_i) begin 
            
      tmp_read_val = ref_queue_i.pop_front();
      
      if ( data_i !=  tmp_read_val) begin
        $warning("%0t: Read FIFO value did not match ref value.", $time,
                 "\nRead: %d, Expected: %d", data_i, tmp_read_val);
      end
      
      pop_o = 1'b1;
      @(negedge clk);

    end
  
    pop_o = 1'b0;
    
    $display("%0t: Read FIFO emptied and values checked against reference.", $time);
    
    @(negedge clk);
    
  endtask /********************************************************************/

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

    rstn              = '0;
    req_s             = '0;
    rd_fifo_pop_s     = '0;
    wr_fifo_push_s    = '0;
    axi_wr_addr_s     = '0;
    axi_rd_addr_s     = '0;
    rd_data_count_s   = '0;
    wr_fifo_data_in_s = '0;

    #(2*CLK_PERIOD_NS) rstn = 1'b1;

    #(2*CLK_PERIOD_NS);

    // fill write FIFO
    fill_FIFO(clk, wr_fifo_usage_s, TestDataCount, 
              wr_fifo_push_s, wr_fifo_data_in_s, ref_queue);

    rd_data_count_s = ref_queue.size();

    // initiate write
    $display("%0t: Starting write transfer.", $time);
    req_s = 2'b01;
    @(negedge clk) req_s = 2'b00;

    while(rsp_s[0] == 1'b0)
        @(negedge clk);

    $display("%0t: Write transfer completed.", $time);
    $display("%0t: Starting read transfer.", $time);
    @(negedge clk) req_s = 2'b10;
    @(negedge clk) req_s = 2'b00;

    while(rsp_s[1] == 1'b0)
        @(negedge clk);

    $display("%0t: Read transfer completed.", $time);

    empty_FIFO(clk, TestDataCount, ref_queue, 
               rd_fifo_pop_s, rd_fifo_data_out_s);

    $display("%0t: Simulation Complete.", $time);
    $finish;

  end /************************************************************************/

endmodule // tb_fpga_axi4_mgr

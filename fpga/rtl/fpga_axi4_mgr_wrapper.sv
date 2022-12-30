/*******************************************************************************
-- Title      : AXI4 Mgr FPGA Wrapper
-- Project    : T-Szymk
********************************************************************************
-- File       : fpga_axi4_mgr_wrapper.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-30
-- Design     : fpga_axi4_mgr_wrapper
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Wrapper to contain FPGA implementation of AXI4 Manager
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-30  1.0      TZS     Created
*******************************************************************************/

module fpga_axi4_mgr_wrapper #(
  parameter unsigned AXI_ADDR_WIDTH   =   32,
  parameter unsigned AXI_DATA_WIDTH   =   64,
  parameter unsigned AXI_ID_WIDTH     =    9,
  parameter unsigned AXI_USER_WIDTH   =    5,
  parameter unsigned FIFO_DEPTH       = 1024,
  parameter unsigned AXI_XSIZE        = (AXI_DATA_WIDTH / 8),
  parameter unsigned DATA_COUNT_WIDTH =    8
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  input  logic                        rd_fifo_pop_i,
  input  logic                        wr_fifo_push_i,
  input  logic [               2-1:0] req_i,
  input  logic [  AXI_ADDR_WIDTH-1:0] axi_wr_addr_i,
  input  logic [  AXI_ADDR_WIDTH-1:0] axi_rd_addr_i,
  input  logic [DATA_COUNT_WIDTH-1:0] rd_data_count_i,
  input  logic [  AXI_DATA_WIDTH-1:0] wr_fifo_data_i,
  output logic [  AXI_DATA_WIDTH-1:0] rd_fifo_data_o,
  output logic [DATA_COUNT_WIDTH-1:0] wr_fifo_usage_o,
  output logic [DATA_COUNT_WIDTH-1:0] rd_fifo_usage_o,
  output logic                        wr_fifo_full_o,  
  output logic                        rd_fifo_full_o,
  output logic                        wr_fifo_empty_o, 
  output logic                        rd_fifo_empty_o,
  output logic [               2-1:0] rsp_o,    // bit 1: rd, bit 0: wr
  output logic [               2-1:0] wr_err_o, // bresp
  output logic [               2-1:0] rd_err_o, // rresp
  // AXI4 signals                                                     
  // AW                                                                  
  output logic [    AXI_ID_WIDTH-1:0] aw_id_o,
  output logic [  AXI_ADDR_WIDTH-1:0] aw_addr_o,
  output logic [               8-1:0] aw_len_o,
  output logic [               3-1:0] aw_size_o,
  output logic [               2-1:0] aw_burst_o,
  output logic                        aw_lock_o,
  output logic [               4-1:0] aw_cache_o,
  output logic [               3-1:0] aw_prot_o,
  output logic [               4-1:0] aw_qos_o,
  output logic [               4-1:0] aw_region_o,
  output logic [               4-1:0] aw_atop_o,
  output logic [  AXI_USER_WIDTH-1:0] aw_user_o,
  output logic                        aw_valid_o,
  input  logic                        aw_ready_i,
  // W                                                                    
  output logic [  AXI_DATA_WIDTH-1:0] w_data_o,
  output logic [       AXI_XSIZE-1:0] w_strb_o,
  output logic                        w_last_o,
  output logic [  AXI_USER_WIDTH-1:0] w_user_o,
  output logic                        w_valid_o,
  input  logic                        w_ready_i,
  // B                                                                    
  input  logic [    AXI_ID_WIDTH-1:0] b_id_i,
  input  logic [               2-1:0] b_resp_i,
  input  logic [  AXI_USER_WIDTH-1:0] b_user_i,
  input  logic                        b_valid_i,
  output logic                        b_ready_o,
  // AR                                                                    
  output logic [    AXI_ID_WIDTH-1:0] ar_id_o,
  output logic [  AXI_ADDR_WIDTH-1:0] ar_addr_o,
  output logic [               8-1:0] ar_len_o,
  output logic [               3-1:0] ar_size_o,
  output logic [               2-1:0] ar_burst_o,
  output logic                        ar_lock_o,
  output logic [               4-1:0] ar_cache_o,
  output logic [               3-1:0] ar_prot_o,
  output logic [               4-1:0] ar_qos_o,
  output logic [               4-1:0] ar_region_o,
  output logic [  AXI_USER_WIDTH-1:0] ar_user_o,
  output logic                        ar_valid_o,
  input  logic                        ar_ready_i,
  // R                                                             
  input  logic [    AXI_ID_WIDTH-1:0] r_id_i,
  input  logic [  AXI_DATA_WIDTH-1:0] r_data_i,
  input  logic [               2-1:0] r_resp_i,
  input  logic                        r_last_i,
  input  logic [  AXI_USER_WIDTH-1:0] r_user_i,
  input  logic                        r_valid_i,
  output logic                        r_ready_o
);

  axi4_bus_if #(
    .ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .ID_WIDTH   ( AXI_ID_WIDTH   ),
    .USER_WIDTH ( AXI_USER_WIDTH )
  ) axi_mgr_if ();

  logic clk;
  logic rstn;
  logic wr_fifo_pop_s;
  logic rd_fifo_push_s;
  logic wr_fifo_empty_s;
  logic rd_fifo_full_s;

  logic [  AXI_DATA_WIDTH-1:0] axi_wr_data_s;
  logic [  AXI_DATA_WIDTH-1:0] axi_rd_data_s;

  assign wr_fifo_empty_o = wr_fifo_empty_s;      
  assign rd_fifo_full_o  = rd_fifo_full_s;     
  
  assign aw_id_o             = axi_mgr_if.aw_id;
  assign aw_addr_o           = axi_mgr_if.aw_addr;  
  assign aw_len_o            = axi_mgr_if.aw_len; 
  assign aw_size_o           = axi_mgr_if.aw_size;  
  assign aw_burst_o          = axi_mgr_if.aw_burst;   
  assign aw_lock_o           = axi_mgr_if.aw_lock;  
  assign aw_cache_o          = axi_mgr_if.aw_cache;   
  assign aw_prot_o           = axi_mgr_if.aw_prot;  
  assign aw_qos_o            = axi_mgr_if.aw_qos; 
  assign aw_region_o         = axi_mgr_if.aw_region;    
  assign aw_atop_o           = axi_mgr_if.aw_atop;  
  assign aw_user_o           = axi_mgr_if.aw_user;  
  assign aw_valid_o          = axi_mgr_if.aw_valid;   
  assign axi_mgr_if.aw_ready = aw_ready_i;              
  assign w_data_o            = axi_mgr_if.w_data; 
  assign w_strb_o            = axi_mgr_if.w_strb; 
  assign w_last_o            = axi_mgr_if.w_last; 
  assign w_user_o            = axi_mgr_if.w_user; 
  assign w_valid_o           = axi_mgr_if.w_valid;  
  assign axi_mgr_if.w_ready  = w_ready_i;             
  assign axi_mgr_if.b_id     = b_id_i;          
  assign axi_mgr_if.b_resp   = b_resp_i;            
  assign axi_mgr_if.b_user   = b_user_i;            
  assign axi_mgr_if.b_valid  = b_valid_i;             
  assign b_ready_o           = axi_mgr_if.b_ready;  
  assign ar_id_o             = axi_mgr_if.ar_id;
  assign ar_addr_o           = axi_mgr_if.ar_addr;  
  assign ar_len_o            = axi_mgr_if.ar_len; 
  assign ar_size_o           = axi_mgr_if.ar_size;  
  assign ar_burst_o          = axi_mgr_if.ar_burst;   
  assign ar_lock_o           = axi_mgr_if.ar_lock;  
  assign ar_cache_o          = axi_mgr_if.ar_cache;   
  assign ar_prot_o           = axi_mgr_if.ar_prot;  
  assign ar_qos_o            = axi_mgr_if.ar_qos; 
  assign ar_region_o         = axi_mgr_if.ar_region;    
  assign ar_user_o           = axi_mgr_if.ar_user;  
  assign ar_valid_o          = axi_mgr_if.ar_valid;   
  assign axi_mgr_if.ar_ready = ar_ready_i;              
  assign axi_mgr_if.r_id     = r_id_i;          
  assign axi_mgr_if.r_data   = r_data_i;            
  assign axi_mgr_if.r_resp   = r_resp_i;            
  assign axi_mgr_if.r_last   = r_last_i;            
  assign axi_mgr_if.r_user   = r_user_i;            
  assign axi_mgr_if.r_valid  = r_valid_i;             
  assign r_ready_o           = axi_mgr_if.r_ready;  


  /* COMPONENT AND DUT INSTANTIATIONS */

  // Write data is read from this FIFO
  fifo_v3 #(
    .FALL_THROUGH ( 0                          ),                         
    .DATA_WIDTH   ( AXI_DATA_WIDTH             ),                       
    .DEPTH        ( FIFO_DEPTH                 ),                  
    .dtype        ( logic [AXI_DATA_WIDTH-1:0] )
  ) i_wr_fifo (
    .clk_i      ( clk_i           ),      
    .rst_ni     ( rstn_i          ),       
    .flush_i    ( '0              ),        
    .testmode_i ( '0              ),           
    .full_o     ( wr_fifo_full_o  ),       
    .empty_o    ( wr_fifo_empty_s ),        
    .usage_o    ( wr_fifo_usage_o ),        
    .data_i     ( wr_fifo_data_i  ),       
    .push_i     ( wr_fifo_push_i  ),       
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
    .clk_i      ( clk_i           ),                  
    .rst_ni     ( rstn_i          ),                   
    .flush_i    ( '0              ),                    
    .testmode_i ( '0              ),                       
    .full_o     ( rd_fifo_full_s  ),       
    .empty_o    ( rd_fifo_empty_o ),        
    .usage_o    ( rd_fifo_usage_o ),                    
    .data_i     ( axi_rd_data_s   ),       
    .push_i     ( rd_fifo_push_s  ),       
    .data_o     ( rd_fifo_data_o  ),                   
    .pop_i      ( rd_fifo_pop_i   )     
  );

  axi4_mgr #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH   ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH   ),
    .AXI_XSIZE        ( AXI_XSIZE        ),         
    .DATA_COUNT_WIDTH ( DATA_COUNT_WIDTH )           
  ) i_axi4_mgr (
    .clk_i           ( clk_i            ),      
    .rstn_i          ( rstn_i           ),       
    .req_i           ( req_i            ),      
    .axi_wr_addr_i   ( axi_wr_addr_i    ),              
    .axi_rd_addr_i   ( axi_rd_addr_i    ),
    .wr_fifo_gnt_i   ( ~wr_fifo_empty_s ),
    .rd_fifo_req_i   ( ~rd_fifo_full_s  ),              
    .wr_fifo_data_i  ( axi_wr_data_s    ),           
    .wr_data_count_i ( wr_fifo_usage_o  ),                
    .rd_data_count_i ( rd_data_count_i  ),                
    .rsp_o           ( rsp_o            ),      
    .wr_err_o        ( wr_err_o         ),         
    .rd_err_o        ( rd_err_o         ),
    .wr_fifo_req_o   ( wr_fifo_pop_s    ),
    .rd_fifo_gnt_o   ( rd_fifo_push_s   ),         
    .rd_fifo_data_o  ( axi_rd_data_s    ),           
    .axi_mgr_if      ( axi_mgr_if       )           
  );

endmodule // fpga_axi4_mgr_wrapper

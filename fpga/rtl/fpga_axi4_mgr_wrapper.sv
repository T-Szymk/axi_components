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
  parameter unsigned AXI4_ADDR_WIDTH   =   32,
  parameter unsigned AXI4_DATA_WIDTH   =   64,
  parameter unsigned AXIL_ADDR_WIDTH   =   32,
  parameter unsigned AXIL_DATA_WIDTH   =   32,
  parameter unsigned AXI_ID_WIDTH      =    3,
  parameter unsigned AXI_USER_WIDTH    =    5,
  parameter unsigned FIFO_DEPTH        = 1024,
  parameter unsigned AXI_XSIZE         = (AXI4_DATA_WIDTH / 8),
  parameter unsigned REG_BASE_ADDR     =  'h0,
  parameter unsigned DATA_COUNT_WIDTH  =    8,

  localparam integer unsigned AXILSizeBytes = (AXIL_DATA_WIDTH / 8),
  localparam integer unsigned AXI4SizeBytes = (AXI4_DATA_WIDTH / 8)
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  // AXI4
  // AW
  output logic [    AXI_ID_WIDTH-1:0] axi4_mgr_aw_id_o,
  output logic [ AXI4_ADDR_WIDTH-1:0] axi4_mgr_aw_addr_o,
  output logic [               8-1:0] axi4_mgr_aw_len_o,
  output logic [               3-1:0] axi4_mgr_aw_size_o,
  output logic [               2-1:0] axi4_mgr_aw_burst_o,
  output logic                        axi4_mgr_aw_lock_o,
  output logic [               4-1:0] axi4_mgr_aw_cache_o,
  output logic [               3-1:0] axi4_mgr_aw_prot_o,
  output logic [               4-1:0] axi4_mgr_aw_qos_o,
  output logic [               4-1:0] axi4_mgr_aw_region_o,
  output logic [  AXI_USER_WIDTH-1:0] axi4_mgr_aw_user_o,
  output logic                        axi4_mgr_aw_valid_o,
  input  logic                        axi4_mgr_aw_ready_i,
  // W
  output logic [ AXI4_DATA_WIDTH-1:0] axi4_mgr_w_data_o,
  output logic [       AXI_XSIZE-1:0] axi4_mgr_w_strb_o,
  output logic                        axi4_mgr_w_last_o,
  output logic [  AXI_USER_WIDTH-1:0] axi4_mgr_w_user_o,
  output logic                        axi4_mgr_w_valid_o,
  input  logic                        axi4_mgr_w_ready_i,
  // B
  input  logic [    AXI_ID_WIDTH-1:0] axi4_mgr_b_id_i,
  input  logic [               2-1:0] axi4_mgr_b_resp_i,
  input  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_b_user_i,
  input  logic                        axi4_mgr_b_valid_i,
  output logic                        axi4_mgr_b_ready_o,
  // AR
  output logic [    AXI_ID_WIDTH-1:0] axi4_mgr_ar_id_o,
  output logic [ AXI4_ADDR_WIDTH-1:0] axi4_mgr_ar_addr_o,
  output logic [               8-1:0] axi4_mgr_ar_len_o,
  output logic [               3-1:0] axi4_mgr_ar_size_o,
  output logic [               2-1:0] axi4_mgr_ar_burst_o,
  output logic                        axi4_mgr_ar_lock_o,
  output logic [               4-1:0] axi4_mgr_ar_cache_o,
  output logic [               3-1:0] axi4_mgr_ar_prot_o,
  output logic [               4-1:0] axi4_mgr_ar_region_o,
  output logic [               4-1:0] axi4_mgr_ar_qos_o,
  output logic [  AXI_USER_WIDTH-1:0] axi4_mgr_ar_user_o,
  output logic                        axi4_mgr_ar_valid_o,
  input  logic                        axi4_mgr_ar_ready_i,
  // R
  input  logic [    AXI_ID_WIDTH-1:0] axi4_mgr_r_id_i,
  input  logic [ AXI4_DATA_WIDTH-1:0] axi4_mgr_r_data_i,
  input  logic [               2-1:0] axi4_mgr_r_resp_i,
  input  logic                        axi4_mgr_r_last_i,
  input  logic [  AXI_USER_WIDTH-1:0] axi4_mgr_r_user_i,
  input  logic                        axi4_mgr_r_valid_i,
  output logic                        axi4_mgr_r_ready_o,
  // AXI-LITE Signals
  // AW                                                                  
  input  logic [ AXIL_ADDR_WIDTH-1:0] axil_sub_aw_addr_i,
  input  logic [               3-1:0] axil_sub_aw_prot_i,
  input  logic                        axil_sub_aw_valid_i,
  output logic                        axil_sub_aw_ready_o,
  // W                                                                    
  input  logic [ AXIL_DATA_WIDTH-1:0] axil_sub_w_data_i,
  input  logic [   AXILSizeBytes-1:0] axil_sub_w_strb_i,
  input  logic                        axil_sub_w_valid_i,
  output logic                        axil_sub_w_ready_o,
  // B                                                                    
  output logic [               2-1:0] axil_sub_b_resp_o,
  output logic                        axil_sub_b_valid_o,
  input  logic                        axil_sub_b_ready_i,
  // AR                                                                    
  input  logic [ AXIL_ADDR_WIDTH-1:0] axil_sub_ar_addr_i,
  input  logic [               3-1:0] axil_sub_ar_prot_i,
  input  logic                        axil_sub_ar_valid_i,
  output logic                        axil_sub_ar_ready_o,
  // R 
  output  logic [AXIL_DATA_WIDTH-1:0] axil_sub_r_data_o,
  output  logic [              2-1:0] axil_sub_r_resp_o,
  output  logic                       axil_sub_r_valid_o,
  input   logic                       axil_sub_r_ready_i
);

  axi4_bus_if #(
    .ADDR_WIDTH ( AXI4_ADDR_WIDTH ),
    .DATA_WIDTH ( AXI4_DATA_WIDTH ),
    .ID_WIDTH   ( AXI_ID_WIDTH    ),
    .USER_WIDTH ( AXI_USER_WIDTH  )
  ) axi_mgr_if ();

  logic                        rd_fifo_pop_s;
  logic                        wr_fifo_push_s;
  logic [               2-1:0] req_s;
  logic [ AXI4_ADDR_WIDTH-1:0] axi_wr_addr_s;
  logic [ AXI4_ADDR_WIDTH-1:0] axi_rd_addr_s;
  logic [DATA_COUNT_WIDTH-1:0] rd_data_count_s;
  logic [ AXI4_DATA_WIDTH-1:0] wr_fifo_data_s;
  logic [ AXI4_DATA_WIDTH-1:0] rd_fifo_data_s;
  logic [DATA_COUNT_WIDTH-1:0] wr_fifo_usage_s;
  logic [DATA_COUNT_WIDTH-1:0] rd_fifo_usage_s;
  logic                        wr_fifo_full_s;  
  logic                        rd_fifo_full_s;
  logic                        wr_fifo_empty_s; 
  logic                        rd_fifo_empty_s;
  logic [               2-1:0] rsp_s;    // bit 1: rd, bit 0: wr
  logic [               2-1:0] wr_err_s; // bresp
  logic [               2-1:0] rd_err_s; // rresp

  logic enable_s;

  logic wr_fifo_pop_s;
  logic rd_fifo_push_s;

  logic [  AXI4_DATA_WIDTH-1:0] axi_wr_data_s;
  logic [  AXI4_DATA_WIDTH-1:0] axi_rd_data_s;

  assign wr_fifo_empty_o = wr_fifo_empty_s;      
  assign rd_fifo_full_o  = rd_fifo_full_s;     
  
  assign axi4_mgr_aw_id_o     = axi_mgr_if.aw_id;
  assign axi4_mgr_aw_addr_o   = axi_mgr_if.aw_addr;  
  assign axi4_mgr_aw_len_o    = axi_mgr_if.aw_len; 
  assign axi4_mgr_aw_size_o   = axi_mgr_if.aw_size;  
  assign axi4_mgr_aw_burst_o  = axi_mgr_if.aw_burst;   
  assign axi4_mgr_aw_lock_o   = axi_mgr_if.aw_lock;  
  assign axi4_mgr_aw_cache_o  = axi_mgr_if.aw_cache;   
  assign axi4_mgr_aw_prot_o   = axi_mgr_if.aw_prot;  
  assign axi4_mgr_aw_qos_o    = axi_mgr_if.aw_qos; 
  assign axi4_mgr_aw_region_o = axi_mgr_if.aw_region;    
  assign axi4_mgr_aw_atop_o   = axi_mgr_if.aw_atop;  
  assign axi4_mgr_aw_user_o   = axi_mgr_if.aw_user;  
  assign axi4_mgr_aw_valid_o  = axi_mgr_if.aw_valid;   
  assign axi_mgr_if.aw_ready  = axi4_mgr_aw_ready_i;              
  assign axi4_mgr_w_data_o    = axi_mgr_if.w_data; 
  assign axi4_mgr_w_strb_o    = axi_mgr_if.w_strb; 
  assign axi4_mgr_w_last_o    = axi_mgr_if.w_last; 
  assign axi4_mgr_w_user_o    = axi_mgr_if.w_user; 
  assign axi4_mgr_w_valid_o   = axi_mgr_if.w_valid;  
  assign axi_mgr_if.w_ready   = axi4_mgr_w_ready_i;             
  assign axi_mgr_if.b_id      = axi4_mgr_b_id_i;          
  assign axi_mgr_if.b_resp    = axi4_mgr_b_resp_i;            
  assign axi_mgr_if.b_user    = axi4_mgr_b_user_i;            
  assign axi_mgr_if.b_valid   = axi4_mgr_b_valid_i;             
  assign axi4_mgr_b_ready_o   = axi_mgr_if.b_ready;  
  assign axi4_mgr_ar_id_o     = axi_mgr_if.ar_id;
  assign axi4_mgr_ar_addr_o   = axi_mgr_if.ar_addr;  
  assign axi4_mgr_ar_len_o    = axi_mgr_if.ar_len; 
  assign axi4_mgr_ar_size_o   = axi_mgr_if.ar_size;  
  assign axi4_mgr_ar_burst_o  = axi_mgr_if.ar_burst;   
  assign axi4_mgr_ar_lock_o   = axi_mgr_if.ar_lock;  
  assign axi4_mgr_ar_cache_o  = axi_mgr_if.ar_cache;   
  assign axi4_mgr_ar_prot_o   = axi_mgr_if.ar_prot;  
  assign axi4_mgr_ar_qos_o    = axi_mgr_if.ar_qos; 
  assign axi4_mgr_ar_region_o = axi_mgr_if.ar_region;    
  assign axi4_mgr_ar_user_o   = axi_mgr_if.ar_user;  
  assign axi4_mgr_ar_valid_o  = axi_mgr_if.ar_valid;   
  assign axi_mgr_if.ar_ready  = axi4_mgr_ar_ready_i;              
  assign axi_mgr_if.r_id      = axi4_mgr_r_id_i;          
  assign axi_mgr_if.r_data    = axi4_mgr_r_data_i;            
  assign axi_mgr_if.r_resp    = axi4_mgr_r_resp_i;            
  assign axi_mgr_if.r_last    = axi4_mgr_r_last_i;            
  assign axi_mgr_if.r_user    = axi4_mgr_r_user_i;            
  assign axi_mgr_if.r_valid   = axi4_mgr_r_valid_i;             
  assign axi4_mgr_r_ready_o   = axi_mgr_if.r_ready;  


  /* COMPONENT AND DUT INSTANTIATIONS */

  // Write data is read from this FIFO
  fifo_v3 #(
    .FALL_THROUGH ( 0                          ),                         
    .DATA_WIDTH   ( AXI4_DATA_WIDTH             ),                       
    .DEPTH        ( FIFO_DEPTH                 ),                  
    .dtype        ( logic [AXI4_DATA_WIDTH-1:0] )
  ) i_wr_fifo (
    .clk_i      ( clk_i           ),      
    .rst_ni     ( enable_s        ),       
    .flush_i    ( '0              ),        
    .testmode_i ( '0              ),           
    .full_o     ( wr_fifo_full_s  ),       
    .empty_o    ( wr_fifo_empty_s ),        
    .usage_o    ( wr_fifo_usage_s ),        
    .data_i     ( wr_fifo_data_s  ),       
    .push_i     ( wr_fifo_push_s  ),       
    .data_o     ( axi_wr_data_s   ),       
    .pop_i      ( wr_fifo_pop_s   )     
  );
  
  // Read data is written to the following FIFO
  fifo_v3 #(
    .FALL_THROUGH ( 0                          ),                         
    .DATA_WIDTH   ( AXI4_DATA_WIDTH             ),                       
    .DEPTH        ( FIFO_DEPTH                 ),                  
    .dtype        ( logic [AXI4_DATA_WIDTH-1:0] )                      
  ) i_rd_fifo (
    .clk_i      ( clk_i           ),                  
    .rst_ni     ( enable_s        ),                   
    .flush_i    ( '0              ),                    
    .testmode_i ( '0              ),                       
    .full_o     ( rd_fifo_full_s  ),       
    .empty_o    ( rd_fifo_empty_s ),        
    .usage_o    ( rd_fifo_usage_s ),                    
    .data_i     ( axi_rd_data_s   ),       
    .push_i     ( rd_fifo_push_s  ),       
    .data_o     ( rd_fifo_data_s  ),                   
    .pop_i      ( rd_fifo_pop_s   )     
  );

  axi4_mgr #(
    .AXI4_ADDR_WIDTH  ( AXI4_ADDR_WIDTH   ),
    .AXI4_DATA_WIDTH  ( AXI4_DATA_WIDTH   ),
    .AXI_XSIZE        ( AXI_XSIZE        ),         
    .DATA_COUNT_WIDTH ( DATA_COUNT_WIDTH )           
  ) i_axi4_mgr (
    .clk_i           ( clk_i            ),      
    .rstn_i          ( enable_s         ),       
    .req_i           ( req_s            ),      
    .axi_wr_addr_i   ( axi_wr_addr_s    ),              
    .axi_rd_addr_i   ( axi_rd_addr_s    ),
    .wr_fifo_gnt_i   ( ~wr_fifo_empty_s ),
    .rd_fifo_req_i   ( ~rd_fifo_full_s  ),              
    .wr_fifo_data_i  ( axi_wr_data_s    ),           
    .wr_data_count_i ( wr_fifo_usage_s  ),                
    .rd_data_count_i ( rd_data_count_s  ),                
    .rsp_o           ( rsp_s            ),      
    .wr_err_o        ( wr_err_s         ),         
    .rd_err_o        ( rd_err_s         ),
    .wr_fifo_req_o   ( wr_fifo_pop_s    ),
    .rd_fifo_gnt_o   ( rd_fifo_push_s   ),         
    .rd_fifo_data_o  ( axi_rd_data_s    ),           
    .axi_mgr_if      ( axi_mgr_if       )           
  );

  axi_lite_registers #(
    .AXI4_ADDR_WIDTH  ( AXI4_ADDR_WIDTH  ),           
    .AXI4_DATA_WIDTH  ( AXI4_DATA_WIDTH  ),           
    .AXIL_ADDR_WIDTH  ( AXIL_ADDR_WIDTH  ),           
    .AXIL_DATA_WIDTH  ( AXIL_DATA_WIDTH  ),           
    .AXI_ID_WIDTH     ( AXI_ID_WIDTH     ),        
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH   ),          
    .BASE_ADDR        ( REG_BASE_ADDR    ),     
    .DATA_COUNT_WIDTH ( DATA_COUNT_WIDTH )           
  ) i_axi_lite_registers (
    .clk_i           ( clk_i               ),       
    .rstn_i          ( rstn_i              ),        
    .aw_addr_i       ( axil_sub_aw_addr_i  ),           
    .aw_prot_i       ( axil_sub_aw_prot_i  ),           
    .aw_valid_i      ( axil_sub_aw_valid_i ),            
    .aw_ready_o      ( axil_sub_aw_ready_o ),            
    .w_data_i        ( axil_sub_w_data_i   ),          
    .w_strb_i        ( axil_sub_w_strb_i   ),          
    .w_valid_i       ( axil_sub_w_valid_i  ),           
    .w_ready_o       ( axil_sub_w_ready_o  ),           
    .b_resp_o        ( axil_sub_b_resp_o   ),          
    .b_valid_o       ( axil_sub_b_valid_o  ),           
    .b_ready_i       ( axil_sub_b_ready_i  ),           
    .ar_addr_i       ( axil_sub_ar_addr_i  ),           
    .ar_prot_i       ( axil_sub_ar_prot_i  ),           
    .ar_valid_i      ( axil_sub_ar_valid_i ),            
    .ar_ready_o      ( axil_sub_ar_ready_o ),            
    .r_data_o        ( axil_sub_r_data_o   ),          
    .r_resp_o        ( axil_sub_r_resp_o   ),          
    .r_valid_o       ( axil_sub_r_valid_o  ),           
    .r_ready_i       ( axil_sub_r_ready_i  ),
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


endmodule // fpga_axi4_mgr_wrapper

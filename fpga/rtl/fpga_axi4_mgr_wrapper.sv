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
  parameter unsigned AXI_ID_WIDTH      =    4,
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

  logic [15 : 0] s_axi_awaddr;
  logic [ 7 : 0] s_axi_awlen;
  logic [ 2 : 0] s_axi_awsize;
  logic [ 1 : 0] s_axi_awburst;
  logic          s_axi_awlock;
  logic [ 3 : 0] s_axi_awcache;
  logic [ 2 : 0] s_axi_awprot;
  logic          s_axi_awvalid;
  logic          s_axi_awready;
  logic [63 : 0] s_axi_wdata;
  logic [ 7 : 0] s_axi_wstrb;
  logic          s_axi_wlast;
  logic          s_axi_wvalid;
  logic          s_axi_wready;
  logic [ 1 : 0] s_axi_bresp;
  logic          s_axi_bvalid;
  logic          s_axi_bready;
  logic [15 : 0] s_axi_araddr;
  logic [ 7 : 0] s_axi_arlen;
  logic [ 2 : 0] s_axi_arsize;
  logic [ 1 : 0] s_axi_arburst;
  logic          s_axi_arlock;
  logic [ 3 : 0] s_axi_arcache;
  logic [ 2 : 0] s_axi_arprot;
  logic          s_axi_arvalid;
  logic          s_axi_arready;
  logic [63 : 0] s_axi_rdata;
  logic [ 1 : 0] s_axi_rresp;
  logic          s_axi_rlast;
  logic          s_axi_rvalid;
  logic          s_axi_rready;

  assign wr_fifo_empty_o = wr_fifo_empty_s;      
  assign rd_fifo_full_o  = rd_fifo_full_s;  
  
  assign s_axi_awaddr        = axi_mgr_if.aw_addr[15:0];     
  assign s_axi_awlen         = axi_mgr_if.aw_len;    
  assign s_axi_awsize        = axi_mgr_if.aw_size;     
  assign s_axi_awburst       = axi_mgr_if.aw_burst;      
  assign s_axi_awlock        = axi_mgr_if.aw_lock;     
  assign s_axi_awcache       = axi_mgr_if.aw_cache;      
  assign s_axi_awprot        = axi_mgr_if.aw_prot;     
  assign s_axi_awvalid       = axi_mgr_if.aw_valid;      
  assign axi_mgr_if.aw_ready = s_axi_awready;

  assign s_axi_wdata         = axi_mgr_if.w_data;  
  assign s_axi_wstrb         = axi_mgr_if.w_strb;  
  assign s_axi_wlast         = axi_mgr_if.w_last;  
  assign s_axi_wvalid        = axi_mgr_if.w_valid;   
  assign axi_mgr_if.w_ready  = s_axi_wready;

  assign axi_mgr_if.b_resp   = s_axi_bresp;
  assign axi_mgr_if.b_valid  = s_axi_bvalid;
  assign s_axi_bready        = axi_mgr_if.b_ready;

  assign s_axi_araddr        = axi_mgr_if.ar_addr[15:0];     
  assign s_axi_arlen         = axi_mgr_if.ar_len;    
  assign s_axi_arsize        = axi_mgr_if.ar_size;     
  assign s_axi_arburst       = axi_mgr_if.ar_burst;      
  assign s_axi_arlock        = axi_mgr_if.ar_lock;     
  assign s_axi_arcache       = axi_mgr_if.ar_cache;      
  assign s_axi_arprot        = axi_mgr_if.ar_prot;     
  assign s_axi_arvalid       = axi_mgr_if.ar_valid;      
  assign axi_mgr_if.ar_ready = s_axi_arready;

  assign axi_mgr_if.r_data   = s_axi_rdata;
  assign axi_mgr_if.r_resp   = s_axi_rresp;
  assign axi_mgr_if.r_last   = s_axi_rlast;
  assign axi_mgr_if.r_valid  = s_axi_rvalid;
  assign s_axi_rready        = axi_mgr_if.r_ready;
  
  /* COMPONENT AND DUT INSTANTIATIONS */

  // Write data is read from this FIFO
  fpga_fifo_v3 #(                        
    .DATA_WIDTH   ( AXI4_DATA_WIDTH ),                       
    .DEPTH        ( FIFO_DEPTH      )
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
  fpga_fifo_v3 #(                        
    .DATA_WIDTH   ( AXI4_DATA_WIDTH ),                       
    .DEPTH        ( FIFO_DEPTH      )                  
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

  axi_bram_ctrl_0 i_axi_bram (
  .s_axi_aclk    ( clk_i         ), // input  wire s_axi_aclk
  .s_axi_aresetn ( rstn_i        ), // input  wire s_axi_aresetn
  .s_axi_awaddr  ( s_axi_awaddr  ), // input  wire [15 : 0] s_axi_awaddr
  .s_axi_awlen   ( s_axi_awlen   ), // input  wire [7 : 0] s_axi_awlen
  .s_axi_awsize  ( s_axi_awsize  ), // input  wire [2 : 0] s_axi_awsize
  .s_axi_awburst ( s_axi_awburst ), // input  wire [1 : 0] s_axi_awburst
  .s_axi_awlock  ( s_axi_awlock  ), // input  wire s_axi_awlock
  .s_axi_awcache ( s_axi_awcache ), // input  wire [3 : 0] s_axi_awcache
  .s_axi_awprot  ( s_axi_awprot  ), // input  wire [2 : 0] s_axi_awprot
  .s_axi_awvalid ( s_axi_awvalid ), // input  wire s_axi_awvalid
  .s_axi_awready ( s_axi_awready ), // output wire s_axi_awready
  .s_axi_wdata   ( s_axi_wdata   ), // input  wire [63 : 0] s_axi_wdata
  .s_axi_wstrb   ( s_axi_wstrb   ), // input  wire [7 : 0] s_axi_wstrb
  .s_axi_wlast   ( s_axi_wlast   ), // input  wire s_axi_wlast
  .s_axi_wvalid  ( s_axi_wvalid  ), // input  wire s_axi_wvalid
  .s_axi_wready  ( s_axi_wready  ), // output wire s_axi_wready
  .s_axi_bresp   ( s_axi_bresp   ), // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid  ( s_axi_bvalid  ), // output wire s_axi_bvalid
  .s_axi_bready  ( s_axi_bready  ), // input  wire s_axi_bready
  .s_axi_araddr  ( s_axi_araddr  ), // input  wire [15 : 0] s_axi_araddr
  .s_axi_arlen   ( s_axi_arlen   ), // input  wire [7 : 0] s_axi_arlen
  .s_axi_arsize  ( s_axi_arsize  ), // input  wire [2 : 0] s_axi_arsize
  .s_axi_arburst ( s_axi_arburst ), // input  wire [1 : 0] s_axi_arburst
  .s_axi_arlock  ( s_axi_arlock  ), // input  wire s_axi_arlock
  .s_axi_arcache ( s_axi_arcache ), // input  wire [3 : 0] s_axi_arcache
  .s_axi_arprot  ( s_axi_arprot  ), // input  wire [2 : 0] s_axi_arprot
  .s_axi_arvalid ( s_axi_arvalid ), // input  wire s_axi_arvalid
  .s_axi_arready ( s_axi_arready ), // output wire s_axi_arready
  .s_axi_rdata   ( s_axi_rdata   ), // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp   ( s_axi_rresp   ), // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast   ( s_axi_rlast   ), // output wire s_axi_rlast
  .s_axi_rvalid  ( s_axi_rvalid  ), // output wire s_axi_rvalid
  .s_axi_rready  ( s_axi_rready  )  // input  wire s_axi_rready
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

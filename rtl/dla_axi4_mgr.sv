/*******************************************************************************
-- Title      : AXI4 Manager
-- Project    : T-Szymk
********************************************************************************
-- File       : dla_axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-22s
-- Design     : dla_axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Generic non-pipelined AXI4 manager.
--              Does not currently support burst transactions.
--              No reponse error handling is implemented.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-22  1.0      TZS     Created
*******************************************************************************/

module dla_axi4_mgr # (
  parameter int AXI_ADDR_WIDTH = 32,
  parameter int AXI_DATA_WIDTH = 64
)(
  input  logic                      clk_i,
  input  logic                      rstn_i,
  input  logic [             2-1:0] req_i,
  input  logic [AXI_ADDR_WIDTH-1:0] axi_wr_addr_i,
  input  logic [AXI_ADDR_WIDTH-1:0] axi_rd_addr_i,
  input  logic [AXI_DATA_WIDTH-1:0] pp_data_i,
  output logic [             2-1:0] rsp_o, // bit 1: rd, bit 0: wr
  output logic [AXI_DATA_WIDTH-1:0] dla_data_o,
  AXI_BUS.Master                    pp_if
);

  /******** SIGNALS/CONSTANTS/TYPES *******************************************/

  typedef enum logic [3:0] {
    W_IDLE,
    AW,
    W,
    B_RESP
  } wr_state_t; 

  typedef enum logic [3:0] {
    R_IDLE,
    AR,
    R
  } rd_state_t; 

  wr_state_t wr_c_state_r;
  rd_state_t rd_c_state_r;

  logic rsp_wr_s, rsp_rd_s;
  logic req_wr_s, req_rd_s; 

  logic [AXI_DATA_WIDTH-1:0] pp_data_r;
  logic [AXI_DATA_WIDTH-1:0] dla_data_r;

  /******** ASSIGNMENTS FMS  **************************************************/
  // AW signals
  assign pp_if.aw_id     = '0;        
  assign pp_if.aw_len    = '0;       
  assign pp_if.aw_size   = '0;        
  assign pp_if.aw_burst  = '0;         
  assign pp_if.aw_lock   = '0;        
  assign pp_if.aw_cache  = '0;         
  assign pp_if.aw_qos    = '0;       
  assign pp_if.aw_region = '0;          
  assign pp_if.aw_atop   = '0;         
  assign pp_if.aw_user   = '0;        
  assign pp_if.aw_prot   = '0;

  // AR signals
  assign pp_if.ar_id     = '0;        
  assign pp_if.ar_len    = '0;         
  assign pp_if.ar_size   = '0;          
  assign pp_if.ar_burst  = '0;           
  assign pp_if.ar_lock   = '0;          
  assign pp_if.ar_cache  = '0;           
  assign pp_if.ar_qos    = '0;         
  assign pp_if.ar_region = '0;            
  assign pp_if.ar_user   = '0;          
  assign pp_if.ar_prot   = '0;
  // W signals
  assign pp_if.w_user    = '0;

  // Other signals
  assign dla_data_o      = dla_data_r; 
  assign rsp_wr_s        = (pp_if.b_valid & pp_if.b_ready);
  assign rsp_rd_s        = (pp_if.r_valid & pp_if.r_ready);
  assign rsp_o           = {rsp_rd_s, rsp_wr_s};
  assign req_wr_s        = req_i[0];
  assign req_rd_s        = req_i[1];

  /******** WRITE FMS  ********************************************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin : wr_fsm

    if (~rstn_i) begin 
      
      pp_if.aw_valid <= '0;
      pp_if.aw_addr  <= '0;
      pp_if.w_data   <= '0;
      pp_if.w_strb   <= '0;
      pp_if.w_valid  <= '0;
      pp_if.w_last   <= '0;
      pp_if.b_ready  <= '0;
      pp_data_r      <= '0;
      wr_c_state_r   <= W_IDLE;

    end else begin 

      case (wr_c_state_r)

        W_IDLE: begin 

          pp_data_r <= '0;
          
          if (req_wr_s == 1'b1) begin 
            
            pp_if.aw_valid <= 1'b1;
            pp_if.aw_addr  <= axi_wr_addr_i;
            pp_data_r      <= pp_data_i;
            wr_c_state_r   <= AW;
          
          end
        end

        AW: begin 
          
          if (pp_if.aw_ready == 1'b1) begin 
            
            pp_if.aw_valid <= 1'b0;
            pp_if.w_valid  <= 1'b1;
            pp_if.w_last   <= 1'b1;
            pp_if.w_strb   <= 4'hF;
            wr_c_state_r   <= W;

          end
        end

        W: begin

          if (pp_if.w_ready == 1'b1) begin 
            
            pp_if.w_valid  <= 1'b0;
            pp_if.w_last   <= 1'b0;
            pp_if.w_strb   <= 4'h0;
            pp_if.b_ready  <= 1'b1;
            wr_c_state_r   <= B_RESP;

          end
        end
        
        B_RESP: begin 

          if (pp_if.b_valid == 1'b1) begin 
            // no error handling implemented, so BRESP value is ignored.
            pp_if.b_ready <= 1'b0;
            wr_c_state_r  <= W_IDLE;
          
          end
        end
        
        default: begin 
        
          wr_c_state_r <= W_IDLE;

        end

      endcase

    end 
  end : wr_fsm

  /******** READ FMS  *********************************************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin : rd_fsm 
    
    if (~rstn_i) begin 
      
      pp_if.ar_valid <= '0;
      pp_if.ar_addr  <= '0;
      pp_if.r_ready  <= '0;
      dla_data_r     <= '0;
      rd_c_state_r   <= R_IDLE;
    
    end else begin 

      case (rd_c_state_r)

        R_IDLE: begin

          if (req_rd_s == 1'b1) begin 
            
            pp_if.ar_valid <= 1'b1;
            pp_if.ar_addr  <= axi_rd_addr_i;
            rd_c_state_r   <= AR;
          
          end
        end

        AR: begin 

          if (pp_if.ar_ready == 1'b1) begin 
            
            pp_if.ar_valid <= 1'b0;
            pp_if.r_ready  <= 1'b1;
            rd_c_state_r   <= R;

          end
        end

        R: begin 
          // only supports single beats, so RLAST is ignored.
          if (pp_if.r_valid == 1'b1) begin 
            pp_if.r_ready <= 1'b0;
            // no error handling implemented, so RRESP value is ignored.
            dla_data_r    <= pp_if.r_data;
            rd_c_state_r  <= R_IDLE;
          end
        
        end

        default: begin 

          rd_c_state_r <= R_IDLE;
        
        end
      
      endcase

    end 
  end : rd_fsm

endmodule // dla_axi4_mgr

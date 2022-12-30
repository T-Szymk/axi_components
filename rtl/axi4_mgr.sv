/*******************************************************************************
-- Title      : AXI4 Manager
-- Project    : T-Szymk
********************************************************************************
-- File       : axi4_mgr.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-30
-- Design     : axi4_mgr
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Generic non-pipelined AXI4 manager.
--              AOnly supports single and INCR burst transactions.
--              Basic error reporting.
--              No protection against reading across 4kB boundaries is provided.
--              Does not support narrow bursts.
--              Designed to read from and write to separate FIFOs.
-- Guidance:    Set address and data_count and then set the corresponding req 
--              bit. For a write, the wr_valid/rdy will be used to read in new 
--              data to be written in each beat. For a read, the rd_valid/rdy 
--              signals to write out the read results. Once the data_count
--              number of transactions have completed, the corresponding rsp bit
--              will be set.
--              If an error response is encountered, the rd/wr_err bits will be 
--              set to indicate the latest not OK error value. This value will 
--              be cleared when initiating a new set of transactions (setting 
--              req).
--              Only Incrementing bursts are supported right now, so for each 
--              transaction/beat, the address will be incremented by 4, starting
--              from the address value which is present in the first cycle of 
--              req being set. 
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-30  1.0      TZS     Created
*******************************************************************************/

module axi4_mgr # (
  parameter unsigned AXI_ADDR_WIDTH    = 32,
  parameter unsigned AXI_DATA_WIDTH    = 64,
  parameter unsigned AXI_XSIZE         = (AXI_DATA_WIDTH / 8),
  parameter unsigned DATA_COUNT_WIDTH  =  8
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  input  logic [               2-1:0] req_i,
  input  logic [  AXI_ADDR_WIDTH-1:0] axi_wr_addr_i,
  input  logic [  AXI_ADDR_WIDTH-1:0] axi_rd_addr_i,
  input  logic                        wr_fifo_gnt_i, // currently unused 
  input  logic                        rd_fifo_req_i,  
  input  logic [  AXI_DATA_WIDTH-1:0] wr_fifo_data_i,
  input  logic [DATA_COUNT_WIDTH-1:0] wr_data_count_i,
  input  logic [DATA_COUNT_WIDTH-1:0] rd_data_count_i,
  output logic [               2-1:0] rsp_o,    // bit 1: rd, bit 0: wr
  output logic [               2-1:0] wr_err_o, // bresp
  output logic [               2-1:0] rd_err_o, // rresp
  output logic                        wr_fifo_req_o,
  output logic                        rd_fifo_gnt_o,
  output logic [  AXI_DATA_WIDTH-1:0] rd_fifo_data_o,
  axi4_bus_if.Manager                 axi_mgr_if
);

  /******** SIGNALS/CONSTANTS/TYPES *******************************************/

  localparam unsigned WordSizeBytes = (AXI_DATA_WIDTH / 8);

  typedef enum logic [3:0] {
    W_IDLE,
    AW_INIT,
    AW,
    W,
    W_LAST,
    B_RESP
  } wr_state_t;

  typedef enum logic [3:0] {
    R_IDLE,
    AR_INIT,
    AR,
    R,
    R_LAST
  } rd_state_t;

  wr_state_t wr_c_state_r;
  rd_state_t rd_c_state_r;

  logic rsp_wr_r, rsp_rd_r;
  logic req_wr_s, req_rd_s, req_wr_r, req_rd_r;

  logic aw_valid_r, w_valid_r;
  logic ar_valid_r, r_ready_s;
  
  logic [  AXI_ADDR_WIDTH-1:0] axi_aw_addr_r;
  logic [  AXI_ADDR_WIDTH-1:0] axi_ar_addr_r;
  logic [               8-1:0] axi_awlen_r;
  logic [               8-1:0] axi_arlen_r;
  logic [               2-1:0] wr_err_r, wr_err_s;
  logic [               2-1:0] rd_err_r, rd_err_s;
  logic [               9-1:0] wr_beat_count_r;
  logic [               9-1:0] rd_beat_count_r;
  logic [DATA_COUNT_WIDTH-1:0] wr_beats_remain_r;
  logic [DATA_COUNT_WIDTH-1:0] rd_beats_remain_r;

  /******** ASSIGNMENTS FMS  **************************************************/
  // AW signals
  assign axi_mgr_if.aw_valid  = aw_valid_r;
  assign axi_mgr_if.aw_id     = '0;
  assign axi_mgr_if.aw_len    = axi_awlen_r;
  assign axi_mgr_if.aw_size   = $clog2(AXI_XSIZE);
  assign axi_mgr_if.aw_burst  = 2'b01; // INCR
  assign axi_mgr_if.aw_lock   = '0;
  assign axi_mgr_if.aw_cache  = '0;
  assign axi_mgr_if.aw_qos    = '0;
  assign axi_mgr_if.aw_region = '0;
  assign axi_mgr_if.aw_atop   = '0;
  assign axi_mgr_if.aw_user   = '0;
  assign axi_mgr_if.aw_prot   = '0;

  // AR signals
  assign axi_mgr_if.ar_valid  = ar_valid_r;
  assign axi_mgr_if.ar_id     = '0;
  assign axi_mgr_if.ar_len    = axi_arlen_r;
  assign axi_mgr_if.ar_size   = $clog2(AXI_XSIZE);
  assign axi_mgr_if.ar_burst  = 2'b01; // INCR
  assign axi_mgr_if.ar_lock   = '0;
  assign axi_mgr_if.ar_cache  = '0;
  assign axi_mgr_if.ar_qos    = '0;
  assign axi_mgr_if.ar_region = '0;
  assign axi_mgr_if.ar_user   = '0;
  assign axi_mgr_if.ar_prot   = '0;

  // R signals 
  assign axi_mgr_if.r_ready   = r_ready_s;

  // W signals
  assign axi_mgr_if.w_valid = w_valid_r;
  assign axi_mgr_if.w_user  = '0;
  assign axi_mgr_if.w_data  = (w_valid_r == 1'b1) ?  wr_fifo_data_i : '0;

  // Other signals
  assign r_ready_s      = rd_fifo_req_i; // r_ready determined by rd_fifo_full
  assign rd_fifo_data_o = (r_ready_s && axi_mgr_if.r_valid) ? axi_mgr_if.r_data : '0;
  assign rsp_o          = {rsp_rd_r, rsp_wr_r};
  assign req_wr_s       = req_i[0];
  assign req_rd_s       = req_i[1];
  assign wr_err_o       = wr_err_r;
  assign rd_err_o       = rd_err_r;
  assign wr_fifo_req_o  = ( axi_mgr_if.w_ready & w_valid_r );
  assign rd_fifo_gnt_o  = ( r_ready_s & axi_mgr_if.r_valid );

  /******** WRITE FMS  ********************************************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin : wr_fsm

    if (~rstn_i) begin
    
      axi_mgr_if.aw_addr <= '0;      
      axi_mgr_if.w_strb  <= '0;      
      axi_mgr_if.w_last  <= '0;
      axi_mgr_if.b_ready <= '0;
      aw_valid_r         <= '0;
      w_valid_r          <= '0;
      axi_aw_addr_r      <= '0;
      axi_awlen_r        <= '0;
      wr_beat_count_r    <= '0;
      wr_beats_remain_r  <= '0;
      rsp_wr_r           <= '0;
      wr_c_state_r       <= W_IDLE;

    end else begin

      case (wr_c_state_r)

        W_IDLE: begin

          rsp_wr_r <= 1'b0;

          if (req_wr_s == 1'b1 && wr_data_count_i != '0 && wr_beats_remain_r == '0) begin
            
            axi_aw_addr_r <= axi_wr_addr_i;
            wr_c_state_r  <= AW_INIT;

            if (wr_data_count_i > 256) begin              
              wr_beats_remain_r <= wr_data_count_i - 256;
              wr_beat_count_r   <= 256;
            end else begin 
              wr_beats_remain_r <= '0;
              wr_beat_count_r   <= wr_data_count_i;
            end
          
          // current burst complete, but data remaining
          end else if ( wr_beats_remain_r != '0 ) begin 
            
            wr_c_state_r <= AW_INIT;

            if ( wr_beats_remain_r > 256 ) begin 
              wr_beats_remain_r <= wr_beats_remain_r - 256;
              wr_beat_count_r   <= 256;
            end else begin 
              wr_beat_count_r   <= wr_beats_remain_r;
              wr_beats_remain_r <= '0;
            end

          end
        end

        AW_INIT: begin
          
          axi_mgr_if.aw_addr <= axi_aw_addr_r;
          aw_valid_r         <= 1'b1;
          wr_c_state_r       <= AW;

          // check if data count is a power of 2 and if so, use this as burst
          // length, else use single beat bursts
          if ( ((wr_beat_count_r & (wr_beat_count_r - 1)) == '0) && (wr_beat_count_r != 0)) begin
            axi_awlen_r <= (wr_beat_count_r - 1);
          end else begin
            axi_awlen_r <= '0;
          end
        end

        AW: begin

          if (axi_mgr_if.aw_ready == 1'b1) begin
            
            axi_mgr_if.aw_addr <= '0;
            aw_valid_r         <= 1'b0;
            w_valid_r          <= 1'b1; 
            axi_mgr_if.w_strb  <= '1; // all byte lanes valid
            axi_awlen_r        <= '0;

            // if single beat transaction, got to W_LAST
            if ( axi_awlen_r == '0 ) begin
              axi_mgr_if.w_last <= 1'b1;
              wr_c_state_r      <= W_LAST;
            end else begin
              axi_mgr_if.w_last <= 1'b0;
              wr_c_state_r      <= W;
            end
          end
        end

        W: begin

          if (axi_mgr_if.w_ready == 1'b1) begin

            wr_beat_count_r   <= wr_beat_count_r - 1;
            // TODO: add write FIFO controls
            
            // if it is the second to last beat of the burst
            if ( wr_beat_count_r == 2 ) begin

              axi_mgr_if.w_last <= 1'b1;
              wr_c_state_r      <= W_LAST;

            end else begin

              axi_mgr_if.w_last <= 1'b0;
              wr_c_state_r      <= W;

            end
          end
        end

        W_LAST: begin

          if (axi_mgr_if.w_ready == 1'b1) begin

            w_valid_r          <= 1'b0;
            axi_mgr_if.w_last  <= 1'b0;
            axi_mgr_if.w_strb  <= '0;
            axi_mgr_if.b_ready <= 1'b1;
            wr_beat_count_r    <= wr_beat_count_r - 1;
            wr_c_state_r       <= B_RESP;            

          end
        end

        B_RESP: begin

          if (axi_mgr_if.b_valid == 1'b1) begin

            axi_mgr_if.b_ready <= 1'b0;
            // if not beats remaining in burst,
            // return to IDLE. Else, create new transaction
            if ( wr_beat_count_r == '0 ) begin
              
              rsp_wr_r     <= ( wr_beats_remain_r == '0 ) ? 1'b1 : 1'b0;
              wr_c_state_r <= W_IDLE;

            end else begin

              axi_aw_addr_r <= axi_aw_addr_r + WordSizeBytes; // increment address 
              wr_c_state_r  <= AW_INIT;
            
            end
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
      
      axi_mgr_if.ar_addr <= '0;
      ar_valid_r         <= '0;
      axi_ar_addr_r      <= '0;
      axi_arlen_r        <= '0;
      rd_beat_count_r    <= '0;
      rd_beats_remain_r  <= '0;
      rsp_rd_r           <= '0;
      rd_c_state_r       <= R_IDLE;

    end else begin

      case (rd_c_state_r)

        R_IDLE: begin

          rsp_rd_r <= 1'b0;

          if (req_rd_s == 1'b1 && rd_data_count_i != '0 && rd_beats_remain_r == '0) begin

            axi_ar_addr_r   <= axi_rd_addr_i;
            rd_c_state_r    <= AR_INIT;
            
            if (rd_data_count_i > 256) begin              
              rd_beats_remain_r <= rd_data_count_i - 256;
              rd_beat_count_r   <= 256;
            end else begin 
              rd_beats_remain_r <= '0;
              rd_beat_count_r   <= rd_data_count_i;
            end
            
          end else if ( rd_beats_remain_r != '0 ) begin 

            rd_c_state_r <= AR_INIT;

            if ( rd_beats_remain_r > 256 ) begin 
              rd_beats_remain_r <= rd_beats_remain_r - 256;
              rd_beat_count_r   <= 256;
            end else begin 
              rd_beat_count_r   <= rd_beats_remain_r;
              rd_beats_remain_r <= '0;
            end
          end
        end

        AR_INIT: begin
          axi_mgr_if.ar_addr <= axi_ar_addr_r;
          ar_valid_r         <= 1'b1;
          rd_c_state_r       <= AR;
          
          // check if data count is a power of 2 and if so, use this as burst
          // length, else use single beat bursts
          if ( ((rd_beat_count_r & (rd_beat_count_r - 1)) == '0) && (rd_beat_count_r != 0) ) begin
            axi_arlen_r  <= (rd_beat_count_r - 1);
          end else begin
            axi_arlen_r <= '0;
          end
    
        end

        AR: begin

          if (axi_mgr_if.ar_ready == 1'b1) begin
            
            axi_mgr_if.ar_addr <= '0;
            ar_valid_r         <= 1'b0;
            axi_arlen_r        <= '0;

            // if single beat transaction, got to R_LAST
            if ( axi_arlen_r == '0 ) begin
              rd_c_state_r    <= R_LAST;
            end else begin              
              rd_c_state_r    <= R;
            end
          end
        end

        R: begin

          if (axi_mgr_if.r_valid == 1'b1 && r_ready_s == 1'b1) begin

            rd_beat_count_r <= rd_beat_count_r - 1;
            
            // if it is the second to last beat of the burst
            if ( rd_beat_count_r == 2 ) begin
              
              rd_c_state_r <= R_LAST;
            
            end else begin
              
              rd_c_state_r <= R;
            
            end
          end
        end

        R_LAST: begin
          // RLAST is ignored.
          if (axi_mgr_if.r_valid == 1'b1 && r_ready_s == 1'b1) begin

            rd_beat_count_r <= rd_beat_count_r - 1;

            // if not beats remaining in burst,
            // return to IDLE. Else, create new transaction
            if ( rd_beat_count_r == 1 ) begin
              rsp_rd_r     <= ( rd_beats_remain_r == '0 ) ? 1'b1 : 1'b0;
              rd_c_state_r <= R_IDLE;

            end else begin

              axi_ar_addr_r <= axi_ar_addr_r + WordSizeBytes; // increment address 
              rd_c_state_r  <= AR_INIT; 
            
            end            
          end
        end

        default: begin

          rd_c_state_r <= R_IDLE;

        end

      endcase

    end
  end : rd_fsm

  /******** ERROR MGMT ********************************************************/
  /* Set error to 0 when request is detected. Latch last detected error */
  always_comb begin 
    wr_err_s = ((wr_c_state_r == W_IDLE) && (req_wr_s == 1'b1)) ? '0 :
               (axi_mgr_if.b_resp != '0) ? axi_mgr_if.b_resp : wr_err_r;
    rd_err_s = ((rd_c_state_r == R_IDLE) && (req_rd_s == 1'b1)) ? '0 :
               (axi_mgr_if.r_resp != '0) ? axi_mgr_if.r_resp : rd_err_r;
  end

  always_ff @(posedge clk_i or negedge rstn_i) begin 
    if (~rstn_i) begin 
      req_wr_r <= '0;
      req_rd_r <= '0;
      wr_err_r <= '0;
      rd_err_r <= '0;
    end else begin 
      req_wr_r <= req_wr_s;
      req_rd_r <= req_rd_s;
      wr_err_r <= wr_err_s;
      rd_err_r <= rd_err_s;
    end
  end

  /******* FIFO CTRL PULSE GEN ************************************************/
  

endmodule // axi4_mgr

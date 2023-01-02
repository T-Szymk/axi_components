/*******************************************************************************
-- Title      : AXI-Lite Register Interface
-- Project    : T-Szymk
********************************************************************************
-- File       : axi_lite_registers.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2023-01-01
-- Design     : axi_lite_registers
-- Platform   : -
-- Standard   : SystemVerilog '12
--------------------------------------------------------------------------------
-- Description: AXI4-Lite registers used to control the FPGA implementation of 
--              the AXI4 manager.
-- Register Map:
-- ┌───────┬────────┬────────────────────┐───────┐
-- │  #:   │ OFFSET:│ ID:                │ OP:   │
-- ├───────┼────────┼────────────────────┤───────┤
-- │ 0     │ 0x00   │ enable             │ R/W   | 
-- │       │        │                    │       |
-- │ 1     │ 0x04   │ request            │ R/W   |
-- │       │        │                    │       |
-- │ 2     │ 0x08   │ response + ack     │ R/W   |
-- │       │        │                    │       |
-- │ 3     │ 0x0C   │ axi write addr     │ R/W   |
-- │       │        │                    │       |
-- │ 4     │ 0x10   │ axi read addr      │ R/W   |
-- │       │        │                    │       |
-- │ 5     │ 0x14   │ axi read count     │ R/W   |
-- │       │        │                    │       |
-- │ 6     │ 0x18   │ rd err             │ R/W   |
-- │       │        │                    │       |
-- │ 7     │ 0x1C   │ wr err             │ R/W   |
-- │       │        │                    │       |
-- │ 8     │ 0x20   │ wr fifo data in L  │ R/W   |
-- │       │        │                    │       |
-- │ 9     │ 0x24   │ wr fifo data in H  │ R/W   |
-- │       │        │                    │       |
-- │ 10    │ 0x28   │ wr fifo push       │ R/W   |
-- │       │        │                    │       |
-- │ 11    │ 0x2C   │ wr fifo usage      │ R     |
-- │       │        │                    │       |
-- │ 12    │ 0x30   │ wr fifo status     │ R     |
-- │       │        │                    │       |
-- │ 13    │ 0x34   │ rd fifo data out L │ R     |
-- │       │        │                    │       |
-- │ 14    │ 0x38   │ rd fifo data out H │ R     |
-- │       │        │                    │       |
-- │ 15    │ 0x3C   │ rd fifo pop        │ R/W   |
-- │       │        │                    │       |
-- │ 16    │ 0x40   │ rd fifo usage      │ R     |
-- │       │        │                    │       |
-- │ 17    │ 0x44   │ rd fifo status     │ R     |
-- └───────┴────────┴────────────────────┘───────┘       
-- The AXI write operation takes precedence over a write being performed by the
-- IP. During the AXI handshaking process for the write channel, the IP loses
-- access to registers for a clock cycle. 
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-01-01  1.0      TZS     Created
*******************************************************************************/

module axi_lite_registers #(
  parameter unsigned AXI4_ADDR_WIDTH     =   32,
  parameter unsigned AXI4_DATA_WIDTH     =   64,
  parameter unsigned AXIL_ADDR_WIDTH     =   32,
  parameter unsigned AXIL_DATA_WIDTH     =   32,
  parameter unsigned AXI_ID_WIDTH        =    4,
  parameter unsigned AXI_USER_WIDTH      =    5,
  parameter unsigned BASE_ADDR           =  'h0,
  parameter unsigned DATA_COUNT_WIDTH    =    8,

  localparam integer unsigned AXILSizeBytes = (AXIL_DATA_WIDTH / 8),
  localparam integer unsigned AXI4SizeBytes = (AXI4_DATA_WIDTH / 8)
) (
  input  logic                         clk_i,
  input  logic                         rstn_i,
  // AXI-LITE Signals
  // AW                                                                  
  input  logic [  AXIL_ADDR_WIDTH-1:0] aw_addr_i,
  input  logic [                3-1:0] aw_prot_i,
  input  logic                         aw_valid_i,
  output logic                         aw_ready_o,
  // W                                                                    
  input  logic [  AXIL_DATA_WIDTH-1:0] w_data_i,
  input  logic [    AXILSizeBytes-1:0] w_strb_i,
  input  logic                         w_valid_i,
  output logic                         w_ready_o,
  // B                                                                    
  output logic [                2-1:0] b_resp_o,
  output logic                         b_valid_o,
  input  logic                         b_ready_i,
  // AR                                                                    
  input  logic [  AXIL_ADDR_WIDTH-1:0] ar_addr_i,
  input  logic [                3-1:0] ar_prot_i,
  input  logic                         ar_valid_i,
  output logic                         ar_ready_o,
  // R 
  output  logic [ AXIL_DATA_WIDTH-1:0] r_data_o,
  output  logic [               2-1:0] r_resp_o,
  output  logic                        r_valid_o,
  input   logic                        r_ready_i,
  // IP status + controls
  output logic                         enable_o,
  output logic                         rd_fifo_pop_o,
  output logic                         wr_fifo_push_o,
  output logic [                2-1:0] req_o,
  output logic [  AXIL_ADDR_WIDTH-1:0] axi_wr_addr_o,
  output logic [  AXIL_ADDR_WIDTH-1:0] axi_rd_addr_o,
  output logic [ DATA_COUNT_WIDTH-1:0] rd_data_count_o,
  output logic [  AXI4_DATA_WIDTH-1:0] wr_fifo_data_o,
  input  logic [  AXI4_DATA_WIDTH-1:0] rd_fifo_data_i,
  input  logic [ DATA_COUNT_WIDTH-1:0] wr_fifo_usage_i,
  input  logic [ DATA_COUNT_WIDTH-1:0] rd_fifo_usage_i,
  input  logic                         wr_fifo_full_i,  
  input  logic                         rd_fifo_full_i,
  input  logic                         wr_fifo_empty_i, 
  input  logic                         rd_fifo_empty_i,
  input  logic [                2-1:0] rsp_i,    // bit 1: rd, bit 0: wr
  input  logic [                2-1:0] wr_err_i, // bresp
  input  logic [                2-1:0] rd_err_i // rresp
);
  
  localparam integer unsigned RegisterCount     = 18;
  localparam integer unsigned RegisterSizeBytes = RegisterCount * AXILSizeBytes;
  localparam integer unsigned LocalAddrWidth    = $clog2((RegisterCount * AXILSizeBytes) 
                                                    - AXILSizeBytes );  

  typedef enum logic [LocalAddrWidth-1:0] {
    ENABLE             = 'h00,
    REQUEST            = 'h04,
    RESPONSE           = 'h08,
    AXI_WR_ADDR        = 'h0C,
    AXI_RD_ADDR        = 'h10,
    AXI_RD_COUNT       = 'h14,
    RD_ERR             = 'h18, 
    WR_ERR             = 'h1C,
    WR_FIFO_DATA_IN_L  = 'h20,
    WR_FIFO_DATA_IN_H  = 'h24,
    WR_FIFO_PUSH       = 'h28, 
    WR_FIFO_USAGE      = 'h2C,
    WR_FIFO_STATUS     = 'h30,
    RD_FIFO_DATA_OUT_L = 'h34,
    RD_FIFO_DATA_OUT_H = 'h38,
    RD_FIFO_POP        = 'h3C,
    RD_FIFO_USAGE      = 'h40,
    RD_FIFO_STATUS     = 'h44
  } reg_mapping_t;

  typedef enum { 
    WR_IDLE,
    AW,
    W,
    B
  } c_wr_state_t;

  typedef enum { 
    RD_IDLE,
    AR,
    R
  } c_rd_state_t;

  c_wr_state_t c_wr_state_r;
  c_rd_state_t c_rd_state_r; 

  logic [RegisterSizeBytes-1:0][8-1:0] reg_bank_r;
  
  logic ar_ready_r, aw_ready_r, w_ready_r, b_valid_r, r_valid_r;
  logic [AXIL_DATA_WIDTH-1:0] r_data_s;

  logic [1:0] rsp_s; 
  logic       rsp_ack;

  logic [AXIL_ADDR_WIDTH-1:0] ar_addr_r, aw_addr_r;

  logic [LocalAddrWidth-1:0] local_aw_addr_s, local_ar_addr_s;

  assign ar_ready_o = ar_ready_r;
  assign aw_ready_o = aw_ready_r;
  assign r_valid_o  = r_valid_r;
  assign r_data_o   = r_data_s;
  assign w_ready_o  = w_ready_r;
  assign b_valid_o  = b_valid_r;
  assign b_resp_o   = '0; // error reporting not supported
  assign r_resp_o   = '0;

  assign local_aw_addr_s = (aw_addr_r - BASE_ADDR);
  assign local_ar_addr_s = (ar_addr_r - BASE_ADDR);

  assign r_data_s = (r_valid_r && r_ready_i) ? reg_bank_r[local_ar_addr_s +: AXILSizeBytes] : '0;

/* READ FSM *******************************************************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin
    
    if (~rstn_i) begin 
  
      ar_ready_r   <= '0;
      ar_addr_r    <= '0;  
      r_valid_r    <= '0;       
      c_rd_state_r <= RD_IDLE;
    
    end else begin 
      
      case (c_rd_state_r)
        
      RD_IDLE: begin 
  
          ar_ready_r   <= 1'b1;
          c_rd_state_r <= AR;
  
        end
  
        AR: begin         
  
          if (ar_valid_i) begin 
  
            ar_ready_r   <= 1'b0;
            ar_addr_r    <= ar_addr_i;
            r_valid_r    <= 1'b1;
            c_rd_state_r <= R;
  
          end 
        end
  
        R: begin 
          // read out lowest 
          
          r_valid_r <= 1'b1;
  
          if (r_ready_i) begin 
  
            r_valid_r    <= 1'b0;
            ar_ready_r   <= 1'b1;
            ar_addr_r    <= '0;
            c_rd_state_r <= RD_IDLE;
  
          end
        end
        
        default: begin 
  
          c_rd_state_r <= RD_IDLE;
  
        end
      
      endcase
    end 
  end                
  
  /* WRITE FSM ******************************************************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin
    
    if (~rstn_i) begin 
  
      aw_ready_r   <= '0;
      w_ready_r    <= '0;
      b_valid_r    <= '0;
      aw_addr_r    <= '0;
      c_wr_state_r <= WR_IDLE;
    
    end else begin 
  
      case (c_wr_state_r)
        
        WR_IDLE: begin 
          aw_ready_r   <= 1'b1;
          w_ready_r    <= 1'b1;
          c_wr_state_r <= AW;
        end 
        
        AW: begin 
          
          if (aw_valid_i && !w_valid_i) begin 
            
            aw_ready_r   <= 1'b0;
            aw_addr_r    <= aw_addr_i;
            c_wr_state_r <= W;
            
          end else if (aw_valid_i && w_valid_i) begin 
            
            aw_ready_r   <= 1'b0;
            w_ready_r    <= 1'b0;
            aw_addr_r    <= aw_addr_i;
            b_valid_r    <= 1'b1;
            c_wr_state_r <= B;
  
          end
        end
        
        W: begin
  
          if (w_valid_i) begin 
            
            w_ready_r    <= 1'b0;
            b_valid_r    <= 1'b1;
            c_wr_state_r <= B;
  
          end
        end
        
        B: begin
  
          if (b_ready_i) begin 
            
            b_valid_r    <= 1'b0;
            aw_ready_r   <= 1'b1;
            w_ready_r    <= 1'b1;
            c_wr_state_r <= AW;
  
          end
        end
        
        default: begin 
          
          c_wr_state_r <= WR_IDLE;
        
        end
  
      endcase
    end 
  end

/* REGISTER WRITE LOGIC *******************************************************/

  always_ff @(posedge clk_i or negedge rstn_i) begin 
    
    if (~rstn_i) begin 
  
      reg_bank_r <= '0;
    
    end else begin 
  
      if (w_ready_r && w_valid_i) begin // AXI write logic
  
        case ( local_aw_addr_s )
  
        ENABLE: begin
          reg_bank_r[(ENABLE +1 ) +: (AXILSizeBytes-1)] <= '0;
          reg_bank_r[ENABLE]                            <= {'0, w_data_i[0]}; 
        end
  
        REQUEST: begin 
          reg_bank_r[(REQUEST+1) +: (AXILSizeBytes-1)] <= '0;
          reg_bank_r[REQUEST]                          <= {'0, w_data_i[1:0]};
        end
  
        RESPONSE: begin
          // write ack only and only for a clock cycle
          reg_bank_r[(RESPONSE+1) +: (AXILSizeBytes-1)] <= '0;
          reg_bank_r[RESPONSE]                          <= {'0, w_data_i[0]}; 
        end
  
        AXI_WR_ADDR: begin
          reg_bank_r[AXI_WR_ADDR +: AXILSizeBytes] <= w_data_i; 
        end
  
        AXI_RD_ADDR: begin
          reg_bank_r[AXI_RD_ADDR +: AXILSizeBytes] <= w_data_i; 
        end
  
        AXI_RD_COUNT: begin
          reg_bank_r[AXI_RD_COUNT +: AXILSizeBytes] <= w_data_i;
        end
  
        RD_ERR: begin
          // read only
        end
  
        WR_ERR: begin
          // read only
        end
  
        WR_FIFO_DATA_IN_L: begin
          reg_bank_r[WR_FIFO_DATA_IN_L +: AXILSizeBytes] <= w_data_i;
        end
  
        WR_FIFO_DATA_IN_H: begin
          reg_bank_r[WR_FIFO_DATA_IN_H +: AXILSizeBytes] <= w_data_i;
        end
  
        WR_FIFO_PUSH: begin // note, only set for a single cycle, cleared in else branch
          reg_bank_r[(WR_FIFO_PUSH+1) +: (AXILSizeBytes-1)] <= '0;
          reg_bank_r[WR_FIFO_PUSH]                          <= {'0, w_data_i[0]};
        end
  
        WR_FIFO_USAGE: begin
          // read only
        end
  
        WR_FIFO_STATUS: begin
          // read only
        end
  
        RD_FIFO_DATA_OUT_L: begin
          // read only
        end
  
        RD_FIFO_DATA_OUT_H: begin
          // read only
        end
  
        RD_FIFO_POP: begin // note, only set for a single cycle, cleared in else branch
          reg_bank_r[(RD_FIFO_POP+1) +: (AXILSizeBytes-1)] <= '0;
          reg_bank_r[RD_FIFO_POP]                          <= {'0, w_data_i[0]};
        end
  
        RD_FIFO_USAGE: begin
          // read only
        end
  
        RD_FIFO_STATUS: begin
          // read only
        end
  
        default: begin
        end
          
        endcase
  
      end else begin 
      
        // RESPONSE
        reg_bank_r[RESPONSE][2:1] <= rsp_s;
        reg_bank_r[RESPONSE][0]   <= 1'b0;
        // RD_ERR
        reg_bank_r[RD_ERR +(AXILSizeBytes-1)][1:0] <= rd_err_i;
        // WR_ERR
        reg_bank_r[WR_ERR +(AXILSizeBytes-1)][1:0] <= wr_err_i;
        // WR_FIFO_PUSH
        reg_bank_r[WR_FIFO_PUSH +: (AXILSizeBytes)] <= '0;
        // WR_FIFO_USAGE
        reg_bank_r[WR_FIFO_USAGE +: AXILSizeBytes] <= wr_fifo_usage_i;
        // WR_FIFO_STATUS
        reg_bank_r[WR_FIFO_STATUS][1:0] <= {wr_fifo_full_i, wr_fifo_empty_i};
        // RD_FIFO_POP
        reg_bank_r[RD_FIFO_POP +: (AXILSizeBytes)] <= '0;
        // RD_FIFO_USAGE
        reg_bank_r[RD_FIFO_USAGE +: AXILSizeBytes] <= rd_fifo_usage_i;
        // RD_FIFO_STATUS
        reg_bank_r[RD_FIFO_STATUS][1:0] <= {rd_fifo_full_i, rd_fifo_empty_i};
      
      end
    end
  end

/* RESPONSE ACK LOGIC *********************************************************/

/* Response signals are only set by the IP for a clock cycle. This means that 
   the CPU could miss the response being set. Therefore, the response is 
   latched in the register and can only be cleared by setting the ACK bit in
   the register. Currently the ACK bit clears both read and write response.
   This could potentially change, depending on test results.
*/
  always_comb begin 
    // assign for readability
    rsp_ack = reg_bank_r[RESPONSE][0];

    for (int i = 0; i < 2; i++) begin
      
      if(rsp_ack) begin // clear both if ACK is detected

        rsp_s[i] = 1'b0;

      end else if (~reg_bank_r[RESPONSE][i+1] && rsp_i[i]) begin 

        rsp_s[i] = 1'b1; // latch response to 1 if rising edge is detected

      end else begin

        rsp_s[i] = reg_bank_r[RESPONSE][i+1];

      end
    end
  end

/* OUTPUT ASSIGNMENTS *********************************************************/
  
  assign enable_o        =  reg_bank_r[ENABLE][0];
  assign rd_fifo_pop_o   =  reg_bank_r[RD_FIFO_POP][0];
  assign wr_fifo_push_o  =  reg_bank_r[WR_FIFO_PUSH][0];
  assign req_o           =  reg_bank_r[REQUEST][1:0];
  assign axi_wr_addr_o   =  reg_bank_r[AXI_WR_ADDR +: AXILSizeBytes];
  assign axi_rd_addr_o   =  reg_bank_r[AXI_RD_ADDR +: AXILSizeBytes];
  assign rd_data_count_o =  reg_bank_r[AXI_RD_COUNT +: AXILSizeBytes];
  assign wr_fifo_data_o  = {reg_bank_r[WR_FIFO_DATA_IN_H +: AXILSizeBytes],
                            reg_bank_r[WR_FIFO_DATA_IN_L +: AXILSizeBytes]};

endmodule // axi_lite_registers

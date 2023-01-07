/*******************************************************************************
-- Title      : AXI Components - FPGA FIFO
-- Project    : AXI Components
********************************************************************************
-- File       : fpga_fifo_v3.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-01-07
-- Design     : xilinx_sp_bram
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Adaptation of PULP fifo_v3 for optimal use in Xilinx FPGA 
--              implementation. Clock gating removed and BRAM added to prevent
--              high utilisation of LUT/reg resources.
--              Removed procedural assertions as not currently supported in 
--              Vivado.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2023-01-07  1.0      TZS     Created
*******************************************************************************/

module fpga_fifo_v3 #(
  parameter int unsigned DATA_WIDTH   = 32,   // default data width if the fifo is of type logic
  parameter int unsigned DEPTH        = 8,    // depth can be arbitrary from 0 to 2**32
  // DO NOT OVERWRITE THIS PARAMETER
  localparam integer unsigned AddrDepth   = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
  input  logic                  clk_i,            // Clock
  input  logic                  rst_ni,           // Asynchronous reset active low
  input  logic                  flush_i,          // flush the queue
  input  logic                  testmode_i,       // test_mode to bypass clock gating
  // status flags                       
  output logic                  full_o,           // queue is full
  output logic                  empty_o,          // queue is empty
  output logic [   AddrDepth:0] usage_o,          // fill pointer
  // as long as the queue is not full we can push new data
  input  logic [DATA_WIDTH-1:0] data_i,           // data to push into the queue
  input  logic                  push_i,           // data is valid and can be pushed to the queue
  // as long as the queue is not empty we can pop new elements
  output logic [DATA_WIDTH-1:0] data_o,           // output data
  input  logic                  pop_i             // pop head from queue
);
    // local parameter
    // FIFO depth - handle the case of pass-through, synthesizer will do constant propagation
    localparam int unsigned FifoDepth = (DEPTH > 0) ? DEPTH : 1;
    // write enable for bram
    logic bram_we_s;
    // pointer to the read and write section of the queue
    logic [AddrDepth - 1:0] read_pointer_n, read_pointer_q, write_pointer_n, write_pointer_q;
    // keep a counter to keep track of the current queue status
    // this integer will be truncated by the synthesis tool
    logic [AddrDepth:0] status_cnt_n, status_cnt_q;
    // data out signals
    logic [DATA_WIDTH-1:0] bram_data_out_s, data_out_s, fwft_data_q, fwft_data_n;

    xilinx_sdp_bram #(
      .RAM_WIDTH ( DATA_WIDTH ),
      .RAM_DEPTH ( DEPTH ),
      .INIT_FILE ( "" )
    ) i_fifo_bram(
      .clk_i     ( clk_i           ),            
      .wr_addr_i ( write_pointer_q ),    
      .rd_addr_i ( read_pointer_n  ),    
      .data_i    ( data_i          ),   
      .we_i      ( bram_we_s       ), 
      .en_i      ( 1'b1            ), 
      .data_o    ( bram_data_out_s )   
    );

    assign usage_o = status_cnt_q[AddrDepth:0];
    assign data_o  = (DEPTH == 0) ? data_i : data_out_s;
    
    // status flags
    if (DEPTH == 0) begin : gen_pass_through
        assign empty_o     = ~push_i;
        assign full_o      = ~pop_i;
    end else begin : gen_fifo
        assign full_o       = (status_cnt_q == FifoDepth[AddrDepth:0]);
        assign empty_o      = (status_cnt_q == 0);
    end    

    // read and write queue logic
    always_comb begin : read_write_comb
        // default assignment
        read_pointer_n  = read_pointer_q;
        write_pointer_n = write_pointer_q;
        status_cnt_n    = status_cnt_q;
        bram_we_s       = 1'b0;
        fwft_data_n     = data_i;

        // data_out mux
        if (status_cnt_q == '0) begin 
          data_out_s = '0;
        end else if (status_cnt_q == 'd1) begin 
          data_out_s = fwft_data_q;
        end else begin
          data_out_s = bram_data_out_s;
        end 

        // push a new element to the queue
        if (push_i && ~full_o) begin
            // set bram high to write on next cycle
            bram_we_s = 1'b1;
            // increment the write counter
            if (write_pointer_q == FifoDepth[AddrDepth-1:0] - 1)
                write_pointer_n = '0;
            else
                write_pointer_n = write_pointer_q + 1;
            // increment the overall counter
            status_cnt_n    = status_cnt_q + 1;
        end

        if (pop_i && ~empty_o) begin
            // read from the queue is a default assignment
            // but increment the read pointer...
            if (read_pointer_n == FifoDepth[AddrDepth-1:0] - 1)
              read_pointer_n = '0;
            else
              read_pointer_n = read_pointer_q + 1;
            // ... and decrement the overall count
            status_cnt_n   = status_cnt_q - 1;
        end

        // keep the count pointer stable if we push and pop at the same time
        if (push_i && pop_i &&  ~full_o && ~empty_o)
            status_cnt_n = status_cnt_q;

        // FIFO is in pass through mode -> do not change the pointers
        if ((status_cnt_q == 0) && push_i) begin
            if (pop_i) begin
                status_cnt_n = status_cnt_q;
                read_pointer_n = read_pointer_q;
                write_pointer_n = write_pointer_q;
            end
        end
    end

    // sequential process
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            read_pointer_q  <= '0;
            write_pointer_q <= '0;
            status_cnt_q    <= '0;
            fwft_data_q     <= '0; 
        end else begin
            if (flush_i) begin
                read_pointer_q  <= '0;
                write_pointer_q <= '0;
                status_cnt_q    <= '0;
                fwft_data_q     <= '0;
             end else begin
                if (bram_we_s) begin 
                  fwft_data_q <= fwft_data_n;
                end
                read_pointer_q  <= read_pointer_n;
                write_pointer_q <= write_pointer_n;
                status_cnt_q    <= status_cnt_n;
            end
        end
    end

// pragma translate_off
`ifndef VERILATOR
    initial begin
        assert (DEPTH > 0)             else $error("DEPTH must be greater than 0.");
    end
`endif
// pragma translate_on

endmodule // fpga_fifo_v3

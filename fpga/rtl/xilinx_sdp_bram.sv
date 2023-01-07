/*******************************************************************************
-- Title      : AXI Components - Simple Dual Port BRAM
-- Project    : AXI Components
********************************************************************************
-- File       : xilinx_sp_bram.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-01-07
-- Design     : xilinx_sp_bram
-- Platform   : -
-- Standard   : SystemVerilog '12
********************************************************************************
-- Description: Xilinx template for SDP BRAM
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2023-01-07  1.0      TZS     Created
*******************************************************************************/
module xilinx_sdp_bram #(
  parameter integer RAM_WIDTH =   64,                     // Specify RAM data width
  parameter integer RAM_DEPTH = 1024,                     // Specify RAM depth (number of entries)
  parameter integer INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
)(

  input  logic                           clk_i,     // Clock
  input  logic [$clog2(RAM_DEPTH-1)-1:0] wr_addr_i, // Write address bus, width determined from RAM_DEPTH
  input  logic [$clog2(RAM_DEPTH-1)-1:0] rd_addr_i, // Read address bus, width determined from RAM_DEPTH
  input  logic [          RAM_WIDTH-1:0] data_i,    // RAM input data
  input  logic                           we_i,      // Write enable
  input  logic                           en_i,      // Read Enable, for additional power savings, disable when not in use
  output logic [          RAM_WIDTH-1:0] data_o     // RAM output data
);

  reg [RAM_WIDTH-1:0] bram_r [RAM_DEPTH];
  reg [RAM_WIDTH-1:0] bram_data_s = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: g_use_init_file
      initial
        $readmemh(INIT_FILE, bram_r, 0, RAM_DEPTH-1);
    end else begin: g_init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          bram_r[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always_ff @(posedge clk_i) begin
    if (we_i)
      bram_r[wr_addr_i] <= data_i;
    if (en_i)
      bram_data_s <= bram_r[rd_addr_i];
  end

assign data_o = bram_data_s;

endmodule // xilinx_sdp_bram

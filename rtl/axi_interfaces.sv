/*******************************************************************************
-- Title      : AXI Interfaces
-- Project    : T-Szymk
********************************************************************************
-- File       : axi_interfaces.sv
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-28
-- Design     : axi_interfaces
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: SV interface definitions for AXI
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-28  1.0      TZS     Created
*******************************************************************************/

// An AXI4 interface.
interface axi4_bus_if #(
  parameter int unsigned ADDR_WIDTH = 0,
  parameter int unsigned DATA_WIDTH = 0,
  parameter int unsigned ID_WIDTH   = 0,
  parameter int unsigned USER_WIDTH = 0
);

  localparam int unsigned StrobeWidth = (DATA_WIDTH / 8);

  logic [  ID_WIDTH-1:0] aw_id;
  logic [ADDR_WIDTH-1:0] aw_addr;
  logic [         8-1:0] aw_len;
  logic [         3-1:0] aw_size;
  logic [         2-1:0] aw_burst;
  logic                  aw_lock;
  logic [         4-1:0] aw_cache;
  logic [         3-1:0] aw_prot;
  logic [         4-1:0] aw_qos;
  logic [         4-1:0] aw_region;
  logic [         4-1:0] aw_atop;
  logic [USER_WIDTH-1:0] aw_user;
  logic                  aw_valid;
  logic                  aw_ready;

  logic [ DATA_WIDTH-1:0] w_data;
  logic [StrobeWidth-1:0] w_strb;
  logic                   w_last;
  logic [ USER_WIDTH-1:0] w_user;
  logic                   w_valid;
  logic                   w_ready;

  logic [  ID_WIDTH-1:0] b_id;
  logic          [2-1:0] b_resp;
  logic [USER_WIDTH-1:0] b_user;
  logic                  b_valid;
  logic                  b_ready;

  logic [  ID_WIDTH-1:0] ar_id;
  logic [ADDR_WIDTH-1:0] ar_addr;
  logic [         8-1:0] ar_len;
  logic [         3-1:0] ar_size;
  logic [         2-1:0] ar_burst;
  logic                  ar_lock;
  logic [         4-1:0] ar_cache;
  logic [         3-1:0] ar_prot;
  logic [         4-1:0] ar_qos;
  logic [         4-1:0] ar_region;
  logic [USER_WIDTH-1:0] ar_user;
  logic                  ar_valid;
  logic                  ar_ready;

  logic [  ID_WIDTH-1:0] r_id;
  logic [DATA_WIDTH-1:0] r_data;
  logic [         2-1:0] r_resp;
  logic                  r_last;
  logic [USER_WIDTH-1:0] r_user;
  logic                  r_valid;
  logic                  r_ready;

  modport Manager (
    output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, input aw_ready,
    output w_data, w_strb, w_last, w_user, w_valid, input w_ready,
    input b_id, b_resp, b_user, b_valid, output b_ready,
    output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, input ar_ready,
    input r_id, r_data, r_resp, r_last, r_user, r_valid, output r_ready
  );

  modport Subordinate (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, output aw_ready,
    input w_data, w_strb, w_last, w_user, w_valid, output w_ready,
    output b_id, b_resp, b_user, b_valid, input b_ready,
    input ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, output ar_ready,
    output r_id, r_data, r_resp, r_last, r_user, r_valid, input r_ready
  );

  modport Monitor (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, aw_ready,
          w_data, w_strb, w_last, w_user, w_valid, w_ready,
          b_id, b_resp, b_user, b_valid, b_ready,
          ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, ar_ready,
          r_id, r_data, r_resp, r_last, r_user, r_valid, r_ready
  );

endinterface // axi4_bus_if

/// An AXI4 interface with clk included for driving AXI test components
interface axi4_bus_test_if #(
  parameter int unsigned ADDR_WIDTH = 0,
  parameter int unsigned DATA_WIDTH = 0,
  parameter int unsigned ID_WIDTH   = 0,
  parameter int unsigned USER_WIDTH = 0
) ( 
  input logic clk
);

  localparam int unsigned StrobeWidth = (DATA_WIDTH / 8);

  logic [  ID_WIDTH-1:0] aw_id;
  logic [ADDR_WIDTH-1:0] aw_addr;
  logic [         8-1:0] aw_len;
  logic [         3-1:0] aw_size;
  logic [         2-1:0] aw_burst;
  logic                  aw_lock;
  logic [         4-1:0] aw_cache;
  logic [         3-1:0] aw_prot;
  logic [         4-1:0] aw_qos;
  logic [         4-1:0] aw_region;
  logic [         4-1:0] aw_atop;
  logic [USER_WIDTH-1:0] aw_user;
  logic                  aw_valid;
  logic                  aw_ready;

  logic [ DATA_WIDTH-1:0] w_data;
  logic [StrobeWidth-1:0] w_strb;
  logic                   w_last;
  logic [ USER_WIDTH-1:0] w_user;
  logic                   w_valid;
  logic                   w_ready;

  logic [  ID_WIDTH-1:0] b_id;
  logic          [2-1:0] b_resp;
  logic [USER_WIDTH-1:0] b_user;
  logic                  b_valid;
  logic                  b_ready;

  logic [  ID_WIDTH-1:0] ar_id;
  logic [ADDR_WIDTH-1:0] ar_addr;
  logic [         8-1:0] ar_len;
  logic [         3-1:0] ar_size;
  logic [         2-1:0] ar_burst;
  logic                  ar_lock;
  logic [         4-1:0] ar_cache;
  logic [         3-1:0] ar_prot;
  logic [         4-1:0] ar_qos;
  logic [         4-1:0] ar_region;
  logic [USER_WIDTH-1:0] ar_user;
  logic                  ar_valid;
  logic                  ar_ready;

  logic [  ID_WIDTH-1:0] r_id;
  logic [DATA_WIDTH-1:0] r_data;
  logic [         2-1:0] r_resp;
  logic                  r_last;
  logic [USER_WIDTH-1:0] r_user;
  logic                  r_valid;
  logic                  r_ready;

  modport Manager (
    output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, input aw_ready,
    output w_data, w_strb, w_last, w_user, w_valid, input w_ready,
    input b_id, b_resp, b_user, b_valid, output b_ready,
    output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, input ar_ready,
    input r_id, r_data, r_resp, r_last, r_user, r_valid, output r_ready
  );

  modport Subordinate (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, output aw_ready,
    input w_data, w_strb, w_last, w_user, w_valid, output w_ready,
    output b_id, b_resp, b_user, b_valid, input b_ready,
    input ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, output ar_ready,
    output r_id, r_data, r_resp, r_last, r_user, r_valid, input r_ready
  );

  modport Monitor (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, aw_ready,
          w_data, w_strb, w_last, w_user, w_valid, w_ready,
          b_id, b_resp, b_user, b_valid, b_ready,
          ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, ar_ready,
          r_id, r_data, r_resp, r_last, r_user, r_valid, r_ready
  );

endinterface // axi4_bus_if

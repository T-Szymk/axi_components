/*******************************************************************************
-- Title      : AXI4 tester
-- Project    : T-Szymk
********************************************************************************
-- File       : axi4_test_pkg.svh
-- Author(s)  : Tom Szymkowiak
-- Company    : TUNI
-- Created    : 2022-12-28
-- Design     : axi4_test_pkg
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Package to include functions which can be used to test AXI4. 
--              Main aim of this design is to create a test package which can be
--              used across multiple EDA tools e.g. Vivado, Verilator, Icarus 
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-12-28  1.0      TZS     Created
*******************************************************************************/

package axi4_test_pkg;

  timeunit 1ns/1ps;

  /* CHANNEL SIGNALS **********************************************************/

  class ARSignalsAXI4 #(
    parameter unsigned ID_WIDTH   =  8,
    parameter unsigned ADDR_WIDTH = 32,
    parameter unsigned USER_WIDTH =  1
  );

    rand logic [  ID_WIDTH-1:0] ar_id     = '0;
    rand logic [ADDR_WIDTH-1:0] ar_addr   = '0;
    logic      [         8-1:0] ar_len    = '0;
    logic      [         3-1:0] ar_size   = '0;
    logic      [         2-1:0] ar_burst  = '0;
    logic                       ar_lock   = '0;
    logic      [         4-1:0] ar_cache  = '0;
    logic      [         3-1:0] ar_prot   = '0;
    rand logic [         4-1:0] ar_qos    = '0;
    logic      [         4-1:0] ar_region = '0;
    rand logic [USER_WIDTH-1:0] ar_user   = '0;

  endclass // ARSignalsAXI4

  class RSignalsAXI4 #(
    parameter unsigned ID_WIDTH   =  8,
    parameter unsigned DATA_WIDTH = 32,
    parameter unsigned USER_WIDTH =  1
  );

    rand logic [  ID_WIDTH-1:0] r_id   = '0;
    rand logic [DATA_WIDTH-1:0] r_data = '0;
    rand logic [         2-1:0] r_resp = '0;
    logic                       r_last = '0;
    rand logic [USER_WIDTH-1:0] r_user = '0;

  endclass // RSignalsAXI4

  class AWSignalsAXI4 #(
    parameter unsigned ID_WIDTH   =  8,
    parameter unsigned ADDR_WIDTH = 32,
    parameter unsigned USER_WIDTH =  1
  );

    rand logic [  ID_WIDTH-1:0] aw_id     = '0;
    rand logic [ADDR_WIDTH-1:0] aw_addr   = '0;
    logic      [         8-1:0] aw_len    = '0;
    logic      [         3-1:0] aw_size   = '0;
    logic      [         2-1:0] aw_burst  = '0;
    logic                       aw_lock   = '0;
    logic      [         4-1:0] aw_cache  = '0;
    logic      [         3-1:0] aw_prot   = '0;
    rand logic [         4-1:0] aw_qos    = '0;
    logic      [         4-1:0] aw_region = '0;
    logic      [         4-1:0] aw_atop   = '0;
    rand logic [USER_WIDTH-1:0] aw_user   = '0;

  endclass // AWSignalsAXI4

  class WSignalsAXI4 #(
    parameter unsigned DATA_WIDTH = 32,
    parameter unsigned USER_WIDTH =  1
  );

    rand logic [    DATA_WIDTH-1:0] w_data = '0;
    rand logic [(DATA_WIDTH/8)-1:0] w_strb = '0;
    logic                           w_last = '0;
    rand logic [    USER_WIDTH-1:0] w_user = '0;

  endclass // WSignalsAXI4

  class BSignalsAXI4 #(
    parameter unsigned ID_WIDTH   = 8,
    parameter unsigned USER_WIDTH = 1
  );

    rand logic [  ID_WIDTH-1:0] b_id   = '0;
    rand logic [         2-1:0] b_resp = '0;
    rand logic [USER_WIDTH-1:0] b_user = '0;

  endclass // BSignalsAXI4

  /* AXI4 SUBORDINATE *********************************************************/

  class SubAXI4 #(
    parameter unsigned ID_WIDTH     =   8,
    parameter unsigned ADDR_WIDTH   =  32,
    parameter unsigned DATA_WIDTH   =  32,
    parameter unsigned USER_WIDTH   =   1,
    parameter time     ASSIGN_DELAY =   0ps,
    parameter time     EXEC_DELAY   = 500ps
  );

    virtual axi4_bus_test_if #(
      .ADDR_WIDTH ( ADDR_WIDTH ),
      .DATA_WIDTH ( DATA_WIDTH ),
      .ID_WIDTH   ( ID_WIDTH   ),
      .USER_WIDTH ( USER_WIDTH )
    ) axi4;

    ARSignalsAXI4 #(
      .ID_WIDTH   ( ID_WIDTH   ),  
      .ADDR_WIDTH ( ADDR_WIDTH ),    
      .USER_WIDTH ( USER_WIDTH ) 
    ) ar_queue [$];

    AWSignalsAXI4 #(
      .ID_WIDTH   ( ID_WIDTH   ),
      .ADDR_WIDTH ( ADDR_WIDTH ),  
      .USER_WIDTH ( USER_WIDTH )  
    ) aw_queue [$];

    BSignalsAXI4 #(
      .ID_WIDTH   ( ID_WIDTH   ),     
      .USER_WIDTH ( USER_WIDTH )       
    ) b_queue  [$];

    function new(
      virtual axi4_bus_test_if #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH ),
        .ID_WIDTH   ( ID_WIDTH   ),
        .USER_WIDTH ( USER_WIDTH )
      ) axi4
    );
      this.axi4 = axi4;
    endfunction

    function automatic void reset;

      this.axi4.ar_ready  <= '0;

      this.axi4.r_id      <= '0;
      this.axi4.r_data    <= '0;
      this.axi4.r_resp    <= '0;
      this.axi4.r_last    <= '0;
      this.axi4.r_user    <= '0;
      this.axi4.r_valid   <= '0;

      this.axi4.aw_ready  <= '0;

      this.axi4.w_ready   <= '0;

      this.axi4.b_id      <= '0;
      this.axi4.b_resp    <= '0;
      this.axi4.b_user    <= '0;
      this.axi4.b_valid   <= '0;

    endfunction // reset

    task automatic receive_ar;

      automatic ARSignalsAXI4 #(
        .ID_WIDTH   ( ID_WIDTH   ),  
        .ADDR_WIDTH ( ADDR_WIDTH ),    
        .USER_WIDTH ( USER_WIDTH ) 
      ) ar_signals = new();

      this.axi4.ar_ready = #(ASSIGN_DELAY) 1'b1;
      
      #(EXEC_DELAY);
      // wait for handshake
      while (this.axi4.ar_valid != 1'b1) begin        
        @(posedge this.axi4.clk);
        #(EXEC_DELAY);
      end

      ar_signals.ar_id     = this.axi4.ar_id;  
      ar_signals.ar_addr   = this.axi4.ar_addr;    
      ar_signals.ar_len    = this.axi4.ar_len;   
      ar_signals.ar_size   = this.axi4.ar_size;    
      ar_signals.ar_burst  = this.axi4.ar_burst;     
      ar_signals.ar_lock   = this.axi4.ar_lock;    
      ar_signals.ar_cache  = this.axi4.ar_cache;     
      ar_signals.ar_prot   = this.axi4.ar_prot;    
      ar_signals.ar_qos    = this.axi4.ar_qos;   
      ar_signals.ar_region = this.axi4.ar_region;      
      ar_signals.ar_user   = this.axi4.ar_user;              
      
      @(posedge this.axi4.clk);
      this.ar_queue.push_back(ar_signals);
      this.axi4.ar_ready = #(ASSIGN_DELAY) 1'b0;

    endtask // receive_ar

    task automatic transmit_r;

      automatic ARSignalsAXI4 #(
        .ID_WIDTH   ( ID_WIDTH   ),  
        .ADDR_WIDTH ( ADDR_WIDTH ),    
        .USER_WIDTH ( USER_WIDTH ) 
      ) ar_signals;

      automatic RSignalsAXI4 # (
        .ID_WIDTH   ( ID_WIDTH   ),
        .DATA_WIDTH ( DATA_WIDTH ),  
        .USER_WIDTH ( USER_WIDTH )  
      ) r_signals = new();

      automatic int beat_counter;   

      wait (ar_queue.size() > 0);

      ar_signals = this.ar_queue.pop_back();
      // ToDo: Add logic to manipulate r_signals depending on ar_signal vals
 
      beat_counter = ar_signals.ar_len + 1;

      while (beat_counter > 0) begin

        this.axi4.r_valid = #(ASSIGN_DELAY) 1'b1;
        this.axi4.r_id    = #(ASSIGN_DELAY) ar_signals.ar_id;
        this.axi4.r_data  = #(ASSIGN_DELAY) {16'hABCD, beat_counter[16-1:0]}; // Use beat count
        this.axi4.r_resp  = #(ASSIGN_DELAY) '0;     // OKAY
        this.axi4.r_user  = #(ASSIGN_DELAY) ar_signals.ar_user;
        
        this.axi4.r_last  = #(ASSIGN_DELAY) (beat_counter == 1) ? 1'b1 : 1'b0;
        
        #(EXEC_DELAY);
        // wait for handshake
        while (this.axi4.r_ready != 1'b1) begin          
          @(posedge this.axi4.clk);
          #(EXEC_DELAY);
        end

        beat_counter = beat_counter - 1;

        @(posedge this.axi4.clk);
      
      end
    
      this.axi4.ar_valid <= #(ASSIGN_DELAY) 1'b0;

    endtask // transmit_r

    task automatic receive_aw;

      automatic AWSignalsAXI4 #(
        .ID_WIDTH   ( ID_WIDTH   ),
        .ADDR_WIDTH ( ADDR_WIDTH ),  
        .USER_WIDTH ( USER_WIDTH )  
      ) aw_signals = new();

      this.axi4.ar_ready = #(ASSIGN_DELAY) 1'b1;
      
      #(EXEC_DELAY);
      // wait for handshake
      while (this.axi4.aw_valid != 1'b1) begin        
        @(posedge this.axi4.clk);
        #(EXEC_DELAY);
      end

      aw_signals.aw_id     = this.axi4.aw_id;  
      aw_signals.aw_addr   = this.axi4.aw_addr;    
      aw_signals.aw_len    = this.axi4.aw_len;   
      aw_signals.aw_size   = this.axi4.aw_size;    
      aw_signals.aw_burst  = this.axi4.aw_burst;     
      aw_signals.aw_lock   = this.axi4.aw_lock;    
      aw_signals.aw_cache  = this.axi4.aw_cache;     
      aw_signals.aw_prot   = this.axi4.aw_prot;    
      aw_signals.aw_qos    = this.axi4.aw_qos;   
      aw_signals.aw_region = this.axi4.aw_region;
      aw_signals.aw_atop   = this.axi4.aw_atop;   
      aw_signals.aw_user   = this.axi4.aw_user;              
      
      @(posedge this.axi4.clk);
      this.aw_queue.push_back(aw_signals);
      this.axi4.aw_ready = #(ASSIGN_DELAY) 1'b0;

    endtask // receive_aw

    task automatic receive_w;

      automatic AWSignalsAXI4 #(
        .ID_WIDTH   ( ID_WIDTH   ),
        .ADDR_WIDTH ( ADDR_WIDTH ),  
        .USER_WIDTH ( USER_WIDTH )  
      ) aw_signals;

      automatic WSignalsAXI4 #(
        .DATA_WIDTH ( DATA_WIDTH ),
        .USER_WIDTH ( USER_WIDTH )
      )  w_signals = new();

      automatic BSignalsAXI4 #(
        .ID_WIDTH   ( ID_WIDTH   ),     
        .USER_WIDTH ( USER_WIDTH )       
      )  b_signals = new();

      automatic int beat_counter;   

      wait (aw_queue.size() > 0);

      aw_signals = this.aw_queue.pop_back();
      // ToDo: Add logic to manipulate w_signals depending on aw_signal vals

      w_signals.w_user = aw_signals.aw_user;
 
      beat_counter = aw_signals.aw_len + 1;

      while (beat_counter > 0) begin

        this.axi4.w_ready = #(ASSIGN_DELAY) 1'b1;
        this.axi4.w_strb  = #(ASSIGN_DELAY) '1; // full beats only
        this.axi4.w_data  = #(ASSIGN_DELAY) {16'hABCD, beat_counter[16-1:0]}; // Use beat count
        this.axi4.w_user  = #(ASSIGN_DELAY) aw_signals.aw_user;
        
        w_signals.w_last  = #(ASSIGN_DELAY) this.axi4.w_last;
        // Todo: Add check to ensure last is only high on final beat
        
        #(EXEC_DELAY);
        // wait for handshake
        while (this.axi4.r_ready != 1'b1) begin          
          @(posedge this.axi4.clk);
          #(EXEC_DELAY);
        end

        beat_counter = beat_counter - 1;

        @(posedge this.axi4.clk);
      
      end

      b_signals.b_id   = aw_signals.aw_id;
      b_signals.b_resp = '0; // OKAY
      b_signals.b_user = w_signals.w_user;

      this.b_queue.push_back(b_signals);
    
      this.axi4.ar_valid <= #(ASSIGN_DELAY) 1'b0;

    endtask // receive_w

    task automatic transmit_b;

      automatic BSignalsAXI4 #(
        .ID_WIDTH   ( ID_WIDTH   ),     
        .USER_WIDTH ( USER_WIDTH )       
      )  b_signals;

      wait (b_queue.size() > 0);

      b_signals = this.b_queue.pop_back();
      
      this.axi4.b_valid = #(ASSIGN_DELAY) 1'b1;       
      this.axi4.b_id    = #(ASSIGN_DELAY) b_signals.b_id;   
      this.axi4.b_resp  = #(ASSIGN_DELAY) b_signals.b_resp;      
      this.axi4.b_user  = #(ASSIGN_DELAY) b_signals.b_user;  
      
      #(EXEC_DELAY);
      // wait for handshake
      while (this.axi4.b_ready != 1'b1) begin          
        @(posedge this.axi4.clk);
        #(EXEC_DELAY);
      end

      @(posedge this.axi4.clk);
      this.axi4.b_valid <= #(ASSIGN_DELAY) 1'b0;

    endtask // transmit_b

    task automatic run;
    fork 
      forever
        this.receive_ar();
      forever
        this.transmit_r();
      forever
        this.receive_aw();
      forever
        this.receive_w();
      forever
        this.transmit_b();
    join
    endtask

  endclass // SubAXI4

endpackage // axi4_test_pkg

//
// Copyright 2021 Developed by Reza Molaei
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

module top (
   // 24 MHz osc
   input        clock,
   // Push-Buttons
   input        push_button,
   // LEDs
   output [7:0] leds,
   // SPI (Slave)
   inout        slave_sclk,
   input        slave_cs,
   input        slave_mosi,
   output       slave_miso,
   // SPI (Master)
   output       master_sclk,
   output       master_cs,
   output       master_mosi,
   input        master_miso
);

//###############################################################################################
//###                              clock and reset                                            ###
//###############################################################################################
   wire rst;
   por_gen por_gen (
      .clk(clock),
      .reset_out(rst)
   );
//###############################################################################################
//###                              END clock and reset                                        ###
//###############################################################################################

//###############################################################################################
//###                              SPI_SLAVE instantution                                     ###
//###############################################################################################
   reg  [7:0] SPI_SLAVE_din;
   wire [7:0] SPI_SLAVE_dout;
   wire SPI_SLAVE_din_vld, SPI_SLAVE_ready, SPI_SLAVE_dout_vld;
   SPI_SLAVE SPI_SLAVE (
      .CLK      (clock),              // system clock
      .RST      (rst),                // high active synchronous reset
      // SPI SLAVE INTERFACE
      .SCLK     (slave_sclk),         // SPI clock
      .CS_N     (slave_cs),           // SPI chip select, active in low
      .MOSI     (slave_mosi),         // SPI serial data from master to slave
      .MISO     (slave_miso),         // SPI serial data from slave to master
      // USER INTERFACE
      .DIN      (SPI_SLAVE_din),      // input data for SPI master
      .DIN_VLD  (SPI_SLAVE_din_vld),  // when DIN_VLD = 1, input data are valid
      .READY    (SPI_SLAVE_ready),    // when READY = 1, valid input data are accept
      .DOUT     (SPI_SLAVE_dout),     // output data from SPI master
      .DOUT_VLD (SPI_SLAVE_dout_vld)  // when DOUT_VLD = 1, output data are valid
   );
   assign leds = SPI_SLAVE_din;
   assign SPI_SLAVE_din_vld = ~rst;
   always @(posedge clock)
      if(rst)
         SPI_SLAVE_din <= -1;
      else if (SPI_SLAVE_dout_vld)
         SPI_SLAVE_din <= SPI_SLAVE_dout;
//###############################################################################################
//###                              END SPI_SLAVE instantution                                 ###
//###############################################################################################

//###############################################################################################
//###                              SPI_MASTER instantution                                    ###
//###############################################################################################
   reg [7:0] SPI_MASTER_din = 0;
   reg SPI_MASTER_din_last = 1'b0;
   wire SPI_MASTER_din_vld;
   wire SPI_MASTER_ready;
   wire [7:0] SPI_MASTER_dout;
   wire SPI_MASTER_dout_vld;
   SPI_MASTER #(
      .CLK_FREQ    (24000000), // set system clock frequency in Hz
      .SCLK_FREQ   (100000),   // set SPI clock frequency in Hz (condition: SCLK_FREQ <= CLK_FREQ/10)
      .SLAVE_COUNT (1)         // count of SPI slaves
   ) SPI_MASTER (
      .CLK      (clock),               // system clock
      .RST      (rst),                 // high active synchronous reset
      // SPI MASTER INTERFACE
      .SCLK     (master_sclk),         // SPI clock
      .CS_N     (master_cs),           // SPI chip select, active in low
      .MOSI     (master_mosi),         // SPI serial data from master to slave
      .MISO     (master_miso),         // SPI serial data from slave to master
      // INPUT USER INTERFACE
      .ADDR     (1'b0),                   // SPI slave address
      .DIN      (SPI_MASTER_din),      // input data for SPI slave
      .DIN_LAST (SPI_MASTER_din_last), // when DIN_LAST = 1, after transmit these input data is asserted CS_N
      .DIN_VLD  (SPI_MASTER_din_vld),  // when DIN_VLD = 1, input data are valid
      .READY    (SPI_MASTER_ready),    // when READY = 1, valid input data are accept
      // OUTPUT USER INTERFACE
      .DOUT     (SPI_MASTER_dout),     // output data from SPI slave
      .DOUT_VLD (SPI_MASTER_dout_vld)  // when DOUT_VLD = 1, output data are valid
   );

   reg state = 1'b0;
   always @(posedge clock)
      if(rst)
         state <= 1'b0;
      else if(push_button==1'b0 && state==1'b0)
         state <= 1'b1;

   reg [24:0] SPI_MASTER_countr = 0;
   always @(posedge clock)
      if(rst) begin
         SPI_MASTER_din    <= 0;
         SPI_MASTER_countr <= 0;
      end else if(state && SPI_MASTER_ready) begin
         if(SPI_MASTER_countr==10) begin
            SPI_MASTER_din <= SPI_MASTER_din + 1;
         end
         SPI_MASTER_countr <= SPI_MASTER_countr + 1;
      end
   assign SPI_MASTER_din_vld = ( SPI_MASTER_countr==5 ? 1'b1 : 1'b0 );
//###############################################################################################
//###                              END SPI_MASTER instantution                                ###
//###############################################################################################

endmodule // top

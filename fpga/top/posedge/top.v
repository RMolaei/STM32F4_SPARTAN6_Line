//
// Copyright 2021 Developed by Reza Molaei
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

module top (
   // 24 MHz osc
   input        clock,
   // LEDs
   output [7:0] leds,
   // SPI (Slave)
   inout        sclk,
   input        cs,
   input        mosi,
   output       miso
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
      .SCLK     (sclk),               // SPI clock
      .CS_N     (cs),                 // SPI chip select, active in low
      .MOSI     (mosi),               // SPI serial data from master to slave
      .MISO     (miso),               // SPI serial data from slave to master
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

endmodule // top

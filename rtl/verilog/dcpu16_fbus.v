/*
 DCPU16 Verilog Implementation
 Copyright (C) 2012 Shawn Tan <shawn.tan@sybreon.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.  This program is
 distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this program.  If not, see
 <http://www.gnu.org/licenses/>.  */

/*
 FS BUS
 
 Handles the FETCH and STORE memory operations.
 PHA0 - Fetch instruction (if needed)
 PHA1 - Store data (if needed) 
 
 */

module dcpu16_fbus (/*AUTOARG*/
   // Outputs
   fs_adr, fs_dto, regPC, fs_ena,
   // Inputs
   fs_dti, fs_ack, skp, ab_fs, regR, ireg, clk, pha, rst, ena
   );

   // Simplified Wishbone
   output [15:0] fs_adr;
   output 	 fs_stb,
		 fs_wre;
   output [15:0] fs_dto;  
   input [15:0]  fs_dti;
   input 	 fs_ack;   

   // internal
   output [15:0] regPC; 
   output 	 fs_ena;
   input 	 skp;   
   input [15:0]  ab_fs;
   input [15:0]  regR;
   input [15:0]  ireg;   
   
   input 	 clk,
		 pha,
		 rst,
		 ena;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [15:0]		fs_adr;
   reg [15:0]		regPC;
   // End of automatics

   wire [3:0] 		decO;
   wire [5:0] 		decA, decB;
     
   assign {decB, decA, decO} = ireg;   

   wire 		skpA, skpB;
   assign skpA = (decA[5:3] == 3'o2) | (decA[5:1] == 5'h0F);
   assign skpB = (decB[5:3] == 3'o2) | (decB[5:1] == 5'h0F); 
   
   assign fs_ena = fs_stb;   
   assign fs_dto = regR; // data write from ALU pass-thru   
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	fs_adr <= 16'h0;
	fs_stb <= 1'h0;
	fs_wre <= 1'h0;
	// End of automatics
     end else if (ena) begin	
	fs_adr <= (pha) ? regPC : ab_fs;
	fs_stb <= (pha) ? 1'b1 : 1'b0; // FIXME: STORE
	fs_wre <= (pha) ? 1'b0 : 1'b0; // FIXME: STORE	 
     end

   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	regPC <= 16'h0;
	// End of automatics
     end else if (ena) begin
	if ((pha & !skpA & !skpB) | (!pha & skpB))
	  regPC <= regPC + 1;	
     end
   
   
endmodule // dcpu16_abus

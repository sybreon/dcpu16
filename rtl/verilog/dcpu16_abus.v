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
 AB BUS
 
 Handles the LOAD-A and LOAD-B memory transactions.
 PHA0 - Load A (if needed)
 PHA1 - Load B (if needed)
 */

module dcpu16_abus (/*AUTOARG*/
   // Outputs
   ab_adr, ab_stb, ab_ena, ab_wre, regSP, regA, regB, ab_fs, src, tgt,
   // Inputs
   ab_dti, ab_ack, rrd, regPC, regO, ea, clk, pha, rst, ena
   );

   // Simplified Wishbone
   output [15:0] ab_adr;
   output 	 ab_stb,
		 ab_ena,
		 ab_wre;
   //output [15:0] ab_dto;  
   input [15:0]  ab_dti;
   input 	 ab_ack;   

   // internal
   output [15:0] regSP;
   output [15:0] regA,
		 regB;
   
   output [15:0] ab_fs;   
   input [15:0]  rrd;
   input [15:0]  regPC;
   input [15:0]  regO;   
   input [5:0] 	 ea;

   output [15:0] src,
		 tgt;   
   
   input 	 clk,
		 pha,
		 rst,
		 ena;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [15:0]		ab_adr;
   reg [15:0]		ab_fs;
   reg			ab_stb;
   reg [15:0]		regA;
   reg [15:0]		regB;
   reg [15:0]		regSP;
   reg [15:0]		src;
   reg [15:0]		tgt;
   // End of automatics

   reg [15:0] 		_rrd;   
   
   // READ-ONLY OPERATIONS
   assign ab_wre = 1'b0;
   assign ab_dto = 16'hX;   
   assign ab_ena = ab_stb;
   
   // calculator
   /*
    0x00-0x07: register (A, B, C, X, Y, Z, I or J, in that order)
    0x08-0x0f: [register]
    0x10-0x17: [next word + register]
         0x18: POP / [SP++]
         0x19: PEEK / [SP]
         0x1a: PUSH / [--SP]
         0x1b: SP
         0x1c: PC
         0x1d: O
         0x1e: [next word]
         0x1f: next word (literal)
    0x20-0x3f: literal value 0x00-0x1f (literal)
    */
   reg [5:0] 		_ea;
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_ea <= 6'h0;
	ab_adr <= 16'h0;
	ab_stb <= 1'h0;
	regA <= 16'h0;
	regB <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (ea[5:3])
	  3'o1: {ab_stb, ab_adr} <= {1'b1, rrd};
	  3'o2: {ab_stb, ab_adr} <= {1'b1, rrd + regPC};
	  3'o3: case (ea[2:0])
		  3'o0: {ab_stb, ab_adr} <= {1'b1, regSP};		  
		  3'o1: {ab_stb, ab_adr} <= {1'b1, regSP};		  
		  3'o2: {ab_stb, ab_adr} <= {1'b1, (regSP + 16'hFFFF)};		  
		  3'o7: {ab_stb, ab_adr} <= {1'b1, regPC};		  
		  3'o6: {ab_stb, ab_adr} <= {1'b1, regPC};		  
		  default: {ab_stb, ab_adr} <= {1'b0, 16'hX};		  
		endcase // case (ea[2:0])	  
	  default: {ab_stb, ab_adr} <= {1'b0, 16'hX};	  
	endcase // case (ea[5:3])

	if (pha)
	case (_ea[5:3])
	  3'o0: regB <= _rrd;	  
	  3'o3: case (_ea[2:0])
		  3'o3: regB <= regSP;
		  3'o4: regB <= regPC;
		  3'o5: regB <= regO;		 
		  default: regB <= ab_dti;		  
		endcase // case (ea[2:0])	  
	  default: regB <= ab_dti;		  
	endcase // case (ea[5:3])
	else
	case (_ea[5:3])
	  3'o0: regA <= _rrd;	  
	  3'o3: case (_ea[2:0])
		  3'o3: regA <= regSP;
		  3'o4: regA <= regPC;
		  3'o5: regA <= regO;		 
		  default: regA <= ab_dti;		  
		endcase // case (ea[2:0])	  
	  default: regA <= ab_dti;		  
	endcase // case (ea[5:3])

	_ea <= ea;
	
     end

   
   // pass-thru
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	ab_fs <= 16'h0;
	// End of automatics
     end else if (!pha) begin
	ab_fs <= ab_adr;	
     end
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_rrd <= 16'h0;
	// End of automatics
     end else if (ena) begin
	_rrd <= rrd;	
     end
   
   
endmodule // dcpu16_abus

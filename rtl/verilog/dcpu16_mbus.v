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
 MEMORY BUS

 Handles *all* the memory control signals for both F-BUS and A-BUS. 
 */

module dcpu16_mbus (/*AUTOARG*/
   // Outputs
   g_adr, g_stb, g_wre, f_adr, f_stb, f_wre, ena, regSP, regPC, regA,
   regB, src, tgt,
   // Inputs
   g_dti, g_ack, f_dti, f_ack, rrd, ireg, regO, pha, clk, rst
   );

   // Simplified Wishbone
   output [15:0] g_adr;
   output 	 g_stb,
		 g_wre;
   input [15:0]  g_dti;
   input 	 g_ack;   

   // Simplified Wishbone
   output [15:0] f_adr;
   output 	 f_stb,
		 f_wre;
   input [15:0]  f_dti;
   input 	 f_ack;   
   
   // internal
   output 	 ena;   
   output [15:0] regSP,
		 regPC;
   output [15:0] regA,
		 regB;
   
   input [15:0]  rrd;
   input [15:0]  ireg;   
   input [15:0]  regO;   

   output [15:0] src,
		 tgt;   

   input [1:0] 	 pha;   
   input 	 clk,
		 rst;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [15:0]		f_adr;
   reg			f_stb;
   reg			f_wre;
   reg [15:0]		g_adr;
   reg			g_stb;
   reg [15:0]		regA;
   reg [15:0]		regB;
   reg [15:0]		regPC;
   reg [15:0]		regSP;
   reg [15:0]		src;
   reg [15:0]		tgt;
   // End of automatics

   assign ena = (f_stb ~^ f_ack) & (g_stb ~^ g_ack); // pipe stall

   // repeated decoder
   wire [5:0] 		decA, decB;
   wire [3:0] 		decO;   
   assign {decB, decA, decO} = ireg;   
  
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

   // decode EA
   wire 		Adir = (decA[5:3] == 3'o0);
   wire 		Bdir = (decB[5:3] == 3'o0);   
   wire 		Aind = (decA[5:3] == 3'o1);
   wire 		Bind = (decB[5:3] == 3'o1);
   wire 		Anwr = (decA[5:3] == 3'o2);
   wire 		Bnwr = (decB[5:3] == 3'o2);
   wire 		Aspr = (decA[5:0] == 6'h18) | (decA[5:0] == 6'h19) | (decA[5:0] == 6'h1A);
   wire 		Bspr = (decB[5:0] == 6'h18) | (decB[5:0] == 6'h19) | (decB[5:0] == 6'h1A);
   wire 		Anwi = (decA[5:0] == 6'h1E);
   wire 		Bnwi = (decB[5:0] == 6'h1E);
   wire 		Anwl = (decA[5:0] == 6'h1F);
   wire 		Bnwl = (decB[5:0] == 6'h1F);   

   wire 		incA = Anwr | Anwi | Anwl;
   wire 		incB = Bnwr | Bnwi | Bnwl;   


   
   
   // PROGRAMME COUNTER
   reg 			_rd;   
   wire [15:0] 		_regPC = regPC + 1; // incrementer   
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_rd <= 1'h0;
	regPC <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o1: _rd <= Adir;
	  2'o2: _rd <= Bdir;	  
	  default: _rd <= 1'b0;	  
	endcase // case (pha)
	
	case (pha)
	  2'o2: regPC <= _regPC; // normal PC increment due to FETCH
	  2'o3: regPC <= (incA) ? _regPC : regPC;
	  2'o0: regPC <= (incB) ? _regPC : regPC;
	  default: regPC <= regPC;	  
	endcase // case (pha)	
     end
   
   // calculator

   // EA CALCULATOR
   wire [15:0] nwr = rrd + regPC;   // FIXME: Reduce this and combine with other ALU
   reg [15:0] ea, eb;
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	ea <= 16'h0;
	eb <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o0: case (decA[4:1])
		  4'hF: ea <= (decA[0]) ? g_adr : g_dti; // 0x1E;
		  4'hC,4'hD: ea <= regSP; // FIXME: SP calculator
		  4'h8,4'h9,4'hA,4'hB: ea <= nwr;
		  4'h4,4'h5,4'h6,4'h7: ea <= rrd;		  
		  default: ea <= 16'hX;		  
		endcase // case (decA)
	  
	  default: ea <= ea;	  
	endcase // case (pha)
	 	
	case (pha)
	  2'o1: case (decB[4:1])
		  4'hF: eb <= (decB[0]) ? g_adr : g_dti; // 0x1E;
		  4'hC,4'hD: eb <= regSP; // FIXME: SP calculator
		  4'h8,4'h9,4'hA,4'hB: eb <= nwr;
		  4'h4,4'h5,4'h6,4'h7: eb <= rrd;		  
		  default: eb <= 16'hX;		  
		endcase // case (decA)	  
	  default: eb <= eb;
	endcase // case (pha)	
     end
   
   // G-BUS
   assign g_wre = 1'b0;
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	g_adr <= 16'h0;
	g_stb <= 1'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o3: g_adr <= regPC;
	  2'o0: g_adr <= regPC;
	  2'o1: g_adr <= ea;
	  2'o2: g_adr <= eb;	  
	  default: g_adr <= 16'hX;	  
	endcase // case (pha)

	case (pha)
	  2'o3: g_stb <= Anwr | Anwi | Anwl;
	  2'o0: g_stb <= Bnwr | Bnwi | Bnwl;
	  2'o1: g_stb <= Aind | Anwr | Aspr | Anwi;
	  2'o2: g_stb <= Bind | Bnwr | Bspr | Bnwi;	  
	  default: g_stb <= 1'bX;	  
	endcase // case (pha)	
     end
   

   // F-BUS
   reg [15:0] _adr;
   reg 	      _stb, _wre;   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_adr <= 16'h0;
	_stb <= 1'h0;
	_wre <= 1'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o2: begin
	     _adr <= g_adr;
	     _stb <= g_stb;
	  end
	  default:begin
	     _adr <= _adr;
	     _stb <= _stb;	     
	  end
	endcase // case (pha)

	case (pha)
	  2'o2: _wre <= Aind | Anwr | Aspr | Anwi;	     
	  default: _wre <= _wre;	  
	endcase // case (pha)
	
     end

   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	f_adr <= 16'h0;
	f_stb <= 1'h0;
	f_wre <= 1'h0;
	// End of automatics
     end else if (ena) begin

	case (pha)
	  2'o1: f_adr <= regPC;
	  2'o0: f_adr <= _adr;	  
	  default: f_adr <= 16'hX;	  
	endcase // case (pha)

	case (pha)
	  2'o1: {f_stb,f_wre} <= 2'o2;
	  2'o0: {f_stb,f_wre} <= {_stb, _wre};	  
	  default: {f_stb,f_wre} <= 2'o0;	  
	endcase // case (pha)

     end
   
   // REG-A
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	regA <= 16'h0;
	regB <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o0: regA <= (g_stb) ? g_dti : regA;	     
	  2'o2: regA <= (g_stb) ? g_dti :
			(_rd) ? rrd :
			regA;	     
	  default: regA <= regA;
	endcase // case (pha)
	
	case (pha)
	  2'o1: regB <= (g_stb) ? g_dti : regB;	  
	  2'o3: regB <= (g_stb) ? g_dti :
			(_rd) ? rrd :
			regB;
	  default: regB <= regB;	  
	endcase // case (pha)	
     end
   
endmodule // dcpu16_abus

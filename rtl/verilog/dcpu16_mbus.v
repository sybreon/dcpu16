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
   g_adr, g_stb, g_wre, f_adr, f_stb, f_wre, ena, wpc, regA, regB,
   // Inputs
   g_dti, g_ack, f_dti, f_ack, bra, CC, regR, rrd, ireg, regO, pha,
   clk, rst
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
   output 	 wpc;   
   output [15:0] regA,
		 regB;

   input 	 bra;
   input 	 CC;   
   input [15:0]  regR;   
   input [15:0]  rrd;
   input [15:0]  ireg;   
   input [15:0]  regO;   

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
   reg			wpc;
   // End of automatics

   reg [15:0] 		regSP,
			regPC;
   
   assign ena = (f_stb ~^ f_ack) & (g_stb ~^ g_ack); // pipe stall

   // repeated decoder
   wire [5:0] 		decA, decB;
   wire [3:0] 		decO;   
   assign {decB, decA, decO} = ireg;   
  
   /*
    0x00-0x07: register (A, B, C, X, Y, Z, I or J, in that order)
    0x08-0x0f: [register]
`    0x10-0x17: [next word + register]
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

   wire 		Apop = (decA[5:0] == 6'h18);
   wire 		Apek = (decA[5:0] == 6'h19);
   wire 		Apsh = (decA[5:0] == 6'h1A);
   wire 		Bpop = (decB[5:0] == 6'h18);
   wire 		Bpek = (decB[5:0] == 6'h19);
   wire 		Bpsh = (decB[5:0] == 6'h1A);
   
   wire 		Aspr = (decA[5:0] == 6'h18) | (decA[5:0] == 6'h19) | (decA[5:0] == 6'h1A);
   wire 		Bspr = (decB[5:0] == 6'h18) | (decB[5:0] == 6'h19) | (decB[5:0] == 6'h1A);
   wire 		Anwi = (decA[5:0] == 6'h1E);
   wire 		Bnwi = (decB[5:0] == 6'h1E);
   wire 		Anwl = (decA[5:0] == 6'h1F);
   wire 		Bnwl = (decB[5:0] == 6'h1F);   

   wire 		Arsp = (decA[5:0] == 6'h1B);
   wire 		Arpc = (decA[5:0] == 6'h1C);
   wire 		Arro = (decA[5:0] == 6'h1D);
   wire 		Brsp = (decB[5:0] == 6'h1B);
   wire 		Brpc = (decB[5:0] == 6'h1C);
   wire 		Brro = (decB[5:0] == 6'h1D);

   wire 		Asht = (decA[5]);
   wire 		Bsht = (decB[5]);
 		   
   wire 		incA = Anwr | Anwi | Anwl;
   wire 		incB = Bnwr | Bnwi | Bnwl;    

   wire 		Fjsr = (ireg [4:0] == 5'h10);   



   wire [5:0] 		ed = (pha[0]) ? decB : decA;   

   wire 		Eind = (ed[5:3] == 3'o1);
   wire 		Enwr = (ed[5:3] == 3'o2);
   wire 		Epsh = (ed[5:0] == 6'h1A);
   wire 		Epop = (ed[5:0] == 6'h18);
   wire 		Epek = (ed[5:0] == 6'h19);
   wire 		Enwi = (ed[5:0] == 6'h1E);   
   wire 		Espr = (ed[5:0] == 6'h18) | (ed[5:0] == 6'h19) | (ed[5:0] == 6'h1A);

   wire [5:0] 		fg = (pha[0]) ? decA : decB;   

   wire 		Fdir = (fg[5:3] == 3'o0);   
   wire 		Fnwr = (fg[5:3] == 3'o2);
   wire 		Find = (fg[5:3] == 3'o1);
   wire 		Frpc = (fg[5:0] == 6'h1C);
   wire 		Fnwi = (fg[5:0] == 6'h1E);
   wire 		Fnwl = (fg[5:0] == 6'h1F);
   wire 		Fspr = (fg[5:0] == 6'h18) | (fg[5:0] == 6'h19) | (fg[5:0] == 6'h1A);
   

   wire [15:0] 		nwr = rrd + g_dti;   // FIXME: Reduce this and combine with other ALU
   wire [15:0] 		decSP = regSP - 1;
   wire [15:0] 		incSP = regSP + 1;   
   
   // PROGRAMME COUNTER
   reg [15:0] 		rpc;
   reg 			lpc;  
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	regPC <= 16'h0;
	wpc <= 1'h0;
	// End of automatics
     end else if (ena) begin
	if (lpc)
	  regPC <= rpc;
	else
	  regPC <= regPC + 1;

       	case (pha)
	  2'o1: wpc <= Frpc & CC;
	  default: wpc <= wpc;	  
	endcase // case (pha)	
     end

   always @(/*AUTOSENSE*/bra or pha or regB or regPC or regR or wpc) begin      
      case (pha)
	//2'o3: rpc <= regPC;
	//2'o0: rpc <= regPC;
	2'o1: rpc <= (wpc) ? regR :
		     (bra) ? regB :
		     regPC;
	default: rpc <= regPC;	
      endcase // case (pha)
   end // always (...
   
   always @(/*AUTOSENSE*/incA or incB or pha) begin     
      case (pha)
	2'o3: lpc <= ~incA;
	2'o0: lpc <= ~incB;
	2'o1: lpc <= 1'b1;	
	default: lpc <= 1'b0;	
      endcase // case (pha)
   end // always (...
   
   // STACK POINTER
   reg [15:0] _regSP;
   always @(posedge clk)
     if (rst) begin
	regSP <= 16'hFFFF;	
	/*AUTORESET*/
     end else if (ena) begin
	case (pha)
	  2'o0: regSP <= (Fjsr) ? decSP :
			 (Aspr) ? _regSP : regSP;
	  2'o1: regSP <= (Bspr) ? _regSP : regSP;	  
	endcase // case (pha)
     end

   always @(/*AUTOSENSE*/decA or decB or pha or regSP) begin
      case (pha)
	2'o0: case (decA[1:0])
		2'o0: _regSP <= regSP + 1;
		2'o2: _regSP <= regSP - 1;		
		default: _regSP <= regSP;		
	      endcase // case (decA[1:0])
	2'o1: case (decB[1:0])
		2'o0: _regSP <= regSP + 1;
		2'o2: _regSP <= regSP - 1;
		default: _regSP <= regSP;		
	      endcase // case (decB[1:0])
      endcase // case (pha)
   end // always @ (...

   // EA CALCULATOR

   reg [15:0] ea, 
	      eb;
   reg [15:0] ec; // Calculated EA
 
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	ea <= 16'h0;
	eb <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o0: ea <= (Fjsr) ? decSP : ec;	  
	  default: ea <= ea;	  
	endcase // case (pha)

	case (pha)
	  2'o1: eb <= ec;	  
	  default: eb <= eb;	  
	endcase // case (pha)
     end // if (ena)

   
   always @(/*AUTOSENSE*/Eind or Enwi or Enwr or Epek or Epop or Epsh
	    or _regSP or g_dti or nwr or regSP or rrd) begin
      ec <= (Eind) ? rrd :
	    (Enwr) ? nwr :
	    //(Fjsr) ? decSP :
	    (Epsh) ? _regSP :
	    (Epop | Epek) ? regSP :
	    (Enwi) ? g_dti :
	    16'hX;      
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
	  2'o1: g_adr <= ea;
	  2'o2: g_adr <= eb;	  
	  default: g_adr <= regPC;	  
	endcase // case (pha)

	case (pha)
	  2'o3: g_stb <= Fnwr | Fnwi | Fnwl;
	  2'o0: g_stb <= Fnwr | Fnwi | Fnwl;
	  2'o1: g_stb <= Find | Fnwr | Fspr | Fnwi;
	  2'o2: g_stb <= Find | Fnwr | Fspr | Fnwi;	  
	endcase // case (pha)
     end // if (ena)
   

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
	     _stb <= g_stb | Fjsr;
	  end
	  default:begin
	     _adr <= _adr;
	     _stb <= _stb;	     
	  end
	endcase // case (pha)

	case (pha)
	  2'o1: _wre <= Find | Fnwr | Fspr | Fnwi | Fjsr;	     
	  default: _wre <= _wre;	  
	endcase // case (pha)
	
     end // if (ena)

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
	  2'o1: f_adr <= (wpc) ? regR :
			 (bra) ? regB :
			 regPC;
	  2'o0: f_adr <= _adr;	  
	  default: f_adr <= 16'hX;	  
	endcase // case (pha)

	case (pha)
	  2'o1: {f_stb,f_wre} <= (Fjsr) ? 2'o0 : 2'o2;
	  2'o0: {f_stb,f_wre} <= {_stb, _wre & CC};	  
	  default: {f_stb,f_wre} <= 2'o0;	  
	endcase // case (pha)

     end // if (ena)
   
   // REG-A/REG-B
   reg 			_rd;   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_rd <= 1'h0;
	// End of automatics
     end else if (ena)
       	case (pha)
	  2'o1: _rd <= Fdir;
	  2'o2: _rd <= Fdir;	  
	  default: _rd <= 1'b0;	  
	endcase // case (pha)

   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	regA <= 16'h0;
	regB <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o0: regA <= (g_stb) ? g_dti :
			(Arsp) ? regSP :
			(Arpc) ? regPC :
			(Arro) ? regO :
			(Asht) ? {11'd0,decA[4:0]} :
			regA;	     
	  2'o2: regA <= (g_stb) ? g_dti :
			(Fjsr) ? regPC :
			(_rd) ? rrd :
			regA;	     
	  default: regA <= regA;
	endcase // case (pha)
	
	case (pha)
	  2'o1: regB <= (g_stb) ? g_dti :
			(Brsp) ? regSP :
			(Brpc) ? regPC :
			(Brro) ? regO :
			(Bsht) ? {11'd0,decB[4:0]} :
			regB;	  
	  2'o3: regB <= (g_stb) ? g_dti :
			(_rd) ? rrd :
			regB;
	  default: regB <= regB;	  
	endcase // case (pha)
     end // if (ena)
   
endmodule // dcpu16_mbus

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

module dcpu16_alu (/*AUTOARG*/
   // Outputs
   f_dto, g_dto, rwd, regR, regO, CC,
   // Inputs
   regA, regB, opc, clk, rst, ena, pha
   );

   output [15:0] f_dto,
		 g_dto,
		 rwd;
   
   output [15:0] regR,
		 regO;
   output 	 CC;   
   
   input [15:0]  regA,
		 regB;   
   
   input [3:0] 	 opc;
   
   input 	 clk,
		 rst,
		 ena;

   input [1:0] 	 pha;   

   wire [15:0] 	 src, // a
		 tgt; // b
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			CC;
   reg [15:0]		regO;
   reg [15:0]		regR;
   // End of automatics

   
   assign f_dto = regR;
   assign g_dto = regR;   
   assign rwd = regR;   
   
   assign src = regA;
   assign tgt = regB;   
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	CC <= 1'h0;
	regO <= 16'h0;
	regR <= 16'h0;
	// End of automatics
     end else if (ena) begin
	case (opc)
	  /* Assignment */
	  // 0x1: SET a, b - sets a to b
	  4'h1: {regO, regR} <= {regO, tgt};

	  /* Arithmetic */
	  // 0x2: ADD a, b - sets a to a+b, sets O to 0x0001 if there's an overflow, 0x0 otherwise
	  // 0x3: SUB a, b - sets a to a-b, sets O to 0xffff if there's an underflow, 0x0 otherwise
	  // 0x4: MUL a, b - sets a to a*b, sets O to ((a*b)>>16)&0xffff
	  // 0x5: DIV a, b - sets a to a/b, sets O to ((a<<16)/b)&0xffff. if b==0, sets a and O to 0 instead.
	  // 0x6: MOD a, b - sets a to a%b. if b==0, sets a to 0 instead.
	  4'h2: {regO, regR} <= src + tgt;
	  4'h3: {regO, regR} <= src - tgt;
	  4'h4: {regO, regR} <= src * tgt;

	  /* Shift */
	  // 0x7: SHL a, b - sets a to a<<b, sets O to ((a<<b)>>16)&0xffff
	  // 0x8: SHR a, b - sets a to a>>b, sets O to ((a<<16)>>b)&0xffff	 

	  /* Logic */
	  // 0x9: AND a, b - sets a to a&b
	  // 0xa: BOR a, b - sets a to a|b
	  // 0xb: XOR a, b - sets a to a^b
	  4'h9: {regO, regR} <= {regO, src & tgt};
	  4'hA: {regO, regR} <= {regO, src | tgt};
	  4'hB: {regO, regR} <= {regO, src ^ tgt};	  

	  /* Condition */
	  // 0xc: IFE a, b - performs next instruction only if a==b
	  // 0xd: IFN a, b - performs next instruction only if a!=b
	  // 0xe: IFG a, b - performs next instruction only if a>b
	  // 0xf: IFB a, b - performs next instruction only if (a&b)!=0	  	  
	  //4'hC: {regO, regR} <= {regO, (src == tgt)};
	  //4'hD: {regO, regR} <= {regO, (src != tgt)};
	  //4'hE: {regO, regR} <= {regO, (src > tgt)};
	  //4'hF: {regO, regR} <= {regO, |(src & tgt)};	  
	  
	  default: {regO, regR} <= {regO, regR};	  
	endcase // case (opc)

	if (pha == 2'o0)
	case (opc)
	  4'hC: CC <= (src == tgt);
	  4'hD: CC <= (src != tgt);
	  4'hE: CC <= (src > tgt);
	  4'hF: CC <= |(src & tgt);
	  default: CC <= 1'b1;	  
	endcase // case (opc)
	
     end
   
endmodule // dcpu16_alu

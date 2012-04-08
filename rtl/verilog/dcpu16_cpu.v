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
 
DCPU16 PIPELINE
===============

Consists of the following stages:

- Fetch (F): fetches instructions from the FBUS.
- Decode (D): decodes instructions.
- Load A (A): loads operand A from ABUS.
- Load B (B): loads operand B from ABUS.
- Execute (X): performs the ALU operation.
- Save A (S): saves operand A to the FBUS.

FDABXS
  FDABXS
    FDABXS

 */

module dcpu16_cpu (/*AUTOARG*/
   // Outputs
   tgt, src, regSP, fs_wre, fs_stb, fs_dto, fs_adr, ab_wre, ab_stb,
   ab_dto, ab_adr,
   // Inputs
   rst, fs_dti, fs_ack, clk, ab_dti, ab_ack
   );

   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [15:0]	ab_adr;			// From a0 of dcpu16_abus.v
   output [15:0]	ab_dto;			// From x0 of dcpu16_alu.v
   output		ab_stb;			// From a0 of dcpu16_abus.v
   output		ab_wre;			// From a0 of dcpu16_abus.v
   output [15:0]	fs_adr;			// From f0 of dcpu16_fbus.v
   output [15:0]	fs_dto;			// From f0 of dcpu16_fbus.v
   output		fs_stb;			// From f0 of dcpu16_fbus.v
   output		fs_wre;			// From f0 of dcpu16_fbus.v
   output [15:0]	regSP;			// From a0 of dcpu16_abus.v
   output [15:0]	src;			// From a0 of dcpu16_abus.v
   output [15:0]	tgt;			// From a0 of dcpu16_abus.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		ab_ack;			// To c0 of dcpu16_ctl.v, ...
   input [15:0]		ab_dti;			// To c0 of dcpu16_ctl.v, ...
   input		clk;			// To c0 of dcpu16_ctl.v, ...
   input		fs_ack;			// To c0 of dcpu16_ctl.v, ...
   input [15:0]		fs_dti;			// To c0 of dcpu16_ctl.v, ...
   input		rst;			// To c0 of dcpu16_ctl.v, ...
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			ab_ena;			// From a0 of dcpu16_abus.v
   wire [15:0]		ab_fs;			// From a0 of dcpu16_abus.v
   wire [5:0]		ea;			// From c0 of dcpu16_ctl.v
   wire			ena;			// From c0 of dcpu16_ctl.v
   wire			fs_ena;			// From f0 of dcpu16_fbus.v
   wire [15:0]		ireg;			// From c0 of dcpu16_ctl.v
   wire [3:0]		opc;			// From c0 of dcpu16_ctl.v
   wire			pha;			// From c0 of dcpu16_ctl.v
   wire [15:0]		regA;			// From a0 of dcpu16_abus.v
   wire [15:0]		regB;			// From a0 of dcpu16_abus.v
   wire [15:0]		regO;			// From x0 of dcpu16_alu.v
   wire [15:0]		regPC;			// From f0 of dcpu16_fbus.v
   wire [15:0]		regR;			// From x0 of dcpu16_alu.v
   wire [2:0]		rra;			// From c0 of dcpu16_ctl.v
   wire [15:0]		rrd;			// From r0 of dcpu16_regs.v
   wire [2:0]		rwa;			// From c0 of dcpu16_ctl.v
   wire [15:0]		rwd;			// From x0 of dcpu16_alu.v
   wire			rwe;			// From c0 of dcpu16_ctl.v
   wire			skp;			// From c0 of dcpu16_ctl.v
   // End of automatics
   /*AUTOREG*/

   dcpu16_ctl
     c0 (/*AUTOINST*/
	 // Outputs
	 .ireg				(ireg[15:0]),
	 .pha				(pha),
	 .ena				(ena),
	 .opc				(opc[3:0]),
	 .rra				(rra[2:0]),
	 .rwa				(rwa[2:0]),
	 .rwe				(rwe),
	 .skp				(skp),
	 .ea				(ea[5:0]),
	 // Inputs
	 .fs_dti			(fs_dti[15:0]),
	 .ab_dti			(ab_dti[15:0]),
	 .rrd				(rrd[15:0]),
	 .fs_ack			(fs_ack),
	 .fs_ena			(fs_ena),
	 .ab_ena			(ab_ena),
	 .ab_ack			(ab_ack),
	 .clk				(clk),
	 .rst				(rst));   

   dcpu16_fbus
     f0 (/*AUTOINST*/
	 // Outputs
	 .fs_adr			(fs_adr[15:0]),
	 .fs_stb			(fs_stb),
	 .fs_wre			(fs_wre),
	 .fs_dto			(fs_dto[15:0]),
	 .regPC				(regPC[15:0]),
	 .fs_ena			(fs_ena),
	 // Inputs
	 .fs_dti			(fs_dti[15:0]),
	 .fs_ack			(fs_ack),
	 .skp				(skp),
	 .ab_fs				(ab_fs[15:0]),
	 .regR				(regR[15:0]),
	 .ireg				(ireg[15:0]),
	 .clk				(clk),
	 .pha				(pha),
	 .rst				(rst),
	 .ena				(ena));

   dcpu16_abus
     a0 (/*AUTOINST*/
	 // Outputs
	 .ab_adr			(ab_adr[15:0]),
	 .ab_stb			(ab_stb),
	 .ab_ena			(ab_ena),
	 .ab_wre			(ab_wre),
	 .regSP				(regSP[15:0]),
	 .regA				(regA[15:0]),
	 .regB				(regB[15:0]),
	 .ab_fs				(ab_fs[15:0]),
	 .src				(src[15:0]),
	 .tgt				(tgt[15:0]),
	 // Inputs
	 .ab_dti			(ab_dti[15:0]),
	 .ab_ack			(ab_ack),
	 .rrd				(rrd[15:0]),
	 .regPC				(regPC[15:0]),
	 .regO				(regO[15:0]),
	 .ea				(ea[5:0]),
	 .clk				(clk),
	 .pha				(pha),
	 .rst				(rst),
	 .ena				(ena));
   
   dcpu16_alu
     x0 (/*AUTOINST*/
	 // Outputs
	 .ab_dto			(ab_dto[15:0]),
	 .rwd				(rwd[15:0]),
	 .regR				(regR[15:0]),
	 .regO				(regO[15:0]),
	 // Inputs
	 .ab_dti			(ab_dti[15:0]),
	 .rrd				(rrd[15:0]),
	 .opc				(opc[3:0]),
	 .regA				(regA[15:0]),
	 .regB				(regB[15:0]),
	 .clk				(clk),
	 .pha				(pha),
	 .rst				(rst),
	 .ena				(ena));
   
   
   dcpu16_regs
     r0 (/*AUTOINST*/
	 // Outputs
	 .rrd				(rrd[15:0]),
	 // Inputs
	 .rwd				(rwd[15:0]),
	 .rra				(rra[2:0]),
	 .rwa				(rwa[2:0]),
	 .rwe				(rwe),
	 .rst				(rst),
	 .ena				(ena),
	 .clk				(clk));
   
endmodule // dcpu16

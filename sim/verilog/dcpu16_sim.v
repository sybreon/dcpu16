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

module dcpu16sim (/*AUTOARG*/
   // Outputs
   tgt, src, regSP
   );

   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [15:0]	regSP;			// From ut0 of dcpu16_cpu.v
   output [15:0]	src;			// From ut0 of dcpu16_cpu.v
   output [15:0]	tgt;			// From ut0 of dcpu16_cpu.v
   // End of automatics
   /*AUTOINPUT*/
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [15:0]		ab_adr;			// From ut0 of dcpu16_cpu.v
   wire [15:0]		ab_dti;			// From ur0 of fasm_dpsram_wbr.v
   wire [15:0]		ab_dto;			// From ut0 of dcpu16_cpu.v
   wire			ab_stb;			// From ut0 of dcpu16_cpu.v
   wire			ab_wre;			// From ut0 of dcpu16_cpu.v
   wire [15:0]		fs_adr;			// From ut0 of dcpu16_cpu.v
   wire [15:0]		fs_dti;			// From ur0 of fasm_dpsram_wbr.v
   wire [15:0]		fs_dto;			// From ut0 of dcpu16_cpu.v
   wire			fs_stb;			// From ut0 of dcpu16_cpu.v
   wire			fs_wre;			// From ut0 of dcpu16_cpu.v
   // End of automatics
   /*AUTOREG*/

   reg 			rst,
			clk;
   reg 			fs_ack, ab_ack;
   
   
   initial begin
      $dumpfile ("dump.vcd");
      $dumpvars (2,ut0);

      
      clk = $random;
      rst = 1;

      #50 rst = 0;
      $readmemh ("dump.vmem", ur0.bram);      

      #5000 $displayh("\n*** TIMEOUT ", $stime, " ***");
      $finish;
   end // initial begin

   always #5 clk <= !clk;

   always @(posedge clk) begin
      fs_ack <= fs_stb & !fs_ack;
      ab_ack <= ab_stb & !ab_ack;      
   end


   /* fasm_dpsram_wbr AUTO_TEMPLATE (
    .AW(16),
    .DW(16),
    
    .xclk_i(clk), 
    .clk_i(clk),
    
    .xwre_i(ab_wre), 
    .xstb_i(ab_stb), 
    .xadr_i(ab_adr),
    .xdat_o(ab_dti[15:0]),
    .xdat_i(ab_dto[15:0]),
    
    .wre_i(fs_wre),
    .stb_i(fs_stb),
    .adr_i(fs_adr),
    .dat_o(fs_dti[15:0]),
    .dat_i(fs_dto[15:0]),
    
    .rst_i(rst),
    .xrst_i(rst),
    ) */
   
   fasm_dpsram_wbr
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AW				(16),			 // Templated
       .DW				(16))			 // Templated
     ur0 (/*AUTOINST*/
	  // Outputs
	  .dat_o			(fs_dti[15:0]),		 // Templated
	  .xdat_o			(ab_dti[15:0]),		 // Templated
	  // Inputs
	  .dat_i			(fs_dto[15:0]),		 // Templated
	  .adr_i			(fs_adr),		 // Templated
	  .wre_i			(fs_wre),		 // Templated
	  .stb_i			(fs_stb),		 // Templated
	  .rst_i			(rst),			 // Templated
	  .clk_i			(clk),			 // Templated
	  .xdat_i			(ab_dto[15:0]),		 // Templated
	  .xadr_i			(ab_adr),		 // Templated
	  .xwre_i			(ab_wre),		 // Templated
	  .xstb_i			(ab_stb),		 // Templated
	  .xrst_i			(rst),			 // Templated
	  .xclk_i			(clk));			 // Templated

   
   dcpu16_cpu
     ut0 (/*AUTOINST*/
	  // Outputs
	  .ab_adr			(ab_adr[15:0]),
	  .ab_dto			(ab_dto[15:0]),
	  .ab_stb			(ab_stb),
	  .ab_wre			(ab_wre),
	  .fs_adr			(fs_adr[15:0]),
	  .fs_dto			(fs_dto[15:0]),
	  .fs_stb			(fs_stb),
	  .fs_wre			(fs_wre),
	  .regSP			(regSP[15:0]),
	  .src				(src[15:0]),
	  .tgt				(tgt[15:0]),
	  // Inputs
	  .ab_ack			(ab_ack),
	  .ab_dti			(ab_dti[15:0]),
	  .clk				(clk),
	  .fs_ack			(fs_ack),
	  .fs_dti			(fs_dti[15:0]),
	  .rst				(rst));   

   integer i;
   initial begin
      for (i=0; i<8; i=i+1) begin
	 ut0.r0.file[i] <= $random;	 
      end
   end
   
endmodule // dcpu16sim

// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/")
// verilog-library-files:("")
// End:

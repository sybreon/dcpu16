
module dcpu16_ctl (/*AUTOARG*/
   // Outputs
   ireg, pha, ena, opc, rra, ea,
   // Inputs
   fs_dti, ab_dti, rrd, fs_ack, fs_ena, ab_ena, ab_ack, clk, rst
   );

   output [15:0] ireg;   
   output 	 pha,
		 ena;

   // shared
   output [3:0]  opc;
   output [2:0]  rra;
   output [5:0]  ea;   
   input [15:0]  fs_dti, 
		 ab_dti;
   input [15:0]  rrd;   

   input 	 fs_ack,
		 fs_ena;

   input 	 ab_ena,
		 ab_ack;   

   // system
   input 	 clk,
		 rst;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [5:0]		ea;
   reg [15:0]		ireg;
   reg [3:0]		opc;
   reg			pha;
   reg [2:0]		rra;
   // End of automatics

   reg [3:0] 		_opc;   
   reg [2:0] 		_rra;
   reg [15:0] 		_rrd;   

   wire [3:0] 		decO;
   wire [5:0] 		decA, decB;
     
   assign {decB, decA, decO} = fs_dti;   
   assign ena = (fs_ena ~^ fs_ack) & (ab_ena ~^ ab_ack); // pipe stall   

   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	ireg <= 16'h0;
	pha <= 1'h0;
	// End of automatics
     end else if (ena) begin
	pha <= !pha;
	ireg <= fs_dti;	
     end

   // opc
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_opc <= 4'h0;
	ea <= 6'h0;
	opc <= 4'h0;
	rra <= 3'h0;
	// End of automatics
     end else if (ena) begin
	if (pha)
	  {opc, _opc} <= {_opc, decO};

	rra <= (pha) ? decB[2:0] : decA[2:0];

	ea <= (pha) ? decB : decA;
     end
   
   
endmodule // dcpu16_ctl

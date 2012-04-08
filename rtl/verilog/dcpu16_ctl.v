
module dcpu16_ctl (/*AUTOARG*/
   // Outputs
   ireg, pha, ena, opc, rra, rwa, rwe, ea,
   // Inputs
   fs_dti, ab_dti, rrd, fs_ack, fs_ena, ab_ena, ab_ack, clk, rst
   );

   output [15:0] ireg;   
   output 	 pha,
		 ena;

   // shared
   output [3:0]  opc;
   output [2:0]  rra,
		 rwa;
   output 	 rwe;   
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
   reg [2:0]		rwa;
   // End of automatics

   reg [3:0] 		_opc;   
   reg [2:0] 		_rra;
   reg [15:0] 		_rrd;
   reg [2:0] 		_rwa, __rwa, ___rwa;
   reg [3:0] 		_rwe;   

   reg 			skp;   
   
   wire [3:0] 		decO;
   wire [5:0] 		decA, decB;
     
   assign {decB, decA, decO} = ireg;   
   assign ena = (fs_ena ~^ fs_ack) & (ab_ena ~^ ab_ack); // pipe stall   

   assign rwe = _rwe[3];   
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_rwe <= 4'h0;
	pha <= 1'h0;
	// End of automatics
     end else if (ena) begin
	pha <= !pha;
	_rwe <= {_rwe[2:0], (decA[5:3] == 3'o0) & pha & (decO != 4'h0)};
	
     end

   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	ireg <= 16'h0;
	// End of automatics
     end else if (!pha) begin
	case ({skp,fs_ack})
	  default: ireg <= 16'h0;
	  2'b01: ireg <= fs_dti;
	  2'b10: ireg <= 16'h0;	  
	endcase // case ({skp,fs_ack})	
     end

   // Skipping instructions
   wire _skp;
   assign _skp = (decA[5:3] == 3'o2) | (decA[5:1] == 5'b01111) | (decB[5:3] == 3'o2) | (decB[5:1] == 5'h0F); 
   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	skp <= 1'h0;
	// End of automatics
     end else if (pha) begin
	skp <= _skp;	
     end
   
   // opc
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	___rwa <= 3'h0;
	__rwa <= 3'h0;
	_opc <= 4'h0;
	_rwa <= 3'h0;
	ea <= 6'h0;
	opc <= 4'h0;
	rra <= 3'h0;
	rwa <= 3'h0;
	// End of automatics
     end else if (ena) begin
	if (pha)
	  {opc, _opc} <= {_opc, decO};

	{rwa, _rwa, __rwa, ___rwa} <= {_rwa, __rwa, ___rwa, rra};	
	rra <= (pha) ? decB[2:0] : decA[2:0];

	ea <= (pha) ? decB : decA;
     end
   
   
endmodule // dcpu16_ctl

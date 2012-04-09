
module dcpu16_ctl (/*AUTOARG*/
   // Outputs
   ireg, pha, opc, rra, rwa, rwe, bra,
   // Inputs
   wpc, f_dti, f_ack, clk, ena, rst
   );

   output [15:0] ireg;   
   output [1:0]  pha;

   // shared
   output [3:0]  opc;
   output [2:0]  rra,
		 rwa;
   output 	 rwe;
   output 	 bra;
  
   input 	 wpc;
   
   input [15:0]  f_dti;   
   input 	 f_ack;   
  
   // system
   input 	 clk,
		 ena,
		 rst;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			bra;
   reg [15:0]		ireg;
   reg [3:0]		opc;
   reg [1:0]		pha;
   reg [2:0]		rra;
   reg [2:0]		rwa;
   reg			rwe;
   // End of automatics

   // repeated decoder
   wire [5:0] 		decA, decB;
   wire [3:0] 		decO;   
   assign {decB, decA, decO} = ireg;   

   wire 		nop = 16'd1; // NOP = SET A, A   
   wire 		_skp = (decO == 4'h0);
   
   // PHASE CALCULATOR
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	pha <= 2'h0;
	// End of automatics
     end else if (ena) begin
	pha <= pha + 1;		
     end

   // IREG LATCH
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	bra <= 1'h0;
	ireg <= 16'h0;
	opc <= 4'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o2: ireg <= (wpc) ? nop : f_dti; // latch instruction only on PHA2
	  default: ireg <= ireg;	  
	endcase // case (pha)

	case (pha)
	  2'o2: opc <= ireg[3:0];	  
	  default: opc <= opc;
	endcase // case (pha)

	case (pha)
	  2'o2: bra <= (ireg[5:0] == 5'h10);	  
	  default: bra <= bra;	  
	endcase // case (pha)
	
     end

   // BRANCH CONTROL
   
   
   // REGISTER FILE
   reg [2:0] _rwa;
   reg 	     _rwe;   
   always @(posedge clk)
     if (rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	_rwa <= 3'h0;
	_rwe <= 1'h0;
	rra <= 3'h0;
	rwa <= 3'h0;
	rwe <= 1'h0;
	// End of automatics
     end else if (ena) begin
	case (pha)
	  2'o3: rra <= decA[2:0];
	  2'o1: rra <= decA[2:0];
	  2'o2: rra <= decB[2:0];
	  2'o0: rra <= decB[2:0];	  
	  //default: rra <= 3'oX;	  
	endcase // case (pha)

	case (pha)
	  2'o0: {rwa, rwe} <= {_rwa, _rwe};	  
	  default: {rwa, rwe} <= {3'hX, 1'b0};	  
	endcase // case (pha)
	case (pha)
	  2'o0: begin
	     _rwa <= decA[2:0];
	     _rwe <= (decA[5:3] == 3'o0) & !_skp;	     
	  end
	  default: {_rwa, _rwe} <= {_rwa, _rwe};	  
	endcase // case (pha)
	
     end
   
endmodule // dcpu16_ctl

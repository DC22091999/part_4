// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sfp_row (clk, reset, acc, div, sum_in, sum_out, sfp_in, sfp_out, req_in, ack_in, ack_out, req_out, is_signed, reconfigure);

  parameter col = 8;
  parameter bw = 4;
  parameter bw_psum = 2*bw+3;
  parameter sum_bw = bw_psum+7;

  input req_in, ack_in;
  output ack_out, req_out;
  wire req_in_sync;
  wire ack_in_sync;
  input is_signed;
  input reconfigure;
  input  clk, div, acc;
  input reset;
  wire  fifo_ext_rd;
  reg ack_in_sync_dly;
  input  signed [sum_bw-1:0] sum_in;
  input  [col*bw_psum-1:0] sfp_in;
  //wire  [col*bw_psum-1:0] abs;
  reg    div_q;
  reg    ack_out_delay1;
  reg    ack_out_delay2;

  output reg [col*bw_psum-1:0] sfp_out;
  output signed [sum_bw-1:0] sum_out; //width = max{bw_psum + log8, bw_psum+5+log4}
  wire signed [sum_bw-1:0] sum_this_core; //bw_psum + 5 = one psum width in reconf mode
  wire signed [sum_bw:0] sum_2core;
  
  wire [bw_psum-1:0] sfp_in0;
  wire [bw_psum-1:0] sfp_in1;
  wire [bw_psum-1:0] sfp_in2;
  wire [bw_psum-1:0] sfp_in3;
  wire [bw_psum-1:0] sfp_in4;
  wire [bw_psum-1:0] sfp_in5;
  wire [bw_psum-1:0] sfp_in6;
  wire [bw_psum-1:0] sfp_in7;


  wire [bw_psum+5-1:0] sfp_recon_in0;
  wire [bw_psum+5-1:0] sfp_recon_in1;
  wire [bw_psum+5-1:0] sfp_recon_in2;
  wire [bw_psum+5-1:0] sfp_recon_in3;
 

  reg signed [bw_psum-1:0] sfp_out_sign0;
  reg signed [bw_psum-1:0] sfp_out_sign1;
  reg signed [bw_psum-1:0] sfp_out_sign2;
  reg signed [bw_psum-1:0] sfp_out_sign3;
  reg signed [bw_psum-1:0] sfp_out_sign4;
  reg signed [bw_psum-1:0] sfp_out_sign5;
  reg signed [bw_psum-1:0] sfp_out_sign6;
  reg signed [bw_psum-1:0] sfp_out_sign7;

  reg signed [bw_psum*2-1:0] sfp_recon_out_sign0;
  reg signed [bw_psum*2-1:0] sfp_recon_out_sign1;
  reg signed [bw_psum*2-1:0] sfp_recon_out_sign2;
  reg signed [bw_psum*2-1:0] sfp_recon_out_sign3;

  reg [bw_psum+7-1:0] sum_q;
  reg fifo_wr;

  ///////////////////////// Parsing the inputs //////////////////////////

  assign sfp_in0 =  sfp_in[bw_psum*1-1 : bw_psum*0];
  assign sfp_in1 =  sfp_in[bw_psum*2-1 : bw_psum*1];
  assign sfp_in2 =  sfp_in[bw_psum*3-1 : bw_psum*2];
  assign sfp_in3 =  sfp_in[bw_psum*4-1 : bw_psum*3];
  assign sfp_in4 =  sfp_in[bw_psum*5-1 : bw_psum*4];
  assign sfp_in5 =  sfp_in[bw_psum*6-1 : bw_psum*5];
  assign sfp_in6 =  sfp_in[bw_psum*7-1 : bw_psum*6];
  assign sfp_in7 =  sfp_in[bw_psum*8-1 : bw_psum*7];

  assign sfp_recon_in0 = {sfp_in0[bw_psum-1], sfp_in0, 4'b0000} + {{(5){sfp_in1[bw_psum-1]}}, sfp_in1};
  assign sfp_recon_in1 = {sfp_in2[bw_psum-1], sfp_in2, 4'b0000} + {{(5){sfp_in3[bw_psum-1]}}, sfp_in3};
  assign sfp_recon_in2 = {sfp_in4[bw_psum-1], sfp_in4, 4'b0000} + {{(5){sfp_in5[bw_psum-1]}}, sfp_in5};
  assign sfp_recon_in3 = {sfp_in6[bw_psum-1], sfp_in6, 4'b0000} + {{(5){sfp_in7[bw_psum-1]}}, sfp_in7};

////////////////////////////// Assign outputs ///////////////////////

 always @(*)
 begin
	 if(!reconfigure) begin
 	 	sfp_out[bw_psum*1-1 : bw_psum*0] = sfp_out_sign0;
  		sfp_out[bw_psum*2-1 : bw_psum*1] = sfp_out_sign1;
  		sfp_out[bw_psum*3-1 : bw_psum*2] = sfp_out_sign2;
  		sfp_out[bw_psum*4-1 : bw_psum*3] = sfp_out_sign3;
  		sfp_out[bw_psum*5-1 : bw_psum*4] = sfp_out_sign4;
  		sfp_out[bw_psum*6-1 : bw_psum*5] = sfp_out_sign5;
  		sfp_out[bw_psum*7-1 : bw_psum*6] = sfp_out_sign6;
  		sfp_out[bw_psum*8-1 : bw_psum*7] = sfp_out_sign7;
	end
	else begin
		sfp_out[bw_psum*2-1 : bw_psum*0] = sfp_recon_out_sign0;
		sfp_out[bw_psum*4-1 : bw_psum*2] = sfp_recon_out_sign1;
		sfp_out[bw_psum*6-1 : bw_psum*4] = sfp_recon_out_sign2;
		sfp_out[bw_psum*8-1 : bw_psum*6] = sfp_recon_out_sign3;


	end
 end


 /////////////////////// Instantiating FIFO and Synchronisers ////////////////////////////

  fifo_depth16 #(.bw(sum_bw)) fifo_inst_int (
     .rd_clk(clk), 
     .wr_clk(clk), 
     .in(sum_q),
     .out(sum_this_core), 
     .rd(div_q), 
     .wr(fifo_wr), 
     .reset(reset)
  );
  
  sync sync_ack_in (
	  .in(ack_in),
	  .clk(clk), 
	  .out(ack_in_sync)
  ); 
  sync sync_req_in (
	  .in(req_in),
	  .clk(clk), 
	  .out(req_in_sync)
  ); 

     

  fifo_depth16 #(.bw(sum_bw)) fifo_inst_ext (
     .rd_clk(clk), 
     .wr_clk(clk), 
     .in(sum_q),
     .out(sum_out), 
     .rd(fifo_ext_rd), 
     .wr(fifo_wr), 
     .reset(reset)
  );
  
 assign fifo_ext_rd = ack_in_sync & (!ack_in_sync_dly); //posedge of ack_in
 assign ack_out = ack_out_delay2;
 assign sum_2core = sum_this_core + sum_in;

 

  always@(posedge clk) begin
	if (reset) begin
		ack_in_sync_dly <= 0;
	end  
	else begin 
		ack_in_sync_dly <= ack_in_sync;
	end
		
  end

  always @(posedge clk) begin
     if(reset) begin
	ack_out_delay1 <= 0;
	ack_out_delay2 <= 0;
    end
    else begin
	ack_out_delay1 <= req_in_sync;
	ack_out_delay2 <= ack_out_delay1;
    end
end    

  always @ (posedge clk) begin
    if (reset) begin
      fifo_wr <= 0;
    end
    else begin
       div_q <= div ;
       if (acc) begin
	      
	       if(!reconfigure)
      
         		sum_q <= 
           			abs(sfp_in0) +
           			abs(sfp_in1) +
          			abs(sfp_in2) +
           			abs(sfp_in3) +
           			abs(sfp_in4) +
           			abs(sfp_in5) +
           			abs(sfp_in6) +
           			abs(sfp_in7);
		else 
			sum_q <= 
				abs_recon(sfp_recon_in0) +
				abs_recon(sfp_recon_in1) + 
				abs_recon(sfp_recon_in2) +
			        abs_recon(sfp_recon_in3);	
				
         fifo_wr <= 1;
       end
       else begin
         fifo_wr <= 0;
	   if (div) begin
		   if(!reconfigure) begin
			   sfp_out_sign0 <= {abs(sfp_in0), 8'b0000_0000}/ sum_2core;
		   	   sfp_out_sign1 <= {abs(sfp_in1), 8'b0000_0000}/ sum_2core;
			   sfp_out_sign2 <= {abs(sfp_in2), 8'b0000_0000}/ sum_2core;
			   sfp_out_sign3 <= {abs(sfp_in3), 8'b0000_0000}/ sum_2core;
			   sfp_out_sign4 <= {abs(sfp_in4), 8'b0000_0000}/ sum_2core;
			   sfp_out_sign5 <= {abs(sfp_in5), 8'b0000_0000}/ sum_2core;
			   sfp_out_sign6 <= {abs(sfp_in6), 8'b0000_0000}/ sum_2core;
			   sfp_out_sign7 <= {abs(sfp_in7), 8'b0000_0000}/ sum_2core;
		   end
		   else begin
			   sfp_recon_out_sign0 <= {abs_recon(sfp_recon_in0), 8'b0000_0000} / sum_2core;
		   	   sfp_recon_out_sign1 <= {abs_recon(sfp_recon_in1), 8'b0000_0000} / sum_2core;
			   sfp_recon_out_sign2 <= {abs_recon(sfp_recon_in2), 8'b0000_0000} / sum_2core;
			   sfp_recon_out_sign3 <= {abs_recon(sfp_recon_in3), 8'b0000_0000} / sum_2core;
		   end
         end
       end
   end
 end


 function signed [bw_psum-1:0] abs(input signed [bw_psum-1:0] a);
	begin
		 if(a[bw_psum-1]==0)
			abs = a;
		 else
			abs = ~a+1;
	 end
 endfunction

  function signed [bw_psum+5-1:0] abs_recon(input signed [bw_psum+5-1:0] a);
	begin
		 if(a[bw_psum+5-1]==0)
			abs_recon = a;
		 else
			abs_recon = ~a+1;
	 end
 endfunction



endmodule


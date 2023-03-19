// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module fullchip (req_out_core1, req_out_core0, clk_core1, clk_core0, mem_in_core1, mem_in_core0, inst, reset, div_core1, div_core0, acc_core1, acc_core0, sel_pmem_core1, sel_pmem_core0,sum_out, out, is_signed, reconfigure);

parameter col = 8;
parameter bw = 4;
parameter bw_psum = 2*bw+3;
parameter pr = 8;
parameter sum_bw = bw_psum+7; //+2 for log4 +5 for shifted addn

input  clk_core1; 
input  clk_core0; 
input  div_core1; 
input  acc_core1; 
input  sel_pmem_core1; 
input  [pr*bw-1:0] mem_in_core1; 
input  div_core0; 
input  acc_core0; 
input  sel_pmem_core0; 
input  [pr*bw-1:0] mem_in_core0; 
input  [16:0] inst; 
input  reset;
input is_signed, reconfigure;
output [sum_bw:0] sum_out;
output [2*bw_psum*col-1:0] out;

input req_out_core1, req_out_core0;
wire ack_out_core0, ack_out_core1;
wire [sum_bw-1:0] sum_out_core0, sum_out_core1;
wire [bw_psum*col-1:0] out_core1, out_core2;

assign sum_out = sum_out_core0 + sum_out_core1;
assign out = {out_core1,out_core2};

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core1_instance (
      .reset(reset), 
      .clk(clk_core1), 
      .mem_in(mem_in_core1), 
      .out(out_core1),
      .div(div_core1),
      .acc(acc_core1),
      .sel_pmem(sel_pmem_core1),
      .req_in(req_out_core0), 
      .req_out(), 
      .ack_in(ack_out_core0),
      .ack_out(ack_out_core1), 
      .sum_in(sum_out_core0), 
      .sum_out(sum_out_core1),
      .inst(inst),
      .is_signed(is_signed),
      .reconfigure(reconfigure) 
);

core #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) core0_instance (
      .reset(reset), 
      .clk(clk_core0), 
      .mem_in(mem_in_core0), 
      .out(out_core2),
      .div(div_core0),
      .acc(acc_core0),
      .sel_pmem(sel_pmem_core0),
      .req_in(req_out_core1), 
      .req_out(), 
      .ack_in(ack_out_core1),
      .ack_out(ack_out_core0), 
      .sum_in(sum_out_core1), 
      .sum_out(sum_out_core0),
      .inst(inst),
      .is_signed(is_signed),
      .reconfigure(reconfigure) 

);

endmodule

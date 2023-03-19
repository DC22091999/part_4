// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

// Abhishek: Part 4 testbench Dual-Core
`timescale 1ns/1ps

module fullchip_tb;

parameter total_cycle = 8;   // how many streamed Q vectors will be processed
parameter bw = 4;            // Q & K vector bit precision
parameter bw_psum = 2*bw+3;  // partial sum bit precision
parameter pr = 8;           // how many products added in each dot product 
parameter col = 8;           // how many dot product units are equipped
parameter sum_bw = bw_psum+7;

integer qk_file ; // file handler
integer qk_scan_file ; // file handler


integer  captured_data;
integer  weight [col*pr-1:0];
`define NULL 0




integer  K_core0[col-1:0][pr-1:0];
integer  K_core1[col-1:0][pr-1:0];
integer  Q_core0[total_cycle-1:0][pr-1:0];
//integer  Q_core0[total_cycle*2-1:0][pr-1:0];
integer  result_core0[total_cycle-1:0][col-1:0];
integer  sum_core0[total_cycle-1:0];
integer  result_core1[total_cycle-1:0][col-1:0];
integer  sum_core1[total_cycle-1:0];
integer  sum_combined[total_cycle-1:0];

integer i,j,k,t,p,q,s,u, m;




reg reset = 1;
reg clk_core1 = 0;
reg clk_core0 = 0;
reg [pr*bw-1:0] mem_in_core1; 
reg [pr*bw-1:0] mem_in_core0; 
reg ofifo_rd = 0;
wire [16:0] inst; 
reg qmem_rd = 0;
reg qmem_wr = 0; 
reg kmem_rd = 0; 
reg kmem_wr = 0;
reg pmem_rd = 0; 
reg pmem_wr = 0; 
reg execute = 0;
reg load = 0;
reg div_core1 = 0;
reg div_core0 = 0;
reg acc_core1 = 0;
reg acc_core0 = 0;
reg sel_pmem_core1 = 1;
reg sel_pmem_core0 = 1;
reg [3:0] qkmem_add = 0;
reg [3:0] pmem_add = 0;
reg req_out_core0 = 0;
reg req_out_core1 = 0;
reg reconfigure = 0;
reg is_signed = 1;


assign inst[16] = ofifo_rd;
assign inst[15:12] = qkmem_add;
assign inst[11:8]  = pmem_add;
assign inst[7] = execute;
assign inst[6] = load;
assign inst[5] = qmem_rd;
assign inst[4] = qmem_wr;
assign inst[3] = kmem_rd;
assign inst[2] = kmem_wr;
assign inst[1] = pmem_rd;
assign inst[0] = pmem_wr;



reg [bw_psum-1:0] temp5b_core0;
//reg [bw_psum+3:0] temp_sum_core0;
reg [bw_psum*col-1:0] temp16b_core0;
reg [bw_psum-1:0] temp5b_core1;
//reg [bw_psum+3:0] temp_sum_core1;
reg [bw_psum*col-1:0] temp16b_core1;

reg [bw_psum*col-1:0] exp_out_core0 [col-1:0];
reg [bw_psum*col-1:0] exp_out_core1 [col-1:0];
reg [bw_psum*col-1:0] norm_out_core0 [col-1:0];
reg [bw_psum*col-1:0] norm_out_core1 [col-1:0];


fullchip #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr), .sum_bw(sum_bw)) fullchip_instance (
      .reset(reset),
      .clk_core1(clk_core1), 
      .mem_in_core1(mem_in_core1), 
      .div_core1(div_core1),
      .acc_core1(acc_core1),
      .sel_pmem_core1(sel_pmem_core1), 
      .clk_core0(clk_core0), 
      .mem_in_core0(mem_in_core0), 
      .div_core0(div_core0),
      .acc_core0(acc_core0),
      .sel_pmem_core0(sel_pmem_core0), 
      .inst(inst),
      .req_out_core1(req_out_core1),
      .req_out_core0(req_out_core0),
      .is_signed(is_signed),
      .reconfigure(reconfigure)
);

function integer abs(input integer a); begin
	if(a<0) abs = 0-a;
	else abs = a;
end
endfunction


initial begin 

  $dumpfile("fullchip_tb.vcd");
  $dumpvars(0,fullchip_tb);



///// Q data txt reading /////

$display("##### Q data txt reading #####");
  qk_file = reconfigure? $fopen("vdata.txt", "r") : $fopen("qdata.txt","r");
  for (q=0; q<total_cycle; q=q+1) begin
    for (j=0; j<pr; j=j+1) begin
          qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
	  Q_core0[q][j] = captured_data;
	  $display("Q[%2d][%2d] = %2d", q, j, Q_core0[q][j]);
    end
  end
/////////////////////////////////




  for (q=0; q<2; q=q+1) begin
    #0.5 clk_core1 = 1'b0; clk_core0 = 1'b0;   
    #0.5 clk_core1 = 1'b1; clk_core0 = 1'b1;   
  end
$display("##### K data txt reading #####");

if(reconfigure == 0) begin

	//////////// K DATA txt READING for non-RECONF Mode ////////////////////

	for (q=0; q<10; q=q+1) begin
		#0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
    		#0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;  
  	end
  	reset = 0;

  	qk_file = $fopen("kdata_core0.txt", "r");

  	for (q=0; q<col; q=q+1) begin
    		for (j=0; j<pr; j=j+1) begin
          		qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
          		K_core0[q][j] = captured_data;
          		$display("#####   K_core0[%2d][%2d] = %d\n", q, j, K_core0[q][j]);
			
    		end
  	end

  	qk_file = $fopen("kdata_core1.txt", "r");

	for (q=0; q<col; q=q+1) begin
    		for (j=0; j<pr; j=j+1) begin
          		qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
          		K_core1[q][j] = captured_data;
          		$display("#####   K_core1[%2d][%2d] = %d\n", q, j, K_core1[q][j]);
			
    		end
  	end

	/////////// END of K DATA .txt file reading for non-RECONF Mode ////////

end //end of if(reconf - read Kdata-core_0&1

else begin
	/////////// K DATA txt READING for RECONF Mode /////////////

	for (q=0; q<10; q=q+1) begin
   		#0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
    		#0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;  
  	end
  	reset = 0;

  	qk_file = $fopen("ndata_core0.txt", "r");

  	for (q=0; q<col; q=q+2) begin
    		for (j=0; j<pr; j=j+1) begin
          		qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
         		K_core0[q][j] = captured_data%16;
	  		K_core0[q+1][j] = captured_data/16;
          		//$display("#####   K_core0[%2d][%2d] = %d\n", q, j, K_core0[q][j]);
    		end
  	end
  	qk_file = $fopen("ndata_core1.txt", "r");


	for (q=0; q<col; q=q+2) begin
    		for (j=0; j<pr; j=j+1) begin
          		qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
          		K_core1[q][j] = captured_data%16;
	 		K_core1[q+1][j] = captured_data/16;
          		//$display("#####   K_core1[%2d][%2d] = %d\n", q, j, K_core0[q][j]);
    		end
  	end
	////////// END of K_data REading from .txt files ///////////////////////////////
end ////end of if(reconf - read Kdata-core_0&1








/////////////// Estimated result printing /////////////////


$display("##### Estimated multiplication result #####");

  for (t=0; t<total_cycle; t=t+1) begin
     for (q=0; q<col; q=q+1) begin
       result_core1[t][q] = 0;
       result_core0[t][q] = 0;
     end
     sum_core0[t] = 0;
     sum_core1[t] = 0;
  end

  for (t=0; t<total_cycle; t=t+1) begin
     for (q=0; q<col; q=q+1) begin
         for (k=0; k<pr; k=k+1) begin
		 result_core0[t][q] = result_core0[t][q] + Q_core0[t][k] * K_core0[q][k];
		 result_core1[t][q] = result_core1[t][q] + Q_core0[t][k] * K_core1[q][k];
		 //$display("%d x %d = %d", Q_core0[t][k], K_core0[q][k], Q_core0[t][k] * K_core0[q][k]);
         end
	 temp5b_core0 = result_core0[t][q];
	 temp16b_core0 = {temp16b_core0[76:0], temp5b_core0};

	 sum_core0[t] = sum_core0[t] + abs(result_core0[t][q]);

 	 temp5b_core1 = result_core1[t][q];         	
	 temp16b_core1 = {temp16b_core1[76:0], temp5b_core1};
	 sum_core1[t] = sum_core1[t] + abs(result_core1[t][q]); 
	end
	
	$display("############# PRODUCT CYCLE %2d ############", t);

	$display("Core_0: %2d %2d %2d %2d %2d %2d %2d %2d", result_core0[t][0], result_core0[t][1], result_core0[t][2], result_core0[t][3], result_core0[t][4], result_core0[t][5], result_core0[t][6], result_core0[t][7]);

	$display("Core_1: %2d %2d %2d %2d %2d %2d %2d %2d", result_core1[t][0], result_core1[t][1], result_core1[t][2], result_core1[t][3], result_core1[t][4], result_core1[t][5], result_core1[t][6], result_core1[t][7]);
	
	$display("SUM core0 = %2d", sum_core0[t]);
	$display("SUM core1 = %2d", sum_core1[t]);
     
	$display("core0 before norm prd @cycle%2d: %40h", t, temp16b_core0);     
	$display("core1 before norm prd @cycle%2d: %40h", t, temp16b_core1);

	exp_out_core0[t] = temp16b_core0;
	exp_out_core1[t] = temp16b_core1;

     for(q=0; q<col; q=q+1) begin
	     result_core0[t][q] = abs(result_core0[t][q])*256/(sum_core0[t]+sum_core1[t]);
	     temp5b_core0 = result_core0[t][q];
	     temp16b_core0 = {temp16b_core0[76:0], temp5b_core0};

	     result_core1[t][q] = abs(result_core1[t][q])*256/(sum_core0[t]+sum_core1[t]);
	     temp5b_core1 = result_core1[t][q];
	     temp16b_core1 = {temp16b_core1[76:0], temp5b_core1};

     end
     
     $display("After Norm Core0: %d %d %d %d %d %d %d %d", result_core0[t][0], result_core0[t][1], result_core0[t][2], result_core0[t][3], result_core0[t][4], result_core0[t][5], result_core0[t][6], result_core0[t][7]);
     $display("After Norm Core1: %d %d %d %d %d %d %d %d", result_core1[t][0], result_core1[t][1], result_core1[t][2], result_core1[t][3], result_core1[t][4], result_core1[t][5], result_core1[t][6], result_core1[t][7]);
//
     $display("Core0 Norm prd @cycle%2d after norm: %40h", t, temp16b_core0);
     $display("Core1 Norm prd @cycle%2d after norm: %40h", t, temp16b_core1);

     norm_out_core0[t] = temp16b_core0;
     norm_out_core1[t] = temp16b_core1;
	
 end

//////////////////////////////////////////////






///// Qmem writing  /////

$display("%t ##### Qmem writing  #####", $time);

  for (q=0; q<total_cycle; q=q+1) begin

    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    qmem_wr = 1;  if (q>0) qkmem_add = qkmem_add + 1; 

    mem_in_core0[1*bw-1:0*bw] = $signed(Q_core0[q][0]);
    mem_in_core0[2*bw-1:1*bw] = $signed(Q_core0[q][1]);
    mem_in_core0[3*bw-1:2*bw] = $signed(Q_core0[q][2]);
    mem_in_core0[4*bw-1:3*bw] = $signed(Q_core0[q][3]);
    mem_in_core0[5*bw-1:4*bw] = $signed(Q_core0[q][4]);
    mem_in_core0[6*bw-1:5*bw] = $signed(Q_core0[q][5]);
    mem_in_core0[7*bw-1:6*bw] = $signed(Q_core0[q][6]);
    mem_in_core0[8*bw-1:7*bw] = $signed(Q_core0[q][7]);
    /*mem_in_core0[9*bw-1:8*bw] = Q_core0[q][8];
    mem_in_core0[10*bw-1:9*bw] = Q_core0[q][9];
    mem_in_core0[11*bw-1:10*bw] = Q_core0[q][10];
    mem_in_core0[12*bw-1:11*bw] = Q_core0[q][11];
    mem_in_core0[13*bw-1:12*bw] = Q_core0[q][12];
    mem_in_core0[14*bw-1:13*bw] = Q_core0[q][13];
    mem_in_core0[15*bw-1:14*bw] = Q_core0[q][14];
    mem_in_core0[16*bw-1:15*bw] = Q_core0[q][15]; */

    mem_in_core1[1*bw-1:0*bw] = $signed(Q_core0[q][0]);
    mem_in_core1[2*bw-1:1*bw] = $signed(Q_core0[q][1]);
    mem_in_core1[3*bw-1:2*bw] = $signed(Q_core0[q][2]);
    mem_in_core1[4*bw-1:3*bw] = $signed(Q_core0[q][3]);
    mem_in_core1[5*bw-1:4*bw] = $signed(Q_core0[q][4]);
    mem_in_core1[6*bw-1:5*bw] = $signed(Q_core0[q][5]);
    mem_in_core1[7*bw-1:6*bw] = $signed(Q_core0[q][6]);
    mem_in_core1[8*bw-1:7*bw] = $signed(Q_core0[q][7]);
    /*mem_in_core1[9*bw-1:8*bw] = Q_core0[q][8];
    mem_in_core1[10*bw-1:9*bw] = Q_core0[q][9];
    mem_in_core1[11*bw-1:10*bw] = Q_core0[q][10];
    mem_in_core1[12*bw-1:11*bw] = Q_core0[q][11];
    mem_in_core1[13*bw-1:12*bw] = Q_core0[q][12];
    mem_in_core1[14*bw-1:13*bw] = Q_core0[q][13];
    mem_in_core1[15*bw-1:14*bw] = Q_core0[q][14];
    mem_in_core1[16*bw-1:15*bw] = Q_core0[q][15]; */

    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 

  end


  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
  qmem_wr = 0; 
  qkmem_add = 0;
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 
///////////////////////////////////////////





///// Kmem writing  /////

$display("%t ##### Kmem writing #####", $time);

  for (q=0; q<col; q=q+1) begin

    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    kmem_wr = 1; if (q>0) qkmem_add = qkmem_add + 1; 


    mem_in_core1[1*bw-1:0*bw] = $signed(K_core1[q][0]);
    mem_in_core1[2*bw-1:1*bw] = $signed(K_core1[q][1]);
    mem_in_core1[3*bw-1:2*bw] = $signed(K_core1[q][2]);
    mem_in_core1[4*bw-1:3*bw] = $signed(K_core1[q][3]);
    mem_in_core1[5*bw-1:4*bw] = $signed(K_core1[q][4]);
    mem_in_core1[6*bw-1:5*bw] = $signed(K_core1[q][5]);
    mem_in_core1[7*bw-1:6*bw] = $signed(K_core1[q][6]);
    mem_in_core1[8*bw-1:7*bw] = $signed(K_core1[q][7]);
   /* mem_in_core1[9*bw-1:8*bw] = K_core1[q][8];
    mem_in_core1[10*bw-1:9*bw] = K_core1[q][9];
    mem_in_core1[11*bw-1:10*bw] = K_core1[q][10];
    mem_in_core1[12*bw-1:11*bw] = K_core1[q][11];
    mem_in_core1[13*bw-1:12*bw] = K_core1[q][12];
    mem_in_core1[14*bw-1:13*bw] = K_core1[q][13];
    mem_in_core1[15*bw-1:14*bw] = K_core1[q][14];
    mem_in_core1[16*bw-1:15*bw] = K_core1[q][15];*/

    mem_in_core0[1*bw-1:0*bw] = $signed(K_core0[q][0]);
    mem_in_core0[2*bw-1:1*bw] = $signed(K_core0[q][1]);
    mem_in_core0[3*bw-1:2*bw] = $signed(K_core0[q][2]);
    mem_in_core0[4*bw-1:3*bw] = $signed(K_core0[q][3]);
    mem_in_core0[5*bw-1:4*bw] = $signed(K_core0[q][4]);
    mem_in_core0[6*bw-1:5*bw] = $signed(K_core0[q][5]);
    mem_in_core0[7*bw-1:6*bw] = $signed(K_core0[q][6]);
    mem_in_core0[8*bw-1:7*bw] = $signed(K_core0[q][7]);
    /*mem_in_core0[9*bw-1:8*bw] = K_core0[q][8];
    mem_in_core0[10*bw-1:9*bw] = K_core0[q][9];
    mem_in_core0[11*bw-1:10*bw] = K_core0[q][10];
    mem_in_core0[12*bw-1:11*bw] = K_core0[q][11];
    mem_in_core0[13*bw-1:12*bw] = K_core0[q][12];
    mem_in_core0[14*bw-1:13*bw] = K_core0[q][13];
    mem_in_core0[15*bw-1:14*bw] = K_core0[q][14];
    mem_in_core0[16*bw-1:15*bw] = K_core0[q][15];*/

    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 

  end

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
  kmem_wr = 0;  
  qkmem_add = 0;
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 
///////////////////////////////////////////



  for (q=0; q<2; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;
    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 
  end




/////  K data loading  /////
$display("##### K data loading to processor #####");

  for (q=0; q<col+1; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    load = 1; 
    if (q==1) kmem_rd = 1;
    if (q>1) begin
       qkmem_add = qkmem_add + 1;
    end

    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 
  end

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
  kmem_rd = 0; qkmem_add = 0;
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
  load = 0; 
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 

///////////////////////////////////////////

 for (q=0; q<10; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;  
 end





///// execution  /////
$display("##### execute #####");

  for (q=0; q<total_cycle; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    execute = 1; 
    qmem_rd = 1;

    if (q>0) begin
       qkmem_add = qkmem_add + 1;
    end

    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;
  end

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
  qmem_rd = 0; qkmem_add = 0; execute = 0;
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 


///////////////////////////////////////////

 for (q=0; q<10; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;  
 end




////////////// output fifo rd and wb to psum mem ///////////////////

$display("##### move ofifo to pmem #####");

  for (q=0; q<total_cycle; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    ofifo_rd = 1; 
    pmem_wr = 1; 
    sel_pmem_core0 = 1;
    sel_pmem_core1 = 1;

    if (q>0) begin
       pmem_add = pmem_add + 1;
    end

    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;
     
  end

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
  pmem_wr = 0; pmem_add = 0; ofifo_rd = 0;
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 

///////////////////////////////////////////

//SFP Loading

$display("##### move pmem to sfp for sum #####");

  for (q=0; q<total_cycle * 2; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
    pmem_rd = 1; 
    sel_pmem_core0 = 0;
    sel_pmem_core1 = 0;

    if (q%2 == 1) begin
	acc_core1 = 1;
	acc_core0 = 1;
	end
	else begin
	acc_core1 = 0;
	acc_core0 = 0;
	end


    if (q>0 && q%2 == 0) begin
       pmem_add = pmem_add + 1;
    end

    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;  
  end

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
  pmem_rd = 0; pmem_add = 0; sel_pmem_core0 = 1;sel_pmem_core1 = 1; acc_core0 = 0; acc_core1 = 0;
  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;

///////////////////////////////////////////

 for (q=0; q<10; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;  
 end

//Dividing by Sum and writing back to pmem
  
for (q=0; q<total_cycle * 9 ; q=q+1) begin
    #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0; 
    sel_pmem_core0 = 0;
    sel_pmem_core1 = 0;

   if (q%9 == 0)
    pmem_rd = 1;

    if(q%9 == 1) begin
	req_out_core0 = 1;
	req_out_core1 = 1;
    end



    if (q%9 == 6) begin
	div_core0 = 1;
	div_core1 = 1;
	pmem_rd = 0;
	req_out_core0 = 0;
	req_out_core1 = 0;
    end

    else begin 
	    div_core0 = 0;
            div_core1 = 0;
    end

   

    if (q > 0 && q%9 == 0) begin
       pmem_add = pmem_add + 1;
    end

   if (q%9 == 7)
	pmem_wr = 1;
   else 
	pmem_wr = 0;



    #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1;
  end

  #0.5 clk_core0 = 1'b0; clk_core1 = 1'b0;  
  pmem_rd = 0; pmem_add = 0; div_core0 = 0; div_core1 = 0; pmem_wr = 0; sel_pmem_core1 = 1; sel_pmem_core0 = 1; req_out_core0 = 0; req_out_core1 = 0;
    

  #0.5 clk_core0 = 1'b1; clk_core1 = 1'b1; 


$display("##### move sum to sfp for normalization #####");

///////////////////////////////////////////



  #10 $finish;


end

endmodule






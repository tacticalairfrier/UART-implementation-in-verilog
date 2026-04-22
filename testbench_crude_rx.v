`timescale 1ns/1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module testbench;
//reg for across the bench
reg clkgen, reset; 
//uart tx, rx 
//reg data types
reg [7:0] data_tx;
reg TX_enable;
//wire data types here
wire[7:0] data_rx;
wire data_line;
wire error_flag_tb, rx_done_tb, parity_err_tb;
//uart rx side
UART_rx DUT0 (
    .clkin(clkgen),
    .reset(reset),
    .data_in(data_line),
    .data_out(data_rx),
    .error_flag(error_flag_tb),
    .rx_done(rx_done_tb),
    .parity_err(parity_err_tb)
);
//uart tx side
UART_tx DUT1 (
    .clkin(clkgen),
    .reset(reset),
    .data_in(data_tx),
    .data_out(data_line),
    .TX_enable(TX_enable)
);
//reset block
initial begin 
    clkgen = `TRUE;
    reset = `TRUE;
    #5 reset = `FALSE;
    #5 reset = `TRUE;
    #5 TX_enable =`TRUE;
end
//clock generator
always #10 clkgen = ~clkgen;
//Random number generation for the transmtition
always #86800 begin
    data_tx = $urandom_range(0,255);
end

initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,testbench);
    $monitor($time,"the value of input was %d while the value of output is %d", data_tx, data_rx);
    //setting data to some random variable at time =0 
    data_tx = $urandom_range(0,255);
    #11000000
    $finish;
end
endmodule
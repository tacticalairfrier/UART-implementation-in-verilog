`timescale 1ns/1ps
`default_nettype none

module testbench;

reg [7:0] data_in_tb;
reg clkgen, reset, TX_enable_tb;
wire data_out_tb;
// //debug ports
// wire [2:0] debug_state_tb, debug_nextstate_tb;
// wire debug_baud_tick_tb, debug_parity_tb;
UART_tx DUT(
    .data_in(data_in_tb),
    .clkin(clkgen),
    .reset(reset),
    .TX_enable(TX_enable_tb),
    .data_out(data_out_tb)
    // //debug ports
    // .debug_baud(debug_baud_tick_tb),
    // .debug_state(debug_state_tb),
    // .debug_nextstate(debug_nextstate_tb),
    // .debug_parity(debug_parity_tb)
);

initial begin 
    clkgen = 1'b1;
    reset = 1'b1;
    #5 reset = 1'b0;
    #5 reset = 1'b1;
end

always #10 clkgen = ~clkgen;
//01100011

initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,testbench);
    TX_enable_tb = 1'b1;
    data_in_tb = 8'b01000011;
    $monitor($time, "at this time the value of out register is %b", data_out_tb);
    #100000;
    TX_enable_tb = 1'b0;
    #100000;
    $finish;
end

endmodule
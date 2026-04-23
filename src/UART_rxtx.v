`timescale 1ns/1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module combinedRXTX(
    input wire rx, clkgen, reset, 
    output wire tx, pari
);
//reg for across the bench
//uart tx, rx 
// //reg data types
// reg [7:0] data_tx;
// reg TX_enable;
// //wire data types here
// wire[7:0] data_rx;
// wire data_line;
// wire error_flag_tb, rx_done_tb, parity_err_tb;
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
endmodule 
`timescale 1ns/1ps
`default_nettype none

module Combined_RXTX(
    input wire rx, clkgen, reset, tx_enable, 
    input wire [7:0] data_tx,
    output wire tx, parity_err, error_flag, rx_done,
    output wire [7:0] data_rx
);
//using this module to :-
//1.combine the rxtx operation into a single module
//2.handle inputs and outputs in hopefully a more graceful way
//uart rx side
UART_rx M_RX_0 (
    .clkin(clkgen),
    .reset(reset),
    .data_in(rx),
    .data_out(data_rx),
    .error_flag(error_flag),
    .rx_done(rx_done),
    .parity_err(parity_err)
);
//uart tx side
UART_tx M_TX_0 (
    .clkin(clkgen),
    .reset(reset),
    .data_in(data_tx),
    .data_out(tx),
    .TX_enable(tx_enable)
);
endmodule 
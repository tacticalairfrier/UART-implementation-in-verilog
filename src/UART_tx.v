`timescale 1ns/1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module UART_tx #(parameter CLK_FREQ = 50_000_000, BAUD_RATE = 115200)(
    input wire [7:0] data_in,
    input wire clkin, reset, TX_enable,
    output reg data_out
);
//declaring the params for the states of the uart controller
localparam BAUD_PERIOD = CLK_FREQ/BAUD_RATE;
localparam IDLE = 3'd0, START = 3'd1, STOP = 3'd2, DATA = 3'd3, PARITY = 3'd4;
localparam DATCOUNT = 3'd7;
//declaring the register and storage elements
//declaring all the counter regs here
//this block is to be optimised 
reg [8:0] count_tick = BAUD_PERIOD;
reg [7:0] shiftreg, shiftregnext;
reg [2:0] datcount = DATCOUNT;
//state registers here
reg [2:0] state, nextstate;
reg data, datanext;
reg baud_tick, parity_bit;
//BAUD tick generator for 115200 baud rate at 50mhz which can be configured
//this part is perfectly optimised and is verified to work
always@(posedge clkin, negedge reset)begin 
    if(!reset)begin
        count_tick <= BAUD_PERIOD;
        baud_tick <= 1'b0;
    end
    else if(count_tick>1)begin
        count_tick <= count_tick-1;
        baud_tick <= 1'b0;
    end
    else begin 
        count_tick <= BAUD_PERIOD;
        baud_tick <= 1'b1;
    end
end
//state driver some parts of this can be optimised
always@(posedge clkin, negedge reset)begin
    //reset logic
    if(!reset) begin 
        state <= IDLE;
        data_out <= 1'b1;
        datcount <= DATCOUNT;
    end
    else if(baud_tick) begin
    case(state)
    //idle just skips to the next state and outputs 1 in data_out
    IDLE: state <= nextstate; 
    //start param signals the start of the data transfer to the rx side
    START: begin 
        state <= nextstate;
        shiftreg <= shiftregnext;
    end
    // The data transfer part of the code, uses a shift register to control the output
    DATA:begin
        shiftreg <= shiftregnext;
        datcount <= datcount-1;
        state <= nextstate;
    end
    PARITY:begin
        //shiftregnext stays the same as out is controlled by a separate reg
        shiftreg <= shiftregnext;
        //resetting the datcount when the parity condition arrives
        datcount <= DATCOUNT;
        state <= nextstate;
    end
    STOP: state <= nextstate;  //stop condition sets the output bit to 1
    endcase
    end
end
//next state logic for uart tx
// NSL code blocks need a lot of optimization
always@(*)begin
    //preventing latch inferrence
    nextstate = state;
    case(TX_enable)
    `TRUE: begin
        case(state)
        //at idle when the enable is high the next state is start 
        IDLE: nextstate = START;
        // at start the next state is data
        START: nextstate = DATA;
        //at data there are 2 possible conditions ,when the counter is 0 and when its 1,
        DATA: begin 
            //when its not 0, the nextstate is again data
            if(datcount>0) nextstate = DATA; 
            //when its 0, the nextstate is stop
            else nextstate = PARITY;
        end
        //at stop the ideal next state is idle
        PARITY:nextstate = STOP;
        //error here as nextstate should not be idle, need to test it
        STOP: nextstate = START;
        endcase
    end
    `FALSE: begin 
        case(state)
        //only thing here that is different is this
        IDLE: nextstate = IDLE;
        START: nextstate = DATA;
        DATA: begin 
            //when its not 0, the nextstate is again data
            if(datcount>0) nextstate = DATA; 
            //when its 0, the nextstate is stop
            else nextstate = PARITY;
        end
        PARITY: nextstate = STOP;
        STOP: nextstate = IDLE;
        endcase
    end
    endcase
end
//driving the states of the state register
always@(*)begin 
    //making the right shift register
    //prevented latch inference
    shiftregnext = shiftreg;
    case(state)
    //adding the parity calculation right here in the start block
    START: begin 
        shiftregnext = data_in;
        parity_bit = ^data_in;
    end
    DATA: shiftregnext = shiftreg>>1;
    //figure out the shiftreg value here or is it needed at all
    PARITY: shiftregnext = shiftreg;
    endcase
end
//always block added to check if the output still lags behind one tick when simualted
always@(*)begin 
    case(state)
    //the data reg changes right at the instant of the baud tick
    IDLE: data_out = 1'b1;
    START: data_out = 1'b0;
    DATA: data_out = shiftreg[0];
    PARITY: data_out = parity_bit;
    STOP: data_out = 1'b1;
    endcase
end
endmodule

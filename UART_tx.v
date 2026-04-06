`timescale 1ns/1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module UART_tx #(parameter CLK_FREQ = 50_000_000, BAUD_RATE = 115200)(
    input wire [7:0] data_in,
    input wire clkin, reset, TX_enable,
    output reg data_out,
    //debug ports
    output wire debug_baud,
    output wire[1:0] debug_state,
    output wire [1:0] debug_nextstate
);
//declaring the params for the states of the uart controller
localparam BAUD_PERIOD = CLK_FREQ/BAUD_RATE;
localparam IDLE = 2'd0, START = 2'd1, STOP = 2'd2, DATA = 2'd3;
localparam DATCOUNT = 3'd7;
//declaring the register and storage elements
//declaring all the counter regs here
reg [31:0] count_tick = BAUD_PERIOD;
reg [2:0] datcount = DATCOUNT;
//sttate registers here
reg [1:0] state, nextstate;
reg [7:0] shiftreg, shiftregnext;
reg data, datanext;
reg baud_tick;

//debug assignments to monitor the status of fsm
assign debug_baud = baud_tick;
assign debug_state = state;
assign debug_nextstate = nextstate;

//BAUD tick generator for 115200 baud rate at 50mhz which can be configured
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

//state driver
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
    IDLE: begin 
        state <= nextstate; 
    end
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
    STOP: begin
        //stop condition sets the output bit to 1
        state <= nextstate;
        datcount <= DATCOUNT;
    end
    endcase
    end
end

//next state logic for uart tx
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
            else nextstate = STOP;
        end
        //at stop the ideal next state is idle
        STOP: nextstate = IDLE;
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
            else nextstate = STOP;
        end
        STOP: nextstate = IDLE;
        endcase
    end
    endcase
end
//find the error here
//driving the states of the state register
always@(*)begin 
    //making the right shift register
    //prevented latch inference
    shiftregnext = shiftreg;
    case(state)
    START: shiftregnext = data_in;
    DATA: shiftregnext = shiftreg>>1;
    endcase
end

//always block added to check if the output still lags behind one tick when simualted
always@(*)begin 
    case(state)
    START: data_out = 1'b0;
    DATA: data_out = shiftreg[0];
    STOP: data_out = 1'b1;
    endcase
end
endmodule

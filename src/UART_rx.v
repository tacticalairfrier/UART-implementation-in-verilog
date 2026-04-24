`timescale 1ns/1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module UART_rx #(parameter CLK_FREQ = 100_000_000, BAUD_RATE = 115200)(
    input wire data_in, clkin, reset, 
    output reg [7:0] data_out,
    //defining the flags here
    output reg error_flag, rx_done, parity_err
);
//declaring the paramets for the reciever module
//the uart rx side uses oversampling to account for some amount of time delay
localparam BAUD_OVERSAMPLE = CLK_FREQ/(BAUD_RATE*16);
localparam IDLE = 3'd0, STOP = 3'd1, START = 3'd2, DATA = 3'd3, PARITY = 3'd4, ERROR_RX = 3'd5;
localparam DATCOUNT = 3'd7;
localparam SAMPLEX8 = 4'd7, SAMPLEX16 = 4'd15;
//declaring the register variables for the state and next state logic
reg [7:0] shiftreg, shiftregnext;
reg [4:0] samplex16_counter; 
reg [3:0] sample_counter, sample_counter_next, data_counter, data_counter_next; 
reg [2:0] state, nextstate; 
reg  rx, rx_prev, edgedetected;
//determined by fsm are sample counter data counter and state register
//using defining rx as a parameter in this finite state machine
//edge detected will be true if and only if previous state was idle and a transition has happened
//baud tick generator for samplex16
//this part works as intended
always@(posedge clkin, negedge reset)begin 
    if(!reset)begin
        samplex16_counter <= BAUD_OVERSAMPLE;
        state <= IDLE;
        rx <= `FALSE;   // RX is false upon reset;
        rx_prev = `FALSE;
        data_counter <= DATCOUNT;
        data_out <= 8'b0;
        sample_counter <= SAMPLEX8;
        shiftreg <= 8'b0;
    end
    else if(samplex16_counter>0) samplex16_counter <= samplex16_counter-1;
    else begin
        samplex16_counter <= BAUD_OVERSAMPLE; 
        rx <= data_in;  //here rx recieves the value of the data input 
        rx_prev <= rx;  //here rx_prev recieves the older value of the inputted data   
        sample_counter <= sample_counter_next;
        case(state)
            IDLE:begin
                //the machine enters the start condtion after an edge is detected
                //OPTIMISE THIS 
                state <= nextstate;
            end
            START:begin
                sample_counter <= sample_counter_next;
                state <= nextstate;
                
            end
            DATA:begin
                //machine is in data mode for 8 iterations
                state <= nextstate;
                //machine counts down to zero in the data counter
                data_counter <= data_counter_next;
                shiftreg <= shiftregnext;
            end
            PARITY:begin 
                state <= nextstate;
            end
            STOP:begin
                state <= nextstate;
            end
            ERROR_RX:begin
             state <= nextstate;
             end
        endcase
        if(rx_done) data_out <= shiftreg;
    end
end
//code for the state nextstate transistion
// end
//deciding the nextstate logic here and the output control
always@(*)begin
    //if the previous and now values are complements then edgedetected will be high,
    //it will be considered in idle and stop conditions and will be disregarded otherwise
    //we immediately get to know what the state of the edge is in order to switch the states
    edgedetected = rx_prev&~rx;
    //preventing latch inferrence for 7 variables
    nextstate = state;
    shiftregnext = shiftreg;
    sample_counter_next = sample_counter;
    data_counter_next = data_counter;
    parity_err = `FALSE;
    error_flag = `FALSE;
    rx_done = `FALSE;
    case(state)
    IDLE: begin
        if(edgedetected)begin
            //setting the counter to samplex8 to get to rougly the middle of the data
            sample_counter_next = SAMPLEX8;
            //immediately transferring the machine to the start state after a successful
            //edge detection
            nextstate = START;
        end
    end
    START:begin
        if(sample_counter>0)begin
            //decrementing the sample counter here and keeping hte state constant
            sample_counter_next = sample_counter-1;
            nextstate = state;
        end
        else if(sample_counter == 0 && !rx)begin
            //detects true start by checking sample counter and the current rx value
            //true start detected in idle
            nextstate = DATA;
            sample_counter_next = SAMPLEX16;
        end
        else begin
            //default condition for this
            nextstate = IDLE;
            sample_counter_next = 4'b0;
        end
    end
    DATA:begin
        //counter decrement condition
        if(sample_counter>0)sample_counter_next = sample_counter-1;
        else begin
            shiftregnext = {rx, shiftreg[7:1]};
            sample_counter_next = SAMPLEX16;
            if(data_counter>0) begin
                nextstate = DATA;
                data_counter_next = data_counter-1;
                //datcount-data_counter because the encoding was big endian on the rx side
                //and we need output in little endian style
            end
            else begin
                nextstate = PARITY;
                data_counter_next = DATCOUNT;
            end
        end
    end
    PARITY: begin
        if(sample_counter>0)sample_counter_next = sample_counter-1;
        else begin
            //check parity here
            nextstate = STOP;
            sample_counter_next = SAMPLEX16;
            //parity can be checked using simple combinational logic
            if(^shiftreg!=rx) parity_err = `TRUE;
            else parity_err = `FALSE;
        end
    end
    STOP: begin
        if(sample_counter>0)sample_counter_next = sample_counter-1;
        else begin
            //error condition for the rx condition
            if(rx == `FALSE) nextstate = ERROR_RX;
            else begin
                //nextstate is idle and since idle directly puts you to start its not problem
                nextstate = IDLE;
                rx_done = `TRUE;
            end 
        end
        //if there is a framing error then it goes into framing error mode
        //handling the error between idle and going back to start without    
    end
    ERROR_RX: begin
        nextstate = IDLE;
        error_flag = `TRUE;
    end
    endcase
end
endmodule
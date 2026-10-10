module UART_RX #(
    parameter DATA_BITS = 8,
    parameter SAMPLE_TICKS = 16
) (

    input clk,
    input reset,
    input sample_tick,

    input rx_in,

    output reg ready,
    output [DATA_BITS-1 : 0] data_out

);

    localparam [1:0] IDLE = 2'b00,
                     START = 2'b01,
                     DATA = 2'b10,
                     STOP = 2'b11;

    reg [1:0] state, next_state;
    reg [DATA_BITS-1 : 0] data, next_data;
    reg [3:0] num_ticks, next_num_ticks;
    reg [2:0] num_bits, next_num_bits;
    reg tx, next_tx;


        always @(posedge clk or posedge reset) begin
            
            if (reset) begin
                state <= IDLE;
                data <= 0;
                num_ticks <= 0;
                num_bits <= 0;
                tx <= 0;
            end
            else begin
                state <= next_state;
                data <= next_data;
                num_ticks <= next_num_ticks;
                num_bits <= next_num_bits;
                tx <=  next_tx;
            end

        end

        always @(*) begin
            
            next_state = state;
            next_data = data;
            next_num_ticks = num_ticks;
            next_num_bits = num_bits;
            next_tx = tx;
            ready = 1'b0;
            
            case (state)

            IDLE : begin //IDLE

            if (~rx_in) begin
                next_state = START;
                next_num_ticks = 0;
            end
  
            end

            START : begin //START
            
                if (sample_tick) begin
                    if(num_ticks == (SAMPLE_TICKS/2)-1) begin
                        next_state = DATA;
                        next_num_ticks = 0;
                        next_num_bits = 0;
                    end
                    else begin
                    next_num_ticks = num_ticks + 1;
                    end

                end

            end

            DATA : begin //SERIAL DATA RECEPTION

                if (sample_tick) begin
                    if (num_ticks == SAMPLE_TICKS-1) begin
                        next_data = {rx_in, data[7:1]};
                        next_num_ticks = 0;

                        if (num_bits == DATA_BITS-1) begin
                            next_state = STOP;
                        end
                        else begin
                            next_num_bits = num_bits + 1;
                        end
                    end
                    else begin
                        next_num_ticks = num_ticks + 1;
                    end
                end

            end

            STOP : begin //STOP

                if (sample_tick) begin
                    if (num_ticks == SAMPLE_TICKS-1) begin
                        next_state = IDLE;
                        ready = 1'b1;
                    end
                    else begin
                        next_num_ticks = num_ticks + 1;
                    end
                end

            end

            endcase

        end

    assign data_out = data;

endmodule
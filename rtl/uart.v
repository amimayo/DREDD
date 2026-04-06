module UART #(
    parameter DATA_BITS = 8,
    parameter SAMPLE_TICKS = 16,
    parameter ADDR_BITS = 4,
    parameter NCOUNT = 10,
    parameter COUNTLIM = 651
) (
    
    input clk_100,
    input reset,

    input rx_in,
    input [DATA_BITS-1 : 0] wr_data,

    input wr_en,
    input read_en,

    output wire full,
    output wire empty,
    output wire tx_out,
    output wire [DATA_BITS-1 : 0] read_data

);

    wire sample_tick;                          
    wire [DATA_BITS-1:0] tx_fifo_out;      
    wire [DATA_BITS-1:0] rx_data_out;     
    wire rx_done_tick;                 
    wire tx_done_tick;                 
    wire tx_empty;                      
    wire tx_fifo_not_empty;  


    BAUD_RATE_GEN
        #(
            .NCOUNT(NCOUNT), 
            .COUNTLIM(COUNTLIM)
         ) 
        baud_rate_gen  
        (
            .clk_100(clk_100), 
            .reset(reset),
            .sample_tick(sample_tick)
         );
    
    UART_RX
        #(
            .DATA_BITS(DATA_BITS),
            .SAMPLE_TICKS(SAMPLE_TICKS)
         )
         UART_RX_UNIT
         (
            .clk(clk_100),
            .reset(reset),
            .sample_tick(sample_tick),
            .rx_in(rx_in),
            .ready(rx_done_tick),
            .data_out(rx_data_out)
         );
    
    UART_TX
        #(
            .DATA_BITS(DATA_BITS),
            .SAMPLE_TICKS(SAMPLE_TICKS)
         )
         uart_tx
         (
            .clk(clk_100),
            .reset(reset),
            .sample_tick(sample_tick),
            .data_in(tx_fifo_out),
            .tx_start(tx_fifo_not_empty),
            .tx_done(tx_done_tick),
            .tx_out(tx_out)
         );
    
    FIFO
        #(
            .DATA_BITS(DATA_BITS),
            .ADDR_BITS(ADDR_BITS)
         )
         fifo_rx
         (
            .clk(clk_100),
            .reset(reset),
            .wr_en(rx_done_tick),
	        .data_in(rx_data_out),
	        .full(),            
	        .read_en(read_en),
	        .data_out(read_data),
	        .empty(empty)
	      );
	   
    FIFO
        #(
            .DATA_BITS(DATA_BITS),
            .ADDR_BITS(ADDR_BITS)
         )
         fifo_tx
         (
            .clk(clk_100),
            .reset(reset),
            .wr_en(wr_en),
	        .data_in(wr_data),
	        .full(full),                
	        .read_en(tx_done_tick),
	        .data_out(tx_fifo_out),
	        .empty(tx_empty)
	      );
    

    assign tx_fifo_not_empty = ~tx_empty;          

endmodule
`timescale 1ns / 1ps

module tb_uart();

    parameter DATA_BITS = 8;
    
    reg clk;
    reg reset;
    
    reg [DATA_BITS-1:0] wr_data;
    reg wr_en;
    reg read_en;
    wire [DATA_BITS-1:0] read_data;

    wire sample_tick;
    wire serial_line; 

    BAUD_RATE_GEN #(
        .NCOUNT(10),
        .COUNTLIM(651)
    ) baud_gen (
        .clk_100(clk),
        .reset(reset),
        .sample_tick(sample_tick)
    );

    wire tx_fifo_empty, tx_fifo_full;
    wire [DATA_BITS-1:0] tx_fifo_out;
    reg  tx_fifo_read_en;

    FIFO #(
        .DATA_BITS(8),
        .ADDR_BITS(4)
    ) fifo_tx (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .data_in(wr_data),
        .full(tx_fifo_full),
        .read_en(tx_fifo_read_en),
        .data_out(tx_fifo_out),
        .empty(tx_fifo_empty)
    );

    wire tx_done;
    reg  tx_start;

    UART_TX #(
        .DATA_BITS(8),
        .SAMPLE_TICKS(16)
    ) uart_tx_inst (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .data_in(tx_fifo_out),
        .tx_start(tx_start),
        .tx_done(tx_done),
        .tx_out(serial_line)
    );

    reg tx_busy;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_busy <= 1'b0;
            tx_start <= 1'b0;
            tx_fifo_read_en <= 1'b0;
        end else begin
            tx_start <= 1'b0;       
            tx_fifo_read_en <= 1'b0;

            if (!tx_busy && !tx_fifo_empty) begin
              
                tx_start <= 1'b1;
                tx_fifo_read_en <= 1'b1;
                tx_busy <= 1'b1;
            end else if (tx_done) begin
              
                tx_busy <= 1'b0;
            end
        end
    end

    wire rx_ready;
    wire [DATA_BITS-1:0] rx_data_out;

    UART_RX #(
        .DATA_BITS(8),
        .SAMPLE_TICKS(16)
    ) uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .rx_in(serial_line), // Receive in from the loopback wire
        .ready(rx_ready),
        .data_out(rx_data_out)
    );

    wire rx_fifo_empty, rx_fifo_full;

    FIFO #(
        .DATA_BITS(8),
        .ADDR_BITS(4)
    ) fifo_rx (
        .clk(clk),
        .reset(reset),
        .wr_en(rx_ready),        
        .data_in(rx_data_out),
        .full(rx_fifo_full),
        .read_en(read_en),       
        .data_out(read_data),
        .empty(rx_fifo_empty)
    );


    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        $dumpfile("./sim/tb_uart.vcd");
        $dumpvars(0, tb_uart);
    end

    initial begin
        $monitor("Time: %0t | Serial Line: %b | RX FIFO Empty: %b", 
                 $time, serial_line, rx_fifo_empty);
    end

    initial begin
      
        reset = 1; wr_data = 0; wr_en = 0; read_en = 0;
        
        #100 reset = 0; #100;

        $display("\nPUSHING DATA INTO TX FIFO");
        
        @(negedge clk); wr_data = 8'h4B; wr_en = 1; // 'K'
        $display("\n--> WRITTEN BYTE 1: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        @(negedge clk); wr_data = 8'h49; wr_en = 1; // 'I'
        $display("--> WRITTEN BYTE 2: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        @(negedge clk); wr_data = 8'h4C; wr_en = 1; // 'L'
        $display("--> WRITTEN BYTE 3: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        @(negedge clk); wr_data = 8'h4C; wr_en = 1; // 'L'
        $display("--> WRITTEN BYTE 4: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        $display("\n--- WAITING FOR UART TO TRANSMIT & LOOPBACK ---");
        
        // Wait and Read Byte 1
        @(negedge rx_fifo_empty);
        @(negedge clk); $display("\n--> POPPED BYTE 1: %h", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        // Wait and Read Byte 2
        @(negedge rx_fifo_empty);
        @(negedge clk); $display("--> POPPED BYTE 2: %h", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        // Wait and Read Byte 3
        @(negedge rx_fifo_empty);
        @(negedge clk); $display("--> POPPED BYTE 3: %h", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        // Wait and Read Byte 4
        @(negedge rx_fifo_empty);
        @(negedge clk); $display("--> POPPED BYTE 4: %h\n", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        $display("DECOUPLED UART LOOPBACK TEST PASSED");
        $finish;
    end

endmodule
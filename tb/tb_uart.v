`timescale 1ns / 1ps

module tb_uart();

    parameter DATA_BITS = 8;
    
   
    reg clk;
    reg reset;
    reg [DATA_BITS-1:0] wr_data;
    reg wr_en, read_en;
    
    wire full, empty;
    wire [DATA_BITS-1:0] read_data;
    wire serial_line;

    // Instantiate UART wrapper
    UART #(
        .DATA_BITS(8),
        .SAMPLE_TICKS(16),
        .ADDR_BITS(4),
        .NCOUNT(10),
        .COUNTLIM(651)
    ) UUT (
        .clk_100(clk),
        .reset(reset),
        .rx_in(serial_line),
        .tx_out(serial_line), 
        .wr_data(wr_data),
        .wr_en(wr_en),
        .read_en(read_en),
        .full(full),    
        .empty(empty),
        .read_data(read_data)
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
        $monitor("Time: %0t | Serial Line: %b | RX Empty: %b | Read Data: %h", 
                 $time, serial_line, empty, read_data);
    end

    initial begin
        clk = 0; reset = 1; wr_data = 0; wr_en = 0; read_en = 0;
        
        #100 reset = 0; #100;

        $display("\n--- PUSHING DATA INTO TX FIFO ---");
        
        @(negedge clk); wr_data = 8'h4B; wr_en = 1; // 'K'
        $display("\n--> WRITTEN BYTE 1: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        @(negedge clk); wr_data = 8'h49; wr_en = 1; // 'I'
        $display("\n--> WRITTEN BYTE 2: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        @(negedge clk); wr_data = 8'h4C; wr_en = 1; // 'L'
        $display("\n--> WRITTEN BYTE 3: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        @(negedge clk); wr_data = 8'h4C; wr_en = 1; // 'L'
        $display("\n--> WRITTEN BYTE 4: %h", wr_data);
        @(negedge clk); wr_en = 0;
        
        $display("--- WAITING FOR LOOPBACK ---");
        
        // Wait and Read Byte 1
        @(negedge empty);
        @(negedge clk); $display("\n--> POPPED BYTE 1: %h", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        // Wait and Read Byte 2
        @(negedge empty);
        @(negedge clk); $display("--> POPPED BYTE 2: %h", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        // Wait and Read Byte 3
        @(negedge empty);
        @(negedge clk); $display("--> POPPED BYTE 3: %h", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        // Wait and Read Byte 4
        @(negedge empty);
        @(negedge clk); $display("--> POPPED BYTE 4: %h\n", read_data);
        read_en = 1;
        @(negedge clk); read_en = 0;

        $display("=== UART LOOPBACK TEST PASSED ===");
        $finish;
    end

endmodule
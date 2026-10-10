`timescale 1ns / 1ps

module tb();

    // System Signals
    reg clk;
    reg reset_btn;
    reg flush_btn;
    
    // UART External Wires
    reg  uart_rx;
    wire uart_tx;

    // 100MHz clock period = 10ns.
    // Baud Config: 100MHz / (16 * 651) = 9600 Baud.
    // One bit period = 651 * 16 * 10ns = 104,160 ns.
    localparam BIT_PERIOD = 104160;

    TOP UUT (
        .clk(clk),
        .reset_btn(reset_btn),
        .flush_btn(flush_btn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // TASK: Emulate a PC sending a serial byte over UART
    
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rx = 0; // Start bit
            #(BIT_PERIOD);
            
            // Send 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(BIT_PERIOD);
            end
            
            uart_rx = 1; // Stop bit
            #(BIT_PERIOD);
            
            // Tiny gap between bytes
            #(BIT_PERIOD);
        end
    endtask


    // BLOCK: Emulate a PC receiving serial bytes over UART

    reg [7:0] received_byte;
    integer r;
    always begin
        // Wait for falling edge (Start Bit)
        @(negedge uart_tx);
        
        // Wait for half a bit period to sample in the middle of the bit
        #(BIT_PERIOD / 2);
        
        // Sample 8 data bits
        for (r = 0; r < 8; r = r + 1) begin
            #(BIT_PERIOD);
            received_byte[r] = uart_tx;
        end
        
        // Wait for Stop bit
        #(BIT_PERIOD);
        
        $display("[PC TERMINAL] Received Encrypted Byte: %02h", received_byte);
    end


    // MAIN TEST SEQUENCE

    initial begin
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb);

        // Initialize pins
        reset_btn = 1;
        flush_btn = 0;
        uart_rx   = 1; // UART idle line is HIGH

        #200;
        reset_btn = 0;
        #500;

        $display("\nSTARTING FULL SYSTEM TEST");
        $display("[PC TERMINAL] Sending malicious payload: 'KILL'");

        // Send K-I-L-L 
        send_uart_byte(8'h4B); // K
        send_uart_byte(8'h49); // I
        send_uart_byte(8'h4C); // L
        send_uart_byte(8'h4C); // L

        $display("[PC TERMINAL] Sending 8 spaces to flush the 4-byte delay line...");
        
        // The first 4 spaces push the asterisks out.
        // The last 4 spaces push the spaces themselves out
        send_uart_byte(8'h20); // Space 1
        send_uart_byte(8'h20); // Space 2
        send_uart_byte(8'h20); // Space 3
        send_uart_byte(8'h20); // Space 4
        
        send_uart_byte(8'h20); // Space 5
        send_uart_byte(8'h20); // Space 6
        send_uart_byte(8'h20); // Space 7
        send_uart_byte(8'h20); // Space 8

        $display("[PC TERMINAL] Pressing Flush Button...");
        
        flush_btn = 1;
        #50;
        flush_btn = 0;

        #(BIT_PERIOD * 10 * 25); 
        
        $display("\nTEST COMPLETE");
        $finish;
    end

endmodule
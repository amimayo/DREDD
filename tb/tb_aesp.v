`timescale 1ns / 1ps

module tb_aesp();

    reg clk;
    reg reset;

    reg [7:0] fw_data;
    reg fw_write;
    reg fw_flush;
    wire packer_full;

    wire [127:0] aes_block;
    wire aes_valid;
    wire unpacker_ready;
    
    wire [7:0] tx_data;
    wire tx_write;
    reg tx_full;

    integer i;

    AES_PACKER packer (
        .clk(clk),
        .reset(reset),
        .data_in(fw_data),
        .write_en(fw_write),
        .packer_full(packer_full),
        .flush(fw_flush),
        .block_out(aes_block),
        .block_valid(aes_valid),
        .aes_busy(~unpacker_ready) // If unpacker isn't ready, treat as busy
    );

    AES_UNPACKER unpacker (
        .clk(clk),
        .reset(reset),
        .block_in(aes_block),      // Direct wire from Packer
        .block_valid(aes_valid),   // Direct wire from Packer
        .unpacker_ready(unpacker_ready),
        .data_out(tx_data),
        .write_en(tx_write),
        .tx_full(tx_full)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (tx_write) begin
            $display("  [UART TX] Popped Byte: %c (%02h)", tx_data, tx_data);
        end
    end

    always @(posedge clk) begin
        if (aes_valid) begin
            $display("\n[AES BUS] 128-bit Block Transferred");
            $display("[AES BUS] Raw Hex: %32h\n", aes_block);
        end
    end

    // Main Test Sequence
    initial begin
        $dumpfile("sim/tb_aesp.vcd");
        $dumpvars(0, tb_aesp);
    end

    initial begin

        clk = 0; reset = 1; 
        fw_data = 0; fw_write = 0; fw_flush = 0; tx_full = 0;
        
        #20 reset = 0;

        // TEST 1: A FULL 16-BYTE BLOCK (No padding needed)
        $display("\ TEST 1: SENDING 16-BYTE STRING 'FULL_BLOCK_12345'");
        begin : test1
            reg [7:0] msg1 [0:15];
            msg1[0]="F"; msg1[1]="U"; msg1[2]="L"; msg1[3]="L"; 
            msg1[4]="_"; msg1[5]="B"; msg1[6]="L"; msg1[7]="O";
            msg1[8]="C"; msg1[9]="K"; msg1[10]="_"; msg1[11]="1";
            msg1[12]="2"; msg1[13]="3"; msg1[14]="4"; msg1[15]="5";
            
            for (i = 0; i < 16; i = i + 1) begin
                @(negedge clk);
                fw_data = msg1[i];
                fw_write = 1;
                @(negedge clk);
                fw_write = 0;
            end
        end

        #300;

        // TEST 2: A PARTIAL BLOCK WITH PKCS#7 PADDING
        $display("\nTEST 2: SENDING 5-BYTE STRING 'HELLO' & FLUSHING");
        $display("Expected: Unpacker should strip the 11 padding bytes and ONLY print 'HELLO'.");
        
        begin : test2
            reg [7:0] msg2 [0:4];
            msg2[0]="H"; msg2[1]="E"; msg2[2]="L"; msg2[3]="L"; msg2[4]="O";
            
            for (i = 0; i < 5; i = i + 1) begin
                @(negedge clk);
                fw_data = msg2[i];
                fw_write = 1;
                @(negedge clk);
                fw_write = 0;
            end
        end

        #50;
        $display("\n[FIREWALL] Triggering manual flush...");
        @(negedge clk); fw_flush = 1;
        @(negedge clk); fw_flush = 0;

        #300;

        $display("\n PIPELINE TEST COMPLETE");
        $finish;
    end

endmodule
`timescale 1ns/1ps
 
module tb_firewall;
 
    reg clk, reset;
    reg [7:0] data_in;
    
    reg rx_empty;
    reg packer_full;
    wire read_rx;
    wire write_out;
    wire [7:0] data_out;
    
    localparam WORD_LEN_FLUSH = 4;
    integer j1, j2, j3;
 
    FIREWALL #(
        .DATA_BITS(8),
        .WORD_LEN (4),
        .NUM_WORDS(2),
        .SUBST    (8'h2A)   // '*'
    ) uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .rx_empty(rx_empty),
        .read_rx(read_rx),
        .data_out(data_out),
        .write_out(write_out),
        .packer_full(packer_full)
    );
 
    initial begin 
        clk = 0;
        forever #5 clk = ~clk;
    end
 
    always @(posedge clk) begin
        if (write_out) begin
            if (data_out == 8'h2A)
                $display("  DROP  emit: %c (%02h)  <-- substituted", data_out, data_out);
            else
                $display("  PASS  emit: %c (%02h)", data_out, data_out);
        end
    end
 
    initial begin
        $dumpfile("sim/tb_firewall.vcd");
        $dumpvars(0, tb_firewall);
    end

    initial begin

        reset = 1; rx_empty = 1; packer_full = 0; data_in = 0;
        repeat(4) @(posedge clk);
        reset = 0;
 
        //Test 1: "GO KILL GOOD"
        $display("\nTest 1: 'GO KILL GOOD'");
        $display("Expected: G O ' ' * * * * ' ' G O O D\n");
 
        begin : t1
            reg [7:0] msg [0:12];
            msg[0]  = "G"; msg[1]  = "O"; msg[2]  = " ";
            msg[3]  = "K"; msg[4]  = "I"; msg[5]  = "L"; msg[6]  = "L";
            msg[7]  = " "; msg[8]  = "G"; msg[9]  = "O";
            msg[10] = "O"; msg[11] = "D";
            for (j1 = 0; j1 < 12; j1 = j1 + 1) begin
                @(negedge clk);
                data_in  = msg[j1];
                rx_empty = 1'b0; // Simulate FIFO having data
                @(negedge clk);
                rx_empty = 1'b1; // Simulate FIFO empty
            end
        end
 
        // Flush remaining bytes from window
        repeat(WORD_LEN_FLUSH) begin
            @(negedge clk);
            data_in  = 8'h00;
            rx_empty = 1'b0;
            @(negedge clk);
            rx_empty = 1'b1;
        end
 
        #100;
 
        //Test 2: no match
        $display("\nTest 2: 'HELLO' (no banned word)");
        $display("Expected: H E L L O\n");
        begin : t2
            reg [7:0] msg2 [0:4];
            msg2[0]="H"; msg2[1]="E"; msg2[2]="L"; msg2[3]="L"; msg2[4]="O";
            for (j2 = 0; j2 < 5; j2 = j2 + 1) begin
                @(negedge clk);
                data_in  = msg2[j2];
                rx_empty = 1'b0;
                @(negedge clk);
                rx_empty = 1'b1;
            end
        end
 
        repeat(WORD_LEN_FLUSH) begin
            @(negedge clk); data_in = 8'h00; rx_empty = 0;
            @(negedge clk); rx_empty = 1;
        end
 
        #100;
 
        //Test 3: adjacent banned words "KILLKILL"
        $display("\nTest 3: 'KILLKILL' (two consecutive matches)");
        $display("Expected: all *\n");
        begin : t3
            reg [7:0] msg3 [0:7];
            msg3[0]="K"; msg3[1]="I"; msg3[2]="L"; msg3[3]="L";
            msg3[4]="K"; msg3[5]="I"; msg3[6]="L"; msg3[7]="L";
            for (j3 = 0; j3 < 8; j3 = j3 + 1) begin
                @(negedge clk);
                data_in  = msg3[j3];
                rx_empty = 1'b0;
                @(negedge clk);
                rx_empty = 1'b1;
            end
        end
 
        repeat(WORD_LEN_FLUSH) begin
            @(negedge clk); data_in = 8'h00; rx_empty = 0;
            @(negedge clk); rx_empty = 1;
        end
 
        #200;
        $display("\nDONE");
        $finish;

    end
 
endmodule
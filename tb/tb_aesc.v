`timescale 1ns / 1ps

module tb_aesc();

    reg clk;
    reg reset;
    
    reg [127:0] key;
    reg [127:0] plaintext;
    reg valid_in;
    
    wire [127:0] ciphertext;
    wire valid_out;

    AES_CORE uut (
        .clk(clk),
        .reset(reset),
        .key(key),
        .plaintext(plaintext),
        .valid_in(valid_in),
        .ciphertext(ciphertext),
        .valid_out(valid_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Monitor for successful output
    always @(posedge clk) begin
        if (valid_out) begin
            $display("\n[AES_CORE] Ciphertext Output: %32h", ciphertext);
            if (ciphertext === 128'h3925841d02dc09fbdc118597196a0b32)
                $display("[RESULT] PASS: Matches NIST FIPS-197 Expected Output");
            else if (ciphertext === 128'h7df76b0c1ab899b33e42f047b91b546f)
                $display("[RESULT] PASS: Pipelined Zero-Block Encrypted Perfectly");
            else
                $display("[RESULT] FAIL: Incorrect Ciphertext.");
        end
    end

    initial begin
        $dumpfile("sim/tb_aesc.vcd");
        $dumpvars(0, tb_aesc);
    end

    initial begin
       
        clk = 0; reset = 1; valid_in = 0;
        
        // FIPS-197 Appendix B Standard Test Vector
        key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        plaintext = 128'h3243f6a8885a308d313198a2e0370734;

        #20 reset = 0;
        
        $display("\nAES FULL CORE PIPELINE VERIFICATION");
        $display("Key        : %32h", key);
       
        // Cycle 1: Push Block 1 (The NIST Vector)
        @(negedge clk); 
        $display("Pushing Block 1 (NIST): %32h", plaintext);
        valid_in = 1; 

        // Cycle 2: Push Block 2 (Dummy Data) immediately after
        @(negedge clk);
        plaintext = 128'h00000000000000000000000000000000; 
        $display("Pushing Block 2 (Zero): %32h", plaintext);
        valid_in = 1;

        // Cycle 3: Stop pushing data, wait for pipeline to flush
        @(negedge clk);
        valid_in = 0;

        #200;

        $display("\nSIMULATION COMPLETE");
        $finish;
    end

endmodule
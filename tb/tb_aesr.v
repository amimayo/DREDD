`timescale 1ns / 1ps

module tb_aesr();

    reg  [127:0] state_in;
    reg  [127:0] round_key;
    reg  is_final;
    wire [127:0] state_out;

    AES_ROUND uut (
        .state_in(state_in),
        .round_key(round_key),
        .is_final(is_final),
        .state_out(state_out)
    );

    initial begin
        $display("\n=== AES ROUND 1 VERIFICATION (FIPS-197 Appx B) ===");

        // According to FIPS-197, after the initial AddRoundKey (Stage 0), 
        // State entering Round 1 :
        state_in  = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        
        // Round 1 Generated Key :
        round_key = 128'ha0fafe1788542cb123a339392a6c7605;
        
        is_final = 0; //MixColumns
        
        #10; 

        $display("State In   : %32h", state_in);
        $display("Round Key  : %32h", round_key);
        $display("State Out  : %32h", state_out);
        $display("Expected   : a49c7ff2689f352b6b5bea43026a5049");

        if (state_out === 128'ha49c7ff2689f352b6b5bea43026a5049)
            $display("\n[RESULT] PASS: Round 1 matches NIST standard perfectly");
        else
            $display("\n[RESULT] FAIL: Math is incorrect");

        $finish;
    end

endmodule
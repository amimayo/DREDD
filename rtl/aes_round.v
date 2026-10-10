module AES_ROUND (

    input [127:0] state_in,
    input [127:0] round_key,
    input is_final,  
    output wire [127:0] state_out

);

    wire [7:0] sb_out [0:15];
 
    genvar b;
    generate
        for (b = 0; b < 16; b = b + 1) begin : subbytes
            AES_SBOX sbox_inst (
                .in(state_in[127 - b*8 -: 8]), 
                .out(sb_out[b])
            );
        end
    endgenerate
 
    // Col 0: 0, 1,  2,  3
    // Col 1: 4, 5,  6,  7
    // Col 2: 8, 9, 10, 11
    // Col 3: 12,13,14, 15

    wire [7:0] sr [0:15]; 
 
    // Column 0
    assign sr[0]  = sb_out[0];   // Row 0: Shift Left 0
    assign sr[1]  = sb_out[5];   // Row 1: Shift Left 1 
    assign sr[2]  = sb_out[10];  // Row 2: Shift Left 2 
    assign sr[3]  = sb_out[15];  // Row 3: Shift Left 3 

    // Column 1
    assign sr[4]  = sb_out[4];   // Row 0: Shift Left 0
    assign sr[5]  = sb_out[9];   // Row 1: Shift Left 1 
    assign sr[6]  = sb_out[14];  // Row 2: Shift Left 2 
    assign sr[7]  = sb_out[3];   // Row 3: Shift Left 3

    // Column 2
    assign sr[8]  = sb_out[8];   // Row 0: Shift Left 0
    assign sr[9]  = sb_out[13];  // Row 1: Shift Left 1 
    assign sr[10] = sb_out[2];   // Row 2: Shift Left 2 
    assign sr[11] = sb_out[7];   // Row 3: Shift Left 3 

    // Column 3
    assign sr[12] = sb_out[12];  // Row 0: Shift Left 0
    assign sr[13] = sb_out[1];   // Row 1: Shift Left 1 
    assign sr[14] = sb_out[6];   // Row 2: Shift Left 2 
    assign sr[15] = sb_out[11];  // Row 3: Shift Left 3 
 
    // MixColumns
  
    wire [31:0] mc_in  [0:3];
    wire [31:0] mc_out [0:3];
 
    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : mixcol
           
            assign mc_in[c] = {sr[c*4], sr[c*4+1], sr[c*4+2], sr[c*4+3]};
            AES_MIXCOL mc (.col_in(mc_in[c]), .col_out(mc_out[c]));
        end
    endgenerate
 
    wire [127:0] after_mc;
    assign after_mc = is_final ? 
        {mc_in[0], mc_in[1], mc_in[2], mc_in[3]} :
        {mc_out[0], mc_out[1], mc_out[2], mc_out[3]};
 
   
    assign state_out = after_mc ^ round_key;

endmodule
module AES_MIXCOL (

    input [31:0] col_in,   
    output wire [31:0] col_out

);

    wire [7:0] s0, s1, s2, s3;
    assign {s0, s1, s2, s3} = col_in;
 
    function [7:0] xtime;
        input [7:0] a;
        xtime = (a << 1) ^ (a[7] ? 8'h1b : 8'h00);
    endfunction
 
    function [7:0] xt3;
        input [7:0] a;
        xt3 = xtime(a) ^ a;
    endfunction
 
    assign col_out[31:24] = xtime(s0) ^ xt3(s1)  ^ s2         ^ s3;
    assign col_out[23:16] = s0        ^ xtime(s1) ^ xt3(s2)   ^ s3;
    assign col_out[15: 8] = s0        ^ s1        ^ xtime(s2) ^ xt3(s3);
    assign col_out[ 7: 0] = xt3(s0)   ^ s1        ^ s2        ^ xtime(s3);

endmodule
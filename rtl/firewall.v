module FIREWALL #(
    parameter DATA_BITS = 8,
    parameter WORD_LEN  = 4,
    parameter NUM_WORDS = 2,
    parameter [DATA_BITS-1:0] SUBST = 8'h2A   // '*'
) (
    input clk,
    input reset,
    
    input wire [DATA_BITS-1:0] data_in,
    input rx_empty,
    output read_rx,

    input wire packer_full,
    output reg  [DATA_BITS-1:0] data_out,
    output reg write_out
);

    reg [DATA_BITS-1:0] window [0:WORD_LEN-1];
    reg [DATA_BITS-1:0] banned [0:NUM_WORDS-1][0:WORD_LEN-1];

    reg [2:0] fill_count;   
    reg [2:0] suppress_ctr;

    integer i, w, b;

    wire shift_en = ~rx_empty & ~packer_full;
    assign read_rx = shift_en; 

    initial begin
        // Word 0: "KILL" = 4B 49 4C 4C
        banned[0][0] = 8'h4B; // K
        banned[0][1] = 8'h49; // I
        banned[0][2] = 8'h4C; // L
        banned[0][3] = 8'h4C; // L

        // Word 1: "HACK" = 48 41 43 4B
        banned[1][0] = 8'h48; // H
        banned[1][1] = 8'h41; // A
        banned[1][2] = 8'h43; // C
        banned[1][3] = 8'h4B; // K
    end

    reg match_found;
    reg word_ok;

    always @(*) begin
        match_found = 1'b0;
        for (w = 0; w < NUM_WORDS; w = w + 1) begin
            word_ok = 1'b1;
            for (b = 0; b < WORD_LEN; b = b + 1) begin
                if (window[WORD_LEN-1-b] !== banned[w][b])
                    word_ok = 1'b0;
            end
            if (word_ok) match_found = 1'b1;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < WORD_LEN; i = i + 1)
                window[i] <= 8'h00;
            fill_count   <= 3'd0;
            suppress_ctr <= 3'd0;
            data_out     <= 8'h00;
            write_out    <= 1'b0;
        end else begin
            write_out <= 1'b0;
            if (shift_en) begin

                for (i = WORD_LEN-1; i > 0; i = i - 1)
                    window[i] <= window[i-1];
                window[0] <= data_in;

                if (fill_count < WORD_LEN)
                    fill_count <= fill_count + 1;

                if (fill_count == WORD_LEN) begin

                    if (match_found) begin
                        suppress_ctr <= (WORD_LEN-1);
                        data_out     <= SUBST;
                        write_out    <= 1'b1; 
                    end else if (suppress_ctr > 0) begin
                        suppress_ctr <= suppress_ctr - 1;
                        data_out     <= SUBST;
                        write_out    <= 1'b1;
                    end else begin
                        data_out  <= window[WORD_LEN-1];
                        write_out <= 1'b1; 
                    end
                end
            end
        end
    end

endmodule
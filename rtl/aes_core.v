module AES_CORE (
    input  clk,
    input  reset,
    input  [1407:0] flattened_keys,  
    input  [127:0] plaintext,
    input  valid_in,
    
    (* keep *) output reg  [127:0] ciphertext,
    output reg          valid_out,
    output wire         ready
);

    wire [127:0] round_key [0:10];
    genvar k;
    generate
        for (k = 0; k <= 10; k = k + 1) begin : unpack_keys
            assign round_key[k] = flattened_keys[k*128 +: 128];
        end
    endgenerate

    localparam IDLE   = 2'd0;
    localparam CALC   = 2'd1;
    localparam DONE   = 2'd2;
    localparam OUTPUT = 2'd3;

    reg [1:0]   state;
    reg [3:0]   round_ctr;
    reg [127:0] current_state;

    assign ready = (state == IDLE);

    wire [127:0] rnd_out;

    AES_ROUND single_rnd (
        .state_in  (current_state),
        .round_key (round_key[round_ctr]),
        .is_final  (round_ctr == 4'd10 ? 1'b1 : 1'b0),
        .state_out (rnd_out)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            round_ctr     <= 4'd0;
            current_state <= 128'b0;
            ciphertext    <= 128'b0;
            valid_out     <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            case (state)

                IDLE: begin
                    if (valid_in) begin
                        current_state <= plaintext ^ round_key[0];
                        round_ctr     <= 4'd1;
                        state         <= CALC;
                    end
                end

                CALC: begin
                    current_state <= rnd_out;
                    if (round_ctr == 4'd10) begin
                        state <= DONE;
                    end else begin
                        round_ctr <= round_ctr + 1;
                    end
                end

                DONE: begin
                    ciphertext <= current_state;
                    state      <= OUTPUT;
                end

                OUTPUT: begin
                    valid_out <= 1'b1;
                    state     <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

    // 11-Stage Pipelined Design for Arty A7-100T

    // wire [127:0] round_key [0:10];
    
    // genvar k;
    // generate
    //     for (k = 0; k <= 10; k = k + 1) begin : unpack_keys
    //         assign round_key[k] = flattened_keys[k*128 +: 128];
    //     end
    // endgenerate

  
    // reg  [127:0] pipe_state [0:10];
    // reg  [10:0]  valid_pipe; 
 
    // wire [127:0] round_out [1:10];
 
    // genvar r;
    // generate
    //     for (r = 1; r <= 10; r = r + 1) begin : rounds
    //         AES_ROUND rnd (
    //             .state_in  (pipe_state[r-1]),
    //             .round_key (round_key[r]),
    //             .is_final  (r == 10 ? 1'b1 : 1'b0),
    //             .state_out (round_out[r])
    //         );
    //     end
    // endgenerate

    // integer i;
    // always @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         for (i = 0; i <= 10; i = i + 1)
    //             pipe_state[i] <= 128'b0;
    //         valid_pipe  <= 11'b0;
    //         ciphertext  <= 128'b0;
    //         valid_out   <= 1'b0;
    //     end else begin
            
    //         if (valid_in) begin
    //             pipe_state[0] <= plaintext ^ round_key[0];
    //         end
    //         valid_pipe[0] <= valid_in;
 
           
    //         for (i = 1; i <= 10; i = i + 1) begin
    //             if (valid_pipe[i-1]) begin
    //                 pipe_state[i] <= round_out[i];
    //             end
    //             valid_pipe[i] <= valid_pipe[i-1];
    //         end
            
    //         ciphertext <= pipe_state[10];
    //         valid_out  <= valid_pipe[10];
    //     end
    // end

endmodule
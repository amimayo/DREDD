`timescale 1ns / 1ps

module AES_UNPACKER (

    input clk,
    input reset,

    input [127:0] block_in,
    input block_valid,   
    output unpacker_ready, 

    input tx_full,  
    output reg [7:0] data_out,  
    output reg write_en  

);

    localparam IDLE  = 1'b0;
    localparam DRAIN = 1'b1;

    reg state;
    reg [127:0] block_buf;
    reg [4:0] byte_idx;   
    reg [4:0] target_len;

    assign unpacker_ready = (state == IDLE);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            block_buf  <= 128'd0;
            byte_idx   <= 5'd0;
            target_len <= 5'd16;
            data_out   <= 8'd0;
            write_en   <= 1'b0;
        end else begin
            write_en <= 1'b0; 

            case (state)
                IDLE: begin
                    if (block_valid) begin
                        block_buf  <= block_in;
                        byte_idx   <= 5'd0;
                        target_len <= 5'd16;
                        state      <= DRAIN;
                    end
                end

                DRAIN: begin
                    
                    if (!tx_full && target_len > 0) begin
                        
                        data_out <= block_buf[127 - byte_idx*8 -: 8];
                        write_en <= 1'b1;

                        if (byte_idx == target_len - 1) begin
                            state    <= IDLE; 
                            byte_idx <= 5'd0;
                        end else begin
                            byte_idx <= byte_idx + 1;
                        end
                        
                    end else if (target_len == 0) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
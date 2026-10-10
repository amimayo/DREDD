module AES_PACKER (

    input clk,
    input reset,
    
    input [7:0] data_in,
    input write_en,     
    output wire packer_full,  

    input wire flush,     
   
    input wire aes_busy, 
    output reg [127:0] block_out,
    output reg block_valid

);

    localparam COLLECT = 1'b0;
    localparam SEND    = 1'b1;

    reg [7:0] buf_reg [0:15];
    reg [3:0] count_reg;
    reg state;
    integer i;

    assign packer_full = (state == SEND) || aes_busy;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) buf_reg[i] <= 8'h00;
            count_reg   <= 4'd0;
            state       <= COLLECT;
            block_out   <= 128'd0;
            block_valid <= 1'b0;
        end else begin
            block_valid <= 1'b0; 

            case (state)
                COLLECT: begin
                    if (write_en && !packer_full) begin
                        buf_reg[count_reg] <= data_in;
                        
                        if (count_reg == 4'd15) begin
                           
                            block_out   <= {buf_reg[0], buf_reg[1], buf_reg[2],  buf_reg[3],
                                            buf_reg[4], buf_reg[5], buf_reg[6],  buf_reg[7],
                                            buf_reg[8], buf_reg[9], buf_reg[10], buf_reg[11],
                                            buf_reg[12],buf_reg[13],buf_reg[14], data_in};
                            block_valid <= 1'b1;
                            count_reg   <= 4'd0;
                            state       <= SEND; 
                        end else begin
                            count_reg <= count_reg + 1;
                        end
                        
                    end else if (flush && count_reg != 4'd0) begin
                       
                        begin : pad_block
                            reg [7:0] pv;
                            integer j;
                            pv = 8'd16 - {4'd0, count_reg}; 
                            for (j = 0; j < 16; j = j + 1) begin
                                if (j < count_reg)
                                    block_out[127 - j*8 -: 8] <= buf_reg[j];
                                else
                                    block_out[127 - j*8 -: 8] <= pv;
                            end
                        end
                        block_valid <= 1'b1;
                        count_reg   <= 4'd0;
                        state       <= SEND;
                    end
                end

                SEND: begin
                   
                    if (!aes_busy) begin
                        state <= COLLECT;
                    end
                end
            endcase
        end
    end

endmodule
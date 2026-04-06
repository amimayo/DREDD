module FIFO #(
    parameter DATA_BITS = 8,
    parameter ADDR_BITS = 2
) (

    input clk,
    input reset,

    input wr_en,
    input [DATA_BITS-1:0] data_in,
    output full,

    input read_en,
    output wire [DATA_BITS-1:0] data_out,
    output wire empty

);

    reg [DATA_BITS-1:0] ram_array [0:(1<<ADDR_BITS)-1];

    reg [ADDR_BITS-1:0] wr_ptr_reg;
    reg [ADDR_BITS-1:0] read_ptr_reg;
    reg full_reg;
    reg empty_reg;

    reg  [ADDR_BITS-1:0] wr_ptr_next;
    reg  [ADDR_BITS-1:0] read_ptr_next;
    reg full_next;
    reg empty_next;

    wire [ADDR_BITS-1:0] wr_ptr_succ;
    wire [ADDR_BITS-1:0] read_ptr_succ;

    wire wr_allow;

    assign wr_allow = wr_en & ~full_reg;

    integer i;
    initial begin
        for (i = 0; i < (1<<ADDR_BITS); i = i+1)
            ram_array[i] = 0;
    end

        always @(posedge clk) begin
            if (wr_allow) begin
                ram_array[wr_ptr_reg] <= data_in;
            end
        end

    assign data_out = ram_array[read_ptr_reg];

        always @(posedge clk or posedge reset) begin
            if (reset) begin
                wr_ptr_reg <= 0;
                read_ptr_reg <= 0;
                full_reg   <= 1'b0;
                empty_reg  <= 1'b1; 
            end else begin
                wr_ptr_reg <= wr_ptr_next;
                read_ptr_reg <= read_ptr_next;
                full_reg   <= full_next;
                empty_reg  <= empty_next;
            end
        end

    assign wr_ptr_succ = wr_ptr_reg + 1;
    assign read_ptr_succ = read_ptr_reg + 1;

        always @* begin
            
            wr_ptr_next = wr_ptr_reg;
            read_ptr_next = read_ptr_reg;
            full_next   = full_reg;
            empty_next  = empty_reg;

            case ({wr_en, read_en})
                
                2'b01: // READ ONLY
                    if (~empty_reg) begin
                        read_ptr_next = read_ptr_succ;
                        full_next   = 1'b0;                 
                        if (read_ptr_succ == wr_ptr_reg) begin
                            empty_next = 1'b1;              
                        end
                    end

                2'b10: // WRITE ONLY
                    if (~full_reg) begin
                        wr_ptr_next = wr_ptr_succ;
                        empty_next  = 1'b0;                 
                        if (wr_ptr_succ == read_ptr_reg) begin
                            full_next = 1'b1;              
                        end
                    end

                2'b11: // WRITE AND READ SIMULTANEOUSLY
                    begin
                        wr_ptr_next = wr_ptr_succ;
                        read_ptr_next = read_ptr_succ;
                    end
                
            endcase
        end

    assign full  = full_reg;
    assign empty = empty_reg;

endmodule
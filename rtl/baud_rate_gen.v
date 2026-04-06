module BAUD_RATE_GEN #(
    parameter NCOUNT = 10,
    parameter COUNTLIM = 651
) (

    input clk_100,
    input reset,
    output wire sample_tick

);

    reg [NCOUNT-1 : 0] current_count;
    wire [NCOUNT-1 : 0] next_count;

        always @(posedge clk_100 or posedge reset) begin
            
            if(reset) begin
                current_count <= 0;
            end
            else begin
                current_count <= next_count;
            end

        end

    assign next_count = (current_count == COUNTLIM - 1) ? 0 : current_count+1 ;
    assign sample_tick = (current_count == COUNTLIM - 1) ? 1'b1 : 1'b0 ;

endmodule
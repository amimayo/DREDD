module TOP (
    input clk,        
    input reset_btn,  
    input flush_btn,  
    
    input uart_rx,    
    output wire uart_tx,
    output wire led_active 
);

    wire safe_reset = ~reset_btn;
    wire safe_flush = ~flush_btn;

    // ALTERA POR PATCH
    reg [3:0] por_cnt  = 0;
    reg       por_done = 0;
    always @(posedge clk) begin
        if (!por_done) begin
            por_cnt <= por_cnt + 1;
            if (por_cnt == 4'hF)
                por_done <= 1'b1;
        end
    end
    wire reset = safe_reset | ~por_done;

    // FLUSH BUTTON DEBOUNCER
    reg [19:0] tick_cnt = 0;
    always @(posedge clk) begin
        tick_cnt <= tick_cnt + 1;
    end
    
    wire db_tick = (tick_cnt == 20'hFFFFF); 

    reg db_stable = 0;
    always @(posedge clk) begin
        if (db_tick) begin
            db_stable <= safe_flush; 
        end
    end

    reg flush_q0, flush_q1;
    always @(posedge clk) begin
        flush_q0 <= db_stable;
        flush_q1 <= flush_q0;
    end
    wire flush_raw = flush_q0 & ~flush_q1;

    localparam WORD_LEN = 4;
    reg [WORD_LEN-1:0] flush_delay_sr;
    always @(posedge clk or posedge reset) begin
        if (reset)
            flush_delay_sr <= 0;
        else
            flush_delay_sr <= {flush_delay_sr[WORD_LEN-2:0], flush_raw};
    end
    wire flush_pulse = flush_delay_sr[WORD_LEN-1];

    // AES Key & Baud Generator

    wire [127:0]  aes_key             = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    wire [1407:0] flattened_round_keys;

    wire sample_tick;
    BAUD_RATE_GEN #(
        .NCOUNT(10), .COUNTLIM(326)
    ) baud_gen (
        .clk_100(clk), .reset(reset),
        .sample_tick(sample_tick)
    );

    // THE FAKE RX FIFO (Auto-Byte-Injector)
    // Streams "KILLGOODTRUEHACK" byte-by-byte into the Firewall on startup
    wire [7:0] rom_data [0:19];
    assign rom_data[0]  = 8'h4B; // K
    assign rom_data[1]  = 8'h49; // I
    assign rom_data[2]  = 8'h4C; // L
    assign rom_data[3]  = 8'h4C; // L
    assign rom_data[4]  = 8'h47; // G
    assign rom_data[5]  = 8'h4F; // O
    assign rom_data[6]  = 8'h4F; // O
    assign rom_data[7]  = 8'h44; // D
    assign rom_data[8]  = 8'h54; // T
    assign rom_data[9]  = 8'h52; // R
    assign rom_data[10] = 8'h55; // U
    assign rom_data[11] = 8'h45; // E
    assign rom_data[12] = 8'h48; // H
    assign rom_data[13] = 8'h41; // A
    assign rom_data[14] = 8'h43; // C
    assign rom_data[15] = 8'h4B; // K
	 assign rom_data[16] = 8'h20; 
	 assign rom_data[17] = 8'h20; 
	 assign rom_data[18] = 8'h20;
	 assign rom_data[19] = 8'h20;
	 

    reg [4:0] rom_ptr;
    wire fw_read_rx;
    wire fake_rx_empty = (rom_ptr >= 20);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rom_ptr <= 0;
        end else if (!fake_rx_empty && fw_read_rx) begin
            rom_ptr <= rom_ptr + 1; 
        end
    end

    wire [7:0] fake_rx_out = fake_rx_empty ? 8'h00 : rom_data[rom_ptr];


    // FIREWALL

    wire [7:0] fw_data_out;
    wire       fw_write_out;
    wire       packer_full;

    FIREWALL #(
        .DATA_BITS(8), .WORD_LEN(4), .NUM_WORDS(2), .SUBST(8'h2A) 
    ) firewall_inst (
        .clk(clk), .reset(reset),
        .data_in(fake_rx_out), .rx_empty(fake_rx_empty), .read_rx(fw_read_rx),
        .packer_full(packer_full), .data_out(fw_data_out), .write_out(fw_write_out)
    );


    // AES PACKER

    wire [127:0] packer_block_out;
    wire         packer_block_valid;
    wire         unpacker_ready;
    wire         core_ready;
    wire         aes_busy = ~unpacker_ready | ~core_ready;

    AES_PACKER packer_inst (
        .clk(clk), .reset(reset),
        .data_in(fw_data_out), .write_en(fw_write_out), .packer_full(packer_full),
        .flush(flush_pulse), .aes_busy(aes_busy),
        .block_out(packer_block_out), .block_valid(packer_block_valid)
    );

  
    // AES CORE

    AES_KEY_EXPAND key_expand_inst (
        .key(aes_key),
        .round_keys_flat(flattened_round_keys)
    );

    wire [127:0] core_ciphertext;
    wire         core_valid_out;

    AES_CORE aes_core_inst (
        .clk(clk), .reset(reset), .flattened_keys(flattened_round_keys),
        .plaintext(packer_block_out), .valid_in(packer_block_valid),
        .ciphertext(core_ciphertext), .valid_out(core_valid_out),
        .ready(core_ready)
    );


    // AES UNPACKER

    wire [7:0] unpacker_data_out;
    wire       unpacker_write_en;
    wire       tx_fifo_full;

    AES_UNPACKER unpacker_inst (
        .clk(clk), .reset(reset),
        .block_in(core_ciphertext), .block_valid(core_valid_out),
        .unpacker_ready(unpacker_ready),
        .tx_full(tx_fifo_full), .data_out(unpacker_data_out), .write_en(unpacker_write_en)
    );


    // TX FIFO & UART TX

    wire tx_fifo_empty;
    wire [7:0] tx_fifo_out;
    reg  tx_fifo_read_en;

    FIFO #(.DATA_BITS(8), .ADDR_BITS(4)) tx_fifo (
        .clk(clk), .reset(reset),
        .wr_en(unpacker_write_en), .data_in(unpacker_data_out), .full(tx_fifo_full),
        .read_en(tx_fifo_read_en), .data_out(tx_fifo_out), .empty(tx_fifo_empty)
    );

    assign led_active = ~tx_fifo_empty; // LED ON while transmitting

    wire tx_done;
    reg  tx_start;

    UART_TX #(.DATA_BITS(8), .SAMPLE_TICKS(16)) uart_tx_inst (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .data_in(tx_fifo_out), .tx_start(tx_start), .tx_done(tx_done), .tx_out(uart_tx)
    );

    reg tx_busy;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_busy         <= 1'b0;
            tx_start        <= 1'b0;
            tx_fifo_read_en <= 1'b0;
        end else begin
            tx_start        <= 1'b0;
            tx_fifo_read_en <= 1'b0;

            if (!tx_busy && !tx_fifo_empty) begin
                tx_start        <= 1'b1;
                tx_fifo_read_en <= 1'b1;
                tx_busy         <= 1'b1;
            end else if (tx_done) begin
                tx_busy <= 1'b0;
            end
        end
    end

endmodule
// ============================================================================
// SPI ARM INTERFACE - Interfaz SPI para procesador ARM (Behavioral)
// ============================================================================
// Protocolo:
//   - Handshake: 0xA5 → 0x5A
//   - Operando A: 0x1N → ACK 0xAN
//   - Operando B: 0x2N → ACK 0xBN
//   - Leer resultado: 0x30 → 0x0R
// ============================================================================

module spi_arm_interface #(
    parameter bit LOOSE_HANDSHAKE = 1'b1,
    parameter bit ACK_SWAP_NIBBLES = 1'b1,
    parameter bit RES_SWAP_NIBBLES = 1'b1
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // SPI signals
    input  logic        spi_sck,
    input  logic        spi_mosi,
    input  logic        spi_cs_n,
    output logic        spi_miso,
    
    // Interface to ARM processor
    output logic [3:0]  operand_a,
    output logic [3:0]  operand_b,
    output logic        operands_valid,
    input  logic [31:0] arm_result,
    
    // Status outputs
    output logic        handshake_ok,
    output logic [3:0]  debug_leds
);

    localparam [7:0] HANDSHAKE_CODE = 8'hA5;
    localparam [7:0] HANDSHAKE_RESP = 8'h5A;

    // ========================================================================
    // Sincronización de señales SPI
    // ========================================================================
    logic [1:0] sck_sync, cs_sync, mosi_sync;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sck_sync <= 2'b0;
            cs_sync <= 2'b11;
            mosi_sync <= 2'b0;
        end else begin
            sck_sync <= {sck_sync[0], spi_sck};
            cs_sync <= {cs_sync[0], spi_cs_n};
            mosi_sync <= {mosi_sync[0], spi_mosi};
        end
    end
    
    logic sck_prev, cs_prev;
    logic sck_rising, sck_falling, cs_falling;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sck_prev <= 1'b0;
            cs_prev <= 1'b1;
        end else begin
            sck_prev <= sck_sync[1];
            cs_prev <= cs_sync[1];
        end
    end
    
    assign sck_rising = sck_sync[1] & ~sck_prev;
    assign sck_falling = ~sck_sync[1] & sck_prev;
    assign cs_falling = ~cs_sync[1] & cs_prev;
    
    logic cs_active;
    assign cs_active = ~cs_sync[1];

    // ========================================================================
    // Shift Register RX (8 bits MSB first)
    // ========================================================================
    logic [7:0] rx_shift;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            rx_shift <= 8'h00;
        else if (cs_active && sck_rising)
            rx_shift <= {rx_shift[6:0], mosi_sync[1]};
    end

    // ========================================================================
    // Shift Register TX (8 bits MSB first)
    // ========================================================================
    logic [7:0] tx_shift;
    logic [7:0] tx_data;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tx_shift <= 8'h5A;  // Reset a handshake response
            spi_miso <= 1'b1;
        end else if (cs_falling) begin
            tx_shift <= handshake_ok ? tx_data : HANDSHAKE_RESP;
            spi_miso <= handshake_ok ? tx_data[7] : HANDSHAKE_RESP[7];
        end else if (cs_active && sck_falling) begin
            tx_shift <= {tx_shift[6:0], 1'b0};
            spi_miso <= tx_shift[6];
        end
    end

    // ========================================================================
    // Contador de bits
    // ========================================================================
    logic [2:0] bit_count;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            bit_count <= 3'b0;
        else if (~cs_active)
            bit_count <= 3'b0;
        else if (sck_rising)
            bit_count <= bit_count + 1;
    end
    
    logic byte_complete;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            byte_complete <= 1'b0;
        else
            byte_complete <= cs_active && sck_rising && (bit_count == 3'd7);
    end

    // ========================================================================
    // Registro de byte recibido
    // ========================================================================
    logic [7:0] rx_byte;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            rx_byte <= 8'h00;
        else if (byte_complete)
            rx_byte <= rx_shift;
    end

    // ========================================================================
    // Decodificación de comandos
    // ========================================================================
    logic is_handshake, is_cmd_a, is_cmd_b, is_cmd_result;
    
    always_comb begin
        is_handshake = (rx_byte == HANDSHAKE_CODE);
        is_cmd_a = (rx_byte[7:4] == 4'h1);
        is_cmd_b = (rx_byte[7:4] == 4'h2);
        is_cmd_result = (rx_byte == 8'h30) || (rx_byte[7:4] == 4'h3);
    end

    // ========================================================================
    // Registros de operandos
    // ========================================================================
    logic [3:0] reg_a, reg_b;
    logic a_received, b_received;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_a <= 4'h0;
            reg_b <= 4'h0;
            a_received <= 1'b0;
            b_received <= 1'b0;
        end else if (byte_complete) begin
            if (is_cmd_a) begin
                reg_a <= rx_byte[3:0];
                a_received <= 1'b1;
            end
            if (is_cmd_b) begin
                reg_b <= rx_byte[3:0];
                b_received <= 1'b1;
            end
        end
    end
    
    assign operands_valid = byte_complete && ((is_cmd_a && b_received) || (is_cmd_b && a_received));
    assign operand_a = reg_a;
    assign operand_b = reg_b;

    // ========================================================================
    // Registro de resultado
    // ========================================================================
    logic [3:0] result_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            result_reg <= 4'h0;
        else if (byte_complete && is_cmd_result)
            result_reg <= arm_result[3:0];
    end

    // ========================================================================
    // Preparación de TX data
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            tx_data <= 8'h00;
        else if (byte_complete) begin
            if (is_handshake)
                tx_data <= HANDSHAKE_RESP;
            else if (is_cmd_a) begin
                if (ACK_SWAP_NIBBLES)
                    tx_data <= {rx_byte[3:0], 4'hA};
                else
                    tx_data <= {4'hA, rx_byte[3:0]};
            end
            else if (is_cmd_b) begin
                if (ACK_SWAP_NIBBLES)
                    tx_data <= {rx_byte[3:0], 4'hB};
                else
                    tx_data <= {4'hB, rx_byte[3:0]};
            end
            else if (is_cmd_result) begin
                if (RES_SWAP_NIBBLES)
                    tx_data <= {result_reg, 4'h0};
                else
                    tx_data <= {4'h0, result_reg};
            end
        end
    end

    // ========================================================================
    // Handshake control
    // ========================================================================
    logic first_byte_seen;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            handshake_ok <= 1'b0;
            first_byte_seen <= 1'b0;
        end else if (byte_complete) begin
            if (~first_byte_seen) begin
                first_byte_seen <= 1'b1;
                if (LOOSE_HANDSHAKE || is_handshake)
                    handshake_ok <= 1'b1;
            end else if (is_handshake)
                handshake_ok <= 1'b1;
        end
    end

    // ========================================================================
    // Debug output
    // ========================================================================
    assign debug_leds = reg_b;

endmodule
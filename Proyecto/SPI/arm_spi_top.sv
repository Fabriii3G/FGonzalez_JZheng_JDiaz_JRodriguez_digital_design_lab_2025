// ============================================================================
// ARM SPI TOP - Procesador ARM con interfaz SPI
// ============================================================================
// Este módulo integra:
//   1. Interfaz SPI para recibir operandos A y B desde Raspberry Pi Pico
//   2. Procesador ARM que ejecuta operaciones con A y B
//   3. Memoria de instrucciones y datos
//   4. Devolución de resultados por SPI
//
// Flujo:
//   Pico envía A (0x1N) → ARM recibe A
//   Pico envía B (0x2N) → ARM recibe B → ARM ejecuta
//   Pico lee resultado (0x30) → recibe resultado de ALU
// ============================================================================

module arm_spi_top (
    input  logic        clk,          // 50 MHz system clock
    input  logic        rst_n,        // Reset activo bajo
    
    // SPI Interface (Slave)
    input  logic        spi_sck,
    input  logic        spi_mosi,
    input  logic        spi_cs_n,
    output logic        spi_miso,
    
    // Debug outputs
    output logic [3:0]  debug_leds,
    output logic        handshake_ok
);

    // ========================================================================
    // SPI INTERFACE
    // ========================================================================
    logic [3:0]  spi_operand_a;
    logic [3:0]  spi_operand_b;
    logic        operands_valid;
    logic [31:0] arm_result_to_spi;
    
    spi_arm_interface #(
        .LOOSE_HANDSHAKE(1'b1),
        .ACK_SWAP_NIBBLES(1'b0),     // ACK: 0xAN y 0xBN (nibble alto = A/B)
        .RES_SWAP_NIBBLES(1'b0)      // RES: 0x0R (nibble alto = 0)
    ) spi_interface (
        .clk(clk),
        .rst_n(rst_n),
        
        // SPI signals
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_cs_n(spi_cs_n),
        .spi_miso(spi_miso),
        
        // Interface to ARM
        .operand_a(spi_operand_a),
        .operand_b(spi_operand_b),
        .operands_valid(operands_valid),
        .arm_result(arm_result_to_spi),
        
        // Status
        .handshake_ok(handshake_ok),
        .debug_leds(debug_leds)
    );

    // ========================================================================
    // ALU DIRECTA - Suma de operandos SPI
    // ========================================================================
    // Usamos la ALU del procesador ARM directamente para sumar A + B
    
    logic [31:0] alu_src1, alu_src2;
    logic [31:0] alu_result;
    logic [3:0]  alu_flags;
    logic [1:0]  alu_control;
    
    // Extender operandos de 4 bits a 32 bits
    assign alu_src1 = {28'h0, spi_operand_a};
    assign alu_src2 = {28'h0, spi_operand_b};
    assign alu_control = 2'b00;  // 00 = ADD (según el módulo alu.sv)
    
    // Instanciar la ALU del procesador ARM
    alu #(
        .BusWidth(32)
    ) alu_instance (
        .i_ALU_Src1(alu_src1),
        .i_ALU_Src2(alu_src2),
        .i_ALU_Control(alu_control),
        .o_ALU_Result(alu_result),
        .o_ALU_Flags(alu_flags)
    );
    
    // ========================================================================
    // CAPTURA DE RESULTADO CON DELAY
    // ========================================================================
    // La ALU es combinacional, su resultado está disponible inmediatamente
    // Registramos los operandos primero, luego capturamos el resultado
    
    logic [3:0] operand_a_reg, operand_b_reg;
    logic [31:0] result_reg;
    logic [1:0] capture_delay;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            operand_a_reg <= 4'h0;
            operand_b_reg <= 4'h0;
            result_reg <= 32'h0;
            capture_delay <= 2'b00;
        end else begin
            // Capturar operandos cuando son válidos
            if (operands_valid) begin
                operand_a_reg <= spi_operand_a;
                operand_b_reg <= spi_operand_b;
                capture_delay <= 2'b11;  // Iniciar contador de delay
            end else if (capture_delay != 2'b00) begin
                capture_delay <= capture_delay - 1;
            end
            
            // Capturar resultado después del delay (cuando counter llega a 1)
            if (capture_delay == 2'b01) begin
                result_reg <= alu_result;
            end
        end
    end
    
    // Enviar resultado al SPI
    assign arm_result_to_spi = result_reg;

endmodule
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
        .ACK_SWAP_NIBBLES(1'b0),     // Cambiado a 0
        .RES_SWAP_NIBBLES(1'b0)      // Cambiado a 0
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
    // ARM PROCESSOR
    // ========================================================================
    logic [31:0] PC;
    logic [31:0] Instr;
    logic        MemWrite;
    logic [31:0] ALUResult;
    logic [31:0] WriteData;
    logic [31:0] ReadData;
    
    arm arm_core (
        .clk(clk),
        .reset(~rst_n),  // ARM usa reset activo alto
        .PC(PC),
        .Instr(Instr),
        .MemWrite(MemWrite),
        .ALUResult(ALUResult),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );

    // ========================================================================
    // INSTRUCTION MEMORY
    // ========================================================================
    imem instruction_memory (
        .a(PC),
        .rd(Instr)
    );

    // ========================================================================
    // DATA MEMORY CON OPERANDOS SPI
    // ========================================================================
    // La memoria de datos se modifica para que ciertas direcciones
    // contengan los operandos recibidos por SPI
    
    logic [31:0] dmem_read_data;
    
    // Direcciones especiales para operandos SPI:
    //   0x00: Operando A (extendido a 32 bits)
    //   0x04: Operando B (extendido a 32 bits)
    //   0x08: Señal de validación (1 si hay operandos nuevos)
    
    wire is_operand_a_addr = (ALUResult == 32'h00000000);
    wire is_operand_b_addr = (ALUResult == 32'h00000004);
    wire is_valid_addr     = (ALUResult == 32'h00000008);
    
    // Memoria de datos normal
    dmem data_memory (
        .clk(clk),
        .we(MemWrite & ~is_operand_a_addr & ~is_operand_b_addr & ~is_valid_addr),
        .a(ALUResult),
        .wd(WriteData),
        .rd(dmem_read_data)
    );
    
    // Multiplexor para lectura de datos especiales
    assign ReadData = ({32{is_operand_a_addr}} & {28'h0, spi_operand_a}) |
                     ({32{is_operand_b_addr}} & {28'h0, spi_operand_b}) |
                     ({32{is_valid_addr}}     & {31'h0, operands_valid}) |
                     ({32{~is_operand_a_addr & ~is_operand_b_addr & ~is_valid_addr}} & dmem_read_data);

    // ========================================================================
    // RESULTADO AL SPI
    // ========================================================================
    // Enviamos el resultado de la ALU (4 bits bajos) de vuelta por SPI
    assign arm_result_to_spi = ALUResult;

endmodule
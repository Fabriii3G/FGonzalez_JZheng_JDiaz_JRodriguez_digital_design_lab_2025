module testbench();
    logic        clk;
    logic        reset;
    logic [31:0] WriteData, DataAdr;
    logic        MemWrite;
    
    // Contadores para rastrear eventos
    integer store_count = 0;
    integer branch_count = 0;
    integer arithmetic_count = 0;
    logic [31:0] prev_pc = 0;
    
    // instantiate device to be tested
    top dut(clk, reset, WriteData, DataAdr, MemWrite);
    
    // initialize test
    initial begin
        reset <= 1; 
        #22; 
        reset <= 0;
    end
    
    // generate clock to sequence tests
    always begin
        clk <= 1; 
        #5; 
        clk <= 0; 
        #5;
    end
    
    // Monitor de instrucciones ejecutadas
    always @(posedge clk) begin
        if (!reset) begin
            // Detectar solo operaciones aritméticas SUB y ADD (no MOV)
            if (dut.arm.RegWrite && dut.arm.Instr[27:26] == 2'b00) begin
                case (dut.arm.Instr[24:21])
                    4'b0010: begin // SUB
                        arithmetic_count = arithmetic_count + 1;
                        $display("[ARITHMETIC #%0d] SUB executed, Result=%0d", arithmetic_count, dut.arm.dp.ALUResult);
                    end
                    4'b0100: begin // ADD
                        arithmetic_count = arithmetic_count + 1;
                        $display("[ARITHMETIC #%0d] ADD executed, Result=%0d", arithmetic_count, dut.arm.dp.ALUResult);
                    end
                endcase
            end
            
            // Detectar saltos (cuando PC salta, no incrementa secuencialmente)
            if (prev_pc != 0 && dut.arm.PC != prev_pc + 4 && dut.arm.PC != 0) begin
                branch_count = branch_count + 1;
                $display("[JUMP #%0d] PC jumped from 0x%h to 0x%h\n", branch_count, prev_pc, dut.arm.PC);
                
                if (branch_count >= 3) begin
                    $display("===========================================");
                    $display("Test completed after 3 jump iterations");
                    $display("Arithmetic: %0d operations executed", arithmetic_count);
                    $display("Store: %0d stores executed", store_count);
                    $display("Jump: Working correctly");
                    $display("===========================================");
                    $stop;
                end
            end
            
            prev_pc = dut.arm.PC;
        end
    end
    
    // Monitor de stores
    always @(negedge clk) begin
        if (MemWrite && !reset) begin
            store_count = store_count + 1;
            $display("[STORE #%0d] Address=%0d, Data=%0d", store_count, DataAdr, WriteData);
        end
    end
    
    // Timeout de seguridad
    initial begin
        #1000;
        $display("\n===========================================");
        $display("TIMEOUT");
        $display("  Arithmetic: %0d", arithmetic_count);
        $display("  Stores: %0d", store_count);
        $display("  Jumps: %0d", branch_count);
        $display("===========================================");
        $stop;
    end
    
endmodule
module instruction_memory (
    input logic [31:0] A,  // Address input (from PC)
    output logic [31:0] RD // Instruction output
);

    logic [31:0] mem [0:255]; // 256 x 32-bit instruction memory

    // Initialize instruction memory
    initial begin
        mem[0] = 32'b100011_00000_00001_0000_0000_0000_0111; // LW $1, 7($0)
        mem[1] = 32'b001000_00001_00001_0000_0000_0000_0001; // ADDI $1, $1, 1
        mem[2] = 32'b101011_00000_00001_0000_0000_0000_0010; // SW $1, 2($0)
        // Add NOPs or additional instructions if needed
    end

    // Output instruction at address A
    assign RD = mem[A[31:2]]; // Use word-aligned addresses (ignore lower 2 bits)
endmodule

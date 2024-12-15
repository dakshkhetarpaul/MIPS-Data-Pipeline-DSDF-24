module MUX_MemtoReg(
    input logic MemtoReg,            // Selector signal
    input logic [31:0] ALUResult,    // Input from ALU
    input logic [31:0] RD,           // Input from Data Memory
    output logic [31:0] MemtoReg_out // Output
);

    // MUX logic using always_comb
    always_comb begin
        if (MemtoReg)
            MemtoReg_out = RD;       // Select Data Memory (RD) if MemtoReg is 1
        else
            MemtoReg_out = ALUResult; // Select ALUResult if MemtoReg is 0
    end

endmodule

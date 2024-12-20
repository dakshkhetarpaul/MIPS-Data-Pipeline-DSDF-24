module MUX_ALUSrc(
    input logic ALUSrc,              // Selector signal
    input logic [31:0] RegData,      // Input from Register File
    input logic [31:0] ImmData,      // Input from Sign Extend (immediate value)
    output logic [31:0] ALUOutput     // Output to ALU
);

    // MUX logic using always_comb
    always_comb begin
        if (ALUSrc)
            ALUOutput = ImmData;      // Select Immediate Data if ALUSrc is 1
        else
            ALUOutput = RegData;      // Select Register Data if ALUSrc is 0
    end

endmodule

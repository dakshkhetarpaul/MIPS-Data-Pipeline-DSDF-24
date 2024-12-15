module ALU (
    input [31:0] SrcA,        // First operand
    input [31:0] SrcB,        // Second operand
    input [2:0] ALUControl, // ALU control signal
    output logic [31:0] ALUResult // Output result
);

    // Perform operations based on ALUControl
    always @(*) begin
        case (ALUControl)
            3'b010: ALUResult = SrcA + SrcB;   // ADD operation
            3'b110: ALUResult = SrcA - SrcB;   // SUB operation
            default: ALUResult = 32'b0;  
        endcase
    end
endmodule

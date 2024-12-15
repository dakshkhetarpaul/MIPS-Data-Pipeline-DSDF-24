module SignExtend(
    input logic [15:0] imm,          // 16-bit immediate input
    output logic [31:0] sign_ext_imm // 32-bit sign-extended output
);

    // Sign extend the 16-bit immediate value to 32 bits
    always_comb begin
        sign_ext_imm = {{16{imm[15]}}, imm}; // Extend the sign bit (imm[15]) to the upper 16 bits
    end

endmodule

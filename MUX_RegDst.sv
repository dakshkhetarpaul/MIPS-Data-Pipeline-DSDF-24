module MUX_RegDst(
    input logic RegDst,              // Selector signal
    input logic [4:0] RT,            // Input from RT field (Register Target)
    input logic [4:0] RD,            // Input from RD field (Register Destination)
    output logic [4:0] RegDst_out    // Output to select the destination register
);

    // MUX logic using always_comb
    always_comb begin
        if (RegDst)
            RegDst_out = RD;         // Select RD if RegDst is 1
        else
            RegDst_out = RT;         // Select RT if RegDst is 0
    end

endmodule

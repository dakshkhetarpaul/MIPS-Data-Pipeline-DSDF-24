module register_file (
    input logic clk, rst,
    input logic [4:0] A1, A2, A3,
    input logic [31:0] WD3,
    input logic WE3,
    output logic [31:0] RD1, RD2,
    output logic [31:0] prode,
    output logic [31:0] prode9 // New output for rf[6]
);

    logic [31:0] rf [31:0]; // 32 registers

    // Existing assignments
    assign RD1 = rf[A1];
    assign RD2 = rf[A2];
    assign prode = rf[1];

    // New assignment
    assign prode9 = rf[9];

    // Rest of your code remains the same
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (int i = 0; i < 32; i++) begin
                rf[i] <= 32'd0;
            end
            rf[9] <= 32'd9; // Set Reg File
        end else if (WE3) begin
            rf[A3] <= WD3;
        end
    end

endmodule


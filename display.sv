module display (
    input logic [31:0] data_in,    // Input from register file (32-bit)
    output logic [6:0] segments    // Output to 7-segment display (active low)
);
    // Use only the lower 4 bits to display a single digit (0-9)
    logic [3:0] display_value;

    assign display_value = data_in[3:0];  // Extract 4 bits for display

    // Segment pattern for digits 0-9 (active low: 0 turns ON the segment)
    always_comb begin
        case (display_value)
            4'b0000: segments = 7'b100_0000;  // 0
            4'b0001: segments = 7'b111_1001;  // 1
            4'b0010: segments = 7'b010_0100;  // 2
            4'b0011: segments = 7'b011_0000;  // 3
            4'b0100: segments = 7'b001_1001;  // 4
            4'b0101: segments = 7'b001_0010;  // 5
            4'b0110: segments = 7'b000_0010;  // 6
            4'b0111: segments = 7'b111_1000;  // 7
            4'b1000: segments = 7'b000_0000;  // 8
            4'b1001: segments = 7'b001_0000;  // 9
            default: segments = 7'b111_1111;  // Off (invalid input)
        endcase
    end
endmodule


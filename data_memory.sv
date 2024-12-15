module data_memory (
    input logic clk, rst,             // Clock and reset
    input logic [31:0] A,             // Address input (32-bit)
    input logic [31:0] WD,            // Data to write to memory
    input logic WE,                   // Write enable signal
    output logic [31:0] RD,           // Data output (read)
    output logic [31:0] prode,         // Probe to observe specific memory content
	 output logic [31:0] MemVal2,
	 output logic [31:0] MemVal7
);

    logic [31:0] mem [255:0];         // 256 x 32-bit memory

    // Initialize data memory during reset
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (int i = 0; i < 256; i++) begin
                mem[i] <= 32'd0;      // Initialize all memory locations to 0
            end
				mem[7] <= 32'd7;  //new set data mem
        end else if (WE) begin
            mem[A[7:0]] <= WD;        // Write data to memory at the specified address
        end
    end

    // Read data from memory (combinational)
    assign RD = mem[A[7:0]];          // Address restricted to 8 bits (256 locations)

    // Probe specific memory content
    assign MemVal7 = mem[7];            // Set memval7` to observe the content of memory[1]
	 assign MemVal2 = mem[2]; 

endmodule


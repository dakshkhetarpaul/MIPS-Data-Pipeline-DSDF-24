module top(
    input logic clk, rst,
    input logic [1:0] sw,             // Address for instruction memory selection
    output logic [31:0] ALUResult,    // Output for pre-lab simulation
    output logic [31:0] RD1, RD2,     // Output for pre-lab simulation
    output logic [31:0] prode_register_file, // Output for pre-lab simulation
    output logic [6:0] display_led,   // Output for in-lab display
    output logic [31:0] MemReadData,  // Data read from memory (for load operation)
    output logic [31:0] RegFile1,     // Register file output for Register_File[1]
    output logic [31:0] RegFile9,     // Register file output for Register_File[9]
    output logic [31:0] MemWriteData, // Data written to memory (for store operation)
    output logic [31:0] MemVal2,
    output logic [31:0] MemVal7,
	 output logic [7:0] pipeline_leds  // New output for pipeline LEDs
);

    // Declare missing signals
    logic [31:0] sign_ext_imm;
    logic [3:0] display_input;

    // Instruction fetched from instruction memory
    logic [31:0] instruction;

    // Pipeline Registers

    // IF/ID Pipeline Register
    logic [31:0] IF_ID_PC, IF_ID_Instruction;

    // ID/EX Pipeline Register
    logic [31:0] ID_EX_PC, ID_EX_ReadData1, ID_EX_ReadData2, ID_EX_SignExtImm;
    logic [4:0]  ID_EX_RS, ID_EX_RT, ID_EX_RD;
    logic [2:0]  ID_EX_ALUControl;
    logic        ID_EX_RegWrite, ID_EX_MemWrite, ID_EX_ALUSrc, ID_EX_MemtoReg, ID_EX_RegDst;

    // EX/MEM Pipeline Register
    logic [31:0] EX_MEM_ALUResult, EX_MEM_WriteData;
    logic [4:0]  EX_MEM_WriteReg;
    logic        EX_MEM_RegWrite, EX_MEM_MemWrite, EX_MEM_MemtoReg;

    // MEM/WB Pipeline Register
    logic [31:0] MEM_WB_ReadData, MEM_WB_ALUResult;
    logic [4:0]  MEM_WB_WriteReg;
    logic        MEM_WB_RegWrite, MEM_WB_MemtoReg;

    // Program Counter
    logic [31:0] PC;

    // Instantiate Instruction Memory
    instruction_memory instr_mem (
        .A(PC),
        .RD(instruction)
    );

    // Program Counter (PC) and IF/ID Pipeline Register with Stall
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            PC <= 0;
            IF_ID_PC <= 0;
            IF_ID_Instruction <= 0;
        end else if (Stall) begin
            // Hold PC and IF/ID registers (do not update)
            PC <= PC;
            IF_ID_PC <= IF_ID_PC;
            IF_ID_Instruction <= IF_ID_Instruction;
        end else begin
            PC <= PC + 4; // Increment PC by 4
            IF_ID_PC <= PC;
            IF_ID_Instruction <= instruction;
        end
    end

    // Control Signals
    logic [2:0] ALUControl;
    logic RegWrite, MemWrite, ALUSrc, MemtoReg, RegDst;

    // Control Logic
    always_comb begin
        // Default control signals
        RegWrite    = 0;
        MemWrite    = 0;
        ALUSrc      = 0;
        MemtoReg    = 0;
        RegDst      = 0;
        ALUControl  = 3'b010; // Default to ADD

        case (IF_ID_Instruction[31:26])
            6'b100011: begin // LW
                RegWrite    = 1;
                MemWrite    = 0;
                ALUSrc      = 1;
                MemtoReg    = 1;
                RegDst      = 0; // rt field
                ALUControl  = 3'b010; // ADD for address calculation
            end
            6'b101011: begin // SW
                RegWrite    = 0;
                MemWrite    = 1;
                ALUSrc      = 1;
                MemtoReg    = 0; // Not used
                RegDst      = 0; // Not used
                ALUControl  = 3'b010; // ADD for address calculation
            end
            6'b001000: begin // ADDI
                RegWrite    = 1;
                MemWrite    = 0;
                ALUSrc      = 1;
                MemtoReg    = 0; // Write ALUResult to register
                RegDst      = 0; // rt field
                ALUControl  = 3'b010; // ADD
            end
            default: begin
                // Handle other instructions or default case
            end
        endcase
    end

    // Register File
    register_file r_f(
        .clk(clk),
        .rst(rst),
        .A1(IF_ID_Instruction[25:21]), // rs
        .A2(IF_ID_Instruction[20:16]), // rt
        .A3(MEM_WB_WriteReg),          // Destination register from WB stage
        .WD3(WB_WriteData),            // Write data from WB stage
        .WE3(MEM_WB_RegWrite),         // Write enable from WB stage
        .RD1(RD1),
        .RD2(RD2),
        .prode(prode_register_file),
        .prode9(RegFile9)
    );

    // Sign Extend
    SignExtend sign_ext(
        .imm(IF_ID_Instruction[15:0]), // Use IF_ID_Instruction instead of instruction
        .sign_ext_imm(sign_ext_imm)
    );

    // Hazard Detection Unit
    logic Stall;

    always_comb begin
        // Default is no stall
        Stall = 0;

        // Load-Use Hazard Detection
        if ((ID_EX_MemtoReg) && ((ID_EX_RT == IF_ID_Instruction[25:21]) || (ID_EX_RT == IF_ID_Instruction[20:16]))) begin
            Stall = 1;
        end
    end

    // ID Stage and ID/EX Pipeline Register with Stall
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Initialize all ID/EX pipeline registers to zero
            ID_EX_RegWrite      <= 0;
            ID_EX_MemWrite      <= 0;
            ID_EX_ALUSrc        <= 0;
            ID_EX_MemtoReg      <= 0;
            ID_EX_RegDst        <= 0;
            ID_EX_ALUControl    <= 0;
            ID_EX_PC            <= 0;
            ID_EX_ReadData1     <= 0;
            ID_EX_ReadData2     <= 0;
            ID_EX_SignExtImm    <= 0;
            ID_EX_RS            <= 0;
            ID_EX_RT            <= 0;
            ID_EX_RD            <= 0;
        end else if (Stall) begin
            // Insert bubble: set control signals to zero
            ID_EX_RegWrite      <= 0;
            ID_EX_MemWrite      <= 0;
            ID_EX_ALUSrc        <= 0;
            ID_EX_MemtoReg      <= 0;
            ID_EX_RegDst        <= 0;
            ID_EX_ALUControl    <= 0;
            // Pass other values unchanged
            ID_EX_PC            <= IF_ID_PC;
            ID_EX_ReadData1     <= RD1;
            ID_EX_ReadData2     <= RD2;
            ID_EX_SignExtImm    <= sign_ext_imm;
            ID_EX_RS            <= IF_ID_Instruction[25:21];
            ID_EX_RT            <= IF_ID_Instruction[20:16];
            ID_EX_RD            <= IF_ID_Instruction[15:11];
        end else begin
            // Normal operation: update ID/EX pipeline registers
            ID_EX_RegWrite      <= RegWrite;
            ID_EX_MemWrite      <= MemWrite;
            ID_EX_ALUSrc        <= ALUSrc;
            ID_EX_MemtoReg      <= MemtoReg;
            ID_EX_RegDst        <= RegDst;
            ID_EX_ALUControl    <= ALUControl;
            ID_EX_PC            <= IF_ID_PC;
            ID_EX_ReadData1     <= RD1;
            ID_EX_ReadData2     <= RD2;
            ID_EX_SignExtImm    <= sign_ext_imm;
            ID_EX_RS            <= IF_ID_Instruction[25:21];
            ID_EX_RT            <= IF_ID_Instruction[20:16];
            ID_EX_RD            <= IF_ID_Instruction[15:11];
        end
    end

    // MUX for Write Register in EX Stage
    logic [4:0] EX_WriteReg;

    assign EX_WriteReg = ID_EX_RegDst ? ID_EX_RD : ID_EX_RT;

    // Forwarding Unit Logic
    logic [1:0] ForwardA, ForwardB;

    always_comb begin
        // Default forwarding signals
        ForwardA = 2'b00;
        ForwardB = 2'b00;

        // EX Hazard
        if ((EX_MEM_RegWrite) && (EX_MEM_WriteReg != 0) && (EX_MEM_WriteReg == ID_EX_RS)) begin
            ForwardA = 2'b10;
        end
        if ((EX_MEM_RegWrite) && (EX_MEM_WriteReg != 0) && (EX_MEM_WriteReg == ID_EX_RT)) begin
            ForwardB = 2'b10;
        end

        // MEM Hazard
        if ((MEM_WB_RegWrite) && (MEM_WB_WriteReg != 0) && (MEM_WB_WriteReg == ID_EX_RS)) begin
            ForwardA = 2'b01;
        end
        if ((MEM_WB_RegWrite) && (MEM_WB_WriteReg != 0) && (MEM_WB_WriteReg == ID_EX_RT)) begin
            ForwardB = 2'b01;
        end
    end

    // Forwarded ALU inputs
    logic [31:0] ForwardedA, ForwardedB;

    assign ForwardedA = (ForwardA == 2'b00) ? ID_EX_ReadData1 :
                        (ForwardA == 2'b10) ? EX_MEM_ALUResult :
                        (ForwardA == 2'b01) ? WB_WriteData : ID_EX_ReadData1;

    assign ForwardedB = (ForwardB == 2'b00) ? ID_EX_ReadData2 :
                        (ForwardB == 2'b10) ? EX_MEM_ALUResult :
                        (ForwardB == 2'b01) ? WB_WriteData : ID_EX_ReadData2;

    // ALU inputs
    logic [31:0] ALU_SrcA, ALU_SrcB;

    assign ALU_SrcA = ForwardedA;
    assign ALU_SrcB = ID_EX_ALUSrc ? ID_EX_SignExtImm : ForwardedB;

    // ALU
    ALU alu_inst(
        .SrcA(ALU_SrcA),
        .SrcB(ALU_SrcB),
        .ALUControl(ID_EX_ALUControl),
        .ALUResult(ALUResult)
    );

    // EX Stage and EX/MEM Pipeline Register
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Initialize all EX/MEM pipeline registers to zero
            EX_MEM_ALUResult    <= 0;
            EX_MEM_WriteData    <= 0;
            EX_MEM_WriteReg     <= 0;
            EX_MEM_RegWrite     <= 0;
            EX_MEM_MemWrite     <= 0;
            EX_MEM_MemtoReg     <= 0;
        end else begin
            // Pass values from the EX stage to the EX/MEM pipeline registers
            EX_MEM_ALUResult    <= ALUResult;
            EX_MEM_WriteData    <= ForwardedB; // Data to write to memory
            EX_MEM_WriteReg     <= EX_WriteReg;
            EX_MEM_RegWrite     <= ID_EX_RegWrite;
            EX_MEM_MemWrite     <= ID_EX_MemWrite;
            EX_MEM_MemtoReg     <= ID_EX_MemtoReg;
        end
    end

    // Data Memory
    logic [31:0] RD;

    data_memory d_mem(
        .clk(clk),
        .rst(rst),
        .A(EX_MEM_ALUResult),      // Address from EX/MEM pipeline register
        .WD(EX_MEM_WriteData),     // Write data from EX/MEM pipeline register
        .WE(EX_MEM_MemWrite),      // Write enable from EX/MEM pipeline register
        .RD(RD),                   // Data read from memory
        .prode(),
        .MemVal2(MemVal2),
        .MemVal7(MemVal7)
    );

    assign MemReadData = RD;               // Data read from memory
    assign MemWriteData = EX_MEM_WriteData; // Data being written to memory

    // MEM Stage and MEM/WB Pipeline Register
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Initialize all MEM/WB pipeline registers to zero
            MEM_WB_ReadData    <= 0;
            MEM_WB_ALUResult   <= 0;
            MEM_WB_WriteReg    <= 0;
            MEM_WB_RegWrite    <= 0;
            MEM_WB_MemtoReg    <= 0;
        end else begin
            // Pass values from the MEM stage to the MEM/WB pipeline registers
            MEM_WB_ReadData    <= RD; // Data read from memory
            MEM_WB_ALUResult   <= EX_MEM_ALUResult;
            MEM_WB_WriteReg    <= EX_MEM_WriteReg;
            MEM_WB_RegWrite    <= EX_MEM_RegWrite;
            MEM_WB_MemtoReg    <= EX_MEM_MemtoReg;
        end
    end

    // MUX for MemtoReg in WB Stage
    logic [31:0] WB_WriteData;

    assign WB_WriteData = MEM_WB_MemtoReg ? MEM_WB_ReadData : MEM_WB_ALUResult;

    // MUX for Display Input Selection
    always_comb begin
        case (sw)
            2'b00: display_input = prode_register_file[3:0]; // Display lower 4 bits of Register_File[1]
            2'b01: display_input = MemVal2[3:0];             // Display lower 4 bits of Data_Memory[2]
            2'b10: display_input = PC[3:0];                  // Display lower 4 bits of Program Counter
            2'b11: display_input = MemVal7[3:0];
            default: display_input = 4'b0000;                // Default: Display '0'
        endcase
    end

    // Display
    display disp_inst(
        .data_in(display_input),
        .segments(display_led)
    );
	 
	     // LED[0]: Lights up when a stall occurs
    assign pipeline_leds[0] = Stall;

    // LED[1]: Lights up when forwarding from EX stage occurs
    assign pipeline_leds[1] = (ForwardA == 2'b10) || (ForwardB == 2'b10);

    // LED[2]: Lights up when forwarding from MEM stage occurs
    assign pipeline_leds[2] = (ForwardA == 2'b01) || (ForwardB == 2'b01);

    // LED[3]: Indicates whether the pipeline is active (not stalled)
    assign pipeline_leds[3] = ~Stall;

    // LEDs[4-7]: Indicate the presence of instructions in pipeline registers
    assign pipeline_leds[4] = (IF_ID_Instruction != 32'd0); // Instruction in IF/ID
    assign pipeline_leds[5] = (ID_EX_RegWrite || ID_EX_MemWrite); // Instruction in ID/EX
    assign pipeline_leds[6] = (EX_MEM_RegWrite || EX_MEM_MemWrite); // Instruction in EX/MEM
    assign pipeline_leds[7] = MEM_WB_RegWrite; // Instruction in MEM/WB

    // For monitoring register values
    assign RegFile1 = prode_register_file; // Assuming prode_register_file outputs rf[1]

endmodule

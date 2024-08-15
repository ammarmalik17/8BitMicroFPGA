module Project(
  input clk, rst
);

  // Define states
  parameter LOAD = 2'b00, FETCH = 2'b01, DECODE = 2'b10, EXECUTE = 2'b11;
  reg [1:0] current_state, next_state;

  // Program memory
  reg [11:0] program_mem [9:0];
  reg [7:0] load_addr;
  reg load_done;

  // Instruction and data registers
  reg [7:0] PC, DR, Acc;
  reg [11:0] IR;
  reg [3:0] SR;

  // Control signals for clearing registers
  reg PC_clr, Acc_clr, SR_clr, DR_clr, IR_clr;

  // Updated values from various modules
  wire [7:0] PC_updated, DR_updated;
  wire [11:0] IR_updated;
  wire [3:0] SR_updated;

  // Control signals for multiplexers and modules
  wire PC_E, Acc_E, SR_E, DR_E, IR_E;
  wire PMem_E, DMem_E, DMem_WE, ALU_E, PMem_LE, MUX1_Sel, MUX2_Sel;
  wire [3:0] ALU_Mode;
  wire [7:0] Adder_Out, ALU_Oper2, ALU_Out;

  // Modules instantiation
  ALU ALU_unit(
    .Operand1(Acc),
    .Operand2(ALU_Oper2),
    .E(ALU_E),
    .Mode(ALU_Mode),
    .CFlags(SR),
    .Out(ALU_Out),
    .Flags(SR_updated)
  );

  MUX1 MUX2_unit(
    .In2(IR[7:0]),
    .In1(DR),
    .Sel(MUX2_Sel),
    .Out(ALU_Oper2)
  );

  DMem DMem_unit(
    .clk(clk),
    .E(DMem_E),
    .WE(DMem_WE),
    .Addr(IR[3:0]),
    .DI(ALU_Out),
    .DO(DR_updated)
  );

  PMem PMem_unit(
    .clk(clk),
    .E(PMem_E),
    .Addr(PC),
    .I(IR_updated),
    .LE(PMem_LE),
    .LA(load_addr),
    .LI(load_instr)
  );

  adder PC_Adder_unit(
    .In(PC),
    .Out(Adder_Out)
  );

  MUX1 MUX1_unit(
    .In2(IR[7:0]),
    .In1(Adder_Out),
    .Sel(MUX1_Sel),
    .Out(PC_updated)
  );

  Control_Logic Control_Logic_Unit(
    .stage(current_state),
    .IR(IR),
    .SR(SR),
    .PC_E(PC_E),
    .Acc_E(Acc_E),
    .SR_E(SR_E),
    .IR_E(IR_E),
    .DR_E(DR_E),
    .PMem_E(PMem_E),
    .DMem_E(DMem_E),
    .DMem_WE(DMem_WE),
    .ALU_E(ALU_E),
    .MUX1_Sel(MUX1_Sel),
    .MUX2_Sel(MUX2_Sel),
    .PMem_LE(PMem_LE),
    .ALU_Mode(ALU_Mode)
  );

  // Initialize program memory
  initial begin
    $readmemb("progr.dat", program_mem, 0, 9);
  end

  // Load instruction from program memory
  always @(posedge clk) begin
    if (rst == 1) begin
      load_addr <= 0;
      load_done <= 1'b0;
    end else if (PMem_LE == 1) begin
      load_addr <= load_addr + 8'd1;
      if (load_addr == 8'd9) begin
        load_addr <= 8'd0;
        load_done <= 1'b1;
      end else begin
        load_done <= 1'b0;
      end
    end
  end

  // Assign loaded instruction from program memory
  assign load_instr = program_mem[load_addr];

  // State transition and control logic
  always @(posedge clk) begin
    if (rst == 1) begin
      current_state <= LOAD;
    end else begin
      current_state <= next_state;
    end
  end

  always @(*) begin
    // Clear control signals
    PC_clr = 0;
    Acc_clr = 0;
    SR_clr = 0;
    DR_clr = 0;
    IR_clr = 0;

    // State-specific logic
    case (current_state)
      LOAD: begin
        if (load_done == 1) begin
          next_state = FETCH;
          PC_clr = 1;
          Acc_clr = 1;
          SR_clr = 1;
          DR_clr = 1;
          IR_clr = 1;
        end else begin
          next_state = LOAD;
        end
      end
      FETCH: next_state = DECODE;
      DECODE: next_state = EXECUTE;
      EXECUTE: next_state = FETCH;
    endcase
  end

  // Update visible registers
  always @(posedge clk) begin
    if (rst == 1) begin
      PC <= 8'd0;
      Acc <= 8'd0;
      SR <= 4'd0;
    end else begin
      if (PC_E == 1'd1) PC <= PC_updated;
      else if (PC_clr == 1) PC <= 8'd0;

      if (Acc_E == 1'd1) Acc <= ALU_Out;
      else if (Acc_clr == 1) Acc <= 8'd0;

      if (SR_E == 1'd1) SR <= SR_updated;
      else if (SR_clr == 1) SR <= 4'd0;
    end
  end

  // Update invisible registers
  always @(posedge clk) begin
    if (DR_E == 1'd1) DR <= DR_updated;
    else if (DR_clr == 1) DR <= 8'd0;

    if (IR_E == 1'd1) IR <= IR_updated;
    else if (IR_clr == 1) IR <= 12'd0;
  end
endmodule

module Control_Logic(
  input [1:0] stage,
  input [11:0] IR,
  input [3:0] SR,
  output reg PC_E, Acc_E, SR_E, IR_E, DR_E, PMem_E, DMem_E, DMem_WE, ALU_E, MUX1_Sel, MUX2_Sel, PMem_LE,
  output reg [3:0] ALU_Mode
);

  // Define instruction types
  parameter LOAD = 2'b00, FETCH = 2'b01, DECODE = 2'b10, EXECUTE = 2'b11;

  // Initialize control signals to default values
  always @(*) begin
    PMem_LE = 0;
    PC_E = 0;
    Acc_E = 0;
    SR_E = 0;
    IR_E = 0;
    DR_E = 0;
    PMem_E = 0;
    DMem_E = 0;
    DMem_WE = 0;
    ALU_E = 0;
    ALU_Mode = 4'd0;
    MUX1_Sel = 0;
    MUX2_Sel = 0;

    // State-based control logic
    case (stage)
      LOAD: begin
        PMem_LE = 1;
        PMem_E = 1;
      end

      FETCH: begin
        IR_E = 1;
        PMem_E = 1;
      end

      DECODE: begin
        if (IR[11:9] == 3'b001) begin
          DR_E = 1;
          DMem_E = 1;
        end else begin
          DR_E = 0;
          DMem_E = 0;
        end
      end

      EXECUTE: begin
        if (IR[11] == 1) begin // ALU I-type
          PC_E = 1;
          Acc_E = 1;
          SR_E = 1;
          ALU_E = 1;
          ALU_Mode = IR[10:8];
          MUX1_Sel = 1;
          MUX2_Sel = 0;
        end else if (IR[10] == 1) begin // JZ, JC, JS, JO
          PC_E = 1;
          MUX1_Sel = SR[IR[9:8]];
        end else if (IR[9] == 1) begin
          PC_E = 1;
          Acc_E = IR[8];
          SR_E = 1;
          DMem_E = !IR[8];
          DMem_WE = !IR[8];
          ALU_E = 1;
          ALU_Mode = IR[7:4];
          MUX1_Sel = 1;
          MUX2_Sel = 1;
        end else if (IR[8] == 0) begin
          PC_E = 1;
          MUX1_Sel = 1;
        end else begin
          PC_E = 1;
          MUX1_Sel = 0;
        end
      end
    endcase
  end
endmodule

module PMem(
  input clk,
  input E,      // Enable port
  input [7:0] Addr,  // Address port
  output [11:0] I,  // Instruction port
  // 3 special ports are used to load program to the memory
  input LE,     // Load enable port 
  input [7:0] LA, // Load address port
  input [11:0] LI // Load instruction port
);
  reg [11:0] Prog_Mem [255:0];

  // Load instruction into memory on positive clock edge when LE is asserted
  always @(posedge clk) begin
    if (LE == 1) begin
      Prog_Mem[LA] <= LI;
    end
  end

  // Output the instruction based on the enable and address
  assign I = (E == 1) ? Prog_Mem[Addr] : 12'b0;
endmodule

module MUX1(
  input [7:0] In1, In2,
  input Sel,
  output reg [7:0] Out
);
  // Select input based on the value of Sel
  always @*
    Out = (Sel == 1) ? In1 : In2;
endmodule

module adder(
  input [7:0] In,
  output reg [7:0] Out
);
  always @* begin
    Out = In + 1;
  end
endmodule

module DMem(
  input clk,
  input E,    // Enable port 
  input WE,   // Write enable port
  input [3:0] Addr, // Address port 
  input [7:0] DI,   // Data input port
  output wire [7:0] DO // Data output port
);
  reg [7:0] data_mem [255:0];

  // Write to memory on positive clock edge when both E and WE are asserted
  always @(posedge clk) begin
    if (E == 1 && WE == 1)
      data_mem[Addr] <= DI;
  end 

  // Read from memory based on the enable and address
  assign DO = (E == 1) ? data_mem[Addr] : 8'b0;
endmodule

module ALU(
  input [7:0] Operand1, Operand2,
  input E,
  input [3:0] Mode,
  input [3:0] CFlags,
  output wire [7:0] Out,
  output wire [3:0] Flags
);
  wire Z, S, O;
  reg CarryOut;
  reg [7:0] Out_ALU;

  always @* begin
    case (Mode)
      4'b0000: {CarryOut, Out_ALU} = Operand1 + Operand2;
      4'b0001: begin Out_ALU = Operand1 - Operand2; CarryOut = ~Out_ALU[7]; end
      4'b0010: Out_ALU = Operand1;
      4'b0011: Out_ALU = Operand2;
      4'b0100: Out_ALU = Operand1 & Operand2;
      4'b0101: Out_ALU = Operand1 | Operand2;
      4'b0110: Out_ALU = Operand1 ^ Operand2;
      4'b0111: begin Out_ALU = Operand2 - Operand1; CarryOut = ~Out_ALU[7]; end
      4'b1000: {CarryOut, Out_ALU} = Operand2 + 8'h1;
      4'b1001: begin Out_ALU = Operand2 - 8'h1; CarryOut = ~Out_ALU[7]; end
      4'b1010: Out_ALU = (Operand2 << Operand1[2:0]) | (Operand2 >> Operand1[2:0]);
      4'b1011: Out_ALU = (Operand2 >> Operand1[2:0]) | (Operand2 << Operand1[2:0]);
      4'b1100: Out_ALU = Operand2 << Operand1[2:0];
      4'b1101: Out_ALU = Operand2 >> Operand1[2:0];
      4'b1110: Out_ALU = Operand2 >>> Operand1[2:0];
      4'b1111: begin Out_ALU = 8'h0 - Operand2; CarryOut = ~Out_ALU[7]; end
      default: Out_ALU = Operand2;
    endcase
  end

  assign O = Out_ALU[7] ^ Out_ALU[6];
  assign Z = (Out_ALU == 8'h0) ? 1'b1 : 1'b0;
  assign S = Out_ALU[7];
  assign Flags = {Z, CarryOut, S, O};
  assign Out = Out_ALU;
endmodule


`timescale 1ns / 1ps

module testbench;
    reg clk;
    reg rst_n;
    wire [7:0] bus;
    wire [7:0] A_Dir;
    wire [7:0] B_Dir_ALU;
    wire [7:0] B_Dir_JMP;
    wire [15:0] PC_Dir;
    wire [15:0] PC;
    wire PC_inc;

    wire [3:0] ALU_Ctrl;
    wire [3:0] JMP_Ctrl;
    wire [3:0] MMU_Ctrl;

    wire [7:0] data_ext;
    wire [15:0] addr_ext;
    wire rW;

    wire A_E;
    wire B_E;
    wire A_L;
    wire B_L;
    wire B_L_ALU;
    wire PCH_L;
    wire PCH_E;
    wire PCL_L;
    wire PCL_E;
    
    wire PC_Dir_L;

    reg [7:0] rom [0:15];

    ALU ALU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .A_Dir(A_Dir),
        .B_Dir_ALU(B_Dir_ALU),
        .B_L_ALU(B_L_ALU),
        .ALU_Ctrl(ALU_Ctrl)
    );

    registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .A_E(A_E),
        .B_E(B_E),
        .A_L(A_L),
        .B_L(B_L),
        .B_L_ALU(B_L_ALU),
        .PCH_E(PCH_E),
        .PCH_L(PCH_L),
        .PCL_E(PCL_E),
        .PCL_L(PCL_L),
        .PC_inc(PC_inc),
        .A_Dir(A_Dir),
        .B_Dir_ALU(B_Dir_ALU),
        .B_Dir_JMP(B_Dir_JMP),
        .PC_Dir(PC_Dir),
        .PC_Dir_L(PC_Dir_L),
        .PC_Dir_out(PC)
    );

    PCmover PCmover (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .PC_Dir(PC_Dir),
        .PC_Dir_L(PC_Dir_L),
        .JMP_Ctrl(JMP_Ctrl),
        .B_Dir_JMP(B_Dir_JMP)
    );

    MMU MMU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .MMU_Ctrl(MMU_Ctrl),
        .data_out(data_ext),
        .addr_out(addr_ext),
        .rW(rW),
        .PC(PC)
    );

    CU CU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .PC_inc(PC_inc),
        .ALU_Ctrl(ALU_Ctrl),
        .JMP_Ctrl(JMP_Ctrl),
        .MMU_Ctrl(MMU_Ctrl),
        .A_E(A_E),
        .A_L(A_L),
        .B_E(B_E),
        .B_L(B_L),
        .PCH_E(PCH_E),
        .PCH_L(PCH_L),
        .PCL_E(PCL_E),
        .PCL_L(PCL_L)
    );

    assign data_ext = (rW) ? rom[addr_ext] : 8'bZ;

    always begin
        #10 clk = ~clk; 
        if (!rW) rom[addr_ext] <= data_ext;
    end

    initial begin
        //$readmemh("test_rom.txt", rom);

        clk = 0;
        rst_n = 0;
        
        //$dumpfile("testbench_waveform.vcd");
        //$dumpvars(0, testbench);

        #30 rst_n = 1;
        #1000;

        $finish;
    end

endmodule

//cu.v

module CU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        output reg PC_inc,

        output reg [3:0] ALU_Ctrl,
        output reg [3:0] JMP_Ctrl,
        output reg [3:0] MMU_Ctrl,

        output reg A_E,
        output reg A_L,
        output reg B_E,
        output reg B_L,
        output reg PCH_L,
        output reg PCH_E,
        output reg PCL_L,
        output reg PCL_E
    );

    //0 - instruction load
    //1 - operand load
    //2 - execution
    reg [1:0] status;
    reg halt;
    reg waiting;
    reg operand;

    reg [7:0] instruction;

    reg bus_enable;
    reg [7:0] out;

    assign bus = (bus_enable) ? out : 8'bZ;

    always @(negedge clk) begin
        ALU_Ctrl = 4'd0;
        JMP_Ctrl = 4'd0;
        MMU_Ctrl = 4'd0;

        A_E = 0;
        B_E = 0;
        B_L = 0;
        A_L = 0;

        if (rst_n & !halt) begin
            case (status)
                0 : begin
                    if (!waiting) begin //opcode load
                        PC_inc <= 1;
                        MMU_Ctrl <= 4'b0101;
                        waiting <= 1;
                    end else begin //store opcode in instruction register
                        PC_inc <= 0;
                        instruction <= bus;
                        waiting <= 0;
                        if (bus[5]) begin
                            status <= 2'd1;
                        end else status <= 2'd2;
                    end
                end
                1 : begin
                    if (!operand) begin //first operand
                        if (!waiting) begin //operand load
                            PC_inc <= 1;
                            MMU_Ctrl = 4'b0101;
                            waiting <= 1;
                        end else begin //store operand in MMU//JMP address low
                            PC_inc <= 0;
                            if (instruction[7]) begin
                                JMP_Ctrl <= 4'b0001;
                            end else begin
                                MMU_Ctrl <= 4'b0001;
                            end
                            operand <= 1;
                            waiting <= 0;
                        end
                    end else begin
                        if (!waiting) begin //operand load
                            PC_inc <= 1;
                            MMU_Ctrl <= 4'b0101;
                            waiting <= 1;
                        end else begin //store operand in MMU/JMP address high
                            PC_inc <= 0;
                            if (instruction[7]) begin
                                JMP_Ctrl <= 4'b0010;
                            end else begin
                                MMU_Ctrl <= 4'b0010;
                            end
                            operand <= 0;
                            waiting <= 0;
                            status <= 2'd2;
                        end
                    end
                end
                2 : begin
                    PC_inc <= 0;
                    if (instruction == 8'd0) halt <= 1; //halt
                    case (instruction[7:6])
                        2'b00 : begin //ALU operation
                            if (instruction[5]) begin //memory address
                                MMU_Ctrl <= 4'b0011;
                            end else begin
                                if (!instruction[4]) begin //b register
                                    B_E <= 1;
                                end else begin //PC low
                                    PCL_E <= 1;
                                end
                            end
                            ALU_Ctrl <= instruction[3:0];
                        end
                        2'b01 : begin //register transfer
                            case (instruction[3:0])
                                4'b0001 : begin // A to target
                                    A_E <= 1;
                                    if (instruction[5]) begin //memory address
                                        MMU_Ctrl <= 4'b0100;
                                    end else begin
                                        if (!instruction[4]) begin //b register
                                            B_L <= 1;
                                        end else begin //PC low
                                            PCL_L <= 1;
                                        end
                                    end
                                end
                                4'b0010 : begin // target to A
                                    A_L <= 1;
                                    if (instruction[5]) begin //memory address
                                        MMU_Ctrl <= 4'b0011;
                                    end else begin
                                        if (!instruction[4]) begin //b register
                                            B_E <= 1;
                                        end else begin //PC low
                                            PCL_E <= 1;
                                        end
                                    end
                                end
                                4'b0011 : begin // B to target
                                    B_E <= 1;
                                    if (instruction[5]) begin //memory address
                                        MMU_Ctrl <= 4'b0100;
                                    end else begin
                                        if (!instruction[4]) begin //a register
                                            A_L <= 1;
                                        end else begin //PC low
                                            PCL_L <= 1;
                                        end
                                    end
                                end
                                4'b0100 : begin // target to B
                                    B_L <= 1;
                                    if (instruction[5]) begin //memory address
                                        MMU_Ctrl <= 4'b0011;
                                    end else begin
                                        if (!instruction[4]) begin //a register
                                            A_E <= 1;
                                        end else begin //PC low
                                            PCL_E <= 1;
                                        end
                                    end
                                end
                            endcase
                        end
                        2'b10 : begin //jump
                            JMP_Ctrl <= instruction[3:0];
                        end
                    endcase
                    status <= 2'd0;
                end
            endcase
        end
    end

    always @(posedge rst_n) begin
        status <= 2'd0;
        halt <= 0;
        waiting <= 0;
        operand <= 0;

        instruction <= 8'd0;

        PC_inc <= 1;

        ALU_Ctrl <= 4'd0;
        JMP_Ctrl <= 4'd0;
        MMU_Ctrl <= 4'd0;

        A_E <= 0;
        A_L <= 0;
        B_E <= 0;
        B_L <= 0;
        PCH_L <= 0;
        PCH_E <= 0;
        PCL_L <= 0;
        PCL_E <= 0;

        bus_enable <= 0;
        out <= 8'd0;
    end

endmodule

//mmu.v

module MMU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] MMU_Ctrl,

        inout [7:0] data_out,
        output [15:0] addr_out,
        output rW,

        input [15:0] PC
    );

    reg bus_enable;

    reg read;
    reg write;

    reg [7:0] data_external;
    reg [15:0] addr_external;

    reg [15:0] address;

    assign bus = (bus_enable) ? data_out : 8'bZ;

    assign data_out = (write) ? data_external : 8'bZ;
    assign addr_out = (read || write) ? addr_external : 16'bZ;
    assign rW = read ? 1'b1 : (write ? 1'b0 : 1'bZ);

    always @(posedge clk) begin
        if (rst_n) begin
            if (MMU_Ctrl != 4'b0000) begin
                case (MMU_Ctrl)
                    4'b0001 : address[7:0] <= bus; //load low byte of addr
                    4'b0010 : address[15:8] <= bus; //load high byte of addr
                    4'b0011 : begin //load memory at address buffer onto system bus
                        addr_external <= address; 
                        read <= 1;
                        bus_enable <= 1;
                    end
                    4'b0101 : begin //load memory at program counter onto system bus
                        addr_external <= PC;
                        read <= 1;
                        bus_enable <= 1;
                    end
                endcase
            end else begin
                bus_enable <= 0;
                read <= 0;
            end
        end else bus_enable <= 0;
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (MMU_Ctrl != 4'b0000) begin
                case (MMU_Ctrl)
                    4'b0100 : begin //load system bus into memory at address buffer
                        addr_external <= address;
                        data_external <= bus;
                        write <= 1;
                    end
                endcase
            end else begin
                write <= 0;
            end
        end else bus_enable <= 0;
    end

    always @(posedge rst_n) begin
        bus_enable <= 0;
        read <= 0;
        write <= 0;

        data_external <= 16'd0;
        addr_external <= 16'd0;

        address <= 16'd0;
    end

endmodule

//alu.v

module ALU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] ALU_Ctrl,

        input [7:0] A_Dir,
        output [7:0] B_Dir_ALU,
        output reg B_L_ALU
    );

    reg [7:0] sum;
    reg [7:0] out;

    assign B_Dir_ALU = (B_L_ALU) ? sum : 8'bZ;

    always @(negedge clk) begin
        if (rst_n) begin
            if (ALU_Ctrl != 4'b0000) begin
                case (ALU_Ctrl)
                    4'b0001 : sum = (A_Dir + bus); //self explanatory arithmetic
                    4'b0010 : sum = (A_Dir - bus);
                    4'b0011 : sum = (A_Dir & bus);
                    4'b0100 : sum = (A_Dir | bus);
                    4'b0101 : sum = (A_Dir ^ bus); 

                    4'b0110 : sum = (A_Dir << bus);
                    4'b0111 : sum = (A_Dir >> bus);

                    4'b1000 : sum = (A_Dir == bus);
                    4'b1001 : sum = (A_Dir != bus);
                    4'b1010 : sum = (A_Dir >  bus);
                    4'b1011 : sum = (A_Dir <  bus);
                    4'b1100 : sum = (A_Dir >= bus);
                    4'b1101 : sum = (A_Dir <= bus);
                endcase
                B_L_ALU = 1; 
            end else B_L_ALU = 0;
        end else B_L_ALU = 0;
    end;

    always @(posedge rst_n) begin
        sum <= 8'd0;
        out <= 8'd0;
        B_L_ALU <= 0;
    end 


endmodule

module PCmover (
        input clk,
        input rst_n,

        input [7:0] bus,
        inout [15:0] PC_Dir,
        input [3:0] JMP_Ctrl,
        input [7:0] B_Dir_JMP,

        output PC_Dir_L
    );

    reg active;
    reg [15:0] PC_upd;

    reg [15:0] address;

    assign PC_Dir_L = active;

    assign PC_Dir = (active) ? PC_upd : 16'bZ;

    always @(negedge clk) begin
        if (rst_n) begin
            if (JMP_Ctrl != 4'b0000) begin
                case (JMP_Ctrl)
                    4'b0001 : address[7:0] <= bus; //load low byte of addr
                    4'b0010 : address[15:8] <= bus; //load high byte of addr
                    4'b0011 : PC_upd = address; //jump unconditionally
                    4'b0100 : begin //jump if B != 0
                        if (B_Dir_JMP != 7'd0) begin
                            PC_upd = address;
                            active = 1;
                        end
                    end
                endcase
                active = 1;
            end else active = 0;
        end else active = 0;
    end

    always @(posedge rst_n) begin
        active <= 0;
        PC_upd <= 16'd0;
    end

endmodule

//registers.v

module registers (
        input clk,
        input rst_n, 

        inout [7:0] bus,

        input A_E,
        input B_E,
        input PCH_E,
        input PCL_E,
        input A_L,
        input B_L,
        input B_L_ALU,
        input PCH_L,
        input PCL_L,
        input PC_Dir_L,

        input PC_inc,

        output [7:0] A_Dir,
        input [7:0] B_Dir_ALU,
        output [7:0] B_Dir_JMP,
        input [15:0] PC_Dir,
        output [15:0] PC_Dir_out
    );

    reg [7:0] A;
    reg [7:0] B;

    reg [15:0] PC;

    reg A_L_ready;
    reg B_L_ready;
    reg B_L_ALU_ready;

    assign bus = (A_E) ? A : 
                 (B_E) ? B :
                 (PCL_E) ? PC[7:0] :
                 (PCH_E) ? PC[15:8] : 8'bZ;

    assign A_Dir = A;
    assign B_Dir_JMP = B;

    assign PC_Dir_out = PC;

    always @(negedge clk) begin
        if (rst_n) begin
            A <= (A_L_ready) ? bus : A;
            B <= (B_L_ready) ? bus : (B_L_ALU_ready) ? B_Dir_ALU : B;
            PC[7:0] <= (PCL_L) ? bus : PC[7:0];
            PC[15:8] <= (PCH_L) ? bus : PC[15:8];
            PC <= (PC_Dir_L) ? PC_Dir : PC;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            A_L_ready <= A_L;
            B_L_ready <= B_L;
            B_L_ALU_ready <= B_L_ALU;
            if (PC_inc)
                PC <= PC + 1;
        end else begin
            PC <= 16'd0;
        end
    end

    always @(posedge rst_n) begin
        A <= 8'b0;
        B <= 8'b0;
        PC <= 16'b0;

        A_L_ready <= 0;
        B_L_ready <= 0;
        B_L_ALU_ready <= 0;
    end
endmodule
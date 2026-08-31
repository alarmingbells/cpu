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
        $readmemh("test_rom.txt", rom);

        clk = 0;
        rst_n = 0;
        
        $dumpfile("testbench_waveform.vcd");
        $dumpvars(0, testbench);

        #30 rst_n = 1;
        #1000;

        $finish;
    end

endmodule
`timescale 1ns / 1ps

module testbench;
    reg clk;
    reg rst_n;
    wire [7:0] bus;
    wire [7:0] A_Dir;
    wire [7:0] B_Dir;
    wire [7:0] S_Dir_ALU;
    wire [7:0] S_Dir_JMP;
    wire [15:0] PC_Dir;
    wire [15:0] PC;
    wire [7:0] SP_Dir;
    wire [1:0] SP_action;
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
    wire S_E;
    wire SP_E;
    wire S_L_ALU;

    wire ALU_MMU_wait;
    
    wire PC_Dir_L;

    wire halt;

    reg [7:0] rom [0:65535];

    reg [15:0] cycle;

    ALU ALU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .A_Dir(A_Dir),
        .S_Dir_ALU(S_Dir_ALU),
        .S_L_ALU(S_L_ALU),
        .ALU_Ctrl(ALU_Ctrl),
        .ALU_MMU_wait(ALU_MMU_wait)
    );

    registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .A_E(A_E),
        .B_E(B_E),
        .A_L(A_L),
        .B_L(B_L),
        .S_E(S_E),
        .SP_E(SP_E),
        .S_L_ALU(S_L_ALU),
        .PC_inc(PC_inc),
        .A_Dir(A_Dir),
        .B_Dir(B_Dir),
        .S_Dir_ALU(S_Dir_ALU),
        .S_Dir_JMP(S_Dir_JMP),
        .PC_Dir(PC_Dir),
        .PC_Dir_L(PC_Dir_L),
        .PC_Dir_out(PC),
        .SP_Dir(SP_Dir),
        .SP_action(SP_action)
    );

    PCmover PCmover (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .PC_Dir(PC_Dir),
        .PC_Dir_L(PC_Dir_L),
        .JMP_Ctrl(JMP_Ctrl),
        .S_Dir_JMP(S_Dir_JMP)
    );

    MMU MMU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .B_Dir(B_Dir),
        .MMU_Ctrl(MMU_Ctrl),
        .data_out(data_ext),
        .addr_out(addr_ext),
        .rW(rW),
        .PC(PC),
        .SP_Dir(SP_Dir),
        .SP_action(SP_action)
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
        .S_E(S_E),
        .SP_E(SP_E),
        .halt(halt),
        .ALU_MMU_wait(ALU_MMU_wait)
    );

    assign data_ext = (rW) ? rom[addr_ext] : 8'bZ;

    always begin
        #10 clk = ~clk; 
        if (clk == 1) begin
            cycle = cycle + 1;
            if (!rW) begin
                rom[addr_ext] <= data_ext;
                $display("Cycle #%d: Write to address %x: %x", cycle, addr_ext, data_ext);
            end
            if (cycle >= 10000) begin
                $display("Cycle #%d: Too many cycles, timed out", cycle);
                $finish;
            end
        end
    end

    initial begin
        $readmemh("test_rom.txt", rom);

        clk = 0;
        rst_n = 0;
        cycle = 0;
        
        $dumpfile("testbench_waveform.vcd");
        $dumpvars(0, testbench);

        #30 rst_n = 1;

        wait(halt == 1)

        #20;

        $finish;
    end

endmodule
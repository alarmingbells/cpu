`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst_n;
    wire [7:0] bus;
    wire [7:0] A_Dir;
    wire [7:0] B_Dir;
    wire [15:0] PC_Dir;
    wire [15:0] PC;
    wire PC_inc;

    reg [3:0] ALU_Ctrl;
    reg [3:0] JMP_ctrl;
    reg [3:0] MMU_Ctrl;

    wire [7:0] data_ext;
    wire [15:0] addr_ext;

    reg A_E;
    reg B_E;
    reg A_L;
    reg B_L;
    reg PCH_L;
    reg PCH_E;
    reg PCL_L;
    reg PCL_E;
    
    wire PC_Dir_L;

        reg test_bus;
        reg [7:0] bus_value;

        assign bus = (test_bus) ? bus_value : 8'bZ;

    ALU ALU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .A_Dir(A_Dir),
        .B_Dir(B_Dir),
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
        .PCH_E(PCH_E),
        .PCH_L(PCH_L),
        .PCL_E(PCL_E),
        .PCL_L(PCL_L),
        .PC_inc(PC_inc),
        .A_Dir(A_Dir),
        .B_Dir(B_Dir),
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
        .JMP_ctrl(JMP_ctrl),
        .A_Dir(A_Dir)
    );

    MMU MMU (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .MMU_Ctrl(MMU_Ctrl),
        .data_out(data_ext),
        .addr_out(addr_ext),
        .PC(PC)
    );

    always begin
        #10 clk = ~clk; 
    end

    initial begin
        clk = 0;
        rst_n = 0;

        ALU_Ctrl = 0;
        JMP_ctrl = 0;
        MMU_Ctrl = 0;


        A_E = 0;
        A_L = 0;
        B_E = 0;
        B_L = 0;
        PCH_L = 0;
        PCH_E = 0;
        PCL_E = 0;
        PCL_L = 0;
        
        $dumpfile("testbench_waveform.vcd");
        $dumpvars(0, testbench);

        //dummy test control unit
        #30 rst_n = 1; //reset high
        #20 test_bus = 1; bus_value = 8'd15; //set bus to 15
        #20 MMU_Ctrl = 4'b0001; //load mmu address low
        #20 bus_value = 8'd7;
        #20 MMU_Ctrl = 4'b0010; //load mmu address high
        #20 test_bus = 0;
        #20 MMU_Ctrl = 4'b0011; //mmu load command
        #80

        $finish;
    end

endmodule
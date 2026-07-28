//Simulator
`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst_n;
    wire [7:0] bus;
    reg bus_sending;

    assign bus = (bus_sending) ? 8'd10 : 8'bZ;

    reg A_E;
    reg B_E;
    reg A_L;
    reg B_L;

    registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .bus(bus),
        .A_E(A_E),
        .B_E(B_E),
        .A_L(A_L),
        .B_L(B_L)
    );

    always begin
        #10 clk = ~clk; 
    end

    initial begin
        clk = 0;
        rst_n = 0;
        bus_sending = 0;

        A_E = 0;
        A_L = 0;
        B_E = 0;
        B_L = 0;

        $dumpfile("testbench_waveform.vcd");
        $dumpvars(0, testbench);

        #20 rst_n = 1;

        #10 bus_sending = 1;
        A_L = 1;

        #10 bus_sending = 0;
        A_L = 0;

        #10 A_E = 1;
        B_L = 1;

        #10 A_E = 0;
        B_L = 0;

        #80;

        $finish;
    end

endmodule
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
        output reg S_E,
        output reg SP_E,

        output reg ALU_MMU_wait,

        output reg halt
    );

    //0 - instruction load
    //1 - operand load
    //2 - execution
    reg [1:0] status;
    reg waiting;
    reg write_waiting;
    reg operand;
    reg [7:0] operand_buffer;

    reg [7:0] instruction;

    reg bus_enable;
    reg [7:0] out;

    assign bus = (bus_enable) ? out : 8'bZ;

    always @(negedge clk) begin
        ALU_Ctrl = 4'd0;
        JMP_Ctrl = 4'd0;
        MMU_Ctrl = 4'd0;

        bus_enable = 0;

        A_E = 0;
        B_E = 0;
        S_E = 0;
        B_L = 0;
        A_L = 0;

        ALU_MMU_wait = 0;

        if (rst_n & !halt) begin
            case (status)
                0 : begin
                    if (!waiting) begin //opcode load
                        if (!write_waiting) begin
                            PC_inc <= 1;
                            MMU_Ctrl <= 4'b0110;
                            waiting <= 1;
                        end else write_waiting <= 0;
                    end else begin //store opcode in instruction register
                        PC_inc <= 0;
                        instruction <= bus;
                        waiting <= 0;
                        if (bus[7:6] == 2'b11 || (bus[7:6] == 2'b01 && (bus[3:0] == 4'b0110 || bus[3:0] == 4'b0101))) //no operand instructions
                            status <= 2'd2;
                        else if (bus[5:4] != 2'b00) begin
                            status <= 2'd1;
                        end else status <= 2'd2;
                    end
                end
                1 : begin
                    if (!operand) begin //first operand
                        if (!waiting) begin //operand load
                            PC_inc <= 1;
                            MMU_Ctrl = 4'b0110;
                            waiting <= 1;
                        end else begin //store operand in MMU//JMP address low for memory reads, store result in operand buffer for immediate loads
                            PC_inc <= 0;
                            if (instruction[5:4] == 2'b11) begin
                                operand_buffer <= bus;
                                waiting <= 0;
                                status <= 2'd2;
                            end else begin
                                if (instruction[7]) begin
                                    JMP_Ctrl <= 4'b0001;
                                end else begin
                                    MMU_Ctrl <= 4'b0001;
                                end
                                operand <= 1;
                            end
                            waiting <= 0;
                        end
                    end else begin //second operand
                        if (!waiting) begin //operand load
                            PC_inc <= 1;
                            MMU_Ctrl <= 4'b0110;
                            waiting <= 1;
                        end else begin //store operand in MMU//JMP address low for memory reads, store result in operand buffer for immediate loads
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
                            case (instruction[5:4])
                                2'b00 :  //B register
                                    B_E <= 1;
                                2'b01 : begin //Indexed memory
                                    MMU_Ctrl <= 4'b0111;
                                    ALU_MMU_wait <= 1;
                                end
                                2'b10 : begin //Memory
                                    MMU_Ctrl <= 4'b0011;
                                    ALU_MMU_wait <= 1;
                                end
                                2'b11 : begin //Immediate operand
                                    out <= operand_buffer;
                                    bus_enable <= 1;
                                end
                            endcase
                            ALU_Ctrl <= instruction[3:0];
                        end
                        2'b01 : begin //register transfer
                            case (instruction[3:0])
                                4'b0001 : begin // A to target
                                    A_E <= 1;
                                    case (instruction[5:4])
                                        2'b00 :  //B register
                                            B_L <= 1;
                                        2'b01 : begin //Indexed memory
                                            write_waiting <= 1;
                                            MMU_Ctrl <= 4'b0101;
                                        end
                                        2'b10 : begin //Memory
                                            write_waiting <= 1;
                                            MMU_Ctrl <= 4'b0100;
                                        end
                                        2'b11 : halt <= 1; //Illegal (write to immediate)
                                    endcase
                                end
                                4'b0010 : begin // target to A
                                    A_L <= 1;
                                    case (instruction[5:4])
                                        2'b00 :  //B register
                                            B_E <= 1;
                                        2'b01 : begin //Indexed memory
                                            MMU_Ctrl <= 4'b0111;
                                        end
                                        2'b10 : begin //Memory
                                            MMU_Ctrl <= 4'b0011;
                                        end
                                        2'b11 : begin //Immediate operand
                                            out <= operand_buffer;
                                            bus_enable <= 1;
                                        end
                                    endcase
                                end
                                4'b0011 : begin // B to target
                                    B_E <= 1;
                                    case (instruction[5:4])
                                        2'b00 :  //Illegal (B to B)
                                            halt <= 1;
                                        2'b01 : begin //Indexed memory
                                            write_waiting <= 1;
                                            MMU_Ctrl <= 4'b0101;
                                        end
                                        2'b10 : begin //Memory
                                            write_waiting <= 1;
                                            MMU_Ctrl <= 4'b0100;
                                        end
                                        2'b11 : halt <= 1; //Illegal (write to immediate)
                                    endcase
                                end
                                4'b0100 : begin // target to B
                                    B_L <= 1;
                                    case (instruction[5:4])
                                        2'b00 :  //Illegal (B to B)
                                            halt <= 1;
                                        2'b01 : begin //Indexed memory
                                            MMU_Ctrl <= 4'b0111;
                                        end
                                        2'b10 : begin //Memory
                                            MMU_Ctrl <= 4'b0011;
                                        end
                                        2'b11 : begin //Immediate operand
                                            out <= operand_buffer;
                                            bus_enable <= 1;
                                        end
                                    endcase
                                end
                                4'b0101 : begin //Sum transfer
                                    case (instruction[5:4])
                                        2'b00 : begin //Sum to B
                                            S_E <= 1;
                                            B_L <= 1;
                                        end
                                        2'b01 : begin //Sum to A
                                            S_E <= 1;
                                            A_L <= 1;
                                        end
                                    endcase
                                end
                                4'b0110 : begin //SP transfer
                                    case (instruction[5:4])
                                        2'b00 : begin //SP to B
                                            SP_E <= 1;
                                            B_L <= 1;
                                        end
                                        2'b01 : begin //SP to A
                                            SP_E <= 1;
                                            A_L <= 1;
                                        end
                                    endcase
                                end
                            endcase
                        end
                        2'b10 : begin //jump
                            JMP_Ctrl <= instruction[3:0];
                            write_waiting <= 1;
                        end
                        2'b11 : begin //stack
                            case (instruction[3:0]) 
                                4'b0001 : begin //Push
                                    case (instruction[5:4])
                                        2'b00 : begin //B register
                                            B_E <= 1;
                                            MMU_Ctrl <= 4'b1001;
                                            write_waiting <= 1;
                                        end
                                        2'b01 : begin //A register
                                            A_E <= 1;
                                            MMU_Ctrl <= 4'b1001;
                                            write_waiting <= 1;
                                        end
                                    endcase
                                end
                                4'b0010 : begin //Pop
                                    case (instruction[5:4])
                                        2'b00 : begin //B register
                                            B_L <= 1;
                                            MMU_Ctrl <= 4'b1011;
                                        end
                                        2'b01 : begin //A register
                                            A_L <= 1;
                                            MMU_Ctrl <= 4'b1011;
                                        end
                                        2'b10 : begin //Empty target
                                            MMU_Ctrl <= 4'b1011;
                                        end
                                    endcase
                                end
                            endcase
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
        write_waiting <= 0;
        operand <= 0;
        operand_buffer <= 8'd0;

        instruction <= 8'd0;

        PC_inc <= 1;

        ALU_Ctrl <= 4'd0;
        JMP_Ctrl <= 4'd0;
        MMU_Ctrl <= 4'd0;

        A_E <= 0;
        A_L <= 0;
        B_E <= 0;
        B_L <= 0;
        S_E <= 0;
        SP_E <= 0;

        ALU_MMU_wait <= 0;

        bus_enable <= 0;
        out <= 8'd0;
    end

endmodule

module MMU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] MMU_Ctrl,

        input [7:0] B_Dir,

        inout [7:0] data_out,
        output [15:0] addr_out,
        output rW,

        input [15:0] PC,
        input [7:0] SP_Dir,
        output reg [1:0] SP_action
    );

    reg bus_enable;

    reg read;
    reg write;
    reg indexed;
    reg stack;

    reg write_L;

    reg [7:0] data_external;
    reg [15:0] addr_external;

    reg [15:0] address;

    assign bus = (bus_enable) ? data_out : 8'bZ;

    assign data_out = (write) ? data_external : 8'bZ;
    assign addr_out = (read || write) ? addr_external : 16'bZ;
    assign rW = read ? 1'b1 : (write ? 1'b0 : 1'bZ);

    always @(posedge clk) begin
        SP_action <= 2'd0;
        if (rst_n) begin
            if (MMU_Ctrl != 4'b0000) begin
                case (MMU_Ctrl)
                    4'b0001 : address[7:0] <= bus; //load low byte of addr
                    4'b0010 : address[15:8] <= bus; //load high byte of addr
                    4'b0011 : begin //Standard read
                        addr_external <= address; 
                        read <= 1;
                        bus_enable <= 1;
                    end
                    4'b0111 : begin //Standard indexed read
                        addr_external <= (address + B_Dir);
                        read <= 1;
                        bus_enable <= 1;
                    end
                    4'b0100 : begin //Latch write
                        bus_enable <= 0;
                        read <= 0;
                        write_L <= 1;
                    end
                    4'b0101 : begin //Latch indexed write
                        bus_enable <= 0;
                        read <= 0;
                        indexed <= 1;
                        write_L <= 1;
                    end
                    4'b0110 : begin //Opcode read
                        addr_external <= PC;
                        read <= 1;
                        bus_enable <= 1;
                    end
                    4'b1001 : begin //Latch stack push
                        bus_enable <= 0;
                        read <= 0;
                        stack <= 1;
                        write_L <= 1;
                    end
                    4'b1011 : begin //Stack pop
                        addr_external <= {8'b00000001, (SP_Dir + 8'd1)};
                        read <= 1;
                        bus_enable <= 1;
                        SP_action <= 2'b10;
                    end
                    default : begin
                        bus_enable <= 0;
                        read <= 0;
                        write_L <= 0;
                    end
                endcase
            end else begin
                bus_enable <= 0;
                read <= 0;
                write_L <= 0;
                stack <= 0;
                indexed <= 0;
            end
        end else bus_enable <= 0;
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (write_L) begin //load system bus into memory at address buffer
                if (indexed) begin
                    address = (address + B_Dir);
                end else if (stack) begin
                    address = {8'b00000001, SP_Dir};
                    SP_action = 2'b01;
                end
                addr_external <= address;
                data_external <= bus;
                bus_enable <= 0;
                write <= 1;
            end else begin
                write <= 0;
            end
        end else bus_enable <= 0;
    end

    always @(posedge rst_n) begin
        bus_enable <= 0;
        read <= 0;
        write <= 0;
        indexed <= 0;
        stack <= 0;

        SP_action <= 2'b00;

        data_external <= 16'd0;
        addr_external <= 16'd0;

        address <= 16'd0;
    end

endmodule

module ALU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] ALU_Ctrl,

        input [7:0] A_Dir,

        input ALU_MMU_wait,

        output [7:0] S_Dir_ALU,
        output reg S_L_ALU
    );

    reg [7:0] sum;
    reg [7:0] out;

    reg carry;

    reg [3:0] ALU_Ctrl_L;
    reg [7:0] bus_L;
    reg wait_for_bus;

    assign S_Dir_ALU = (S_L_ALU) ? sum : 8'bZ;

    always @(posedge clk) begin
        if (ALU_Ctrl != 4'b0000) begin 
            ALU_Ctrl_L <= ALU_Ctrl;
            bus_L <= bus;
            wait_for_bus <= ALU_MMU_wait;
        end else begin
            ALU_Ctrl_L <= 0;
            bus_L <= 0;
        end
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (ALU_Ctrl_L != 4'b0000) begin
                if (wait_for_bus) begin
                    bus_L = bus;
                end
                case (ALU_Ctrl_L)
                    4'b0001 : sum = (A_Dir + bus_L); //self explanatory arithmetic
                    4'b0010 : sum = (A_Dir - bus_L);
                    4'b0011 : sum = (A_Dir & bus_L);
                    4'b0100 : sum = (A_Dir | bus_L);
                    4'b0101 : sum = (A_Dir ^ bus_L); 

                    4'b0110 : sum = (A_Dir << bus_L);
                    4'b0111 : sum = (A_Dir >> bus_L);

                    4'b1000 : sum = (A_Dir == bus_L);
                    4'b1001 : sum = (A_Dir != bus_L);
                    4'b1010 : sum = (A_Dir >  bus_L);
                    4'b1011 : sum = (A_Dir <  bus_L);
                    4'b1100 : sum = (A_Dir >= bus_L);
                    4'b1101 : sum = (A_Dir <= bus_L);

                    4'b1110 : carry <= 0;
                    4'b1111 : carry <= 1;
                endcase
                S_L_ALU = 1; 
            end else S_L_ALU = 0;
        end else S_L_ALU = 0;
    end;

    always @(posedge rst_n) begin
        sum <= 8'd0;
        out <= 8'd0;
        carry <= 0;
        S_L_ALU <= 0;

        ALU_Ctrl_L <= 4'd0;
        bus_L <= 8'd0;
    end 


endmodule

module PCmover (
        input clk,
        input rst_n,

        input [7:0] bus,
        inout [15:0] PC_Dir,
        input [3:0] JMP_Ctrl,
        input [7:0] S_Dir_JMP,

        output reg PC_Dir_L
    );

    reg [15:0] PC_upd;

    reg [15:0] address;

    reg [3:0] JMP_Ctrl_L;

    assign PC_Dir = (PC_Dir_L) ? PC_upd : 16'bZ;

    always @(posedge clk) begin
        if (rst_n) begin
            if (JMP_Ctrl != 4'b0000) begin
                case (JMP_Ctrl)
                    4'b0001 : address[7:0] <= bus; //load low byte of addr
                    4'b0010 : address[15:8] <= bus; //load high byte of addr
                endcase
            end
            JMP_Ctrl_L <= JMP_Ctrl;
        end
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (JMP_Ctrl_L != 4'b0000) begin
                case (JMP_Ctrl_L)
                    4'b0011 : begin //jump unconditionally
                        PC_upd <= address;
                        PC_Dir_L <= 1;
                    end
                    4'b0100 : begin //jump if S != 0
                        if (S_Dir_JMP != 7'd0) begin
                            PC_upd = address;
                            PC_Dir_L = 1;
                        end
                    end
                endcase
            end else PC_Dir_L = 0;
        end else PC_Dir_L = 0;
    end

    always @(posedge rst_n) begin
        PC_Dir_L <= 0;
        PC_upd <= 16'd0;

        JMP_Ctrl_L <= 4'd0;

        address <= 16'd0;
    end

endmodule

module registers (
        input clk,
        input rst_n, 

        inout [7:0] bus,

        input A_E,
        input B_E,
        input S_E,
        input A_L,
        input B_L,
        input S_L_ALU,
        input PC_Dir_L,
        input SP_L,
        input SP_E,

        input PC_inc,
        input [1:0] SP_action,

        output [7:0] A_Dir,
        output [7:0] B_Dir,
        input [7:0] S_Dir_ALU,
        output [7:0] S_Dir_JMP,
        input [15:0] PC_Dir,
        output [15:0] PC_Dir_out,
        output [7:0] SP_Dir
    );

    reg [7:0] A;
    reg [7:0] B;
    reg [7:0] S;

    reg [15:0] PC;
    reg [7:0] SP;

    reg A_L_ready;
    reg B_L_ready;
    reg S_L_ready;
    reg PC_Dir_L_ready;

    assign bus = (A_E) ? A : 
                 (B_E) ? B :
                 (S_E) ? S : 
                 (SP_E) ? SP : 8'bZ;

    assign A_Dir = A;
    assign B_Dir = B;
    assign S_Dir_JMP = S;

    assign PC_Dir_out = PC;
    assign SP_Dir = SP;

    always @(negedge clk) begin
        if (rst_n) begin
            A <= (A_L_ready) ? bus : A;
            B <= (B_L_ready) ? bus : B;
            S <= (S_L_ready) ? S_Dir_ALU : S;
            PC <= (PC_Dir_L_ready) ? PC_Dir : PC;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            A_L_ready <= A_L;
            B_L_ready <= B_L;
            S_L_ready <= S_L_ALU;
            PC_Dir_L_ready <= PC_Dir_L;
            if (PC_inc)
                PC <= PC + 1;
            if (SP_action == 2'b01) begin
                SP <= SP - 1;
            end else if (SP_action == 2'b10) begin
                SP <= SP + 1;
            end
        end else begin
            PC <= 16'd0;
        end
    end

    always @(posedge rst_n) begin
        A <= 8'b0;
        B <= 8'b0;
        S <= 8'b0;
        PC <= 16'b0;
        SP <= 8'hFF;

        A_L_ready <= 0;
        B_L_ready <= 0;
        S_L_ready <= 0;
        PC_Dir_L_ready <= 0;
    end
endmodule
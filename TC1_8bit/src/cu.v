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
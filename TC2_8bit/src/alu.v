module ALU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] ALU_Ctrl,

        input [7:0] A_Dir,
        output [7:0] S_Dir_ALU,
        output reg S_L_ALU
    );

    reg [7:0] sum;
    reg [7:0] out;

    reg [3:0] ALU_Ctrl_L;
    reg [7:0] bus_L;

    assign S_Dir_ALU = (S_L_ALU) ? sum : 8'bZ;

    always @(posedge clk) begin
        if (ALU_Ctrl != 4'b0000) begin 
            ALU_Ctrl_L <= ALU_Ctrl;
            bus_L <= bus;
        end else begin
            ALU_Ctrl_L <= 0;
            bus_L <= 0;
        end
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (ALU_Ctrl_L != 4'b0000) begin
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
                endcase
                S_L_ALU = 1; 
            end else S_L_ALU = 0;
        end else S_L_ALU = 0;
    end;

    always @(posedge rst_n) begin
        sum <= 8'd0;
        out <= 8'd0;
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
                    4'b0011 : PC_upd <= address; //jump unconditionally
                    4'b0100 : begin //jump if S != 0
                        if (S_Dir_JMP != 7'd0) begin
                            PC_upd = address;
                            PC_Dir_L = 1;
                        end
                    end
                endcase
                PC_Dir_L = 1;
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
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
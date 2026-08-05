module ALU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] ALU_Ctrl,
        input ALU_regselect,

        input [7:0] A_Dir,
        input [7:0] B_Dir
    );

    reg [7:0] sum;
    reg [7:0] out;
    reg active;

    assign bus = (active) ? out : 8'bZ;

    always @(posedge clk) out <= sum;

    always @(negedge clk) begin
        if (rst_n) begin
            if (ALU_Ctrl != 4'b0000) begin
                active = 1; 
                case (ALU_Ctrl)
                    4'b0001 : sum = (A_Dir + bus);
                    4'b0010 : sum = (A_Dir - bus);
                    4'b0011 : sum = (A_Dir & bus);
                    4'b0100 : sum = (A_Dir | bus);
                    4'b0101 : sum = (A_Dir ^ bus); 

                    4'b0110 : sum = (A_Dir << bus);
                    4'b0111 : sum = (A_Dir >> bus);

                    4'b1000 : sum = (8'd1) ? (A_Dir == bus) : 8'd0;
                    4'b1001 : sum = (8'b0) ? (A_Dir == bus) : 8'd1;
                    4'b1010 : sum = (8'b1) ? (A_Dir > bus) : 8'd0;
                    4'b1011 : sum = (8'b1) ? (A_Dir < bus) : 8'd0;
                    4'b1100 : sum = (8'b1) ? (A_Dir >= bus) : 8'd0;
                    4'b1101 : sum = (8'b1) ? (A_Dir <= bus) : 8'd0;
                endcase
            end else active = 0;
        end else active = 0;
    end;

    always @(posedge rst_n) begin
        sum <= 8'd0;
        out <= 8'd0;
        active <= 0;
    end 


endmodule

module PCmover (
        input clk,
        input rst_n,

        input [7:0] bus,
        inout [15:0] PC_Dir,
        input [3:0] JMP_ctrl,
        input [7:0] A_Dir,

        output PC_Dir_L
    );

    reg active;
    reg [15:0] PC_upd;

    assign PC_Dir_L = active;

    assign PC_Dir = (active) ? PC_upd : 16'bZ;

    always @(negedge clk) begin
        if (rst_n) begin
            if (JMP_ctrl != 4'b0000) begin
                active = 1;
                case (JMP_ctrl)
                    4'b0001 : begin
                        PC_upd = bus;
                        active = 1;
                    end
                    4'b0010 : begin
                        if (A_Dir != 7'd0) begin
                            PC_upd = bus;
                            active = 1;
                        end
                    end
                endcase
            end else active = 0;
        end else active = 0;
    end

    always @(posedge rst_n) begin
        active <= 0;
        PC_upd <= 16'd0;
    end

endmodule
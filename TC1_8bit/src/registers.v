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
        input PCH_L,
        input PCL_L,
        input PC_Dir_L,

        input PC_inc,

        output [7:0] A_Dir,
        output [7:0] B_Dir,
        input [15:0] PC_Dir,
        output [15:0] PC_Dir_out
    );

    reg [7:0] A;
    reg [7:0] B;

    reg [15:0] PC;

    assign bus = (A_E) ? A : 
                 (B_E) ? B :
                 (PCL_E) ? PC[7:0] :
                 (PCH_E) ? PC[15:8] : 8'bZ;

    assign A_Dir = A;
    assign B_Dir = B; 

    assign PC_Dir_out = PC;

    always @(negedge clk) begin
        if (rst_n) begin
            A <= (A_L) ? bus : A;
            B <= (B_L) ? bus : B;
            PC[7:0] <= (PCL_L) ? bus : PC[7:0];
            PC[15:8] <= (PCH_L) ? bus : PC[15:8];
            PC <= (PC_Dir_L) ? PC_Dir : PC;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
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
    end
endmodule
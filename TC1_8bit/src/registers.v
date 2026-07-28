module registers (
        input clk,
        input rst_n, 

        inout [7:0] bus,

        input A_E,
        input B_E,
        input A_L,
        input B_L
    );

    assign bus = (A_E) ? A : 
                 (B_E) ? B : 8'bZ;

    reg [0:7] A;
    reg [0:7] B;

    always @(posedge A_L) begin
        A <= bus;
    end

    always @(posedge B_L) begin
        B <= bus;
    end

    always @(posedge rst_n) begin
        A <= 8'b0;
        B <= 8'b0;
    end
    

endmodule
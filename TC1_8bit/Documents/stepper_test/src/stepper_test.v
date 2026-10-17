module top(
        input clk,
        input rst_n,

        input raise,
        input lower,

        output [3:0] step
    );

    stepper stepper(
        .clk(clk),
        .rst_n(rst_n),
        .raise(raise),
        .lower(lower),
        .step(step)
    );

endmodule

module stepper(
        input clk,
        input rst_n,

        input raise,
        input lower,

        output reg [3:0] step
    );

    reg [15:0] divider;
    reg stepClk;

    always @(posedge stepClk) begin
        if (rst_n) begin
            if (raise) begin
                case (step)
                    4'b0001: step <= 4'b0010;
                    4'b0010: step <= 4'b0100;
                    4'b0100: step <= 4'b1000;
                    4'b1000: step <= 4'b0001;
                    default: step <= 4'b0001;
                endcase
            end
            if (lower) begin
                case (step)
                    4'b0001: step <= 4'b1000;
                    4'b0010: step <= 4'b0001;
                    4'b0100: step <= 4'b0010;
                    4'b1000: step <= 4'b0100;
                    default: step <= 4'b0001;
                endcase
            end
        end else begin
            step <= 4'd0;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            divider <= divider + 16'd1;
            if (divider > 16'd44999) begin
                stepClk = ~stepClk;
            end
        end else begin
            divider <= 16'd0;
            stepClk <= 0;
        end
    end

endmodule
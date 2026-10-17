module stepper(
        input [7:0] WL_target;
        input [7:0] DWL_target;
        input [7:0] SP_target;
        input [7:0] SC_difference;

        input clk;
        input rst_n;
    );

    reg [7:0] homing;

    reg stpClk;
    reg [16:0] divider;

    reg [7:0] WL;
    reg [3:0] WL_step;
    reg [3:0] WL_stepcount;

    reg [7:0] DWL;
    reg [3:0] DWL_step;
    reg [3:0] DWL_stepcount;

    reg [7:0] SP;
    reg [3:0] SP_step;
    reg [3:0] SP_stepcount;

    always @(posedge stpClk) begin
        if (WL_target > WL || homing > 8'd0) begin
            case (WL_step)
                4'b0001: WL_step <= 4'b0010;
                4'b0010: WL_step <= 4'b0100;
                4'b0100: WL_step <= 4'b1000;
                4'b1000: WL_step <= 4'b0001;
                default: WL_step <= 4'b0001;
            endcase
            WL_stepcount <= WL_stepcount + 4'd1;
            if (WL_stepcount  > 4'd9) begin
                WL_stepcount <= 0;
                WL <= WL + 8'd1;
                if (homing > 8'd0) homing <= homing - 8'd1;
            end
        end else if (WL_target < WL) begin
            case (WL_step)
                4'b0001: WL_step <= 4'b0010;
                4'b0010: WL_step <= 4'b0100;
                4'b0100: WL_step <= 4'b1000;
                4'b1000: WL_step <= 4'b0001;
                default: WL_step <= 4'b0001;
            endcase
            WL_stepcount <= WL_stepcount + 4'd1;
            if (WL_stepcount  > 4'd9) begin
                WL_stepcount <= 0;
                WL <= WL + 8'd1;
            end
        end

        if (DWL_target > DWL || homing > 8'd0) begin
            case (DWL_step)
                4'b0001: DWL_step <= 4'b0010;
                4'b0010: DWL_step <= 4'b0100;
                4'b0100: DWL_step <= 4'b1000;
                4'b1000: DWL_step <= 4'b0001;
                default: DWL_step <= 4'b0001;
            endcase
            DWL_stepcount <= DWL_stepcount + 4'd1;
            if (DWL_stepcount  > 4'd9) begin
                DWL_stepcount <= 0;
                DWL <= DWL + 8'd1;
                if (homing > 8'd0) homing <= homing - 8'd1;
            end
        end else if (DWL_target < DWL) begin
            case (DWL_step)
                4'b0001: DWL_step <= 4'b0010;
                4'b0010: DWL_step <= 4'b0100;
                4'b0100: DWL_step <= 4'b1000;
                4'b1000: DWL_step <= 4'b0001;
                default: DWL_step <= 4'b0001;
            endcase
            DWL_stepcount <= DWL_stepcount + 4'd1;
            if (DWL_stepcount  > 4'd9) begin
                DWL_stepcount <= 0;
                DWL <= DWL + 8'd1;
            end
        end

        if (SP_target > SP || homing > 8'd0) begin
            case (SP_step)
                4'b0001: SP_step <= 4'b0010;
                4'b0010: SP_step <= 4'b0100;
                4'b0100: SP_step <= 4'b1000;
                4'b1000: SP_step <= 4'b0001;
                default: SP_step <= 4'b0001;
            endcase
            SP_stepcount <= SP_stepcount + 4'd1;
            if (SP_stepcount  > 4'd9) begin
                SP_stepcount <= 0;
                SP <= SP + 8'd1;
                if (homing > 8'd0) homing <= homing - 8'd1;
            end
        end else if (SP_target < SP) begin
            case (SP_step)
                4'b0001: SP_step <= 4'b0010;
                4'b0010: SP_step <= 4'b0100;
                4'b0100: SP_step <= 4'b1000;
                4'b1000: SP_step <= 4'b0001;
                default: SP_step <= 4'b0001;
            endcase
            SP_stepcount <= SP_stepcount + 4'd1;
            if (SP_stepcount  > 4'd9) begin
                SP_stepcount <= 0;
                SP <= SP + 8'd1;
            end
        end

    end

    always @(posedge clk) begin
        divider = divider + 17'd1;
        if (divider > 17'44999) begin
            stpClk <= ~stpClk;
            divider <= 17'd0;
        end
    end
    
    always @(posedge rst_n) begin
        stpClk <= 0;
        divider <= 17'd0;

        WL <= 8'd0;
        WL_step <= 4'd0;
        WL_stepcount <= 4'd0;

        homing <= 8'hFF;
    end

endmodule
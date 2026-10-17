module channel(
        input active,
        input clk,
        input rst_n,

        output reg [7:0] out
    );

    reg [7:0] mem [0:3999];
    reg [12:0] sampleCounter;

    reg [11:0] divider;
    reg sampleClk;

    always @(posedge sampleClk) begin
        sampleCounter = sampleCounter + 1;
        out = mem[sampleCounter];
        if (sampleCounter > 13'd SAMPLE COUNT HERE)
            sampleCounter = 0;
    end

    always @(posedge clk) begin
        divider = divider + 12'd1;
        if (divider > 4'd1687) begin
            sampleClk <= ~sampleClk;
            divider <= 12'd0;
        end
    end

    always @(posedge rst_n) begin
        divider <= 12'd0;
        sampleClk <= 0;
        sampleCounter <= 13'd0;
    end
endmodule
module MMU (
        input clk,
        input rst_n,

        input [3:0] MMU_Ctrl;

        inout data_out;
        output addr_out;

        input [15:0] PC;

        inout [7:0] bus;
    );

    reg active_internal;

    reg read;
    reg write;

    reg [7:0] out;

    reg [7:0] data_external;
    reg [15:0] addr_external;

    reg [15:0] address;

    assign bus = (active_internal) ? out : 8'bZ;

    assign data_out = (write) ? data_external : Z;
    assign addr_out = (read || write) ? addr_external : Z;

    always @(posedge clk) begin
        if (MMU_Ctrl != 4'b0000) begin
            case (MMU_Ctrl)
                4'b0011 : begin //load memory at address buffer onto system bus
                    addr_external <= address; 
                    out <= data_out;
                    read <= 1;
                    active_internal <= 1;
                end
                4'b0101 : begin //load memory at program counter onto system bus
                    addr_external <= PC;
                    out <= data_out;
                    read <= 1;
                    active_internal <= 1;
            endcase
        end else begin
            active_internal <= 0;
            read <= 0;
        end
    end

    always @(negedge clk) begin
        if (MMU_Ctrl != 4'b0000) begin
            case (MMU_Ctrl)
                4'b0001 : address[7:0] <= bus; //load low byte of addr
                4'b0010 : address[15:8] < bus; //load high byte of addr
                4'b0100 : begin //load system bus into memory at address buffer
                    addr_external <= addrress;
                    data_external <= bus;
                    write <= 1;
                end
            endcase
        end else begin
            active_internal <= 0;
            write <= 0;
        end
    end

    always @(posedge rst_n) begin
        active_internal <= 0;
        read <= 0;
        write <= 0;

        out <= 8'd0;

        data_external <= 16'd0;
        addr_external <= 16'd0;

        address <= 16'd0;
    end

endmodule
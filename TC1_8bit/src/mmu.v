module MMU (
        input clk,
        input rst_n,

        inout [7:0] bus,

        input [3:0] MMU_Ctrl,

        inout [7:0] data_out,
        output [15:0] addr_out,
        output rW,

        input [15:0] PC
    );

    reg bus_enable;

    reg read;
    reg write;

    reg write_L;

    reg [7:0] data_external;
    reg [15:0] addr_external;

    reg [15:0] address;

    assign bus = (bus_enable) ? data_out : 8'bZ;

    assign data_out = (write) ? data_external : 8'bZ;
    assign addr_out = (read || write) ? addr_external : 16'bZ;
    assign rW = read ? 1'b1 : (write ? 1'b0 : 1'bZ);

    always @(posedge clk) begin
        if (rst_n) begin
            if (MMU_Ctrl != 4'b0000) begin
                case (MMU_Ctrl)
                    4'b0001 : address[7:0] <= bus; //load low byte of addr
                    4'b0010 : address[15:8] <= bus; //load high byte of addr
                    4'b0011 : begin //load memory at address buffer onto system bus
                        addr_external <= address; 
                        read <= 1;
                        bus_enable <= 1;
                    end
                    4'b0101 : begin //load memory at program counter onto system bus
                        addr_external <= PC;
                        read <= 1;
                        bus_enable <= 1;
                    end
                    4'b0100 : begin 
                        bus_enable <= 0;
                        read <= 0;
                        write_L <= 1;
                    end
                    default : begin 
                        bus_enable <= 0;
                        read <= 0;
                        write_L <= 0;
                    end
                endcase
            end else begin
                bus_enable <= 0;
                read <= 0;
                write_L <= 0;
            end
        end else bus_enable <= 0;
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (write_L) begin //load system bus into memory at address buffer
                addr_external <= address;
                data_external <= bus;
                bus_enable <= 0;
                write <= 1;
            end else begin
                write <= 0;
            end
        end else bus_enable <= 0;
    end

    always @(posedge rst_n) begin
        bus_enable <= 0;
        read <= 0;
        write <= 0;

        data_external <= 16'd0;
        addr_external <= 16'd0;

        address <= 16'd0;
    end

endmodule
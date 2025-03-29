`timescale 1ns / 1ps


module frameBuffer (
    // write side
    input  logic        wclk,
    input  logic        we,
    input  logic [16:0] wAddr,
    input  logic [11:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr,
    output logic [11:0] rData
);
    logic [11:0] mem[0:(320*240-1)];

    always_ff @(posedge wclk) begin
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    always_ff @(posedge rclk) begin
        if (oe) begin
            rData <= mem[rAddr];
        end else begin
            rData <= 0;
        end
    end

endmodule

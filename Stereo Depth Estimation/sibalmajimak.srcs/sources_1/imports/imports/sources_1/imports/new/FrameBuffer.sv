
`timescale 1ns / 1ps


module frameBuffer (
    // write side
    input  logic        wclk,
    input  logic        we,
    input  logic [14:0] wAddr,
    input  logic [15:0] wData,
    // read side for VGA
    input  logic        rclk,
    input  logic        oe,
    input  logic [14:0] rAddr,
    output logic [15:0] rData,
    
    output logic lineFlag
    // read side for SAD
    // input logic clk,
    // output logic [15:0] rData_for_SAD[2:0][2:0]
);
    logic [15:0] mem[0:160*120-1];

    always_ff @(posedge wclk) begin
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    always_ff @(posedge rclk) begin
        if (oe) begin
            rData <= mem[rAddr];
            lineFlag = 1;
        end else begin
            rData <= 0;
            lineFlag = 0;
        end
    end


endmodule

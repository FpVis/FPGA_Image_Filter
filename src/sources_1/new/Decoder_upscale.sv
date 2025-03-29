`timescale 1ns / 1ps

module Decoder_upscale (
    // input  logic        module_en,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    input  logic        btnU,
    input  logic        btnL,
    input  logic        btnR,
    input  logic        btnD,
    input  logic        center_SW,
    input  logic        control_SW,
    output logic        qvga_en,
    output logic [16:0] qvga_addr
);
    logic [9:0] x_start, y_start;
    logic [9:0] x_scaled, y_scaled;

    assign x_scaled = x[9:1] + x_start; // x 좌표를 절반으로 축소 후 시작점 더함
    assign y_scaled = y[9:1] + y_start; // y 좌표를 절반으로 축소 후 시작점 더함

    // 사분면 제어
    always_comb begin
        // 기본값 설정
        x_start = 0;
        y_start = 0;
        if (btnL) begin
            x_start = 0;  // 왼쪽 상단
            y_start = 0;
        end else if (btnU) begin
            x_start = 321;  // 오른쪽 상단
            y_start = 0;
        end else if (btnR) begin
            x_start = 321;  // 오른쪽 하단
            y_start = 241;
        end else if (btnD) begin
            x_start = 0;  // 왼쪽 하단
            y_start = 241;
        end else if (center_SW) begin
            x_start = 160;
            y_start = 120;
        end else begin
            x_start = 0;
            y_start = 0;
        end
    end

    always_comb begin
        // if (module_en) begin
        if (x < 640 && y < 480) begin
            if ((btnU || btnL || btnR || btnD || center_SW) & (control_SW)) begin
                qvga_addr = y_scaled[9:1] * 320 + x_scaled[9:1];
                qvga_en   = 1'b1;
            end else begin
                qvga_addr = y[9:1] * 320 + x[9:1];
                qvga_en   = 1'b1;
            end
        end else begin
            qvga_addr = 0;
            qvga_en   = 1'b0;
        end
    end
    // end
endmodule

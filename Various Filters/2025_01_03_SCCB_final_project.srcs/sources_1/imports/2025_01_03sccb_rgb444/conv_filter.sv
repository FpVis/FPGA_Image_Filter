`timescale 1ns / 1ps


module conv_filter (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] gray_in,
    input  logic [7:0] threshold,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       disp_enable,
    output logic [7:0] sobel_out,
    output logic [7:0] gaussian_out,
    output logic [7:0] average_out,
    output logic [7:0] laplacian_out
);
    localparam IMG_WIDTH = 640;

    logic [5:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [5:0] line_buffer_2[0:IMG_WIDTH-1];
    
    logic [7:0] p11, p12, p13;
    logic [7:0] p21, p22, p23;
    logic [7:0] p31, p32, p33;

    logic [2:0] valid_pipeline;
    logic [9:0] x_pipeline[0:2];
    logic [9:0] y_pipeline[0:2];

    logic signed [10:0] gx_sobel, gy_sobel;
    logic [10:0] mag_sobel;
    logic [7:0] laplacian;
    logic [12:0] mag_gaussian;
    logic [15:0] mag_average;
    logic signed [10:0] mag_laplacian;
    assign average_out = mag_average[7:0];
    assign gaussian_out = mag_gaussian[7:0];
    assign laplacian = (mag_laplacian < 0) ? 0 : mag_laplacian[7:0];
    assign laplacian_out = (laplacian > threshold) ? 8'hff : 8'h00;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
            end
        end else if (disp_enable) begin
            line_buffer_2[x_pixel] <= line_buffer_1[x_pixel];
            line_buffer_1[x_pixel] <= gray_in[7:2];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (disp_enable) begin
            
            p13           <= line_buffer_2[x_pixel] << 2;
            p12           <= p13;
            p11           <= p12;

            p23           <= line_buffer_1[x_pixel] << 2;
            p22           <= p23;
            p21           <= p22;

            p33           <= {gray_in[7:2], 2'b0};
            p32           <= p33;
            p31           <= p32;

            x_pipeline[0] <= x_pixel;
            y_pipeline[0] <= y_pixel;
            for (i = 1; i < 3; i = i + 1) begin
                x_pipeline[i] <= x_pipeline[i-1];
                y_pipeline[i] <= y_pipeline[i-1];
            end

            valid_pipeline <= {
                valid_pipeline[1:0], (x_pixel >= 2 && y_pixel >= 2)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            gx_sobel      <= 0;
            gy_sobel      <= 0;
            mag_sobel     <= 0;
            mag_gaussian  <= 0;
            mag_average   <= 0;
            sobel_out     <= 0;
            mag_laplacian <= 0;
        end else if (valid_pipeline[1]) begin
            // 소벨 필터
            gx_sobel <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
            gy_sobel <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
            mag_sobel <= (gx_sobel[10] ? (~gx_sobel + 1) : gx_sobel) +
                     (gy_sobel[10] ? (~gy_sobel + 1) : gy_sobel);
            sobel_out <= (mag_sobel > threshold) ? 8'hFF : 8'h00;

            // 가우시안 필터
            mag_gaussian <= (p11 + (p12 << 1) + p13 +
                         (p21 << 1) + (p22 << 2) + (p23 << 1) +
                         p31 + (p32 << 1) + p33) >> 4;

            // 평균 필터
            mag_average <= (p11 + p12 + p13 + p21 + p22 + p23 + p31 + p32 + p33) / 9;
            //라플라시안
            mag_laplacian <= (p12 + p21 + p23 + p32) - (p22 << 2);

        end else begin
            sobel_out <= 0;
        end
    end


endmodule

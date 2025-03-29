
`timescale 1ns / 1ps


module conv_filter_5x5 (
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

    logic [3:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_2[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_3[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_4[0:IMG_WIDTH-1];

    logic [7:0] p11, p12, p13, p14, p15;
    logic [7:0] p21, p22, p23, p24, p25;
    logic [7:0] p31, p32, p33, p34, p35;
    logic [7:0] p41, p42, p43, p44, p45;
    logic [7:0] p51, p52, p53, p54, p55;

    logic [2:0] valid_pipeline;
    logic [9:0] x_pipeline[0:4];
    logic [9:0] y_pipeline[0:4];

    logic signed [15:0] gx_sobel, gy_sobel;
    logic [15:0] mag_sobel;
    logic [7:0] laplacian;
    logic [15:0] mag_gaussian;
    logic [15:0] mag_average;
    logic signed [15:0] mag_laplacian;
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
                line_buffer_3[i] <= 0;
                line_buffer_4[i] <= 0;
            end
        end else if (disp_enable) begin
            line_buffer_4[x_pixel] <= line_buffer_3[x_pixel];
            line_buffer_3[x_pixel] <= line_buffer_2[x_pixel];
            line_buffer_2[x_pixel] <= line_buffer_1[x_pixel];
            line_buffer_1[x_pixel] <= gray_in[7:4];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            {p11, p12, p13, p14, p15} <= 0;
            {p21, p22, p23, p24, p25} <= 0;
            {p31, p32, p33, p34, p35} <= 0;
            {p41, p42, p43, p44, p45} <= 0;
            {p51, p52, p53, p54, p55} <= 0;
            valid_pipeline <= 0;
        end else if (disp_enable) begin

            p15           <= line_buffer_4[x_pixel] << 4;
            p14           <= p15;
            p13           <= p14;
            p12           <= p13;
            p11           <= p12;

            p25           <= line_buffer_3[x_pixel] << 4;
            p24           <= p25;
            p23           <= p24;
            p22           <= p23;
            p21           <= p22;

            p35           <= line_buffer_2[x_pixel] << 4;
            p34           <= p35;
            p33           <= p34;
            p32           <= p33;
            p31           <= p32;

            p45           <= line_buffer_1[x_pixel] << 4;
            p44           <= p45;
            p43           <= p44;
            p42           <= p43;
            p41           <= p42;

            p55           <= {gray_in[7:4], 4'b0};
            p54           <= p55;
            p53           <= p54;
            p52           <= p53;
            p51           <= p52;

            x_pipeline[0] <= x_pixel;
            y_pipeline[0] <= y_pixel;
            for (i = 1; i < 5; i = i + 1) begin
                x_pipeline[i] <= x_pipeline[i-1];
                y_pipeline[i] <= y_pipeline[i-1];
            end

            valid_pipeline <= {
                valid_pipeline[1:0], (x_pixel >= 4 && y_pixel >= 4)
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
            gx_sobel <=
            // Row 1
            (-p11 - (p12 << 1) + (p14 << 1) + p15) +
            // Row 2
            (-(p21 << 2) - (p22 << 3) + (p24 << 3) + (p25 << 2)) +
            // Row 3
            (-(p31 * 6) - (p32 * 12) + (p34 * 12) + (p35 * 6)) +
            // Row 4
            (-(p41 << 2) - (p42 << 3) + (p44 << 3) + (p45 << 2)) +
            // Row 5
            (-p51 - (p52 << 1) + (p54 << 1) + p55);

            gy_sobel <=
            // Row 1: -1, -4, -6, -4, -1
            (-p11 + -(p12 << 2) + -(p13 * 6) + -(p14 << 2) + -p15)
            // Row 2: -2, -8, -12, -8, -2
            + ( -(p21 << 1)+ -(p22 << 3)+ -(p23 * 12)+ -(p24 << 3)+ -(p25 << 1) )
            // Row 4: +2, +8, +12, +8, +2
            + ((p41 << 1) + (p42 << 3) + (p43 * 12) + (p44 << 3) + (p45 << 1))
            // Row 5: +1, +4, +6, +4, +1
            + (p51 + (p52 << 2) + (p53 * 6) + (p54 << 2) + p55);

            // gx_sobel <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
            // gy_sobel <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
            mag_sobel <= (gx_sobel[15] ? (~gx_sobel + 1) : gx_sobel) +
                     (gy_sobel[15] ? (~gy_sobel + 1) : gy_sobel);
            sobel_out <= (mag_sobel[12:5] > threshold) ? 8'hFF : 8'h00;

            // 가우시안 필터
            // mag_gaussian <= (p11 + (p12 << 1) + p13 +
            //              (p21 << 1) + (p22 << 2) + (p23 << 1) +
            //              p31 + (p32 << 1) + p33) >> 4;
            // mag_gaussian<= (
            // p11 + (p12 << 1) + (p13 << 2) + (p14 << 1) + p15 +  // 1st row
            // (p21 << 1) + (p22 << 2) + (p23 << 3) + (p24 << 2) + (p25 << 1) +  // 2nd row
            // (p31 << 2) + (p32 << 3) + (p33 << 4) + (p34 << 3) + (p35 << 2) +  // 3rd row
            // (p41 << 1) + (p42 << 2) + (p43 << 3) + (p44 << 2) + (p45 << 1) +  // 4th row
            // p51 + (p52 << 1) + (p53 << 2) + (p54 << 1) + p55  // 5th row
            // ) / 100;  // 256으로 나누기 (정규화)
            mag_gaussian<= (
            p11 + (p12 << 2) + (p13 * 6) + (p14 << 2) + p15 +  // 1st row
            (p21 << 2) + (p22 << 4) + (p23 *24) + (p24 << 4) + (p25 << 2) +  // 2nd row
            (p31 * 6) + (p32 *24) + (p33 *36) + (p34 *24) + (p35 *6) +  // 3rd row
            (p41 << 2) + (p42 << 4) + (p43 *24) + (p44 << 4) + (p45 << 2) +  // 2nd row
            p51 + (p52 << 2) + (p53 * 6) + (p54 << 2) + p55  // 1st row
            ) >> 8;  // 256으로 나누기 (정규화)
            // 평균 필터
            mag_average <= (p11 + p12 + p13 + p14+p15+
            p21 + p22 + p23 + p24 + p25+
            p31 + p32 + p33 + p34 + p35+
            p41 + p42 + p43 + p44 + p45+
            p51 + p52 + p53 + p54 + p55)/25;
            //라플라시안
            // mag_laplacian <= (p11 + p12 + p13 +  p21 + p23 + p31 + p32 + p33) - (p22 << 3);
            mag_laplacian <= (-(p13)) + (-(p22) - (p23 << 1) - p24) 
                         + (-(p31) - (p32 << 1) + (p33 << 4) - (p34 << 1) - p35)
                         + (-(p42) - (p43 << 1) - p44) + (-(p53));
        end else begin
            mag_gaussian <= gray_in;
            mag_laplacian <= 0;
            mag_average <= 0;
            sobel_out <= 0;
        end
    end


endmodule

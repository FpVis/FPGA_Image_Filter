`timescale 1ns / 1ps

module vga_switch_data (
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    input  logic       disp_enable,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    assign red_port   = disp_enable ? sw_red : 0;
    assign green_port = disp_enable ? sw_green : 0;
    assign blue_port  = disp_enable ? sw_blue : 0;
endmodule

module colorbar (
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       disp_enable,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic [3:0] red_data, green_data, blue_data;

    assign red_port   = disp_enable ? red_data : 0;
    assign green_port = disp_enable ? green_data : 0;
    assign blue_port  = disp_enable ? blue_data : 0;

    always @(*) begin
        if((x_pixel >=0 && x_pixel <= 91)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b1000;
            green_data = 4'b1000;
            blue_data  = 4'b1000;
        end else if((x_pixel >=92 && x_pixel <= 182)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b1111;
            green_data = 4'b1111;
            blue_data  = 4'b0000;
        end else if((x_pixel >=183 && x_pixel <= 274)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b0000;
            green_data = 4'b1111;
            blue_data  = 4'b1111;
        end else if((x_pixel >=275 && x_pixel <= 366)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b0000;
            green_data = 4'b1111;
            blue_data  = 4'b0000;
        end else if((x_pixel >=367 && x_pixel <= 458)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b1111;
            green_data = 4'b0000;
            blue_data  = 4'b1111;
        end else if((x_pixel >=459 && x_pixel <= 550)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b1111;
            green_data = 4'b0000;
            blue_data  = 4'b0000;
        end else if((x_pixel >=551 && x_pixel <= 640)&& (y_pixel >= 0 && y_pixel <= 300))begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b1111;
        end else if((x_pixel >=0 && x_pixel <= 91)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b1111;
        end else if((x_pixel >=92 && x_pixel <= 182)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b0000;
        end else if((x_pixel >=183 && x_pixel <= 274)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b1111;
            green_data = 4'b0000;
            blue_data  = 4'b1111;
        end else if((x_pixel >=275 && x_pixel <= 366)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b0000;
        end else if((x_pixel >=367 && x_pixel <= 458)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b0000;
            green_data = 4'b1111;
            blue_data  = 4'b1111;
        end else if((x_pixel >=459 && x_pixel <= 550)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b000;
            green_data = 4'b0000;
            blue_data  = 4'b0000;
        end else if((x_pixel >=551 && x_pixel <= 640)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b1000;
            green_data = 4'b1000;
            blue_data  = 4'b1000;
        end else if((x_pixel >=0 && x_pixel <= 110)&& (y_pixel >= 301 && y_pixel <= 341))begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b0011;
        end else if((x_pixel >=111 && x_pixel <= 222)&& (y_pixel >= 342 && y_pixel <= 480))begin
            red_data   = 4'b1111;
            green_data = 4'b1111;
            blue_data  = 4'b1111;
        end else if((x_pixel >=223 && x_pixel <= 333)&& (y_pixel >= 342 && y_pixel <= 480))begin
            red_data   = 4'b0110;
            green_data = 4'b0000;
            blue_data  = 4'b0111;
        end else if((x_pixel >=334 && x_pixel <= 640)&& (y_pixel >= 342 && y_pixel <= 480))begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b0000;
        end else begin
            red_data   = 4'b0000;
            green_data = 4'b0000;
            blue_data  = 4'b0000;
        end
    end
endmodule

module dec_565_to_444 (
    input  logic [15:0] data_565,
    output logic [11:0] data_444
);
    assign data_444 = {data_565[15:12], data_565[10:7], data_565[4:1]};
endmodule

module dec_444_to_vgaport (
    input  logic [11:0] data_444,
    output logic [11:0] vga_port
);
    assign vga_port = {data_444[7:4], data_444[3:0], data_444[11:8]};
endmodule

module gray_to_444 (
    input  logic [ 3:0] gray,
    output logic [11:0] vga_port
);
    assign vga_port = {gray, gray, gray};
endmodule

module rom_lena (
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0 : 76800-1];
    initial begin
        $readmemh("lena.mem", rom);
    end

    assign data = rom[addr];
endmodule

module vga_decoder_upscale (
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic        en,
    output logic [16:0] addr
);

    always @(*) begin
        if(((x_pixel >=0 && x_pixel < 640)&& (y_pixel >= 0 && y_pixel <480))) begin
            addr = y_pixel[9:1] * 320 + x_pixel[9:1];
            en   = 1'b1;
        end else begin
            addr = 16'bx;
            en   = 1'b0;
        end
    end
endmodule

module RGB_to_GRAY (
    input  logic [11:0] RGB,
    output logic [ 4:0] GRAY
);
    localparam RW = 8'h47;
    localparam GW = 8'h96;
    localparam BW = 8'h1D;

    logic [ 3:0] red_data;
    logic [ 3:0] green_data;
    logic [ 3:0] blue_data;
    logic [11:0] gray_data;

    assign GRAY = gray_data[11:7];

    assign red_data = RGB[3:0];
    assign green_data = RGB[11:8];
    assign blue_data = RGB[7:4];

    assign gray_data = RW * red_data + GW * green_data + BW * blue_data;
endmodule

module bright (
    input  [11:0] RGB,
    output [11:0] B_RGB
);
    logic [3:0] red_data;
    logic [3:0] green_data;
    logic [3:0] blue_data;

    logic [3:0] b_red_data;
    logic [3:0] b_green_data;
    logic [3:0] b_blue_data;


    assign red_data = RGB[3:0];
    assign green_data = RGB[11:8];
    assign blue_data = RGB[7:4];

    assign B_RGB = {b_green_data, b_blue_data, b_red_data};

    always @(*) begin
        if (red_data * 2 >= 4'b1111) begin
            b_red_data = 4'b1111;
        end else begin
            b_red_data = red_data * 2;
        end

        if (green_data * 2 >= 4'b1111) begin
            b_green_data = 4'b1111;
        end else begin
            b_green_data = green_data * 2;
        end

        if (blue_data * 2 >= 4'b1111) begin
            b_blue_data = 4'b1111;
        end else begin
            b_blue_data = blue_data * 2;
        end
    end

endmodule

module DARK (
    input  [11:0] RGB,
    output [11:0] D_RGB
);

    logic [3:0] red_data;
    logic [3:0] green_data;
    logic [3:0] blue_data;

    logic [3:0] d_red_data;
    logic [3:0] d_green_data;
    logic [3:0] d_blue_data;


    assign red_data = RGB[3:0];
    assign green_data = RGB[11:8];
    assign blue_data = RGB[7:4];

    assign D_RGB = {d_green_data, d_blue_data, d_red_data};

    always @(*) begin
        if (red_data / 2 == 0) begin
            d_red_data = red_data;
        end else begin
            d_red_data = red_data / 2;
        end

        if (blue_data / 2 == 0) begin
            d_blue_data = blue_data;
        end else begin
            d_blue_data = blue_data / 2;
        end

        if (green_data / 2 == 0) begin
            d_green_data = green_data;
        end else begin
            d_green_data = green_data / 2;
        end
    end

endmodule

module filter_normal (
    input  wire  [15:0] rData1,
    input  wire  [15:0] rData2,
    input  wire  [15:0] rData3,
    input  wire  [15:0] rData4,
    input  wire  [15:0] rData5,
    input  wire  [15:0] rData6,
    input  wire  [15:0] rData7,
    input  wire  [15:0] rData8,
    input  wire  [15:0] rData9,
    output logic [15:0] filt_Data
);
    logic [15:0] outData;

    assign filt_Data = outData;

    always_comb begin
        outData = (rData1 + rData2 + rData3 + rData4 + rData5 + rData6 + rData7 + rData8 + rData9)/9;
    end
endmodule


module sobel_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 3:0] top0,
    input  logic [ 3:0] top1,
    input  logic [ 3:0] top2,
    input  logic [ 3:0] mid0,
    input  logic [ 3:0] target,
    input  logic [ 3:0] mid2,
    input  logic [ 3:0] bot0,
    input  logic [ 3:0] bot1,
    input  logic [ 3:0] bot2,
    output logic [11:0] sobel_out
);

    localparam threshold = 0;
    logic signed [7:0] G_x, G_y;
    logic [7:0] abs_Gx, abs_Gy;
    logic [15:0] mag_result;
    logic [11:0] sobel_out_reg;

    // Gx, Gy 계산 (연속 할당)
    assign G_x = -top0 + top2 - (2 * mid0) + (2 * mid2) - bot0 + bot2;
    assign G_y = -top0 - (2 * top1) - top2 + bot0 + (2 * bot1) + bot2;

    // 절차적 로직
    always_ff @(posedge clk, posedge reset) begin : blockName
        if (reset) begin
            sobel_out <= 0;
        end else begin
            sobel_out <= sobel_out_reg;
        end
    end

    always_comb begin
        abs_Gx = (G_x < 0) ? -G_x : G_x;  // G_x의 절대값
        abs_Gy = (G_y < 0) ? -G_y : G_y;  // G_y의 절대값
        mag_result = abs_Gx + abs_Gy;  // 절대값의 합

        // mag_result 클리핑
        if (mag_result > 255) begin
            mag_result = 255;
        end

        // 출력 결정
        if (mag_result > threshold) begin
            sobel_out_reg = 12'hfff;
        end else begin
            sobel_out_reg = 12'h0;
        end
    end

endmodule

module gaussian_sobel_top (
    input logic clk,
    input logic [3:0] data_00,  // Top-left pixel (Gray)
    input logic [3:0] data_01,  // Top-center pixel (Gray)
    input logic [3:0] data_02,  // Top-right pixel (Gray)
    input logic [3:0] data_10,  // Middle-left pixel (Gray)
    input logic [3:0] data_11,  // Center pixel (Gray)
    input logic [3:0] data_12,  // Middle-right pixel (Gray)
    input logic [3:0] data_20,  // Bottom-left pixel (Gray)
    input logic [3:0] data_21,  // Bottom-center pixel (Gray)
    input logic [3:0] data_22,  // Bottom-right pixel (Gray)
    output logic [7:0] magnitude_out,  // Gradient Magnitude
    output logic [7:0] direction_out  // Gradient Direction
);

    // 내부 신호 선언
    logic [3:0] gaussian_result;

    // 가우시안 필터 인스턴스
    gaussian_filter gaussian (
        .clk(clk),
        .data_00(data_00),
        .data_01(data_01),
        .data_02(data_02),
        .data_10(data_10),
        .data_11(data_11),
        .data_12(data_12),
        .data_20(data_20),
        .data_21(data_21),
        .data_22(data_22),
        .pixel_out(gaussian_result)
    );

    // 소벨 필터 인스턴스
    sobel_filter sobel (
        .clk(clk),
        .data_00(gaussian_result),
        .data_01(gaussian_result),
        .data_02(gaussian_result),
        .data_10(gaussian_result),
        .data_11(gaussian_result),
        .data_12(gaussian_result),
        .data_20(gaussian_result),
        .data_21(gaussian_result),
        .data_22(gaussian_result),
        .magnitude_out(magnitude_out),
        .direction_out(direction_out)
    );

endmodule





module sobel_filter_yong (
    input logic clk,
    input logic [3:0] data_00,  // Top-left pixel (Gray)
    input logic [3:0] data_01,  // Top-center pixel (Gray)
    input logic [3:0] data_02,  // Top-right pixel (Gray)
    input logic [3:0] data_10,  // Middle-left pixel (Gray)
    input logic [3:0] data_11,  // Center pixel (Gray)
    input logic [3:0] data_12,  // Middle-right pixel (Gray)
    input logic [3:0] data_20,  // Bottom-left pixel (Gray)
    input logic [3:0] data_21,  // Bottom-center pixel (Gray)
    input logic [3:0] data_22,  // Bottom-right pixel (Gray)
    output logic [7:0] magnitude_out,  // Gradient Magnitude
    output logic [7:0] direction_out  // Gradient Direction
);

    // 내부 변수 선언
    logic [7:0] gx_sum, gy_sum;  // X, Y 방향 합
    logic [3:0] sobel_x[0:8], sobel_y[0:8];  // 소벨 커널
    int i;

    // 소벨 커널 초기화
    initial begin
        sobel_x = '{-4'd1, 4'd0, 4'd1, -4'd2, 4'd0, 4'd2, -4'd1, 4'd0, 4'd1};

        sobel_y = '{-4'd1, -4'd2, -4'd1, 4'd0, 4'd0, 4'd0, 4'd1, 4'd2, 4'd1};
    end

    // 소벨 필터 연산
    always_ff @(posedge clk) begin
        gx_sum = 0;
        gy_sum = 0;

        // X, Y 방향 합 계산
        gx_sum += data_00 * sobel_x[0];
        gx_sum += data_01 * sobel_x[1];
        gx_sum += data_02 * sobel_x[2];
        gx_sum += data_10 * sobel_x[3];
        gx_sum += data_11 * sobel_x[4];
        gx_sum += data_12 * sobel_x[5];
        gx_sum += data_20 * sobel_x[6];
        gx_sum += data_21 * sobel_x[7];
        gx_sum += data_22 * sobel_x[8];

        gy_sum += data_00 * sobel_y[0];
        gy_sum += data_01 * sobel_y[1];
        gy_sum += data_02 * sobel_y[2];
        gy_sum += data_10 * sobel_y[3];
        gy_sum += data_11 * sobel_y[4];
        gy_sum += data_12 * sobel_y[5];
        gy_sum += data_20 * sobel_y[6];
        gy_sum += data_21 * sobel_y[7];
        gy_sum += data_22 * sobel_y[8];

        // Magnitude 계산
        magnitude_out = gx_sum + gy_sum;

        // Direction 계산
        direction_out = gx_sum - gy_sum;
    end

endmodule



module gaussian_filter (
    input logic clk,
    input logic [4:0] data_00,  // Top-left pixel (Gray)
    input logic [4:0] data_01,  // Top-center pixel (Gray)
    input logic [4:0] data_02,  // Top-right pixel (Gray)
    input logic [4:0] data_10,  // Middle-left pixel (Gray)
    input logic [4:0] data_11,  // Center pixel (Gray)
    input logic [4:0] data_12,  // Middle-right pixel (Gray)
    input logic [4:0] data_20,  // Bottom-left pixel (Gray)
    input logic [4:0] data_21,  // Bottom-center pixel (Gray)
    input logic [4:0] data_22,  // Bottom-right pixel (Gray)
    output logic [4:0] pixel_out  // Filtered output (Gray)
);

    // 내부 변수 선언
    logic [8:0] sum;  // 필터 합산 결과 (확장된 비트)
    logic [3:0] kernel[0:8];  // 가우시안 커널
    int i;

    // 가우시안 커널 초기화
    initial begin
        kernel = '{3'd1, 3'd2, 3'd1, 3'd2, 3'd4, 3'd2, 3'd1, 3'd2, 3'd1};
    end
    // 필터 연산
    always_ff @(posedge clk) begin
        sum <= data_00 + (data_01 << 1) + data_02 + (data_10 << 1) + (data_11 << 2) + (data_12 << 1) + data_20 + (data_21 << 1) + data_22;
        // 정규화 (커널 총합: 16)
        pixel_out <= sum >> 4;
    end

endmodule


module sobel_filter_with_nms (
    input logic clk,
    input logic [4:0] data_00,  // Top-left pixel (Gray)
    input logic [4:0] data_01,  // Top-center pixel (Gray)
    input logic [4:0] data_02,  // Top-right pixel (Gray)
    input logic [4:0] data_10,  // Middle-left pixel (Gray)
    input logic [4:0] data_11,  // Center pixel (Gray)
    input logic [4:0] data_12,  // Middle-right pixel (Gray)
    input logic [4:0] data_20,  // Bottom-left pixel (Gray)
    input logic [4:0] data_21,  // Bottom-center pixel (Gray)
    input logic [4:0] data_22,  // Bottom-right pixel (Gray)
    output logic [3:0] pixel_out, // Binary edge output (4'b0000 or 4'b1111)
    input logic [8:0] th_switch
);

    // Internal variables
    logic signed [8:0] gx, gy;         // Gradient in X and Y directions
    logic [8:0] magnitude;             // Gradient magnitude
    logic [8:0] neighbor_1, neighbor_2; // Neighbors for NMS
    logic [1:0] direction;             // Gradient direction
    logic [8:0] threshold;

    assign threshold = th_switch;
    // Sobel filter computation

    always_ff @( posedge clk ) begin : blockName
        // Calculate Gx and Gy using Sobel kernels
        gy <= (-data_00 - (data_10 << 1) - data_20) +
             (data_02 + (data_12 << 1) + data_22);
        gx <= (-data_00 - (data_01 << 1) - data_02) +
             (data_20 + (data_21 << 1) + data_22);

        // Gradient magnitude (approximated as |Gx| + |Gy|)
        magnitude <= (gx < 0 ? -gx : gx) + (gy < 0 ? -gy : gy);

        // Determine gradient direction
        if (gy == 0)
            direction <= 2'd0; // Horizontal
        else if (gx == 0)
            direction <= 2'd1; // Vertical
        else if (gx > gy)
            direction <= 2'd2; // Diagonal \
        else
            direction <= 2'd3; // Diagonal /

        // Determine neighbors for NMS
        case (direction)
            2'd0: begin // Horizontal
                neighbor_1 <= data_10;
                neighbor_2 <= data_12;
            end
            2'd1: begin // Vertical
                neighbor_1 <= data_01;
                neighbor_2 <= data_21;
            end
            2'd2: begin // Diagonal \
                neighbor_1 <= data_00;
                neighbor_2 <= data_22;
            end
            2'd3: begin // Diagonal /
                neighbor_1 <= data_02;
                neighbor_2 <= data_20;
            end
        endcase

        // Check if the current pixel is the maximum in its direction
        if ((magnitude >= threshold) && (magnitude >= neighbor_1) && (magnitude >= neighbor_2))
            pixel_out <= 4'b1111; // Edge detected
        else
            pixel_out <= 4'b0000; // Suppressed
    end
    always_comb begin
        
    end
endmodule

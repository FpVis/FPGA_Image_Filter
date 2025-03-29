`timescale 1ns / 1ps

module ISP (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        h_sync,
    input  logic        v_sync,
    input  logic [ 3:0] btn,
    input  logic [15:0] sw,
    input  logic        disp_enable,
    //output 
    output logic [11:0] o_RGB,
    output logic [16:0] qvga_addr,
    output logic        qvga_en,
    //vga
    input  logic [11:0] buffer
);
    logic [11:0] out_buffer;
    up_scaling U_Interpolation (
        .clk_25(clk),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .out_buffer(out_buffer),
        .buffer(buffer)
    );
    Decoder_upscale U_Decoder_Upscaling (
        // input  logic         module_en,
        .x(x_pixel),
        .y(y_pixel),
        .btnU(btn[0]),
        .btnL(btn[3]),
        .btnR(btn[1]),
        .btnD(btn[2]),
        .center_SW(sw[7]),
        .control_SW(sw[8]),
        .qvga_en(qvga_en),
        .qvga_addr(qvga_addr)
    );
    // qvga_addr_decoder U_QVGA_Decoder (
    //     .x(x_pixel),
    //     .y(y_pixel),
    //     .qvga_en(qvga_en),
    //     .qvga_addr(qvga_addr)
    // );
    // rgb2gray U_gray (
    //     .color_rgb({out_buffer[15:12], out_buffer[10:7], out_buffer[4:1]}),
    //     .gray_rbg (gray_buffer)
    // );

    // sobel_6bit U_sobel (
    //     .clk(clk),
    //     .rst(reset),
    //     .gray_in(gray_buffer[11:4]),
    //     .threshold({sw[6:0], 1'b0}),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .disp_enable(disp_enable),
    //     .sobel_out(sobel_out)
    // );
    filter U_filter (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .disp_enable(disp_enable),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .buffer(out_buffer),
        .o_RGB(o_RGB)
    );

    // mux_4x1 U_mux_4x1 (
    //     .sel(sw[15:14]),
    //     .x0 ({out_buffer[15:12], out_buffer[10:7], out_buffer[4:1]}),
    //     .x1 ({gray_buffer[11:8], gray_buffer[11:8], gray_buffer[11:8]}),
    //     .x2 ({sobel_out[7:4], sobel_out[7:4], sobel_out[7:4]}),
    //     .x3 ({buffer[15:12], buffer[10:7], buffer[4:1]}),
    //     .y  (o_RGB)
    // );
endmodule


module filter (
    input  logic        clk,
    input  logic        reset,
    input  logic        disp_enable,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] sw,
    input  logic [11:0] buffer,
    output logic [11:0] o_RGB
);

    logic [11:0] gray_buffer;
    logic [ 7:0] sobel_out;
    logic [7:0] gaussian_out, laplacian_out, average_out;
    logic [11:0]
        red_buffer, green_buffer, blue_buffer, bright_buffer, dark_buffer;

    RGB_to_Red U_RED (
        .RGB_Color(buffer),
        .Red_Color(red_buffer)
    );

    RGB_to_Green U_GREEN (
        .RGB_Color  (buffer),
        .Green_Color(green_buffer)
    );
    RGB_to_Blue U_BLUE (
        .RGB_Color (buffer),
        .Blue_Color(blue_buffer)
    );
    bright_mode U_Brighter (
        .RGB_Color(buffer),
        .bright_sw(sw[3:0]),
        .bright_Color(bright_buffer)
    );
    dark_mode U_Darker (
        .RGB_Color(buffer),
        .dark_sw(sw[3:0]),
        .dark_Color(dark_buffer)
    );
    rgb2gray U_gray (
        .color_rgb(buffer),
        .gray_rbg (gray_buffer)
    );

    //    sobel_4bit U_sobel (
    //         .clk        (clk),
    //         .rst        (reset),
    //         .gray_in    (gray_buffer[11:4]),
    //         .threshold  ({sw[6:0], 1'b0}),
    //         .x_pixel    (x_pixel),
    //         .y_pixel    (y_pixel),
    //         .disp_enable(disp_enable),
    //         .sobel_out  (sobel_out)
    //     );
    // sobel_6bit U_sobel (
    //     .clk        (clk),
    //     .rst        (reset),
    //     .gray_in    (gray_buffer[11:4]),
    //     .threshold  ({sw[6:0], 1'b0}),
    //     .x_pixel    (x_pixel),
    //     .y_pixel    (y_pixel),
    //     .disp_enable(disp_enable),
    //     .sobel_out  (sobel_out)
    // );
    // gaussian_4bit U_gaussian(
    //     .clk(clk),
    //     .rst(reset),
    //     .gray_in(gray_buffer[11:4]),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .disp_enable(disp_enable),
    //     .gaussian_out(gaussian_out)
    // );

    // gaussian U_gaussian (
    //     .clk(clk),
    //     .rst(reset),
    //     .gray_in(gray_buffer[11:4]),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .disp_enable(disp_enable),
    //     .gaussian_out(gaussian_out)
    // );

    conv_filter_5x5 U_conv_filter (
        .clk(clk),
        .rst(reset),
        .gray_in(gray_buffer[11:4]),
        .threshold({sw[6:0], 1'b0}),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .disp_enable(disp_enable),
        .sobel_out(sobel_out),
        .gaussian_out(gaussian_out),
        .average_out(average_out),
        .laplacian_out(laplacian_out)
    );
    always_comb begin
        o_RGB = {buffer};
        case (sw[15:9])
            // 8'b10000000: o_RGB = red_buffer;
            // 8'b01000000: o_RGB = blue_buffer;
            7'b1000000:
            o_RGB = {average_out[7:4], average_out[7:4], average_out[7:4]};
            7'b0100000:
            o_RGB = {gaussian_out[7:4], gaussian_out[7:4], gaussian_out[7:4]};
            7'b0010000: o_RGB = bright_buffer;
            7'b0001000: o_RGB = dark_buffer;
            7'b0000100:
            o_RGB = {gray_buffer[11:8], gray_buffer[11:8], gray_buffer[11:8]};
            7'b0000010:
            o_RGB = {sobel_out[7:4], sobel_out[7:4], sobel_out[7:4]};
            7'b0000001:
            o_RGB = {
                laplacian_out[7:4], laplacian_out[7:4], laplacian_out[7:4]
            };
        endcase
    end
endmodule

module RGB_to_Red (
    input  logic [11:0] RGB_Color,
    output logic [11:0] Red_Color
);
    logic [3:0] r;

    assign r = RGB_Color[11:8];
    assign Red_Color = {r, 4'b0, 4'b0};

endmodule

module RGB_to_Green (
    input  logic [11:0] RGB_Color,
    output logic [11:0] Green_Color
);
    logic [3:0] g;

    assign g = RGB_Color[7:4];
    assign Green_Color = {4'b0, g, 4'b0};

endmodule

module RGB_to_Blue (
    input  logic [11:0] RGB_Color,
    output logic [11:0] Blue_Color
);
    logic [3:0] b;

    assign b = RGB_Color[3:0];
    assign Blue_Color = {4'b0, 4'b0, b};

endmodule

module bright_mode (
    input  logic [11:0] RGB_Color,
    input  logic [ 3:0] bright_sw,
    output logic [11:0] bright_Color
);
    logic [3:0] r, g, b;
    logic [4:0] red, green, blue;

    assign r = RGB_Color[11:8];
    assign g = RGB_Color[7:4];
    assign b = RGB_Color[3:0];

    always_comb begin
        red = r + bright_sw;
        green = g + bright_sw;
        blue = b + bright_sw;


        bright_Color[11:8] = (red > 4'd15) ? 4'd15 : red[3:0];
        bright_Color[7:4] = (green > 4'd15) ? 4'd15 : green[3:0];
        bright_Color[3:0] = (blue > 4'd15) ? 4'd15 : blue[3:0];
    end

endmodule

module dark_mode (
    input  logic [11:0] RGB_Color,
    input  logic [ 3:0] dark_sw,
    output logic [11:0] dark_Color
);
    logic [3:0] r, g, b;
    logic [4:0] red, green, blue;

    assign r = RGB_Color[11:8];
    assign g = RGB_Color[7:4];
    assign b = RGB_Color[3:0];

    always_comb begin
        red = (r > dark_sw) ? r - dark_sw : 4'd0;
        green = (g > dark_sw) ? g - dark_sw : 4'd0;
        blue = (b > dark_sw) ? b - dark_sw : 4'd0;

        dark_Color[11:8] = red[3:0];
        dark_Color[7:4] = green[3:0];
        dark_Color[3:0] = blue[3:0];
    end

endmodule

module rgb2gray (
    input  logic [11:0] color_rgb,
    output logic [11:0] gray_rbg
);
    localparam RW = 8'h47;  // weight for red
    localparam GW = 8'h96;  // weight for green
    localparam BW = 8'h1D;  // weight for blue

    logic [3:0] r, g, b, gray;
    logic [11:0] gray12;

    assign r = color_rgb[11:8];
    assign g = color_rgb[7:4];
    assign b = color_rgb[3:0];
    assign gray12 = r * RW + g * GW + b * BW;
    assign gray_rbg = gray12;
    // assign gray = gray12[11:8];
    // assign gray_rbg = {gray, gray, gray};

endmodule

`timescale 1ns / 1ps
/*
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


module vga_rgb_bar (
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       disp_enable,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    always_comb begin
        red_port   = 4'd0;
        green_port = 4'd0;
        blue_port  = 4'd0;
        if (disp_enable) begin

            /////////////////////////1
            if (y_pixel < 320) begin
                if (x_pixel < 91) begin  //gray
                    red_port   = 4'd14;
                    green_port = 4'd14;
                    blue_port  = 4'd14;
                end else if (x_pixel < 183) begin  //yellow
                    red_port   = 4'd15;
                    green_port = 4'd15;
                    blue_port  = 4'd0;
                end else if (x_pixel < 274) begin  //sky
                    red_port   = 4'd0;
                    green_port = 4'd15;
                    blue_port  = 4'd15;
                end else if (x_pixel < 366) begin  //green
                    red_port   = 4'd0;
                    green_port = 4'd15;
                    blue_port  = 4'd0;
                end else if (x_pixel < 457) begin  //magenta
                    red_port   = 4'd15;
                    green_port = 4'd0;
                    blue_port  = 4'd15;
                end else if (x_pixel < 549) begin  //red
                    red_port   = 4'd15;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end else if (x_pixel < 640) begin  //blue
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd15;
                end
            end  ////////////////////////////2
            else if (y_pixel < 350) begin
                if (x_pixel < 91) begin  //blue
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd15;
                end else if (x_pixel < 183) begin  //black
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end else if (x_pixel < 274) begin  //magenta
                    red_port   = 4'd15;
                    green_port = 4'd0;
                    blue_port  = 4'd15;
                end else if (x_pixel < 366) begin  //black
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end else if (x_pixel < 457) begin  //sky
                    red_port   = 4'd0;
                    green_port = 4'd15;
                    blue_port  = 4'd15;
                end else if (x_pixel < 549) begin  //black
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end else if (x_pixel < 640) begin  //gray
                    red_port   = 4'd14;
                    green_port = 4'd14;
                    blue_port  = 4'd14;
                end
            end  /////////////////////////////3
            else if (y_pixel < 480) begin
                if (x_pixel < 107) begin  //
                    red_port   = 4'd8;
                    green_port = 4'd0;
                    blue_port  = 4'd15;
                end else if (x_pixel < 214) begin  //white
                    red_port   = 4'd15;
                    green_port = 4'd15;
                    blue_port  = 4'd15;
                end else if (x_pixel < 321) begin  //purple
                    red_port   = 4'd15;
                    green_port = 4'd0;
                    blue_port  = 4'd8;
                end else if (x_pixel < 428) begin  //black
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end else if (x_pixel < 535) begin  //black
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end else if (x_pixel < 640) begin  //black
                    red_port   = 4'd0;
                    green_port = 4'd0;
                    blue_port  = 4'd0;
                end
            end
        end
    end

endmodule


module rgb2gray (
    input  logic [11:0] color_rgb,
    output logic [11:0] gray_rbg
);
    localparam RW = 8'h47; // weight for red
    localparam GW = 8'h96; // weight for green
    localparam BW = 8'h1D; // weight for blue

    logic [3:0] r, g, b, gray;
    logic [11:0] gray12;

    assign r = color_rgb[11:8];
    assign g = color_rgb[7:4];
    assign b = color_rgb[3:0];
    assign gray12 = r * RW + g * GW + b * BW;
    assign gray = gray12[11:8];
    assign gray_rbg = {gray, gray, gray};

endmodule
*/
`timescale 1ns / 1ps


module ISP_UP_Scaling (
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] cam_Data,
    input  logic [15:0] saved_background_Data,
    input  logic [15:0] cam_background_Data,
    input  logic [15:0] chromakey_Data,
    output logic [15:0] screen_data,
    output logic [14:0] address,
    output logic        out_en
);

    logic [15:0] line_buffer[0 : 639];
    logic [15:0] out_data;
    logic [9:0] x, y;
    logic [6:0] green;
    logic [5:0] red, blue;

    assign out_en = 1;
    assign screen_data = (x_pixel[0]) ? {red[4:0], green[5:0], blue[4:0]} : out_data;

    always_ff @(posedge clk) begin
        line_buffer[x_pixel] <= 0;
        out_data             <= 0;
        if ((x_pixel < 320) && (y_pixel < 240)) begin
            line_buffer[x_pixel] <= cam_Data;
            out_data             <= cam_Data;
        end else if ((x_pixel >= 320 && x_pixel < 640) && (y_pixel < 240)) begin
            line_buffer[x_pixel] <= saved_background_Data;
            out_data             <= saved_background_Data;
        end else if ((x_pixel < 320) && (y_pixel >= 240 && y_pixel < 480)) begin
            line_buffer[x_pixel] <= cam_background_Data;
            out_data             <= cam_background_Data;
        end else if((x_pixel >= 320 && x_pixel < 640) && (y_pixel >= 240 && y_pixel < 480))begin
            line_buffer[x_pixel] <= chromakey_Data;
            out_data             <= chromakey_Data;
        end
    end

    always_comb begin
        red     = 6'b0;
        green   = 7'b0;
        blue    = 6'b0;
        x       = (x_pixel < 320) ? x_pixel : x_pixel - 320;
        y       = (y_pixel < 240) ? y_pixel : y_pixel - 240;
        address = (y >> 1) * 160 + (x >> 1);
        if (x_pixel[0]) begin
            red     = ({1'b0, line_buffer[x_pixel - 1][15:11]} + {1'b0, line_buffer[x_pixel][15:11]}) >> 1;
            green   = ({1'b0, line_buffer[x_pixel - 1][10:5]} + {1'b0, line_buffer[x_pixel][10:5]}) >> 1;
            blue    = ({1'b0, line_buffer[x_pixel - 1][4:0]} + {1'b0, line_buffer[x_pixel][4:0]}) >> 1;
            address = (y >> 1) * 160 + ((x + 1) >> 1);
        end
    end

endmodule

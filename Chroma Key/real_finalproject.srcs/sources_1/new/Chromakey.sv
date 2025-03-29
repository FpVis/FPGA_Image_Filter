`timescale 1ns / 1ps


module comparator_green (
    input  logic [15:0] cam_Data,
    input  logic [15:0] saved_background_data,
    input  logic [15:0] cam_background_data,
    input  logic        background_sel,
    output logic [15:0] disp_data
);

    logic [4:0] red, blue;
    logic [5:0] green;

    assign red   = cam_Data[15:11];
    assign green = cam_Data[10:5];
    assign blue  = cam_Data[4:0];

    always_comb begin
        if (red < 10 && green > 15 && blue < 10) begin
            case (background_sel)
                1'b0: disp_data = saved_background_data;
                1'b1: disp_data = cam_background_data;
                default: disp_data = saved_background_data;
            endcase
        end else begin
            disp_data = cam_Data;
        end
    end

endmodule

module rom_background (
    input  logic        rclk,
    input  logic        oe,
    input  logic [14:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:160*120-1];

    initial begin
        $readmemh("background.mem", rom);
    end

    always_ff @(posedge rclk) begin
        if (oe) begin
            data <= rom[addr];
        end else begin
            data <= 0;
        end
    end

endmodule

`timescale 1ns / 1ps


module vga_controller (
    input  logic       clk,
    input  logic       reset,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       disp_enable
);

    logic [9:0] h_counter, v_counter;

    pixel_counter U_PIXEL_COUNTER (
        .clk      (clk),       //pclk in
        .reset    (reset),
        .h_counter(h_counter),  //horizontal counter
        .v_counter(v_counter)   //vertical counter
    );
    vga_decoder U_VGA_DECODER (
        .h_counter(h_counter),
        .v_counter(v_counter),
        .h_sync(h_sync),  //front porch = high , sync = low, back porch = high
        .v_sync(v_sync),  //front porch = high , sync = low, back porch = high
        .x_pixel(x_pixel),  //x == h_counter 
        .y_pixel(y_pixel),  //y == v_counter
        .disp_enable(disp_enable)  // 1: display, 0 : non-display
    );


endmodule

module vga_decoder (
    input logic [9:0] h_counter,
    input logic [9:0] v_counter,
    output logic h_sync,  //front porch = high , sync = low, back porch = high
    output logic v_sync,  //front porch = high , sync = low, back porch = high
    output logic [9:0] x_pixel,  //x == h_counter 
    output logic [9:0] y_pixel,  //y == v_counter
    output logic disp_enable  // 1: display, 0 : non-display
);
    //horizon////
    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;
    //vertical///
    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;

    assign disp_enable = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);
    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch))  && (v_counter < (V_Visible_area + V_Front_porch + V_Sync_pulse)));
    assign x_pixel = (h_counter < H_Visible_area) ? h_counter : 0;
    assign y_pixel = (v_counter < V_Visible_area) ? v_counter : 0;

endmodule


module pixel_counter (
    input  logic       clk,        //pclk in
    input  logic       reset,
    output logic [9:0] h_counter,  //horizontal counter
    output logic [9:0] v_counter   //vertical counter
);

    localparam H_PIX_MAX = 800, V_LINE_MAX = 525;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_PIX_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_PIX_MAX - 1) begin
                if (v_counter == V_LINE_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

endmodule
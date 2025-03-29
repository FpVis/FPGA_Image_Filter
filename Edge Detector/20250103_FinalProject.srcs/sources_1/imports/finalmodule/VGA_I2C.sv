`timescale 1ns / 1ps

module VGA_I2C_ISP (
    input  logic        clk,
    input  logic        reset,
    // ov7670 camera module signal
    output logic        ov7670_xclk,    //20Mhz
    input  logic        ov7670_pclk,
    input  logic        ov7670_href,
    input  logic        ov7670_v_sync,
    input  logic [ 7:0] ov7670_data,
    output logic        scl,
    inout  wire         sda,
    input  logic        switch,
    output logic        h_sync,
    output logic        v_sync,
    output logic [11:0] vga_port,
    input  logic [ 8:0] th_switch
);

    logic clk_system, disp_enable, vga_clk;
    logic Mux_sel;
    logic [11:0] w_vga_port, filterData;
    logic [4:0] rData;
    logic [4:0] grayData;
    logic [11:0] wData444;
    logic [9:0] x_pixel, y_pixel;
    logic r_en, we;
    logic [15:0] wData;
    logic [16:0] rAddr, wAddr;

    clk_wiz_0 instance_name (
        .clk_in1    (clk),
        .reset      (reset),       // input reset
        .clk_system (clk_system),  // output clk_system
        .vga_clk    (vga_clk),     // output vga_clk
        .ov7670_xclk(ov7670_xclk)  // output ov7670_xclk
    );

    vga_controller U_vga_controller (
        .clk        (vga_clk),
        .reset      (reset),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .disp_enable(disp_enable)
    );

    i2c_ov7670_unit U_i2c_ov7670_unit (
        .clk          (clk_system),     //100MHz
        .reset        (reset),
        // ov7670 camera module signal
        .ov7670_pclk  (ov7670_pclk),
        .ov7670_href  (ov7670_href),
        .ov7670_v_sync(ov7670_v_sync),
        .ov7670_data  (ov7670_data),
        .scl          (scl),
        .sda          (sda),
        //framebuffer access
        .we           (we),
        .wAddr        (wAddr),
        .wData        (wData),
        //출력력
        .Mux_sel      (Mux_sel)
    );
    // I2C_Control

    TOP_ISP U_TOP_ISP (
        .isp_clk    (clk_system),   // 100MHZ
        .vga_clk    (vga_clk),      // 25MHz
        .reset      (reset),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .x_pixel    (x_pixel),
        //.y_pixel    (y_pixel),
        .disp_enable(disp_enable),
        .r_en       (r_en),
        .rAddr      (rAddr),
        .rData      (rData),
        .vga_data   (w_vga_port),
        .switch     (switch),
        .th_switch  (th_switch)
    );

    dec_565_to_444 U_dec_565_to_444 (
        .data_565(wData),
        .data_444(wData444)
    );

    RGB_to_GRAY U_RGB_to_GRAY (
        .RGB (wData444),
        .GRAY(grayData)
    );

    frameBuffer U_frameBuffer (
        .wclk (ov7670_pclk),  // ov7670_pclk
        .we   (we),
        .wAddr(wAddr),
        .wData(grayData),
        .rclk (clk_system),   // 100MHz
        .oe   (r_en),
        .rAddr(rAddr),
        .rData(rData)
    );

    MUX_2x1_12bit U_MUX_2x1_12bit (
        .sel(Mux_sel && disp_enable),
        .x0 (12'b0),
        .x1 (w_vga_port),
        .y  (vga_port)
    );



endmodule




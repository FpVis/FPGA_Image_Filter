`timescale 1ns / 1ps


module top_module (
    input  logic       clk,
    input  logic       reset,
    input  logic       background_sel,
    // ov7670 camera module signal signal
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // ov7670 background camera
    output logic       ov7670_xclk_back,
    input  logic       ov7670_pclk_back,
    input  logic       ov7670_href_back,
    input  logic       ov7670_v_sync_back,
    input  logic [7:0] ov7670_data_back,
    // vga display port
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    //sccb
    output logic       scl,
    inout  wire        sda,
    output logic       scl_back,
    inout  wire        sda_back
);

    logic disp_enable, we, we_back, enable, w_scl, w_sda;
    logic [9:0] x_pixel, y_pixel;
    logic [15:0] wData, wData_back, final_Data;
    logic [14:0] wAddr, wAddr_back, address;
    logic [15:0]
        cam_Data, saved_background_Data, cam_background_Data, chromakey_Data;

    assign red_port         = (disp_enable) ? final_Data[15:12] : 0;
    assign green_port       = (disp_enable) ? final_Data[10:7] : 0;
    assign blue_port        = (disp_enable) ? final_Data[4:1] : 0;

    assign ov7670_xclk      = ov7670_xclk_all;
    assign ov7670_xclk_back = ov7670_xclk_all;
    assign scl              = w_scl;
    assign scl_back         = w_scl;
    assign sda              = w_sda;
    assign sda_back         = w_sda;

    clk_wiz_0 clk_gen (
        .clk_in1   (clk),
        .reset     (reset),
        .vga_clk   (vga_clk),          //output vga_clk 25MHz
        .ov7670_clk(ov7670_xclk_all),  // output ov7670_clk 24MHz
        .sys_clk   (sys_clk)           // ouput 100MHz
    );

    vga_controller U_VGA_Controller (
        .clk        (vga_clk),
        .reset      (reset),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .disp_enable(disp_enable)
    );

    frameBuffer U_FrameBuffer_160x120 (
        // write side ov7670
        .wclk (ov7670_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        // read side vga display
        .rclk (vga_clk),
        .oe   (enable),
        .rAddr(address),
        .rData(cam_Data)
    );

    ov7670_SetData U_OV7670_SetData (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    frameBuffer U_FrameBuffer_160x120_back (
        // write side ov7670
        .wclk (ov7670_pclk_back),
        .we   (we_back),
        .wAddr(wAddr_back),
        .wData(wData_back),
        // read side vga display
        .rclk (vga_clk),
        .oe   (enable),
        .rAddr(address),
        .rData(cam_background_Data)
    );

    ov7670_SetData U_OV7670_SetData_back (
        .pclk       (ov7670_pclk_back),
        .reset      (reset),
        .href       (ov7670_href_back),
        .v_sync     (ov7670_v_sync_back),
        .ov7670_data(ov7670_data_back),
        .we         (we_back),
        .wAddr      (wAddr_back),
        .wData      (wData_back)
    );
    
    ISP_UP_Scaling U_UP_Scaling (
        .clk                  (sys_clk),
        .x_pixel              (x_pixel),
        .y_pixel              (y_pixel),
        .cam_Data             (cam_Data),
        .saved_background_Data(saved_background_Data),
        .cam_background_Data  (cam_background_Data),
        .chromakey_Data       (chromakey_Data),
        .screen_data          (final_Data),
        .out_en               (enable),
        .address              (address)
    );

    rom_background U_ROM_Background (
        .rclk(vga_clk),
        .oe  (enable),
        .addr(address),
        .data(saved_background_Data)
    );

    comparator_green U_comp_chromakey (
        .cam_Data             (cam_Data),
        .saved_background_data(saved_background_Data),
        .cam_background_data  (cam_background_Data),
        .background_sel       (background_sel),
        .disp_data            (chromakey_Data)
    );

    top_SCCB U_TOP_SCCB (
        .clk  (sys_clk),
        .reset(reset),
        .sda  (w_sda),
        .scl  (w_scl)
    );

endmodule

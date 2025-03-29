`timescale 1ns / 1ps

module VGA_Test (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] sw,
    input  logic [ 3:0] btn,
    output logic        scl,
    output logic        sda,
    // ov7670 signal
    output logic        ov7670_xclk,
    input  logic        ov7670_pclk,
    input  logic        ov7670_href,
    input  logic        ov7670_v_sync,
    input  logic [ 7:0] ov7670_data,
    // vga display port 
    output logic        h_sync,
    output logic        v_sync,
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);
    logic vga_clk;
    logic disp_enable;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic [11:0] buffer, out_buffer;
    logic qvga_en;
    logic [16:0] qvga_addr;
    logic [11:0] o_RGB;
    logic [11:0] isp_rgb;
    logic SCCB_clk;
    logic camera_set;

    assign red_port   = disp_enable ? o_RGB[11:8] : 0;
    assign green_port = disp_enable ? o_RGB[7:4] : 0;
    assign blue_port  = disp_enable ? o_RGB[3:0] : 0;
    assign camera_set = (btn[0] & !(sw[8]));

    clk_wiz_0 instance_name (
        // Clock out ports
        .vga_clk(vga_clk),     // output vga_clk
        .ov7670_clk(ov7670_xclk),     // output ov7670_clk
        .camera_configure(SCCB_clk),
        // Status and control signals
        .reset(reset), // input reset
        // Clock in ports
        .clk_in1(clk)
    );  // input clk_in1

    camera_configure #(
        .CLK_FREQ(100000000)  //25000000
    ) U_camera_config (
        .clk  (SCCB_clk),
        .start(camera_set),
        .sioc (scl),
        .siod (sda),
        .done ()
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
    frameBuffer U_FrameBuffer_320x240 (
        // write side ov7670
        .wclk (ov7670_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData({wData[15:12],wData[10:7],wData[4:1]}),
        // read side vga display
        .rclk (vga_clk),
        .oe   (qvga_en),
        .rAddr(qvga_addr),
        .rData(buffer)
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

    ISP U_ISP (
        .clk        (vga_clk),
        .reset      (reset),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .btn        (btn),
        .sw         (sw),
        .disp_enable(disp_enable),
        //output 
        .o_RGB      (o_RGB),
        .qvga_addr  (qvga_addr),
        .qvga_en    (qvga_en),
        //vga
        .buffer     (buffer)
    );


endmodule

// module qvga_addr_decoder (
//     input  logic [ 9:0] x,
//     input  logic [ 9:0] y,
//     output logic        qvga_en,
//     output logic [16:0] qvga_addr
// );
//     always_comb begin
//         if (x < 640 && y < 480) begin
//             qvga_addr = y / 2 * 320 + x / 2;
//             qvga_en   = 1'b1;
//         end else begin
//             qvga_addr = 0;
//             qvga_en   = 1'b0;
//         end
//     end
// endmodule



module mux (
    input  logic        sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    output logic [11:0] y
);
    always_comb begin
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module mux_4x1 (
    input  logic [ 1:0] sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    input  logic [11:0] x3,
    output logic [11:0] y
);
    always_comb begin
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end
endmodule

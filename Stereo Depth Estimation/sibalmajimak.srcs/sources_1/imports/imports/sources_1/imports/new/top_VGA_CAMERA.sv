`timescale 1ns / 1ps




module qvga_addr_decoder (
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic        qvga_en1,
    output logic [14:0] qvga_addr1,
    output logic        qvga_en2,
    output logic [14:0] qvga_addr2,
    output logic        qvga_en3,
    output logic [14:0] qvga_addr3,
    output logic        qvga_en
);

    logic [15:0] row;
    
    always_comb begin
        qvga_addr1 = 0;
        qvga_en1   = 1'b0;
        qvga_addr2 = 0;
        qvga_en2   = 1'b0;
        qvga_addr3 = 0;
        qvga_en3   = 1'b0;
        qvga_en = 0;
        
        if(x < 640 && y < 240) begin
            qvga_addr1 = ((y[9:1]) * 160) + x[9:1];
            qvga_addr2 = ((y[9:1]) * 160) + x[9:1];
            qvga_addr3 = ((y[9:1]) * 160) + x[9:1];
            qvga_en = 1;
        end
        else if(x <= 320 && y >= 240) begin
            qvga_addr1 = ((y[9:1]) * 160) + x[9:1];
            qvga_addr2 = ((y[9:1]-120) * 160) + x[9:1];
            qvga_addr3 = ((y[9:1]-120) * 160) + x[9:1];
            qvga_en = 1;
        end
        else begin
            qvga_en = 0;
            qvga_addr1 = 0;
            qvga_addr2 = 0;
            qvga_addr3 = 0;
        end
  
    end
endmodule



module display_mux_2x1 (
    input  logic [15:0] Left_Data,
    input  logic [15:0] Right_Data,
    input  logic [15:0] Gray_Data,
    input  logic [15:0] Disparity_Data,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic [15:0] Out_Data
);

    always_comb begin
        if (x < 320 && y < 240) begin
            // Left camera region
            
            Out_Data = {Disparity_Data};
        end else if (x >= 320 && y < 240) begin
//             Right camera region
            Out_Data = Right_Data;
        end 
        else if (x < 320 && y >= 240) begin
         Out_Data = Left_Data;
        end  else begin
            Out_Data = 16'd0;
        end
    end

endmodule

module rgb2gray (
    input  logic [15:0] color_rgb,
    output logic [11:0] gray_rgb
);

    localparam RW = 8'h47;  // weight for RED
    localparam GW = 8'h96;  // weight for Green
    localparam BW = 8'h10;  // weight for Blue

    logic [3:0] r, g, b, gray;
    logic [11:0] gray12;

    assign r = color_rgb[15:12];
    assign g = color_rgb[10:7];
    assign b = color_rgb[4:1];
    assign gray12 = r * RW + g * GW + b * BW;
    assign gray = gray12[11:8];
    assign gray_rgb = {gray, gray, gray};

endmodule

module rgb2gray16 (
    input  logic [15:0] color_rgb,
    output logic [15:0] gray_rgb
);
    localparam RW = 8'h47;  // weight for RED
    localparam GW = 8'h96;  // weight for Green
    localparam BW = 8'h10;  // weight for Blue
    logic [3:0] r, g, b, gray;
    logic [15:0] gray12;
    
    assign r = color_rgb[15:11];
    assign g = color_rgb[10:5];
    assign b = color_rgb[4:0];
    assign gray12 = r * RW + g * GW + b * BW;

    assign gray_rgb = {gray12[7:3],gray12[7:2], gray12[7:3]};
endmodule



module top_VGA_CAMERA (
    input  logic       clk,
    input  logic       reset,
    input  logic       gray_sw,
    // ov7670 camera input signals
    output logic       ov7670_xclk1,
    input  logic       ov7670_pclk1,
    input  logic       ov7670_href1,
    input  logic       ov7670_v_sync1,
    input  logic [7:0] ov7670_data1,

    output logic       ov7670_xclk2,
    input  logic       ov7670_pclk2,
    input  logic       ov7670_href2,
    input  logic       ov7670_v_sync2,
    input  logic [7:0] ov7670_data2,

    // VGA display output
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    
    inout wire sda1,
    output logic scl1,
    inout wire sda2,
    output logic scl2
);
logic [14:0] cnt2;

    // Internal signals
    logic disp_enable;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic we1, we2;
    logic [14:0] wAddr1, wAddr2;
    logic [15:0] wData1, wData2, buffer1, buffer2, buffer3, buffer;
    logic qvga_en1, qvga_en2, qvga_en3;
    logic [14:0] qvga_addr1, qvga_addr2, qvga_addr3;

    logic [15:0] rData_for_SAD1, w_depth_out_gray;
    logic [15:0] rData_for_SAD2;
    logic [11:0] gray_for_SAD1;
    logic [11:0] gray_for_SAD2;
    
    // Disparity signal
    logic [15:0] depth_out;
    logic [15:0] w_depth_out;
    

    assign vgaRed = disp_enable ? depth_out[15:12] : 0;
    assign vgaGreen = disp_enable? depth_out[10:7] : 0;
    assign vgaBlue = disp_enable ?  depth_out[4:1] : 0;

  clk_wiz_0 instance_name
   (
    // Clock out ports
    .ov7670_clk1(ov7670_xclk1),     // output ov7670_clk1
    .ov7670_clk2(ov7670_xclk2),     // output ov7670_clk2
    .vga_clk(vga_clk),     // output vga_clk
    .hclk(hclk),     // output hclk
    // Status and control signals
    .reset(reset), // input reset
   // Clock in ports
    .clk_in1(clk));  
    
    top_SCCB U_LSCCB(
    .clk(clk),
    .reset(reset),
    .sda(sda1),
    .scl(scl1)
);
    top_SCCB U_RSCCB(
    .clk(clk),
    .reset(reset),
    .sda(sda2),
    .scl(scl2)
);

    rgb2gray U_rbt2gray (
        .color_rgb  (buffer1),
        .gray_rgb   (gray_for_SAD1)
    );
    
    rgb2gray U_rbt2grayR (
        .color_rgb  (buffer2),
        .gray_rgb   (gray_for_SAD2)
    );
    
    rgb2gray16 U_16(
    .color_rgb(w_depth_out),
    .gray_rgb(w_depth_out_gray)
    );

    display_mux_2x1 U_display_mux_2x1 (
        .Left_Data (buffer1),
        .Right_Data(buffer2),
        .Disparity_Data(w_depth_out_gray),
        .x         (x_pixel),
        .y         (y_pixel),
        .Out_Data  (depth_out)
    );

    ov7670_SetData U_OV7670_SetDataLeft (
        .pclk       (ov7670_pclk1),
        .reset      (reset),
        .href       (ov7670_href1),
        .v_sync     (ov7670_v_sync1),//
        .ov7670_data(ov7670_data1),
        .we         (we1),
        .wAddr      (wAddr1),
        .wData      (wData1)
    );

    ov7670_SetData U_OV7670_SetDataRight (
        .pclk       (ov7670_pclk2),
        .reset      (reset),
        .href       (ov7670_href2),
        .v_sync     (ov7670_v_sync2),
        .ov7670_data(ov7670_data2),
        .we         (we2),
        .wAddr      (wAddr2),
        .wData      (wData2)
    );

    // ---------------------------------------------------------- LINE BUFFER -------------------------------------------------------------------------//


    // ---------------------------------------------------------------------------------------------------------------------------------------------------------//
    frameBuffer U_FrameBufferLeft (
        // write side ov7670
        .wclk (ov7670_pclk1),
        .we   (we1),
        .wAddr(wAddr1),
        .wData(wData1),
        .rclk (vga_clk),
        .oe   (qvga_en),
        .rAddr(qvga_addr3),
        .rData(buffer1)
    );

    frameBuffer U_FrameBufferRight (
        // write side ov7670
        .wclk (ov7670_pclk2),
        .we   (we2),
        .wAddr(wAddr2),
        .wData(wData2),
        .rclk (vga_clk),
        .oe   (qvga_en),
        .rAddr(qvga_addr2),
        .rData(buffer2)
    );
    
    disparity_generator U_DG(
    .rclk(clk),
    .vga_clk(vga_clk),
    .reset(reset),
    .wData1(gray_for_SAD1),
    .wData2(gray_for_SAD2),
    .rAddr(qvga_addr1),
    .oe(qvga_en),
    .x_pixel(x_pixel),
    .DisplayData(w_depth_out)
    );

    qvga_addr_decoder U_qvga_addr_decoder (
        .x         (x_pixel),
        .y         (y_pixel),
        .qvga_en1  (),
        .qvga_addr1(qvga_addr1),
        .qvga_en2  (),
        .qvga_addr2(qvga_addr2),
        .qvga_en3  (), 
        .qvga_addr3(qvga_addr3),
        .qvga_en(qvga_en)
    );

    vga_controller U_vga_controller (
        .clk        (vga_clk),
        .reset      (reset),
        .h_sync     (Hsync),
        .v_sync     (Vsync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .disp_enable(disp_enable)
    );
    
    

    

endmodule

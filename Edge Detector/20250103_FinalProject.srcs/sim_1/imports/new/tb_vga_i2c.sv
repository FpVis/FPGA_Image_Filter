`timescale 1ns / 1ps



module tb_vga_i2c ();

    logic        clk;
    logic        reset;
    logic        ov7670_xclk;  //20Mhz
    logic        ov7670_pclk;
    logic        ov7670_href;
    logic        ov7670_v_sync;
    logic [ 7:0] ov7670_data;
    logic        scl;
    wire         sda;
    logic        h_sync;
    logic        v_sync;
    logic [11:0] vga_port;

    assign sda = 0;

    VGA_I2C_ISP DUT (
        .clk(clk),
        .reset(reset),
        .ov7670_xclk(ov7670_xclk),  //20Mhz
        .ov7670_pclk(ov7670_pclk),
        .ov7670_href(ov7670_href),
        .ov7670_v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .scl(scl),
        .sda(sda),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .vga_port(vga_port)
    );
    logic sda_w;
    assign sda_w = 0;
    assign sda   = sda_w;

    always #1 clk = ~clk;

    initial begin
        #00 clk = 0;
        reset = 1; ov7670_data =16'hf0f0;
        #10 reset = 0;

    end
endmodule

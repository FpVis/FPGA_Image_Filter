`timescale 1ns / 1ps

module up_scaling (
    input  logic        clk_25,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    //output 
    output logic [11:0] out_buffer,
    //vga
    input  logic [11:0] buffer
);

    logic [5:0] red, blue;
    logic [6:0] green;
    logic [11:0] h_mem[640-1];
    logic [11:0] buffer_prev;
    logic [11:0] buffer_reg;
    logic [5:0] red_sum;
    logic [6:0] green_sum;
    logic [5:0] blue_sum;

    integer i;

    always_ff @(posedge clk_25, posedge reset) begin
        if (reset) begin
            buffer_prev <= 0;
            buffer_reg  <= 0;
            for (i = 0; i < 640; i = i + 1) begin
                h_mem[i] <= 0;
            end
        end else begin
            // buffer_reg  <= buffer;
            // buffer_prev <= buffer_reg;
            buffer_prev <= buffer;
            if (x_pixel < 640) begin
                if (x_pixel > 0) begin
                    h_mem[x_pixel] <= out_buffer;
                end else begin
                    h_mem[x_pixel] <= buffer;
                end
            end
        end
    end

    always_comb begin
        if (x_pixel < 640 & y_pixel < 480) begin
            if ((x_pixel > 0) | (y_pixel > 0)) begin
                if (y_pixel[0] == 0) begin
                    red_sum = ({h_mem[x_pixel][11:8]} + {buffer[11:8]});
                    green_sum = ({h_mem[x_pixel][7:4]} + {buffer[7:4]});
                    blue_sum = ({h_mem[x_pixel][3:0]} + {buffer[3:0]});
                    red = red_sum >> 1;
                    green = green_sum >> 1;
                    blue = blue_sum >> 1;
                    out_buffer = {red[3:0], green[3:0], blue[3:0]};
                end else begin
                    if (x_pixel[0] == 0) begin
                        red_sum = ({buffer_prev[11:8]} + {buffer[11:8]});
                        green_sum = ({buffer_prev[7:4]} + {buffer[7:4]});
                        blue_sum = ({buffer_prev[3:0]} + {buffer[3:0]});
                        red = red_sum >> 1;
                        green = green_sum >> 1;
                        blue = blue_sum >> 1;
                        out_buffer = {red[3:0], green[3:0], blue[3:0]};
                    end else begin
                        out_buffer = buffer;
                    end
                end
            end else begin
                out_buffer = buffer;
            end
        end else begin
            out_buffer = 0;
        end
    end

endmodule



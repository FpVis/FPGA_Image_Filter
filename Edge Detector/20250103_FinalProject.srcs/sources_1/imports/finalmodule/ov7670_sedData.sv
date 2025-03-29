`timescale 1ns / 1ps

module ov7670_setData (
    input  logic        pclk,
    input  logic        reset,
    // ov7670 signal
    input  logic        href,
    input  logic        v_sync,
    input  logic [ 7:0] ov7670_data,
    // frame buffer signal
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wData
);

    logic [15:0] temp_reg, temp_next;
    logic [9:0] pix_counter_reg, pix_counter_next;
    logic [7:0] v_counter_reg, v_counter_next;
    logic we_reg, we_next;

    assign we   = we_reg;
    assign wData = temp_reg;
    assign wAddr = v_counter_reg * 320 + pix_counter_reg[9:1]-1;

    always_ff @(posedge pclk, posedge reset) begin
        if (reset) begin
            temp_reg        <= 0;
            pix_counter_reg <= 0;
            we_reg          <= 0;
            v_counter_reg   <= 0;
        end else begin
            temp_reg        <= temp_next;
            pix_counter_reg <= pix_counter_next;
            we_reg          <= we_next;
            v_counter_reg   <= v_counter_next;
        end
    end

    always_comb begin
        we_next          = we_reg;
        temp_next        = temp_reg;
        pix_counter_next = pix_counter_reg;
        if (href) begin
            pix_counter_next = pix_counter_reg + 1;
            if (!pix_counter_reg[0]) begin
                temp_next[15:8] = ov7670_data;
                we_next         = 0;
            end else begin
                temp_next[7:0] = ov7670_data;
                we_next        = 1;
            end
        end else begin
            we_next          = 0;
            temp_next        = 0;
            pix_counter_next = 0;
        end
    end

    always_comb begin
        v_counter_next = v_counter_reg;
        if (!v_sync) begin
            if (pix_counter_reg == 640-1 ) begin
                v_counter_next = v_counter_reg + 1;
            end
        end else begin
            v_counter_next = 0;
        end

    end
endmodule

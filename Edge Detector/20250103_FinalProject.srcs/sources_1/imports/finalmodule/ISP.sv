`timescale 1ns / 1ps
/*
module TOP_ISP (
    input  logic        isp_clk,      // 100MHZ
    input  logic        vga_clk,      // 25MHz
    input  logic        reset,
    input  logic        h_sync,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        disp_enable,
    //framBuffer access
    output logic        r_en,
    output logic [16:0] rAddr,
    input  logic [ 3:0] rData,
    // 444data
    output logic [11:0] vga_data
);
    logic [3:0] outData;

    assign vga_data = {outData, outData, outData};

    qvga_addr_decoder U_qvga_addr_decoder (
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .r_en(r_en),
        .rAddr(rAddr)
    );

    ISP_lineBuffer U_ISP_lineBuffer (
        .wclk   (isp_clk),    //isp_clk
        .rclk   (vga_clk),     //vga_clk
        .reset  (reset),
        .h_sync (h_sync),
        .wData  (rData),
        .rAddr  (x_pixel),  //x_pixel
        .outData(outData)   //rgb565
    );

endmodule

module ISP_lineBuffer (
    // write side
    input  logic       wclk,    //isp_clk
    input              reset,
    input  logic       h_sync,
    input  logic [3:0] wData,
    // read side
    input  logic       rclk,    //vga_clk
    input  logic [9:0] rAddr,   //x_pixel
    output logic [3:0] outData  //rgb565
);
    //(* ramstyle = "block" *)

    logic [3:0] tempBuffer[0:319];
    logic [3:0] lineBuffer[0:2][0:639];  // 3개의 라인, 320 픽셀
    logic [3:0] currentLine[0:639];  // 현재 라인(채우고 있는 라인)
    logic [3:0] window[0:8];  // 3×3 윈도우
    logic [3:0] gaussian_data;
    logic [3:0] rData_reg;

    logic line_ready;
    logic [10:0] h_cnt, h_cnt_avg;

    always_ff @(posedge wclk, posedge reset) begin
        if (reset) begin
            h_cnt <= 0;
            h_cnt_avg <= 0;
            line_ready <= 0;
            lineBuffer[0] <= '{default: 0};
            lineBuffer[1] <= '{default: 0};
            lineBuffer[2] <= '{default: 0};
        end else begin
            if (!line_ready) begin
                if (rAddr >= 320) begin
                    line_ready <= 1;
                end else begin
                    tempBuffer[rAddr] <= wData;
                end
            end

            if (!h_sync) begin
                if (line_ready) begin
                    if (h_cnt >= 320) begin
                        if (h_cnt_avg >= 320) begin
                            line_ready <= 0;
                            h_cnt <= 0;
                            h_cnt_avg <= 0;
                            lineBuffer[0] <= lineBuffer[1];
                            lineBuffer[1] <= lineBuffer[2];
                            lineBuffer[2] <= currentLine;
                        end else begin
                            currentLine[(2*h_cnt_avg)+1] <= (currentLine[(2*h_cnt_avg)] + currentLine[(2*h_cnt_avg)+2]) / 2;
                            h_cnt_avg <= h_cnt_avg + 1;
                        end
                    end else begin
                        currentLine[2*h_cnt] <= tempBuffer[h_cnt];
                        h_cnt <= h_cnt + 1;
                    end
                end
            end
            outData <= rData_reg;

        end
    end

    
    always_ff @(posedge wclk) begin
        if (reset) begin
            // 라인 버퍼 초기화
            lineBuffer[0] <= '{default: 0};
            lineBuffer[1] <= '{default: 0};
            lineBuffer[2] <= '{default: 0};
        end else if (t_done_reg) begin
            // 라인 버퍼 업데이트
            lineBuffer[0] <= lineBuffer[1];
            lineBuffer[1] <= lineBuffer[2];
            lineBuffer[2] <= currentLine;
        end
    end
    

    always_comb begin
        window[0] = lineBuffer[0][rAddr-1];
        window[1] = lineBuffer[0][rAddr];
        window[2] = lineBuffer[0][rAddr+1];
        window[3] = lineBuffer[1][rAddr-1];
        window[4] = lineBuffer[1][rAddr];
        window[5] = lineBuffer[1][rAddr+1];
        window[6] = lineBuffer[2][rAddr-1];
        window[7] = lineBuffer[2][rAddr];
        window[8] = lineBuffer[2][rAddr+1];
    end

    gaussian_filter U_gaussian_filter (
        .clk      (wclk),
        .data_00  (window[0]),     // Top-left pixel (Gray)
        .data_01  (window[1]),     // Top-center pixel (Gray)
        .data_02  (window[2]),     // Top-right pixel (Gray)
        .data_10  (window[3]),     // Middle-left pixel (Gray)
        .data_11  (window[4]),     // Center pixel (Gray)
        .data_12  (window[5]),     // Middle-right pixel (Gray)
        .data_20  (window[6]),     // Bottom-left pixel (Gray)
        .data_21  (window[7]),     // Bottom-center pixel (Gray)
        .data_22  (window[8]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data)  // Filtered output (Gray)
    );

    sobel_filter_with_nms U_sobel_filter_with_nms (
        .clk      (wclk),
        .data_00  (window[0]),      // Top-left pixel (Gray)
        .data_01  (window[1]),      // Top-center pixel (Gray)
        .data_02  (window[2]),      // Top-right pixel (Gray)
        .data_10  (window[3]),      // Middle-left pixel (Gray)
        .data_11  (gaussian_data),  // Center pixel (Gray)
        .data_12  (window[5]),      // Middle-right pixel (Gray)
        .data_20  (window[6]),      // Bottom-left pixel (Gray)
        .data_21  (window[7]),      // Bottom-center pixel (Gray)
        .data_22  (window[8]),      // Bottom-right pixel (Gray)
        .pixel_out(rData_reg)       // Binary edge output (0 or 1)
    );

    
endmodule
*/


module TOP_ISP (
    input  logic        isp_clk,      // 100MHZ
    input  logic        vga_clk,      // 25MHz
    input  logic        reset,
    input  logic        h_sync,
    input  logic        v_sync,
    input  logic [ 9:0] x_pixel,
    input  logic        disp_enable,
    //framBuffer access
    output logic        r_en,
    output logic [16:0] rAddr,
    input  logic [ 4:0] rData,
    // 444data
    input               switch,
    input        [ 8:0] th_switch,
    output logic [11:0] vga_data
);

    logic we, t_done;
    logic [9:0] wAddr;
    logic [3:0] gray;

    ISP_decoder U_ISP_decoder (
        .clk        (isp_clk),
        .reset      (reset),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .disp_enable(disp_enable),
        // frameBuffer access
        .r_en       (r_en),
        .rAddr      (rAddr),
        //lineBuffer Access
        .w_en       (we),
        .wAddr      (wAddr),
        .t_done     (t_done)
    );


    line_Buffer U_line_Buffer (
        .reset    (reset),
        // write side
        .wclk     (isp_clk),      //isp_clk
        .we       (we),           //isp_we
        .wAddr    (wAddr),        //0~639
        .wData    (rData),        //ispData
        // read side
        .rclk     (vga_clk),      //vga_clk
        .oe       (disp_enable),  //dispEn
        .t_done   (t_done),
        .rAddr    (x_pixel),      //x_pixel
        .rData    (gray),
        .switch   (switch),       //gray
        .th_switch(th_switch)
    );


    gray_to_444 U_gray_to_444 (
        .gray(gray),
        .vga_port(vga_data)
    );

endmodule

module ISP_decoder (
    input  logic        clk,
    input  logic        reset,
    input  logic        h_sync,
    input  logic        v_sync,
    input  logic        disp_enable,
    // frameBuffer access
    output logic        r_en,
    output logic [16:0] rAddr,
    //lineBuffer Access
    output logic        w_en,
    output logic [ 9:0] wAddr,
    output logic        t_done
);
    localparam QVGA_H_PIX_MAX = 320;
    localparam QVGA_V_LINE_MAX = 480;

    typedef enum {
        IDLE,
        WAIT_INIT,
        START_INIT,
        WAIT_NORMAL,
        DATA_READ,
        DATA_TRANS,
        H_COMPLETE,
        V_CHECK,
        FIRST_LINE_READ,
        FIRST_LINE_TRANS,
        WAIT_FIRST_LINE
    } state_s;
    state_s state, state_next;

    logic [8:0] v_cnt_reg, v_cnt_next;
    logic [8:0] h_cnt_reg, h_cnt_next;
    logic r_en_reg, r_en_next;
    logic w_en_reg, w_en_next;
    logic t_done_reg, t_done_next;

    assign rAddr  = v_cnt_reg[8:1] * 320 + h_cnt_reg;
    assign r_en   = r_en_reg;
    assign w_en   = w_en_reg;
    assign t_done = t_done_reg;

    assign wAddr  = h_cnt_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            v_cnt_reg  <= 0;
            h_cnt_reg  <= 0;
            r_en_reg   <= 0;
            w_en_reg   <= 0;
            t_done_reg <= 0;
        end else begin
            state      <= state_next;
            v_cnt_reg  <= v_cnt_next;
            h_cnt_reg  <= h_cnt_next;
            r_en_reg   <= r_en_next;
            w_en_reg   <= w_en_next;
            t_done_reg <= t_done_next;
        end
    end

    always_comb begin
        state_next  = state;
        v_cnt_next  = v_cnt_reg;
        h_cnt_next  = h_cnt_reg;
        r_en_next   = r_en_reg;
        w_en_next   = w_en_reg;
        t_done_next = t_done_reg;
        case (state)
            IDLE: begin
                v_cnt_next  = 0;
                h_cnt_next  = 0;
                t_done_next = 0;
                if (!h_sync && !v_sync) begin
                    state_next = WAIT_INIT;
                end
            end
            WAIT_INIT: begin
                if (disp_enable) begin
                    state_next = START_INIT;
                end
            end
            START_INIT: begin
                if (!h_sync) begin
                    v_cnt_next = 1;
                    h_cnt_next = 0;
                    state_next = DATA_READ;
                end
            end
            WAIT_NORMAL: begin
                t_done_next = 0;
                if (!h_sync) begin
                    state_next = DATA_READ;
                end
            end
            DATA_READ: begin
                r_en_next  = 1;
                w_en_next  = 1;
                state_next = DATA_TRANS;
            end
            DATA_TRANS: begin
                r_en_next = 0;
                w_en_next = 0;
                if (h_cnt_reg == QVGA_H_PIX_MAX) begin
                    state_next = V_CHECK;
                    h_cnt_next = 0;
                end else begin
                    state_next = DATA_READ;
                    h_cnt_next = h_cnt_reg + 1;
                end
            end
            V_CHECK: begin
                if (h_sync) begin
                    t_done_next = 1;
                    if (v_cnt_reg == QVGA_V_LINE_MAX - 1) begin
                        v_cnt_next = 0;
                        state_next = WAIT_FIRST_LINE;
                    end else begin
                        v_cnt_next = v_cnt_reg + 1;
                        state_next = WAIT_NORMAL;
                    end
                end
            end
            WAIT_FIRST_LINE: begin
                t_done_next = 0;
                if (!h_sync) begin
                    state_next = FIRST_LINE_READ;
                end
            end
            FIRST_LINE_READ: begin
                r_en_next  = 1;
                w_en_next  = 1;
                state_next = FIRST_LINE_TRANS;
            end
            FIRST_LINE_TRANS: begin
                r_en_next = 0;
                w_en_next = 0;
                if (h_cnt_reg == QVGA_H_PIX_MAX) begin
                    state_next  = IDLE;
                    t_done_next = 1;
                    h_cnt_next  = 0;
                end else begin
                    state_next = FIRST_LINE_READ;
                    h_cnt_next = h_cnt_reg + 1;
                end
            end
        endcase
    end

endmodule


module line_Buffer (
    input              reset,
    // write side
    input  logic       wclk,      //isp_clk
    input  logic       we,        //isp_we
    input  logic [9:0] wAddr,     //0~639
    input  logic [4:0] wData,     //ispData
    // read side
    input  logic       rclk,      //vga_clk
    input  logic       t_done,
    input  logic       oe,        //dispEn
    input  logic [9:0] rAddr,     //x_pixel
    output logic [3:0] rData,     //rgb565
    input  logic       switch,
    input  logic [8:0] th_switch
);
    //(* ramstyle = "block" *) 
    logic [4:0] lineBuffer[0:4][0:639];  // 3개의 라인, 320 픽셀
    logic [4:0] currentLine[0:639];  // 현재 라인(채우고 있는 라인)
    logic [4:0] window[0:24];  // 3×3 윈도우
    logic [4:0]
        gaussian_data1,
        gaussian_data2,
        gaussian_data3,
        gaussian_data4,
        gaussian_data5,
        gaussian_data6,
        gaussian_data7,
        gaussian_data8,
        gaussian_data9;
    logic [3:0] rData_reg, canny_data;

    always_ff @(posedge wclk) begin
        if (we) begin
            currentLine[2*wAddr]   <= wData;
            currentLine[2*wAddr+1] <= wData;
        end
    end

    always_ff @(posedge rclk) begin
        if (oe) begin
            rData <= rData_reg;
        end
    end

    always_ff @(posedge wclk) begin
        if (reset) begin
            // 라인 버퍼 초기화
            lineBuffer[0] <= '{default: 0};
            lineBuffer[1] <= '{default: 0};
            lineBuffer[2] <= '{default: 0};
            lineBuffer[3] <= '{default: 0};
            lineBuffer[4] <= '{default: 0};
        end else if (t_done) begin
            // 라인 버퍼 업데이트
            lineBuffer[0] <= lineBuffer[1];
            lineBuffer[1] <= lineBuffer[2];
            lineBuffer[2] <= lineBuffer[3];
            lineBuffer[3] <= lineBuffer[4];
            lineBuffer[4] <= currentLine;
        end
    end

    always_ff @(posedge wclk) begin
        window[0]  <= lineBuffer[0][rAddr-2];
        window[1]  <= lineBuffer[0][rAddr-1];
        window[2]  <= lineBuffer[0][rAddr];
        window[3]  <= lineBuffer[0][rAddr+1];
        window[4]  <= lineBuffer[0][rAddr+2];
        window[5]  <= lineBuffer[1][rAddr-2];
        window[6]  <= lineBuffer[1][rAddr-1];
        window[7]  <= lineBuffer[1][rAddr];
        window[8]  <= lineBuffer[1][rAddr+1];
        window[9]  <= lineBuffer[1][rAddr+2];
        window[10] <= lineBuffer[2][rAddr-2];
        window[11] <= lineBuffer[2][rAddr-1];
        window[12] <= lineBuffer[2][rAddr];
        window[13] <= lineBuffer[2][rAddr+1];
        window[14] <= lineBuffer[2][rAddr+2];
        window[15] <= lineBuffer[3][rAddr-2];
        window[16] <= lineBuffer[3][rAddr-1];
        window[17] <= lineBuffer[3][rAddr];
        window[18] <= lineBuffer[3][rAddr+1];
        window[19] <= lineBuffer[3][rAddr+2];
        window[20] <= lineBuffer[4][rAddr-2];
        window[21] <= lineBuffer[4][rAddr-1];
        window[22] <= lineBuffer[4][rAddr];
        window[23] <= lineBuffer[4][rAddr+1];
        window[24] <= lineBuffer[4][rAddr+2];
    end


    gaussian_filter U_gaussian_filter_1 (
        .clk      (wclk),
        .data_00  (window[0]),      // Top-left pixel (Gray)
        .data_01  (window[1]),      // Top-center pixel (Gray)
        .data_02  (window[2]),      // Top-right pixel (Gray)
        .data_10  (window[5]),      // Middle-left pixel (Gray)
        .data_11  (window[6]),      // Center pixel (Gray)
        .data_12  (window[7]),      // Middle-right pixel (Gray)
        .data_20  (window[10]),     // Bottom-left pixel (Gray)
        .data_21  (window[11]),     // Bottom-center pixel (Gray)
        .data_22  (window[12]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data1)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_2 (
        .clk      (wclk),
        .data_00  (window[1]),      // Top-left pixel (Gray)
        .data_01  (window[2]),      // Top-center pixel (Gray)
        .data_02  (window[3]),      // Top-right pixel (Gray)
        .data_10  (window[6]),      // Middle-left pixel (Gray)
        .data_11  (window[7]),      // Center pixel (Gray)
        .data_12  (window[8]),      // Middle-right pixel (Gray)
        .data_20  (window[11]),     // Bottom-left pixel (Gray)
        .data_21  (window[12]),     // Bottom-center pixel (Gray)
        .data_22  (window[13]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data2)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_3 (
        .clk      (wclk),
        .data_00  (window[2]),      // Top-left pixel (Gray)
        .data_01  (window[3]),      // Top-center pixel (Gray)
        .data_02  (window[4]),      // Top-right pixel (Gray)
        .data_10  (window[7]),      // Middle-left pixel (Gray)
        .data_11  (window[8]),      // Center pixel (Gray)
        .data_12  (window[9]),      // Middle-right pixel (Gray)
        .data_20  (window[12]),     // Bottom-left pixel (Gray)
        .data_21  (window[13]),     // Bottom-center pixel (Gray)
        .data_22  (window[14]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data3)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_4 (
        .clk      (wclk),
        .data_00  (window[5]),      // Top-left pixel (Gray)
        .data_01  (window[6]),      // Top-center pixel (Gray)
        .data_02  (window[7]),      // Top-right pixel (Gray)
        .data_10  (window[10]),     // Middle-left pixel (Gray)
        .data_11  (window[11]),     // Center pixel (Gray)
        .data_12  (window[12]),     // Middle-right pixel (Gray)
        .data_20  (window[15]),     // Bottom-left pixel (Gray)
        .data_21  (window[16]),     // Bottom-center pixel (Gray)
        .data_22  (window[17]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data4)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_5 (
        .clk      (wclk),
        .data_00  (window[6]),      // Top-left pixel (Gray)
        .data_01  (window[7]),      // Top-center pixel (Gray)
        .data_02  (window[8]),      // Top-right pixel (Gray)
        .data_10  (window[11]),     // Middle-left pixel (Gray)
        .data_11  (window[12]),     // Center pixel (Gray)
        .data_12  (window[13]),     // Middle-right pixel (Gray)
        .data_20  (window[16]),     // Bottom-left pixel (Gray)
        .data_21  (window[17]),     // Bottom-center pixel (Gray)
        .data_22  (window[18]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data5)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_6 (
        .clk      (wclk),
        .data_00  (window[7]),      // Top-left pixel (Gray)
        .data_01  (window[8]),      // Top-center pixel (Gray)
        .data_02  (window[9]),      // Top-right pixel (Gray)
        .data_10  (window[12]),     // Middle-left pixel (Gray)
        .data_11  (window[13]),     // Center pixel (Gray)
        .data_12  (window[14]),     // Middle-right pixel (Gray)
        .data_20  (window[17]),     // Bottom-left pixel (Gray)
        .data_21  (window[18]),     // Bottom-center pixel (Gray)
        .data_22  (window[19]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data6)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_7 (
        .clk      (wclk),
        .data_00  (window[10]),     // Top-left pixel (Gray)
        .data_01  (window[11]),     // Top-center pixel (Gray)
        .data_02  (window[12]),     // Top-right pixel (Gray)
        .data_10  (window[15]),     // Middle-left pixel (Gray)
        .data_11  (window[16]),     // Center pixel (Gray)
        .data_12  (window[17]),     // Middle-right pixel (Gray)
        .data_20  (window[20]),     // Bottom-left pixel (Gray)
        .data_21  (window[21]),     // Bottom-center pixel (Gray)
        .data_22  (window[22]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data7)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_8 (
        .clk      (wclk),
        .data_00  (window[11]),     // Top-left pixel (Gray)
        .data_01  (window[12]),     // Top-center pixel (Gray)
        .data_02  (window[13]),     // Top-right pixel (Gray)
        .data_10  (window[16]),     // Middle-left pixel (Gray)
        .data_11  (window[17]),     // Center pixel (Gray)
        .data_12  (window[18]),     // Middle-right pixel (Gray)
        .data_20  (window[21]),     // Bottom-left pixel (Gray)
        .data_21  (window[22]),     // Bottom-center pixel (Gray)
        .data_22  (window[23]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data8)  // Filtered output (Gray)
    );

    gaussian_filter U_gaussian_filter_9 (
        .clk      (wclk),
        .data_00  (window[12]),     // Top-left pixel (Gray)
        .data_01  (window[13]),     // Top-center pixel (Gray)
        .data_02  (window[14]),     // Top-right pixel (Gray)
        .data_10  (window[17]),     // Middle-left pixel (Gray)
        .data_11  (window[18]),     // Center pixel (Gray)
        .data_12  (window[19]),     // Middle-right pixel (Gray)
        .data_20  (window[22]),     // Bottom-left pixel (Gray)
        .data_21  (window[23]),     // Bottom-center pixel (Gray)
        .data_22  (window[24]),     // Bottom-right pixel (Gray)
        .pixel_out(gaussian_data9)  // Filtered output (Gray)
    );

    sobel_filter_with_nms U_sobel_filter_with_nms (
        .clk      (wclk),
        .data_00  (gaussian_data1),  // Top-left pixel (Gray)
        .data_01  (gaussian_data2),  // Top-center pixel (Gray)
        .data_02  (gaussian_data3),  // Top-right pixel (Gray)
        .data_10  (gaussian_data4),  // Middle-left pixel (Gray)
        .data_11  (gaussian_data5),  // Center pixel (Gray)
        .data_12  (gaussian_data6),  // Middle-right pixel (Gray)
        .data_20  (gaussian_data7),  // Bottom-left pixel (Gray)
        .data_21  (gaussian_data8),  // Bottom-center pixel (Gray)
        .data_22  (gaussian_data9),  // Bottom-right pixel (Gray)
        .pixel_out(canny_data),      // Binary edge output (0 or 1)
        .th_switch(th_switch)
    );

    MUX_2x1_4bit U_OUTPUT (
        .sel(switch),
        .x0 (window[4][4:1]),
        .x1 (gaussian_data5[4:1]),
        .y  (rData_reg)
    );


endmodule


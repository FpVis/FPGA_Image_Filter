`timescale 1ns / 1ps


module disparity_generator(
    input logic rclk,
    input logic vga_clk,
    input logic reset,
    input logic [11:0] wData1,
    input logic [11:0] wData2,
    input logic [14:0] rAddr,
    input logic oe,
    input logic [9:0] x_pixel,
    output logic [15:0] DisplayData
    );
    assign DisplayData = displayBuffer[x_pixel[9:2]];
    assign sad = sad_reg;
    
    localparam DISPARITY_MAX = 15, FOCAL_LENGTH = 2000, BASELINE = 1;
    logic [11:0] leftBuffer [0 : 159];
    logic [11:0] rightBuffer [0 : 159];
    logic [15:0] displayBuffer[0 : 159]; 
     
    logic [11:0] rData1, rData2;
    
    logic [1:0] state, state_next;
    logic [5:0] disparity, disparity_next;
    logic [15:0] sad, sad_reg, sad_next;
    logic [15:0] best_disp, best_disp_next, best_score, best_score_next;
    logic [14:0] rAddr1, rAddr1_next, rAddr2, rAddr2_next;
    logic rowLineEnd, rowLineEnd_next;
    
    always_ff @(posedge vga_clk, posedge reset) begin
        if(reset)begin
            
        end
        else begin
            if(oe) begin
                leftBuffer[rAddr%160] <= wData1;
                rightBuffer[rAddr%160] <= wData2;
            end
        end
    end
    
    always_ff @ (posedge rclk, posedge reset) begin
        if(reset)begin
            state <= 0;
            disparity <= 0;
            sad_reg <= 0;
            best_disp <= 0; 
            rAddr1 <= 0;
            rAddr2 <= 0;
            best_score <= 16'hffff;
            rowLineEnd <= 0;
        end
        else begin
            state <= state_next;
            disparity <= disparity_next;
            sad_reg <= sad_next;
            best_disp <= best_disp_next;
            best_score <= best_score_next;
            rAddr1 <= rAddr1_next;
            rAddr2 <= rAddr2_next;
            rData1 <= leftBuffer[rAddr1];
            rData2 <= rightBuffer[rAddr2];
            rowLineEnd <= rowLineEnd_next;
        end 
    end
       
    always_comb begin
        state_next = state;
        disparity_next = disparity;
        sad_next = sad_reg;
        best_disp_next = best_disp;
        best_score_next = best_score;
        rAddr1_next = rAddr1;
        rAddr2_next = rAddr2;
        rowLineEnd_next = rowLineEnd;
        
        case(state)
            0 : begin
                //rowLineEnd_next = 0;
                if(rAddr % 160 == 159) begin
                    state_next = 1;
                    rAddr1_next = 0;
                    rAddr2_next = 0;
                end
            end
            1 : begin
                if(disparity == DISPARITY_MAX) begin
                    state_next = 2;
                end
                else begin
                    sad_next = (rData1 > rData2) ? ((rData1 - rData2)) : ((rData2 - rData1));
                    disparity_next = disparity + 1;
                    rAddr2_next = rAddr2 + 1;
                    if(sad_next < best_score) begin
                        best_score_next = sad_next;
                        best_disp_next = disparity;
                    end
                    state_next = 1;
                end
        
//                if(disparity == DISPARITY_MAX)begin
//                    state_next = 2;
//                end 
//                else begin
//                    sad_reg = (rData1 > rData2) ? ((rData1 - rData2)) : ((rData2 - rData1) );
//                    if(sad_reg < best_score) begin
//                        best_score_next = sad;  
//                        best_disp_next = disparity;
//                        disparity_next = disparity + 1;
//                        rAddr2_next = rAddr2 + 1;
//                        state_next = 1;
//                    end
//                    else begin
//                        state_next = 2;
//                    end
//                end
            end
            2 : begin
                if(rAddr1 == 159) begin
                    state_next = 0;
                    //rowLineEnd_next = 1;
                    displayBuffer[rAddr1] = (FOCAL_LENGTH * BASELINE) / best_disp;
                    disparity_next = 0;
                end
                else begin
                    rAddr1_next = rAddr1 + 1;
                    rAddr2_next = rAddr1 + 1;
                    state_next = 1;
                    disparity_next = 0;
                    best_score_next = 16'hffff;
                    if(best_disp != 0) displayBuffer[rAddr1] = (FOCAL_LENGTH * BASELINE) / best_disp;
                    else displayBuffer[rAddr1] = 16'hffff;
                end
            end
        endcase
    end
    
    ila_0 your_instance_name (
	.clk(rclk), // input wire clk
	.probe0(wData1), // input wire [11:0]  probe0  
	.probe1(wData2), // input wire [11:0]  probe1 
	.probe2(rAddr), // input wire [14:0]  probe2 
	.probe3(oe), // input wire [0:0]  probe3 
	.probe4(x_pixel), // input wire [9:0]  probe4 
	.probe5(DisplayData), // input wire [15:0]  probe5 
	.probe6(rData1), // input wire [15:0]  probe6 
	.probe7(rData2), // input wire [15:0]  probe7 
	.probe8(state), // input wire [1:0]  probe8 
	.probe9(disparity), // input wire [5:0]  probe9 
	.probe10(sad), // input wire [15:0]  probe10 
	.probe11(best_disp), // input wire [15:0]  probe11 
	.probe12(rAddr1), // input wire [14:0]  probe12 
	.probe13(rAddr2), // input wire [14:0]  probe13 
	.probe14(vga_clk) // input wire [0:0]  probe14
);
endmodule

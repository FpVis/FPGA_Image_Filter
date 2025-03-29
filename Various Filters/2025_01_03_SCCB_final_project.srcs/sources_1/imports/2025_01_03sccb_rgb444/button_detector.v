`timescale 1ns / 1ps

module button_detector (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);
    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk,edge_reg;
    reg[7:0] q_reg,q_next;
    wire w_debounce;
    
    //clock div
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
    
    //debounce circuit
    always @(posedge r_clk, posedge reset) begin
        if (reset) q_reg<=0; 
        else q_reg <= q_next;
    end
    always @(i_btn, q_reg) begin
        q_next= {i_btn,q_reg[7:1]}; //shift register
    end
    assign w_debounce = &q_reg; //all and 



    //edge detector flip flop
    always @(posedge clk) begin
       edge_reg <= w_debounce; 
    end
    assign o_btn=w_debounce & ~edge_reg; // rising edge detector

endmodule

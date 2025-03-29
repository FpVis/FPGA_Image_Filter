`timescale 1ns / 1ps


module MUX_8x1_12bit (
    input  logic [ 3:0] sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    input  logic [11:0] x3,
    input  logic [11:0] x4,
    input  logic [11:0] x5,
    input  logic [11:0] x6,
    input  logic [11:0] x7,
    output logic [11:0] y
);

    always @(*) begin  // 입력값 모두 감시
        case (sel)
            3'b000:  y = x0;
            3'b001:  y = x1;
            3'b010:  y = x2;
            3'b011:  y = x3;
            3'b100:  y = x4;
            3'b101:  y = x5;
            3'b110:  y = x6;
            3'b111:  y = x7;
            default: y = 12'bx;
        endcase
    end

endmodule

module MUX_2x1_12bit (
    input  logic        sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    output logic [11:0] y
);

    always @(*) begin  // 입력값 모두 감시
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
            default: y = 12'bx;
        endcase
    end

endmodule

module MUX_2x1_4bit (
    input  logic        sel,
    input  logic [3:0] x0,
    input  logic [3:0] x1,
    output logic [3:0] y
);

    always @(*) begin  // 입력값 모두 감시
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
            default: y = 4'bx;
        endcase
    end

endmodule

module MUX_4x1_12bit (
    input  logic [ 1:0] sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    input  logic [11:0] x3,
    output logic [11:0] y
);

    always @(*) begin  // 입력값 모두 감시
        case (sel)
            2'b00:   y = x0;
            2'b01:   y = x1;
            2'b10:   y = x2;
            2'b11:   y = x3;
            default: y = 12'bx;
        endcase
    end

endmodule

module MUX_2x1_1bit (
    input  logic sel,
    input  logic x0,
    input  logic x1,
    output logic y
);

    always @(*) begin  // 입력값 모두 감시
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
            default: y = 1'bx;
        endcase
    end
endmodule

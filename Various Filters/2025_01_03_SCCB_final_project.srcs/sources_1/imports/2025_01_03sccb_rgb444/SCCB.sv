`timescale 1ns / 1ps


module camera_configure
    #(
    parameter CLK_FREQ=100000000
    )
    (
    input wire clk,
    input wire start,
    output wire sioc,
    output wire siod,
    output wire done
    );
    
    wire [7:0] rom_addr;
    wire [15:0] rom_dout;
    wire [7:0] SCCB_addr;
    wire [7:0] SCCB_data;
    wire SCCB_start, w_start;
    wire SCCB_ready;
    wire SCCB_SIOC_oe;
    wire SCCB_SIOD_oe;
    
    assign sioc = SCCB_SIOC_oe ? 1'b0 : 1'bZ;
    assign siod = SCCB_SIOD_oe ? 1'b0 : 1'bZ;
    
    OV7670_config_rom rom1(
        .clk(clk),
        .addr(rom_addr),
        .dout(rom_dout)
        );
    
    button_detector U_button_detector(
    .clk(clk),
    .reset(reset),
    .i_btn(start),
    .o_btn(w_start)
    );

    OV7670_config #(.CLK_FREQ(CLK_FREQ)) config_1(
        .clk(clk),
        .SCCB_interface_ready(SCCB_ready),
        .rom_data(rom_dout),
        .start(w_start),
        .rom_addr(rom_addr),
        .done(done),
        .SCCB_interface_addr(SCCB_addr),
        .SCCB_interface_data(SCCB_data),
        .SCCB_interface_start(SCCB_start)
        );
    
    sccb #( .CLK_FREQ(CLK_FREQ)) SCCB1(
        .clk(clk),
        .start(SCCB_start),
        .address(SCCB_addr),
        .data(SCCB_data),
        .ready(SCCB_ready),
        .SIOC_oe(SCCB_SIOC_oe),
        .SIOD_oe(SCCB_SIOD_oe)
        );
    
endmodule

module camera_read (
    input  logic        p_clock,
    input  logic        vsync,
    input  logic        href,
    input  logic [ 7:0] p_data,
    output logic [15:0] pixel_data,
    output logic        pixel_valid,
    output logic        frame_done
);


    reg [1:0] FSM_state = 0;
    reg pixel_half = 0;

    localparam WAIT_FRAME_START = 0;
    localparam ROW_CAPTURE = 1;


    always @(posedge p_clock) begin

        case (FSM_state)

            WAIT_FRAME_START: begin  //wait for VSYNC
                FSM_state  <= (!vsync) ? ROW_CAPTURE : WAIT_FRAME_START;
                frame_done <= 0;
                pixel_half <= 0;
            end

            ROW_CAPTURE: begin
				pixel_data <= 0;
				pixel_valid <= 0;
				frame_done <= 0;
                FSM_state   <= vsync ? WAIT_FRAME_START : ROW_CAPTURE;
                frame_done  <= vsync ? 1 : 0;
                pixel_valid <= (href && pixel_half) ? 1 : 0;
                if (href) begin
                    pixel_half <= ~pixel_half;
                    if (pixel_half) pixel_data[7:0] <= p_data;
                    else pixel_data[15:8] <= p_data;
                end
            end


        endcase
    end

endmodule

module OV7670_config
#(
    parameter CLK_FREQ = 25000000
)
(
    input wire clk,
    input wire SCCB_interface_ready,
    input wire [15:0] rom_data,
    input wire start,
    output reg [7:0] rom_addr,
    output reg done,
    output reg [7:0] SCCB_interface_addr,
    output reg [7:0] SCCB_interface_data,
    output reg SCCB_interface_start
    );
    
    initial begin
        rom_addr = 0;
        done = 0;
        SCCB_interface_addr = 0;
        SCCB_interface_data = 0;
        SCCB_interface_start = 0;
    end
    
    localparam FSM_IDLE = 0;
    localparam FSM_SEND_CMD = 1;
    localparam FSM_DONE = 2;
    localparam FSM_TIMER = 3;
    
    reg [2:0] FSM_state = FSM_IDLE;
    reg [2:0] FSM_return_state;
    reg [31:0] timer = 0; 
    
    always@(posedge clk) begin
    
        case(FSM_state)
            
            FSM_IDLE: begin 
                FSM_state <= start ? FSM_SEND_CMD : FSM_IDLE;
                rom_addr <= 0;
                done <= start ? 0 : done;
            end
            
            FSM_SEND_CMD: begin 
                case(rom_data)
                    16'hFFFF: begin //end of ROM
                        FSM_state <= FSM_DONE;
                    end
                    
                    16'hFFF0: begin //delay state 
                        timer <= (CLK_FREQ/100); //10 ms delay
                        FSM_state <= FSM_TIMER;
                        FSM_return_state <= FSM_SEND_CMD;
                        rom_addr <= rom_addr + 1;
                    end
                    
                    default: begin //normal rom commands
                        if (SCCB_interface_ready) begin
                            FSM_state <= FSM_TIMER;
                            FSM_return_state <= FSM_SEND_CMD;
                            timer <= 0; //one cycle delay gives ready chance to deassert
                            rom_addr <= rom_addr + 1;
                            SCCB_interface_addr <= rom_data[15:8];
                            SCCB_interface_data <= rom_data[7:0];
                            SCCB_interface_start <= 1;
                        end
                    end
                endcase
            end
                        
            FSM_DONE: begin //signal done 
                FSM_state <= FSM_IDLE;
                done <= 1;
            end
                           
                
            FSM_TIMER: begin //count down and jump to next state
                FSM_state <= (timer == 0) ? FSM_return_state : FSM_TIMER;
                timer <= (timer==0) ? 0 : timer - 1;
                SCCB_interface_start <= 0;
            end
        endcase
    end
endmodule

module OV7670_config_rom(
    input wire clk,
    input wire [7:0] addr,
    output reg [15:0] dout
    );
    always @(posedge clk) begin
    case(addr) 
        
    0:  dout <= 16'h12_80; //reset 
    1:  dout <= 16'hFF_F0; //delay
    2:  dout <= 16'h12_14; // COM7,     set RGB color output
    3:  dout <= 16'h11_80; // CLKRC     internal PLL matches input clock
    4:  dout <= 16'h0C_00; // COM3,     default settings
    5:  dout <= 16'h3E_00; // COM14,    no scaling, normal pclock
    6:  dout <= 16'h04_00; // COM1,     disable CCIR656     
    7:  dout <= 16'h40_d0; //COM15,     RGB565, full output range
    8:  dout <= 16'h3a_04; //TSLB       set correct output data sequence (magic)
    9:  dout <= 16'h14_18; //COM9       MAX AGC value x4
    10: dout <= 16'h4F_B3; //MTX1       all of these are magical matrix coefficients
    11: dout <= 16'h50_B3; //MTX2
    12: dout <= 16'h51_00; //MTX3
    13: dout <= 16'h52_3d; //MTX4
    14: dout <= 16'h53_A7; //MTX5
    15: dout <= 16'h54_E4; //MTX6
    16: dout <= 16'h58_9E; //MTXS
    17: dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
    18: dout <= 16'h17_14; //HSTART   14 -> 15  start high 8 bits 이거만 바꾸면 멈춤 + 초록, 마젠타타
    19: dout <= 16'h18_02; //HSTOP    02 -> 03  stop high 8 bits //these kill the odd colored line
    20: dout <= 16'h32_91; //HREF     80 -> 91  edge offset
    21: dout <= 16'h19_03; //VSTART     start high 8 bits
    22: dout <= 16'h1A_7B; //VSTOP      stop high 8 bits
    23: dout <= 16'h03_00; //VREF     0a -> 00  vsync edge offset 전체적 밝기, 명암비 상승
    24: dout <= 16'h0F_41; //COM6       reset timings
    25: dout <= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
    26: dout <= 16'h33_8f; //CHLF       //magic value ft:nternet
    27: dout <= 16'h3C_78; //COM12      no HREF when VSYNC low
    28: dout <= 16'h69_00; //GFIX       fix gain control
    29: dout <= 16'h74_00; //REG74      Digital gain control
    30: dout <= 16'hB0_84; //RSVD       magic value ft:nternet *required* for good color
    31: dout <= 16'hB1_0c; //ABLC1
    32: dout <= 16'hB2_0e; //RSVD       more magic internet values
    33: dout <= 16'hB3_80; //THL_ST
    //begin mystery scaling numbers
    34: dout <= 16'h70_3a;
    35: dout <= 16'h71_35;
    36: dout <= 16'h72_11;
    37: dout <= 16'h73_f0;
    38: dout <= 16'ha2_02;
    //gamma curve values
    39: dout <= 16'h7a_20;
    40: dout <= 16'h7b_10;
    41: dout <= 16'h7c_1e;
    42: dout <= 16'h7d_35;
    43: dout <= 16'h7e_5a;
    44: dout <= 16'h7f_69;
    45: dout <= 16'h80_76;
    46: dout <= 16'h81_80;
    47: dout <= 16'h82_88;
    48: dout <= 16'h83_8f;
    49: dout <= 16'h84_96;
    50: dout <= 16'h85_a3;
    51: dout <= 16'h86_af;
    52: dout <= 16'h87_c4;
    53: dout <= 16'h88_d7;
    54: dout <= 16'h89_e8;
    //AGC and AEC
    55: dout <= 16'h13_e0; //COM8, disable AGC / AEC
    56: dout <= 16'h00_00; //set gain reg to 0 for AGC
    57: dout <= 16'h10_60; //set ARCJ reg to 0
    58: dout <= 16'h0d_40; //magic reserved bit for COM4
    59: dout <= 16'h14_18; //COM9, 4x gain + magic bit
    60: dout <= 16'ha5_05; // BD50MAX
    61: dout <= 16'hab_07; //DB60MAX
    62: dout <= 16'h24_95; //AGC upper limit
    63: dout <= 16'h25_33; //AGC lower limit
    64: dout <= 16'h26_e3; //AGC/AEC fast mode op region
    65: dout <= 16'h9f_78; //HAECC1 
    66: dout <= 16'ha0_68; //HAECC2 
    67: dout <= 16'ha1_03; //magic
    68: dout <= 16'ha6_d8; //HAECC3
    69: dout <= 16'ha7_d8; //HAECC4
    70: dout <= 16'ha8_f0; //HAECC5
    71: dout <= 16'ha9_90; //HAECC6
    72: dout <= 16'haa_94; //HAECC7
    73: dout <= 16'h6f_9f;
    74: dout <= 16'h13_e7; //COM8, enable AGC / AEC
    ////////////////////////////////////////////
    75: dout <= 16'h55_10; // bright
    76: dout <= 16'h13_40; //AWB off
    77: dout <= 16'h6A_7f; // 초 90
    78: dout <= 16'h01_b0; // 빨 b0
    79: dout <= 16'h02_c0; // 파 a0

    default: dout <= 16'hFF_FF;
    endcase
    end
endmodule

module sccb
#(
    parameter CLK_FREQ = 25000000,
    parameter SCCB_FREQ = 100000
)
(
    input wire clk,
    input wire start,
    input wire [7:0] address,
    input wire [7:0] data,
    output reg ready,
    output reg SIOC_oe,
    output reg SIOD_oe
    );
    
    localparam CAMERA_ADDR = 8'h42;
    localparam FSM_IDLE = 0;
    localparam FSM_START_SIGNAL = 1;
    localparam FSM_LOAD_BYTE = 2;
    localparam FSM_TX_BYTE_1 = 3;
    localparam FSM_TX_BYTE_2 = 4;
    localparam FSM_TX_BYTE_3 = 5;
    localparam FSM_TX_BYTE_4 = 6;
    localparam FSM_END_SIGNAL_1 = 7;
    localparam FSM_END_SIGNAL_2 = 8;
    localparam FSM_END_SIGNAL_3 = 9;
    localparam FSM_END_SIGNAL_4 = 10;
    localparam FSM_DONE = 11;
    localparam FSM_TIMER = 12;
    
    
    initial begin 
        SIOC_oe = 0;
        SIOD_oe = 0;
        ready = 1;
    end
    
    reg [3:0] FSM_state = 0;
    reg [3:0] FSM_return_state = 0;
    reg [31:0] timer = 0;
    reg [7:0] latched_address;
    reg [7:0] latched_data; 
    reg [1:0] byte_counter = 0;
    reg [7:0] tx_byte = 0;
    reg [3:0] byte_index = 0;
    
    
    always@(posedge clk) begin
        
        case(FSM_state) 
        
            FSM_IDLE: begin
                byte_index <= 0;
                byte_counter <= 0;
                if (start) begin 
                    FSM_state <= FSM_START_SIGNAL;
                    latched_address <= address;
                    latched_data <= data;
                    ready <= 0;
                end
                else begin
                    ready <= 1;
                end
            end
            
            FSM_START_SIGNAL: begin //comunication interface start signal, bring SIOD low
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_LOAD_BYTE;
                timer <= (CLK_FREQ/(4*SCCB_FREQ));
                SIOC_oe <= 0;
                SIOD_oe <= 1;
            end
            
            FSM_LOAD_BYTE: begin //load next byte to be transmitted
                FSM_state <= (byte_counter == 3) ? FSM_END_SIGNAL_1 : FSM_TX_BYTE_1;
                byte_counter <= byte_counter + 1;
                byte_index <= 0; //clear byte index
                case(byte_counter)
                    0: tx_byte <= CAMERA_ADDR;
                    1: tx_byte <= latched_address;
                    2: tx_byte <= latched_data;
                    default: tx_byte <= latched_data;
                endcase
            end
            
            FSM_TX_BYTE_1: begin //bring SIOC low and and delay for next state 
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_TX_BYTE_2;
                timer <= (CLK_FREQ/(4*SCCB_FREQ));
                SIOC_oe <= 1; 
            end
            
            FSM_TX_BYTE_2: begin //assign output data, 
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_TX_BYTE_3;
                timer <= (CLK_FREQ/(4*SCCB_FREQ)); //delay for SIOD to stabilize
                SIOD_oe <= (byte_index == 8) ? 0 : ~tx_byte[7]; //allow for 9 cycle ack, output enable signal is inverting
            end
            
            FSM_TX_BYTE_3: begin // bring SIOC high 
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_TX_BYTE_4;
                timer <= (CLK_FREQ/(2*SCCB_FREQ));
                SIOC_oe <= 0; //output enable is an inverting pulldown
            end
            
            FSM_TX_BYTE_4: begin //check for end of byte, incriment counter
                FSM_state <= (byte_index == 8) ? FSM_LOAD_BYTE : FSM_TX_BYTE_1;
                tx_byte <= tx_byte<<1; //shift in next data bit
                byte_index <= byte_index + 1;
            end
            
            FSM_END_SIGNAL_1: begin //state is entered with SIOC high, SIOD high. Start by bringing SIOC low
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_END_SIGNAL_2;
                timer <= (CLK_FREQ/(4*SCCB_FREQ));
                SIOC_oe <= 1;
            end
            
            FSM_END_SIGNAL_2: begin // while SIOC is low, bring SIOD low 
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_END_SIGNAL_3;
                timer <= (CLK_FREQ/(4*SCCB_FREQ));
                SIOD_oe <= 1;
            end
            
            FSM_END_SIGNAL_3: begin // bring SIOC high
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_END_SIGNAL_4;
                timer <= (CLK_FREQ/(4*SCCB_FREQ));
                SIOC_oe <= 0;
            end
            
            FSM_END_SIGNAL_4: begin // bring SIOD high when SIOC is high
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_DONE;
                timer <= (CLK_FREQ/(4*SCCB_FREQ));
                SIOD_oe <= 0;
            end
            
            FSM_DONE: begin //add delay between transactions
                FSM_state <= FSM_TIMER;
                FSM_return_state <= FSM_IDLE;
                timer <= (2*CLK_FREQ/(SCCB_FREQ));
                byte_counter <= 0;
            end
            
            FSM_TIMER: begin //count down and jump to next state
                FSM_state <= (timer == 0) ? FSM_return_state : FSM_TIMER;
                timer <= (timer==0) ? 0 : timer - 1;
            end
        endcase
    end
        
endmodule

/*
----------------------------------------
Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------

Omnivision 7670 Initialization
Authors:  Greg M. Crist, Jr. (gmcrist@gmail.com)

Description:
    Performs initialization of the OV7670 Camera
*/
module ov_7670_init #(
        parameter CHIP_ADDR = 8'hCD
    ) (
        input clk,       // System clock for state transitions
        input clk_sccb,  // Clock for SCCB protocol (100kHz to 400kHz)
        input reset,     // Async reset signal
        output pwdn,
        inout sio_d,
        output sio_c,
        input start,
        output done
    );

    reg [7:0] w_data;
    wire [7:0] r_data;

    reg [7:0] chip_addr;
    reg [7:0] sub_addr;

    reg  sccb_start;
    wire sccb_done;
    wire sccb_busy;
    wire sccb_e;

    (* syn_encoding = "safe" *)
    reg [2:0] state;
    reg [5:0] cmd_counter;

    localparam cmd_count = 40;
    localparam s_idle = 0,
               s_init = 1,
               s_iter = 2,
               s_cmd  = 3,
               s_wait = 4;

    ov_sccb sccb (
        .clk(clk_sccb),
        .reset(reset),
        .sio_d(sio_d),
        .sio_c(sio_c),
        .sccb_e(sccb_e),
        .pwdn(pwdn),
        .addr(chip_addr),
        .subaddr(sub_addr),
        .w_data(w_data),
        .r_data(r_data),
        .tr_start(sccb_start),
        .tr_end(sccb_done),
        .busy(sccb_busy)
    );

    assign done = cmd_counter >= cmd_count && ~sccb_busy;

    always @ (posedge clk) begin
        if (~reset) begin
            state       <= s_init;
            cmd_counter <= 5'd0;
            sccb_start  <= 1'b0;
        end
        else begin
            case (state)
                s_init: begin
                    state <= s_idle;
                end

                s_idle: begin
                    state <= start ? s_iter : s_idle;
                end

                s_iter: begin
                    state       <= cmd_counter < cmd_count ? s_cmd : s_idle;
                    cmd_counter <= cmd_counter + 1'b1;
                end

                s_cmd: begin
                    state <= done ? s_iter : s_wait;

                    case (cmd_counter)
                        0:  write_sccb(CHIP_ADDR, 8'h12, 8'h80);     // COM 7    Reset
                        1:  write_sccb(CHIP_ADDR, 8'hf0, 8'hf0);     //          Delay
                        2:  write_sccb(CHIP_ADDR, 8'h12, 8'h04);     // COM 7    Set RGB
                        3:  write_sccb(CHIP_ADDR, 8'h11, 8'h00);     // CLKRC    Use external clock directly
                        4:  write_sccb(CHIP_ADDR, 8'h0c, 8'h00);     // COM3     Disable DCW & scaling. + RSVD bits.
                        5:  write_sccb(CHIP_ADDR, 8'h3e, 8'h00);     // COM14    Normal PCLK
                        6:  write_sccb(CHIP_ADDR, 8'h8c, 8'h00);     // RGB444   Disable RGB444
                        7:  write_sccb(CHIP_ADDR, 8'h04, 8'h00);     // COM1     Disable CCIR656. AEC low 2 LSB
                        8:  write_sccb(CHIP_ADDR, 8'h40, 8'hd0);     // COM15    Set RGB565 full value range
                        9:  write_sccb(CHIP_ADDR, 8'h3a, 8'h04);     // TSLB     Don't set window automatically. + RSVD bits.
                        10: write_sccb(CHIP_ADDR, 8'h14, 8'h18);     // COM9     Maximum AGC value x4. Freeze AGC/AEC. + RSVD bits.
                        11: write_sccb(CHIP_ADDR, 8'h4f, 8'hb3);     // MTX1     Matrix Coefficient 1
                        12: write_sccb(CHIP_ADDR, 8'h50, 8'hb3);     // MTX2     Matrix Coefficient 2
                        13: write_sccb(CHIP_ADDR, 8'h51, 8'h00);     // MTX3     Matrix Coefficient 3
                        14: write_sccb(CHIP_ADDR, 8'h52, 8'h3d);     // MTX4     Matrix Coefficient 4
                        15: write_sccb(CHIP_ADDR, 8'h53, 8'ha7);     // MTX5     Matrix Coefficient 5
                        16: write_sccb(CHIP_ADDR, 8'h54, 8'he4);     // MTX6     Matrix Coefficient 6
                        17: write_sccb(CHIP_ADDR, 8'h58, 8'h9e);     // MTXS     Enable auto contrast center. Matrix coefficient sign. + RSVD bits.
                        18: write_sccb(CHIP_ADDR, 8'h3d, 8'hc0);     // COM13    Gamma enable. + RSVD bits.
                        19: write_sccb(CHIP_ADDR, 8'h11, 8'h00);     // CLKRC    Use external clock directly
                        20: write_sccb(CHIP_ADDR, 8'h17, 8'h14);     // HSTART   HREF start high 8 bits.
                        21: write_sccb(CHIP_ADDR, 8'h18, 8'h02);     // HSTOP    HREF stop high 8 bits.
                        22: write_sccb(CHIP_ADDR, 8'h32, 8'h80);     // HREF     HREF edge offset. HSTART/HSTOP low 3 bits.
                        23: write_sccb(CHIP_ADDR, 8'h19, 8'h03);     // VSTART   VSYNC start high 8 bits
                        24: write_sccb(CHIP_ADDR, 8'h1a, 8'h7b);     // VSTOP    VSYNC stop high 8 bits
                        25: write_sccb(CHIP_ADDR, 8'h03, 8'h0a);     // VREF     VSYNC edge offset. VSTART/VSTOP low 3 bits
                        26: write_sccb(CHIP_ADDR, 8'h0f, 8'h41);     // COM6     Disable HREF at optical black. Reset timings. + RSVD bits.
                        27: write_sccb(CHIP_ADDR, 8'h1e, 8'h03);     // MVFP     No mirror/vclip. Black sun disable. + RSVD bits.
                        28: write_sccb(CHIP_ADDR, 8'h33, 8'h0b);     // CHLF     Array Current Control - Reserved
                        29: write_sccb(CHIP_ADDR, 8'h3c, 8'h78);     // COM12    No HREF when VSYNC is low. + RSVD bits.
                        30: write_sccb(CHIP_ADDR, 8'h69, 8'h00);     // GFIX     Fix Gain Control? No.
                        31: write_sccb(CHIP_ADDR, 8'h6b, 8'h1a);     // DBLV     Bypass PLL. Enabel internal regulator. + RSVD bits.
                        32: write_sccb(CHIP_ADDR, 8'h74, 8'h00);     // REG74    Digital gain controlled by VREF[7:6] + RSVD bits.
                        33: write_sccb(CHIP_ADDR, 8'hb0, 8'h84);     // RSVD     ?
                        34: write_sccb(CHIP_ADDR, 8'hb1, 8'h0c);     // ABLC1    Enable ABLC function. + RSVD bits.
                        35: write_sccb(CHIP_ADDR, 8'hb2, 8'h0e);     // RSVD     ?
                        36: write_sccb(CHIP_ADDR, 8'hb3, 8'h80);     // THL_ST   ALBC Target

                        default: state <= s_iter;                    //          Do nothing
                    endcase
                end

                s_wait: begin
                    sccb_start <= 1'b0;
                    state      <= sccb_done ? s_iter : s_wait;
                end
            endcase
        end
    end

    task write_sccb;
        input [7:0] t_chip_addr;
        input [7:0] t_sub_addr;
        input [7:0] t_data;

        begin
            chip_addr   <= t_chip_addr & 8'b1111_1110;
            sub_addr    <= t_sub_addr;
            w_data      <= t_data;
            sccb_start  <= 1'b1;
        end
    endtask
endmodule

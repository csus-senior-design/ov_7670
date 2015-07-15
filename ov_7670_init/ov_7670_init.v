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
        parameter CHIP_ADDR = 8'b11001101
    ) (
        input clk,       // System clock for state transitions
        input clk_sccb,  // Clock for SCCB protocol (100kHz to 400kHz)
        input reset,     // Async reset signal
        output pwdn,
        inout sio_d,
        output sio_c
    );

    reg [7:0] w_data;
    wire [7:0] r_data;

    reg [7:0] subaddr;

    reg tr_start;
    wire tr_end;

    ov_sccb sccb (.clk(clk_sccb),
            .reset(reset),
            .sio_d(sio_d),
            .sio_c(sio_c),
            .sccb_e(sccb_e),
            .pwdn(pwdn),
            .addr(CHIP_ADDR),
            .subaddr(subaddr),
            .w_data(w_data),
            .r_data(r_data),
            .tr_start(tr_start),
            .tr_end(tr_end));

    (* syn_encoding = "safe" *)
    reg [1:0] state;
    reg [5:0] cmd_counter;

    localparam s_reset = 0,
               s_idle  = 1,
               s_cmd   = 2,
               s_wait  = 3;

    always @ (posedge clk) begin
        if (~reset) begin
            state <= s_reset;

            cmd_counter <= 4'd0;
            subaddr <= 8'h00;
            w_data <= 8'h00;
            tr_start <= 1'b0;
        end
        else begin
            case (state)
                s_reset: begin
                    state <= s_idle;
                    cmd_counter <= 4'd0;
                    tr_start <= 1'b0;
                    w_data <= 8'h00;
                end

                s_idle: begin
                    state <= cmd_counter == 4'd0 ? s_cmd : s_idle;
                end

                s_cmd: begin
                    cmd_counter <= cmd_counter + 1'b1;
                    state <= cmd_counter == 6'd31 ? s_idle : s_wait;

                    tr_start <= 1'b1;

                    case (cmd_counter)
                        6'd0:  {subaddr, w_data} <= {8'h12, 8'h80};     // COM 7    Reset
                        6'd1:  {subaddr, w_data} <= {8'hf0, 8'hf0};     //          Delay
                        6'd2:  {subaddr, w_data} <= {8'h12, 8'h04};     // COM 7    Set RGB
                        6'd3:  {subaddr, w_data} <= {8'h11, 8'h00};     // CLKRC    Use external clock directly
                        6'd4:  {subaddr, w_data} <= {8'h0c, 8'h00};     // COM3     Disable DCW & scaling. + RSVD bits.
                        6'd5:  {subaddr, w_data} <= {8'h3e, 8'h00};     // COM14    Normal PCLK
                        6'd6:  {subaddr, w_data} <= {8'h8c, 8'h00};     // RGB444   Disable RGB444
                        6'd7:  {subaddr, w_data} <= {8'h04, 8'h00};     // COM1     Disable CCIR656. AEC low 2 LSB
                        6'd8:  {subaddr, w_data} <= {8'h40, 8'hd0};     // COM15    Set RGB565 full value range
                        6'd9:  {subaddr, w_data} <= {8'h3a, 8'h04};     // TSLB     Don't set window automatically. + RSVD bits.
                        6'd10: {subaddr, w_data} <= {8'h14, 8'h18};     // COM9     Maximum AGC value x4. Freeze AGC/AEC. + RSVD bits.
                        6'd11: {subaddr, w_data} <= {8'h4f, 8'hb3};     // MTX1     Matrix Coefficient 1
                        6'd12: {subaddr, w_data} <= {8'h50, 8'hb3};     // MTX2     Matrix Coefficient 2
                        6'd13: {subaddr, w_data} <= {8'h51, 8'h00};     // MTX3     Matrix Coefficient 3
                        6'd14: {subaddr, w_data} <= {8'h52, 8'h3d};     // MTX4     Matrix Coefficient 4
                        6'd15: {subaddr, w_data} <= {8'h53, 8'ha7};     // MTX5     Matrix Coefficient 5
                        6'd16: {subaddr, w_data} <= {8'h54, 8'he4};     // MTX6     Matrix Coefficient 6
                        6'd17: {subaddr, w_data} <= {8'h58, 8'h9e};     // MTXS     Enable auto contrast center. Matrix coefficient sign. + RSVD bits.
                        6'd18: {subaddr, w_data} <= {8'h3d, 8'hc0};     // COM13    Gamma enable. + RSVD bits.
                        6'd19: {subaddr, w_data} <= {8'h11, 8'h00};     // CLKRC    Use external clock directly
                        6'd20: {subaddr, w_data} <= {8'h17, 8'h14};     // HSTART   HREF start high 8 bits.
                        6'd21: {subaddr, w_data} <= {8'h18, 8'h02};     // HSTOP    HREF stop high 8 bits.
                        6'd22: {subaddr, w_data} <= {8'h32, 8'h80};     // HREF     HREF edge offset. HSTART/HSTOP low 3 bits.
                        6'd23: {subaddr, w_data} <= {8'h19, 8'h03};     // VSTART   VSYNC start high 8 bits
                        6'd24: {subaddr, w_data} <= {8'h1a, 8'h7b};     // VSTOP    VSYNC stop high 8 bits
                        6'd25: {subaddr, w_data} <= {8'h03, 8'h0a};     // VREF     VSYNC edge offset. VSTART/VSTOP low 3 bits
                        6'd26: {subaddr, w_data} <= {8'h0f, 8'h41};     // COM6     Disable HREF at optical black. Reset timings. + RSVD bits.
                        6'd27: {subaddr, w_data} <= {8'h1e, 8'h03};     // MVFP     No mirror/vclip. Black sun disable. + RSVD bits.
                        6'd28: {subaddr, w_data} <= {8'h33, 8'h0b};     // CHLF     Array Current Control - Reserved
                        6'd29: {subaddr, w_data} <= {8'h3c, 8'h78};     // COM12    No HREF when VSYNC is low. + RSVD bits.
                        6'd30: {subaddr, w_data} <= {8'h69, 8'h00};     // GFIX     Fix Gain Control? No.
                        6'd31: {subaddr, w_data} <= {8'h6b, 8'h1a};     // DBLV     Bypass PLL. Enabel internal regulator. + RSVD bits.
                        6'd32: {subaddr, w_data} <= {8'h74, 8'h00};     // REG74    Digital gain controlled by VREF[7:6] + RSVD bits.
                        6'd33: {subaddr, w_data} <= {8'hb0, 8'h84};     // RSVD     ?
                        6'd34: {subaddr, w_data} <= {8'hb1, 8'h0c};     // ABLC1    Enable ABLC function. + RSVD bits.
                        6'd35: {subaddr, w_data} <= {8'hb2, 8'h0e};     // RSVD     ?
                        6'd36: {subaddr, w_data} <= {8'hb3, 8'h80};     // THL_ST   ALBC Target

                        default: {subaddr, w_data} <= {8'h00, 8'h00};   //          Do nothing
                    endcase
                end

                s_wait: begin
                    state <= tr_end ? s_cmd : s_wait;
                end
            endcase
        end
    end
endmodule

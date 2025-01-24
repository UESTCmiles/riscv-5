module uart_debug #(
    parameter CLK_FREQ      = 'd100_000_000,
    parameter BAUD_RATE     = 'd9600,
    parameter DATA_BIT      = 'd8,
    parameter STOP_BIT      = 'd1,
    parameter CHECK_BIT     = 'd0,
    parameter CHECK_MODE    = "EVEN",
    parameter DW            = 32
) (
    input           clk,
    input           rst_n,
    input           rx,

    output [DW-1:0] inst,
    output          inst_valid,     //wren
    output [31:0]   inst_addr,

    output          inst_tran_done  //rden
);
    wire [7:0]rx_data;
    wire rx_valid;
    wire rx_valid_d;
    wire rx_valid_rising;
    dff #(1'b1) u_dff1 (.clk(clk),.data_i(rx_valid),.data_o(rx_valid_d));
    assign rx_valid_rising = rx_valid & (~rx_valid_d);

    uart_rx #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .DATA_BIT   (DATA_BIT),
        .STOP_BIT   (STOP_BIT),
        .CHECK_BIT  (CHECK_BIT),
        .CHECK_MODE (CHECK_MODE)
    )
    u_rx(
        .clk        (clk),
        .rst        (~rst_n),
        .rx         (rx),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid)
    );

    reg [31:0]inst_r;
    reg inst_valid_r;
    reg [31:0]inst_addr_r;

    reg [1:0]cnt;
    // cnt
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cnt <= 2'b00;
        else if(rx_valid_rising)
            if(cnt == 2'b11)
                cnt <= 2'b00;
            else
                cnt <= cnt + 1'b1;
        else
            cnt <= cnt;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inst_r          <= 'd0;
            inst_valid_r    <= 1'b0; 
            inst_addr_r     <= 'd0;
        end 
        else if(rx_valid_rising)
            case (cnt)
                2'b00: begin
                    inst_r[7:0]     <= rx_data;
                    inst_valid_r    <= 1'b0;
                end
                2'b01: begin
                    inst_r[15:8]    <= rx_data;
                    inst_valid_r    <= 1'b0; 
                end
                2'b10: begin
                    inst_r[23:16]   <= rx_data;
                    inst_valid_r    <= 1'b0; 
                end
                2'b11: begin
                    inst_r[31:24]   <= rx_data;
                    inst_valid_r    <= 1'b1; 
                    inst_addr_r     <= inst_addr_r + 3'd4;
                end
                default: begin
                    inst_r          <= 'd0;
                    inst_valid_r    <= 1'b0;
                    inst_addr_r     <= 'd0;
                end
            endcase
    end

    wire inst_valid_r_d;
    dff #(1'b1) u_dff2 (.clk(clk),.data_i(inst_valid_r),.data_o(inst_valid_r_d));
    
    assign inst_valid       = inst_valid_r & (~inst_valid_r_d);
    assign inst             = inst_r & {32{inst_valid_r}};
    assign inst_addr        = inst_addr_r;
    assign inst_tran_done   = (inst_r[15:0] == 16'hffff) ? 1'b1 : 1'b0;
    
endmodule
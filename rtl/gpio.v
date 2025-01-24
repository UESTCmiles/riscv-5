/*  
寄存器->4096~。。。1_0000_0000_0000
    偏移量  |    含义                     |   读写特性   |    备注
    0x00    gpio_width-1~0:GPIO输出             R/W
    0x04    gpio_width-1~0:GPIO写电平掩码       R/W
    0x08    gpio_width-1~0:GPIO方向             R/W         0为输出, 1为输入
    0x0C    gpio_width-1~0:GPIO输入             R 
功能：GPIO
作者：景绿川
日期：2024/11/28
版本：1.0
*/
module gpio #(
    parameter   AW = 32,
    parameter   DW = 32,
    parameter integer GPIO_WIDTH = 32,              // GPIO位宽(1~32)
    parameter GPIO_DIRECT = "inout",                  // GPIO方向(inout|input|output)
    parameter DEFAULT_OUTPUT_VALUE = 32'hffff_ffff, // GPIO默认输出电平
    parameter DEFAULT_DIRECT = 32'hffff_ffff     // GPIO默认方向(0->输出 1->输入)(仅在inout模式下可用)
) (
    // 时钟和复位
    input                   clk,
    input                   rst_n,

    // wr
    input                   wr_en,
    input [AW-1:0]          wr_addr_i,
    input [DW-1:0]          wr_data_i,

    // rd
    input                   rd_en,
    input [AW-1:0]          rd_addr_i,
    output [DW-1:0]         rd_data_o,

    //gpio
    input [GPIO_WIDTH-1:0]  gpio_i, 
    output [GPIO_WIDTH-1:0] gpio_o, 
    output [GPIO_WIDTH-1:0] gpio_t
);
    wire [GPIO_WIDTH-1:0]gpio_i_w;
    wire [GPIO_WIDTH-1:0]gpio_o_w;
    wire [GPIO_WIDTH-1:0]gpio_t_w;

    generate
        if(GPIO_DIRECT != "input")
            assign gpio_o = gpio_o_w;
        else
            assign gpio_o = DEFAULT_OUTPUT_VALUE;
        
        if(GPIO_DIRECT == "inout")
            assign gpio_t = gpio_t_w;
        else if(GPIO_DIRECT == "input")
            assign gpio_t = 32'hffff_ffff;
        else
            assign gpio_t = 32'h0000_0000;
        
        if(GPIO_DIRECT != "output")
            assign gpio_i_w = gpio_i;
        else
            assign gpio_i_w = gpio_o_w;
    endgenerate

    // 寄存器区
    reg [DW-1:0]gpio_o_value_r;
    reg [DW-1:0]gpio_o_value_mask;
    reg [DW-1:0]gpio_direct_r;
    reg [DW-1:0]gpio_i_value_r;

    // 寄存器写
    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            gpio_o_value_r      <= 'd0;
            gpio_o_value_mask   <= 'd0;
            if(GPIO_DIRECT == "inout")
                gpio_direct_r   <= DEFAULT_DIRECT;
            else if(GPIO_DIRECT == "input")
                gpio_direct_r   <= 'd1;
            else
                gpio_direct_r   <= 'd0;
        end 
        else if(wr_en)
            case (wr_addr_i[3:2])
                2'b00: begin
                    for (i = 0;i < GPIO_WIDTH;i = i + 1)begin
                        gpio_o_value_r[i] = gpio_o_value_mask[i] ? wr_data_i[i] : gpio_o_value_r[i];
                    end
                end
                2'b01: gpio_o_value_mask    <= wr_data_i;
                2'b10: gpio_direct_r        <= wr_data_i;
                default: begin
                    gpio_o_value_r      <= gpio_o_value_r;
                    gpio_o_value_mask   <= gpio_o_value_mask;
                    gpio_direct_r       <= gpio_direct_r;
                end
            endcase
    end

    always@(posedge clk) begin
        gpio_i_value_r[GPIO_WIDTH-1:0] <= gpio_i_w;
    end

    // 寄存器读
    reg[DW-1:0] rd_data_r;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rd_data_r <= 'd0;
        else
            case (rd_addr_i[3:2])
                2'b11:  rd_data_r <= gpio_i_value_r; 
                default:rd_data_r <= rd_data_r; 
            endcase
    end

    assign rd_data_o    = rd_data_r;
    assign gpio_o_w     = gpio_o_value_r[GPIO_WIDTH-1:0];
    assign gpio_t_w     = gpio_direct_r[GPIO_WIDTH-1:0];
    
endmodule
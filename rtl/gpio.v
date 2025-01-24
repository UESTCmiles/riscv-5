/*  
�Ĵ���->4096~������1_0000_0000_0000
    ƫ����  |    ����                     |   ��д����   |    ��ע
    0x00    gpio_width-1~0:GPIO���             R/W
    0x04    gpio_width-1~0:GPIOд��ƽ����       R/W
    0x08    gpio_width-1~0:GPIO����             R/W         0Ϊ���, 1Ϊ����
    0x0C    gpio_width-1~0:GPIO����             R 
���ܣ�GPIO
���ߣ����̴�
���ڣ�2024/11/28
�汾��1.0
*/
module gpio #(
    parameter   AW = 32,
    parameter   DW = 32,
    parameter integer GPIO_WIDTH = 32,              // GPIOλ��(1~32)
    parameter GPIO_DIRECT = "inout",                  // GPIO����(inout|input|output)
    parameter DEFAULT_OUTPUT_VALUE = 32'hffff_ffff, // GPIOĬ�������ƽ
    parameter DEFAULT_DIRECT = 32'hffff_ffff     // GPIOĬ�Ϸ���(0->��� 1->����)(����inoutģʽ�¿���)
) (
    // ʱ�Ӻ͸�λ
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

    // �Ĵ�����
    reg [DW-1:0]gpio_o_value_r;
    reg [DW-1:0]gpio_o_value_mask;
    reg [DW-1:0]gpio_direct_r;
    reg [DW-1:0]gpio_i_value_r;

    // �Ĵ���д
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

    // �Ĵ�����
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
/*  名称：rom
    作用：指令存储器，通过例化ram得到，写端口用于烧录汇编程序
    日期：2024/9/12
    作者：景绿川
    版本：1.1 */

module rom #(
    parameter WIDTH = 32
) (
    input               clk,
    input               rst_n,

    // wr
    input               wr_en,
    input [WIDTH-1:0]   wr_addr_i,
    input [WIDTH-1:0]   wr_data_i,


    // rd
    input               rd_en,
    input [WIDTH-1:0]   rd_addr_i,
    output[WIDTH-1:0]   rd_data_o
);

    dual_ram #(
        .DW         (WIDTH),
        .AW         ('d12),
        .MEM_NUM    ('d4096)
    ) u_ram(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (wr_en),
        .wr_addr_i  (wr_addr_i[13:2]),
        .wr_data_i  (wr_data_i),


        // rd
        .rd_en      (rd_en),
        .rd_addr_i  (rd_addr_i[13:2]),
        .rd_data_o  (rd_data_o)
    );

    
endmodule
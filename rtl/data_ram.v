/*  模块名：data_ram
    作用：  数据存储器
    日期：  2024/10/11
    作者：  景绿川
    版本：  1.0 */

module data_ram #(
    parameter WIDTH = 'd32
) (
    input               clk,
    input               rst_n,

    // wr
    input [3:0]         wr_en,
    input [WIDTH-1:0]   wr_addr_i,
    input [WIDTH-1:0]   wr_data_i,

    // rd
    input               rd_en,
    input [WIDTH-1:0]   rd_addr_i,
    output [WIDTH-1:0]  rd_data_o
);

    /* ***temp signal*** */
    wire [11:0]wr_addr;
    wire [11:0]rd_addr;

    /* *****logic***** */
    assign wr_addr = wr_addr_i[13:2];
    assign rd_addr = rd_addr_i[13:2];

    /* ******例化****** */
    dual_ram #(
        .DW         (WIDTH/4),
        .AW         ('d12),
        .MEM_NUM    ('d4096)
    ) u_ram_byte0(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (wr_en[0]),
        .wr_addr_i  (wr_addr),
        .wr_data_i  (wr_data_i[7:0]),


        // rd
        .rd_en      (rd_en),
        .rd_addr_i  (rd_addr),
        .rd_data_o  (rd_data_o[7:0])
    );

    dual_ram #(
        .DW         (WIDTH/4),
        .AW         ('d12),
        .MEM_NUM    ('d4096)
    ) u_ram_byte1(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (wr_en[1]),
        .wr_addr_i  (wr_addr),
        .wr_data_i  (wr_data_i[15:8]),


        // rd
        .rd_en      (rd_en),
        .rd_addr_i  (rd_addr),
        .rd_data_o  (rd_data_o[15:8])
    );

    dual_ram #(
        .DW         (WIDTH/4),
        .AW         ('d12),
        .MEM_NUM    ('d4096)
    ) u_ram_byte2(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (wr_en[2]),
        .wr_addr_i  (wr_addr),
        .wr_data_i  (wr_data_i[23:16]),


        // rd
        .rd_en      (rd_en),
        .rd_addr_i  (rd_addr),
        .rd_data_o  (rd_data_o[23:16])
    );

    dual_ram #(
        .DW         (WIDTH/4),
        .AW         ('d12),
        .MEM_NUM    ('d4096)
    ) u_ram_byte3(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (wr_en[3]),
        .wr_addr_i  (wr_addr),
        .wr_data_i  (wr_data_i[31:24]),


        // rd
        .rd_en      (rd_en),
        .rd_addr_i  (rd_addr),
        .rd_data_o  (rd_data_o[31:24])
    );
    
endmodule
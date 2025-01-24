/*  模块名：dual_ram
    作用：  真双口ram，读写同时进行时读取写入的数据
    日期：  2024/10/10
    作者：  景绿川
    版本：  1.0 */
    

module dual_ram #(
    parameter DW = 'd32,
    parameter AW = 'd12,
    parameter MEM_NUM = 'd4096
) (
    input           clk,
    input           rst_n,

    // wr
    input           wr_en,
    input [AW-1:0]  wr_addr_i,
    input [DW-1:0]  wr_data_i,


    // rd
    input           rd_en,
    input [AW-1:0]  rd_addr_i,
    output[DW-1:0]  rd_data_o
);
    /* ********temp signal********* */
    reg [DW-1:0]    wr_data_i_d;
    reg             wr_rd_flag;             // 读写同时发生且地址相同标志位
    wire [DW-1:0]   rd_data_tmp;

    /* **********logic*********** */
    always@(posedge clk) begin
        wr_data_i_d <= wr_data_i; 
    end

    always@(posedge clk) begin
        if(rst_n && wr_en && rd_en && (wr_addr_i == rd_addr_i)) 
            wr_rd_flag <= 1'b1;
        else
            wr_rd_flag <= 1'b0;
    end

    assign rd_data_o = wr_rd_flag ? wr_data_i_d : rd_data_tmp;

    /* ***********例化************** */
    dual_ram_mini #(
        .DW(DW),
        .AW(AW),
        .MEM_NUM(MEM_NUM)
    ) u_ram(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (wr_en),
        .wr_addr_i  (wr_addr_i),
        .wr_data_i  (wr_data_i),


        // rd
        .rd_en      (rd_en),
        .rd_addr_i  (rd_addr_i),
        .rd_data_o  (rd_data_tmp)
    );

    

    
    
endmodule
/*  名称：ctrl
    作用：控制分支执行与否
    日期：2024/9/22
    作者：景绿川
    版本：1.0 */

module ctrl #(
    parameter WIDTH = 32
) (
    input [WIDTH-1:0]       jump_addr_i,
    input                   jump_en_i,
    input                   hold_flag_i,

    output reg[WIDTH-1:0]   jump_addr_o,
    output reg              jump_en_o,
    output reg              hold_flag_o
);

    /* ***********logic*********** */
    always@(*) begin
        jump_addr_o = jump_addr_i;
        jump_en_o   = jump_en_i;
        if(jump_en_i || hold_flag_i)
            hold_flag_o = 1'b1;
        else 
            hold_flag_o = 1'b0;
    end
    
endmodule

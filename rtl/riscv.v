/*  名称：riscv
    作用：顶层
    日期：2024/9/19
    作者：景绿川
    版本：1.0 */
module riscv #(
    parameter WIDTH = 'd32
) (
    input               clk,
    input               rst_n,

    input [WIDTH-1:0]   inst_i,

    output [WIDTH-1:0]  inst_addr_o,

    // 读数据存储器
    output [WIDTH-1:0]  mem_rd_addr_o,
    output              mem_rd_req_o,
    input [WIDTH-1:0]   mem_rd_data_i,

    // 写数据存储器
    output [WIDTH-1:0]  mem_wr_addr_o,
    output [WIDTH-1:0]  mem_wr_data_o,
    output [3:0]        mem_wr_sel_o
);

/* ****************temp signal****************** */
    // pc_reg - if / rom
    wire [WIDTH-1:0]        pc_reg_inst_addr_o;

    // if - id
    wire [WIDTH-1:0]        if_inst_addr_o;
    wire [WIDTH-1:0]        if_inst_o;

    // id - regs
    wire [log2n(WIDTH)-1:0] id_rs1_addr_o;
    wire [log2n(WIDTH)-1:0] id_rs2_addr_o;

    wire [WIDTH-1:0]        regs_rs1_rdata_o;
    wire [WIDTH-1:0]        regs_rs2_rdata_o;

    // id - id2ex
    wire [WIDTH-1:0]        id_inst_o;
    wire [WIDTH-1:0]        id_inst_addr_o;

    wire [WIDTH-1:0]        id_op1_o;
    wire [WIDTH-1:0]        id_op2_o;

    wire [log2n(WIDTH)-1:0] id_rd_addr_o;
    wire                    id_regs_wen_o;

    wire [WIDTH-1:0]        id_base_addr_o;
    wire [WIDTH-1:0]        id_addr_offset_o;

    // id2ex - ex
    wire [WIDTH-1:0]        id2ex_inst_o;
    wire [WIDTH-1:0]        id2ex_inst_addr_o;

    wire [WIDTH-1:0]        id2ex_op1_o;
    wire [WIDTH-1:0]        id2ex_op2_o;

    wire [WIDTH-1:0]        id2ex_base_addr_o;
    wire [WIDTH-1:0]        id2ex_addr_offset_o;

    wire [log2n(WIDTH)-1:0] id2ex_rd_addr_o;
    wire                    id2ex_reg_wen_o;

    // ex - regs
    wire [WIDTH-1:0]        ex_rd_data_o;
    wire [log2n(WIDTH)-1:0] ex_rd_addr_o;
    wire                    ex_reg_wen_o;

    // ex - ctrl
    wire [WIDTH-1:0]        ex_jump_addr_o;
    wire                    ex_jump_en_o;
    wire                    ex_hold_flag_o;
    
    // ctrl - if2id / id2ex
    wire                    ctrl_hold_flag_o;

    //ctrl - pc_reg
    wire                    ctrl_jump_en_o;
    wire [WIDTH-1:0]        ctrl_jump_addr_o;
    
/* ********************logic********************* */
    assign inst_addr_o = pc_reg_inst_addr_o;

/* *********************例化********************* */
    pc_reg #(
        .WIDTH          (WIDTH)
    ) u_pc_reg(
        .clk            (clk),
        .rst_n          (rst_n),

        .inst_addr      (pc_reg_inst_addr_o),
        
        .jump_addr_i    (ctrl_jump_addr_o),
        .jump_en_i      (ctrl_jump_en_o)
    ); 

    Inst_Fetch #(
        .WIDTH          (WIDTH)
    ) u_if(
        .clk            (clk),
        .rst_n          (rst_n),
        .inst_addr_i    (pc_reg_inst_addr_o),
        .inst_i         (inst_i),
        .inst_addr_o    (if_inst_addr_o),
        .inst_o         (if_inst_o),
        .hold_flag_i    (ctrl_hold_flag_o)
    );

    Inst_Decode #(
        .WIDTH          (WIDTH)
    ) u_id(
        .inst_addr_i    (if_inst_addr_o),
        .inst_i         (if_inst_o),

        .rs1_data_i     (regs_rs1_rdata_o),        // from regs
        .rs2_data_i     (regs_rs2_rdata_o),        // from regs

        .rs1_addr_o     (id_rs1_addr_o),       // to regs
        .rs2_addr_o     (id_rs2_addr_o),        // to regs

        .inst_o         (id_inst_o),
        .inst_addr_o    (id_inst_addr_o),
        .op1_o          (id_op1_o),
        .op2_o          (id_op2_o),
        .rd_addr_o      (id_rd_addr_o),
        .regs_wen_o     (id_regs_wen_o),
        .addr_offset_o  (id_addr_offset_o),
        .base_addr_o    (id_base_addr_o),
        .mem_rd_addr_o  (mem_rd_addr_o),
        .mem_rd_req_o   (mem_rd_req_o)
    );
 
    regs #(
        .WIDTH      (WIDTH)
    ) u_regs(
        .clk        (clk),
        .rst_n      (rst_n),

        // from id
        .rs1_raddr_i(id_rs1_addr_o),
        .rs2_raddr_i(id_rs2_addr_o),

        // to id
        .rs1_rdata_o(regs_rs1_rdata_o),
        .rs2_rdata_o(regs_rs2_rdata_o),

        // from ex
        .reg_waddr_i(ex_rd_addr_o),
        .reg_wdata_i(ex_rd_data_o),
        .reg_wen_i  (ex_reg_wen_o)
    );

    ID2EX #(
        .WIDTH          (WIDTH)
    ) u_id2ex(
        .clk            (clk),
        .rst_n          (rst_n),

        .inst_i         (id_inst_o),
        .inst_addr_i    (id_inst_addr_o),

        .op1_i          (id_op1_o),
        .op2_i          (id_op2_o),

        .base_addr_i    (id_base_addr_o),
        .addr_offset_i  (id_addr_offset_o),

        .rd_addr_i      (id_rd_addr_o),
        .reg_wen_i      (id_regs_wen_o),

        .inst_o         (id2ex_inst_o),
        .inst_addr_o    (id2ex_inst_addr_o),

        .op1_o          (id2ex_op1_o),
        .op2_o          (id2ex_op2_o),
        
        .base_addr_o    (id2ex_base_addr_o),
        .addr_offset_o  (id2ex_addr_offset_o),

        .rd_addr_o      (id2ex_rd_addr_o),
        .reg_wen_o      (id2ex_reg_wen_o),
        .hold_flag_i    (ctrl_hold_flag_o)
    );

    EXecute #(
        .WIDTH          (WIDTH)
    ) u_ex(
        .inst_i         (id2ex_inst_o),
        .inst_addr_i    (id2ex_inst_addr_o),
        .op1_i          (id2ex_op1_o),
        .op2_i          (id2ex_op2_o),

        .rd_addr_i      (id2ex_rd_addr_o),
        .reg_wen_i      (id2ex_reg_wen_o),

        .base_addr_i    (id2ex_base_addr_o),
        .addr_offset_i  (id2ex_addr_offset_o),

        .rd_data_o      (ex_rd_data_o),
        .rd_addr_o      (ex_rd_addr_o),
        .reg_wen_o      (ex_reg_wen_o),

        .jump_addr_o    (ex_jump_addr_o),
        .jump_en_o      (ex_jump_en_o),
        .hold_flag_o    (ex_hold_flag_o),

        // from data_ram
        .mem_rd_data_i  (mem_rd_data_i),

        // to data_ram
        .mem_wr_sel_o   (mem_wr_sel_o),
        .mem_wr_addr_o  (mem_wr_addr_o),
        .mem_wr_data_o  (mem_wr_data_o)
    );

    ctrl #(
        .WIDTH(WIDTH)
    ) u_ctrl(
        .jump_addr_i(ex_jump_addr_o),
        .jump_en_i  (ex_jump_en_o),
        .hold_flag_i(ex_hold_flag_o),

        .jump_addr_o(ctrl_jump_addr_o),
        .jump_en_o  (ctrl_jump_en_o),
        .hold_flag_o(ctrl_hold_flag_o)
    );
    

/* *****************function****************** */

    function integer log2n;
        input integer length;
        integer tmp;
    begin
        tmp = length;
        for(log2n = 0; tmp > 1;log2n = log2n + 1)
            tmp = tmp >> 1;
    end
        
    endfunction

endmodule
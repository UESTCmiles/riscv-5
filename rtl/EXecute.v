/*  名称：EXecute
    作用：相比1.2新增了使用ALU模块进行计算
    日期：2024/10/7
    作者：景绿川
    版本：1.3 */

`include "defines.v"
module EXecute #(
    parameter WIDTH = 32
) (
    input [WIDTH-1:0]           inst_i,
    input [WIDTH-1:0]           inst_addr_i,
    input [WIDTH-1:0]           op1_i,
    input [WIDTH-1:0]           op2_i,

    input [log2n(WIDTH)-1:0]    rd_addr_i,
    input                       reg_wen_i,

    input [WIDTH-1:0]           base_addr_i,
    input [WIDTH-1:0]           addr_offset_i,

    // to regs
    output reg[WIDTH-1:0]       rd_data_o,
    output reg[log2n(WIDTH)-1:0]rd_addr_o,
    output reg                  reg_wen_o,

    // to ctrl
    output reg[31:0]            jump_addr_o,
    output reg                  jump_en_o,
    output reg                  hold_flag_o,

    // from data_ram
    input [WIDTH-1:0]           mem_rd_data_i,

    // to data_ram
    output reg[3:0]             mem_wr_sel_o,
    output reg[WIDTH-1:0]       mem_wr_addr_o,
    output reg[WIDTH-1:0]       mem_wr_data_o
    
);
    
    /* **************temp signal*************** */
    // 译码
    wire [6:0]opcode;
    wire [4:0]rd;
    wire [2:0]funct3;
    wire [4:0]rs1;
    wire [4:0]rs2;
    wire [6:0]funct7;
    wire [11:0]imm;

    // branch
    wire [31:0]b_imm;
    wire op1_equal_op2;
    wire op1_less_op2_signed;
    wire op1_less_op2_unsigned;

    // ALU
    wire [WIDTH-1:0]op1_add_op2;
    wire [WIDTH-1:0]op1_sub_op2;
    wire [WIDTH-1:0]op1_xor_op2;
    wire [WIDTH-1:0]op1_or_op2;
    wire [WIDTH-1:0]op1_and_op2;
    wire [WIDTH-1:0]op1_sl_op2;         // shift left
    wire [WIDTH-1:0]op1_srl_op2;        // shift right logic
    // wire [WIDTH-1:0]op1_add_op2;
    // wire [WIDTH-1:0]op1_add_op2;
    wire [WIDTH-1:0]op1_sra_op2;        // shift right Arithmetic
    wire [WIDTH-1:0]base_addr_add_offset;

    // L & S
    wire [1:0]load_index;
    wire [1:0]store_index;

    /* ****************logic***************** */
    // 译码
    assign opcode = inst_i[6:0];
    assign rd = inst_i[11:7];
    assign funct3 = inst_i[14:12];
    assign rs1 = inst_i[19:15];
    assign rs2 = inst_i[24:20];
    assign funct7 = inst_i[31:25];
    assign imm = inst_i[31:20];

    // branch
    assign b_imm = {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
    assign op1_equal_op2 = (op1_i == op2_i) ? 1'b1 : 1'b0;
    assign op1_less_op2_signed = ($signed(op1_i) < $signed(op2_i)) ? 1'b1 : 1'b0;
    assign op1_less_op2_unsigned = (op1_i < op2_i) ? 1'b1 : 1'b0;

    // ALU
    assign op1_add_op2 = op1_i + op2_i;
    assign op1_sub_op2 = op1_i - op2_i;
    assign op1_xor_op2 = op1_i ^ op2_i;
    assign op1_or_op2  = op1_i | op2_i;
    assign op1_and_op2 = op1_i & op2_i;
    assign op1_sl_op2  = op1_i << op2_i;
    assign op1_srl_op2 = op1_i >> op2_i;
    assign op1_sra_op2 = $signed(op1_i) >>> op2_i;
    assign base_addr_add_offset = base_addr_i + addr_offset_i;

    // L & S
    assign load_index   = base_addr_add_offset[1:0];
    assign store_index  = base_addr_add_offset[1:0];

    always@(*)  begin
        case (opcode)
            `INST_TYPE_I:   begin
                jump_addr_o     = 'd0;
                jump_en_o       = 1'b0;
                hold_flag_o     = 1'b0;
                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
                case (funct3)
                    `INST_ADDI: begin
                        rd_data_o = op1_add_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_SLTI: begin
                        rd_data_o = {31'd0,op1_less_op2_signed}; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_SLTIU:begin
                        rd_data_o = {31'd0,op1_less_op2_unsigned}; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_XORI: begin
                        rd_data_o = op1_xor_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_ORI:  begin
                        rd_data_o = op1_or_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_ANDI: begin
                        rd_data_o = op1_and_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i; 
                    end
                    `INST_SLLI: begin
                        rd_data_o = op1_sl_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_SRI: begin
                        if(funct7[5]) begin // SRAI
                            rd_data_o = op1_sra_op2; 
                            rd_addr_o = rd_addr_i;
                            reg_wen_o = reg_wen_i; 
                        end
                        else begin          // SRLI
                            rd_data_o = op1_srl_op2; 
                            rd_addr_o = rd_addr_i;
                            reg_wen_o = reg_wen_i; 
                        end
                    end
                    default: begin
                        rd_data_o = 'd0; 
                        rd_addr_o = 'd0;
                        reg_wen_o = 1'b0;
                    end
                endcase 
            end
            `INST_TYPE_R_M: begin
                jump_addr_o = 'd0;
                jump_en_o   = 1'b0;
                hold_flag_o = 1'b0;
                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
                case (funct3)
                    `INST_ADD_SUB: begin
                        if(funct7[5]) begin
                            rd_data_o = op1_sub_op2; 
                            rd_addr_o = rd_addr_i;
                            reg_wen_o = reg_wen_i;
                        end
                        else begin
                            rd_data_o = op1_add_op2; 
                            rd_addr_o = rd_addr_i;
                            reg_wen_o = reg_wen_i; 
                        end
                    end
                    `INST_SLL:  begin
                        rd_data_o = op1_sl_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_SLT:  begin
                        rd_data_o = {31'd0,op1_less_op2_signed}; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_SLTU: begin
                        rd_data_o = {31'd0,op1_less_op2_unsigned}; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_XOR:  begin
                        rd_data_o = op1_xor_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_SR:  begin
                        if(funct7[5]) begin  // SRA
                            rd_data_o = op1_sra_op2; 
                            rd_addr_o = rd_addr_i;
                            reg_wen_o = reg_wen_i;
                        end
                        else begin                      // SRL
                            rd_data_o = op1_srl_op2; 
                            rd_addr_o = rd_addr_i;
                            reg_wen_o = reg_wen_i; 
                        end
                    end
                    `INST_OR:  begin
                        rd_data_o = op1_or_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    `INST_AND:  begin
                        rd_data_o = op1_and_op2; 
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                    end
                    default: begin
                        rd_data_o = 'd0; 
                        rd_addr_o = 'd0;
                        reg_wen_o = 1'b0;
                    end
                endcase 
            end
            `INST_TYPE_B:   begin
                rd_data_o   = 'd0; 
                rd_addr_o   = 'd0;
                reg_wen_o   = 1'b0;
                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
                case (funct3)
                    `INST_BNE: begin
                        jump_addr_o = base_addr_add_offset; // (inst_addr_i + b_imm) & {32{op1_equal_op2}}
                        jump_en_o   = ~op1_equal_op2;
                        hold_flag_o = 1'b0;
                    end 
                    `INST_BEQ: begin
                        jump_addr_o = base_addr_add_offset; // (inst_addr_i + b_imm) & {32{op1_equal_op2}}
                        jump_en_o   = op1_equal_op2;
                        hold_flag_o = 1'b0;
                    end
                    `INST_BLT: begin
                        jump_addr_o = base_addr_add_offset;
                        jump_en_o   = op1_less_op2_signed;
                        hold_flag_o = 1'b0;
                    end
                    `INST_BGE: begin
                        jump_addr_o = base_addr_add_offset;
                        jump_en_o   = ~op1_less_op2_signed;
                        hold_flag_o = 1'b0;
                    end
                    `INST_BLTU: begin
                        jump_addr_o = base_addr_add_offset;
                        jump_en_o   = op1_less_op2_unsigned;
                        hold_flag_o = 1'b0;
                    end
                    `INST_BGEU: begin
                        jump_addr_o = base_addr_add_offset;
                        jump_en_o   = ~op1_less_op2_unsigned;
                        hold_flag_o = 1'b0;
                    end
                    default: begin
                        jump_addr_o = 'd0;
                        jump_en_o   = 1'b0;
                        hold_flag_o = 1'b0;
                    end
                endcase 
            end
            `INST_JAL:      begin
                jump_addr_o = base_addr_add_offset;
                jump_en_o   = 1'b1;
                hold_flag_o = 1'b0;

                rd_data_o   = op1_add_op2; 
                rd_addr_o   = rd_addr_i;
                reg_wen_o   = reg_wen_i;

                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
            end
            `INST_JALR:      begin
                jump_addr_o = base_addr_add_offset;
                jump_en_o   = 1'b1;
                hold_flag_o = 1'b0;

                rd_data_o   = op1_add_op2; 
                rd_addr_o   = rd_addr_i;
                reg_wen_o   = reg_wen_i;

                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
            end
            `INST_LUI:      begin
                jump_addr_o = 'd0;
                jump_en_o   = 1'b0;
                hold_flag_o = 1'b0;

                rd_data_o   = op1_i; 
                rd_addr_o   = rd_addr_i;
                reg_wen_o   = reg_wen_i;

                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
            end
            `INST_AUIPC:    begin
                jump_addr_o = 'd0;
                jump_en_o   = 1'b0;
                hold_flag_o = 1'b0;

                rd_data_o   = op1_add_op2; 
                rd_addr_o   = rd_addr_i;
                reg_wen_o   = reg_wen_i; 

                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
            end
            `INST_TYPE_L:   begin
                jump_addr_o     = 'd0;
                jump_en_o       = 1'b0;
                hold_flag_o     = 1'b0;
                mem_wr_addr_o   = 'd0; 
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 'd0;
                case (funct3)
                    `INST_LW: begin
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i; 
                        rd_data_o = mem_rd_data_i;
                    end
                    `INST_LH: begin
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                        case (load_index[1])
                            1'b0: begin
                                rd_data_o = {{16{mem_rd_data_i[15]}},mem_rd_data_i[15:0]}; 
                            end 
                            1'b1: begin
                                rd_data_o = {{16{mem_rd_data_i[31]}},mem_rd_data_i[31:16]}; 
                            end
                            default: begin
                                rd_data_o = 'd0; 
                            end
                        endcase
                    end
                    `INST_LB: begin
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                        case (load_index)
                            2'b00: begin
                                rd_data_o = {{24{mem_rd_data_i[7]}},mem_rd_data_i[7:0]}; 
                            end
                            2'b01: begin
                                rd_data_o = {{24{mem_rd_data_i[15]}},mem_rd_data_i[15:8]}; 
                            end
                            2'b10: begin
                                rd_data_o = {{24{mem_rd_data_i[23]}},mem_rd_data_i[23:16]}; 
                            end
                            2'b11: begin
                                rd_data_o = {{24{mem_rd_data_i[31]}},mem_rd_data_i[31:24]}; 
                            end
                            default: begin
                                rd_data_o = 'd0; 
                            end
                        endcase 
                    end
                    `INST_LHU: begin
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                        case (load_index[1])
                            1'b0: begin
                                rd_data_o = {16'd0,mem_rd_data_i[15:0]}; 
                            end 
                            1'b1: begin
                                rd_data_o = {16'd0,mem_rd_data_i[31:16]}; 
                            end
                            default: begin
                                rd_data_o = 'd0; 
                            end
                        endcase 
                    end
                    `INST_LBU: begin
                        rd_addr_o = rd_addr_i;
                        reg_wen_o = reg_wen_i;
                        case (load_index)
                            2'b00: begin
                                rd_data_o = {24'd0,mem_rd_data_i[7:0]}; 
                            end 
                            2'b01: begin
                                rd_data_o = {24'd0,mem_rd_data_i[15:8]}; 
                            end
                            2'b10: begin
                                rd_data_o = {24'd0,mem_rd_data_i[23:16]}; 
                            end
                            2'b11: begin
                                rd_data_o = {24'd0,mem_rd_data_i[31:24]}; 
                            end
                            default: begin
                                rd_data_o = 'd0;  
                            end
                        endcase 
                    end
                    default: begin
                        rd_addr_o = 'd0;
                        reg_wen_o = 1'b0;
                        rd_data_o = 'd0;
                    end
                endcase
            end
            `INST_TYPE_S:   begin
                jump_addr_o = 'd0;
                jump_en_o   = 1'b0;
                hold_flag_o = 1'b0;
                rd_addr_o   = 'd0;
                reg_wen_o   = 1'b0; 
                rd_data_o   = 'd0;
                case (funct3)
                    `INST_SW: begin
                        mem_wr_addr_o   = base_addr_add_offset;
                        mem_wr_data_o   = op2_i;
                        mem_wr_sel_o    = 4'b1111; 
                    end
                    `INST_SH: begin
                        mem_wr_addr_o   = base_addr_add_offset;
                        case (store_index[1])
                            1'b0: begin
                                mem_wr_data_o   = {16'd0,op2_i[15:0]};
                                mem_wr_sel_o    = 4'b0011; 
                            end 
                            1'b1: begin
                                mem_wr_data_o   = {op2_i[15:0],16'd0};
                                mem_wr_sel_o    = 4'b1100;  
                            end
                            default: begin
                                mem_wr_data_o   = 'd0;
                                mem_wr_sel_o    = 4'd0; 
                            end
                        endcase
                    end
                    `INST_SB: begin
                        mem_wr_addr_o           = base_addr_add_offset;
                        case (store_index)
                            2'b00: begin
                                mem_wr_data_o   = {24'd0,op2_i[7:0]};
                                mem_wr_sel_o    = 4'b0001;
                            end 
                            2'b01: begin
                                mem_wr_data_o   = {16'd0,op2_i[7:0],8'd0};
                                mem_wr_sel_o    = 4'b0010; 
                            end
                            2'b10: begin
                                mem_wr_data_o   = {8'd0,op2_i[7:0],16'd0};
                                mem_wr_sel_o    = 4'b0100; 
                            end
                            2'b11: begin
                                mem_wr_data_o   = {op2_i[7:0],24'd0};
                                mem_wr_sel_o    = 4'b1000; 
                            end
                            default: begin
                                mem_wr_data_o   = 'd0;
                                mem_wr_sel_o    = 4'd0; 
                            end
                        endcase 
                    end
                    default: begin
                        mem_wr_addr_o   = 'd0;
                        mem_wr_data_o   = 'd0;
                        mem_wr_sel_o    = 4'd0;
                    end
                endcase
            end
            default:begin
                jump_addr_o = 'd0;
                jump_en_o   = 1'b0;
                hold_flag_o = 1'b0;

                rd_data_o   = 'd0; 
                rd_addr_o   = 'd0;
                reg_wen_o   = 1'b0;

                mem_wr_addr_o   = 'd0;
                mem_wr_data_o   = 'd0;
                mem_wr_sel_o    = 4'd0;
            end
        endcase
    end






    /* ***************function***************** */
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
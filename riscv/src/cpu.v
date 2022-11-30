// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "riscv\src\defines.v"
`include "riscv\src\Mem\MemCtrl.v"
`include "riscv\src\IF\Fetcher.v"
`include "riscv\src\IF\Predictor.v"
`include "riscv\src\IF\Register.v"
`include "riscv\src\IF\ROB.v"
`include "riscv\src\ID\Commander.v"
`include "riscv\src\ID\Decoder.v"
`include "riscv\src\EX\LS_EX.v"
`include "riscv\src\EX\LS.v"
`include "riscv\src\EX\RS_EX.v"
`include "riscv\src\EX\RS.v"

module cpu(
    input wire clk_in,            // system clock signal
    input wire rst_in,            // reset signal
    input wire rdy_in,            // ready signal, pause cpu when low

    input wire[7:0] mem_din,        // data input bus
    output wire[7:0] mem_dout,        // data output bus
    output wire[31:0] mem_a,            // address bus (only 17:0 is used)
    output wire mem_wr,            // write/read signal (1 for write)

    input wire io_buffer_full, // 1 if uart buffer is full

    output wire[31:0] dbgreg_dout        // cpu register output (debugging demo)
);

    // implementation goes here

    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    // Memctrl & Fetcher
    wire [`ADDR_TYPE] pc_from_fch_to_memctrl;
    wire [`ICACHE_INST_BLOCK_SIZE-1:0] inst_from_memctrl_to_fch;
    wire enable_sign_from_fch_to_memctrl;
    wire finish_sign_from_memctrl_to_fch;

    // Memctrl & LS_EX
    wire enable_sign_from_ls_ex_to_memctrl;
    wire load_store_sign_from_ls_ex_to_memctrl;
    wire finish_sign_from_memctrl_to_ls_ex;
    wire [2:0] size_of_ls;
    wire [`DATA_TYPE] store_data_of_ls;
    wire [`DATA_TYPE] load_data_of_ls;
    wire [`ADDR_TYPE] addr_of_ls;

    // Fetcher & Predictor
    wire predicted_jump_sign_from_pdt_to_fch;
    wire [`ADDR_TYPE] predicted_pc_from_pdt_to_fch;
    wire [`ADDR_TYPE] pc_from_fch_to_pdt;
    wire [`INST_TYPE] inst_from_fch_to_pdt;
    
    // Fetcher & Commander
    wire finish_flag_from_fch_to_cmd;
    wire [`INST_TYPE] inst_from_fch_to_cmd;
    wire [`ADDR_TYPE] pc_from_fch_to_cmd;
    wire [`ADDR_TYPE] rollback_pc_from_fch_to_cmd;
    wire predicted_jump_sign_from_fch_to_cmd;

    // Fetcher & ROB
    wire rollback_sign_from_rob_to_fch;
    wire [`ADDR_TYPE] pc_from_rob_to_fch;

    // full sign to Fetcher
    wire full_sign_from_rs, full_sign_from_ls, full_sign_from_rob;
    wire full_sign_to_fch = (full_sign_from_ls || full_sign_from_rs || full_sign_from_rob);

    // ROB & Predictor
    wire hit_from_rob_to_pdt;
    wire enable_sign_from_rob_to_pdt;
    wire [`ADDR_TYPE] pc_from_rob_to_pdt;

    // ROB & Register
    wire commit_sign_from_rob_to_reg;
    wire rollback_sign_from_rob_to_reg;
    wire [`DATA_TYPE] V_from_rob_to_reg;
    wire [`ROB_ID_TYPE] Q_from_rob_to_reg;
    wire [`REG_POS_TYPE] rd_from_rob_to_reg;

    // ROB & Commander
    wire [`ROB_ID_TYPE] Q1_from_cmd_to_rob;
    wire [`ROB_ID_TYPE] Q2_from_cmd_to_rob;
    wire Q1_ready_sign_from_rob_to_cmd;
    wire Q2_ready_sign_from_rob_to_cmd;
    wire [`DATA_TYPE] V1_from_rob_to_cmd;
    wire [`DATA_TYPE] V2_from_rob_to_cmd;
    wire enable_sign_from_cmd_to_rob;
    wire is_jump_inst_from_cmd_to_rob;
    wire predicted_jump_sign_from_cmd_to_rob;
    wire [`REG_POS_TYPE] rd_from_cmd_to_rob;
    wire [`ADDR_TYPE] pc_from_cmd_to_rob;
    wire [`ADDR_TYPE] rollback_pc_from_cmd_to_rob;
    wire [`ROB_ID_TYPE] rob_id_from_rob_to_cmd;

    // ROB & LS
    wire valid_sign_from_ls_to_rob;
    wire [`ROB_ID_TYPE] rob_id_from_ls_to_rob;
    wire [`DATA_TYPE] data_from_ls_to_rob;
    wire [`ROB_ID_TYPE] io_rob_id_from_ls_to_rob;

    // Commander & Register
    wire [`ROB_ID_TYPE] Q1_from_reg_to_cmd;
    wire [`ROB_ID_TYPE] Q2_from_reg_to_cmd;
    wire [`DATA_TYPE] V1_from_reg_to_cmd;
    wire [`DATA_TYPE] V2_from_reg_to_cmd;
    wire enable_sign_from_cmd_to_reg;
    wire [`REG_POS_TYPE] rd_from_cmd_to_reg;
    wire [`ROB_ID_TYPE] rd_rob_id_from_cmd_to_reg;
    wire [`REG_POS_TYPE] rs1_from_cmd_to_reg;
    wire [`REG_POS_TYPE] rs2_from_cmd_to_reg;

    // Commander & RS
    wire enable_sign_from_cmd_to_rs;
    wire [`OPNUM_TYPE] opnum_from_cmd_to_rs;
    wire [`DATA_TYPE] V1_from_cmd_to_rs;
    wire [`DATA_TYPE] V2_from_cmd_to_rs;
    wire [`ROB_ID_TYPE] Q1_from_cmd_to_rs;
    wire [`ROB_ID_TYPE] Q2_from_cmd_to_rs;
    wire [`ADDR_TYPE] pc_from_cmd_to_rs;
    wire [`DATA_TYPE] imm_from_cmd_to_rs;
    wire [`ROB_ID_TYPE] rob_id_from_cmd_to_rs;

    // Commander & LS
    wire enable_sign_from_cmd_to_ls;
    wire [`OPNUM_TYPE] opnum_from_cmd_to_ls;
    wire [`DATA_TYPE] V1_from_cmd_to_ls;
    wire [`DATA_TYPE] V2_from_cmd_to_ls;
    wire [`ROB_ID_TYPE] Q1_from_cmd_to_ls;
    wire [`ROB_ID_TYPE] Q2_from_cmd_to_ls;
    wire [`DATA_TYPE] imm_from_cmd_to_ls;
    wire [`ROB_ID_TYPE] rob_id_from_cmd_to_ls;

    // RS & RS_EX
    wire [`OPNUM_TYPE] opnum_from_rs_to_rs_ex;
    wire [`DATA_TYPE] V1_from_rs_to_rs_ex;
    wire [`DATA_TYPE] V2_from_rs_to_rs_ex;
    wire [`DATA_TYPE] imm_from_rs_to_rs_ex;
    wire [`ADDR_TYPE] pc_from_rs_to_rs_ex;

    // LS & LS_EX
    wire enable_sign_from_ls_to_ls_ex;
    wire [`OPNUM_TYPE] opnum_from_ls_to_ls_ex;
    wire [`ADDR_TYPE] address_from_ls_to_ls_ex;
    wire [`DATA_TYPE] store_data_from_ls_to_ls_ex;

    // Global
    // from RS_EX
    wire valid_sign_from_rs_ex;
    wire jump_sign_from_rs_ex;
    wire [`ADDR_TYPE] target_pc_from_rs_ex;
    wire [`DATA_TYPE] data_from_rs_ex;
    wire [`ROB_ID_TYPE] rob_id_from_rs_ex;

    // from LS_EX
    wire valid_sign_from_ls_ex;
    wire [`ROB_ID_TYPE] rob_id_from_ls_ex;
    wire [`DATA_TYPE] data_from_ls_ex;

    // from ROB
    wire commit_sign_from_rob;
    wire rollback_sign_from_rob;

    MemCtrl memctrl (
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in)
    );

    ROB rob (
    );

    Predictor predictor (
    );

    Register register (
    );

    Fetcher fetcher (
    );

    Commander commander (
    );

    RS rs (
    );

    RS_EX rs_ex (
    );

    LS ls (
    );

    LS_EX ls_ex (
    );


endmodule
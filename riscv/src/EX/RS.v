`include "riscv\src\defines.v"

module RS (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from cmd
    input wire enable_sign_from_cmd,
    input wire [`OPNUM_TYPE] opnum_from_cmd,
    input wire [`DATA_TYPE] V1_from_cmd,
    input wire [`DATA_TYPE] V2_from_cmd,
    input wire [`ROB_ID_TYPE] Q1_from_cmd,
    input wire [`ROB_ID_TYPE] Q2_from_cmd,
    input wire [`ADDR_TYPE] pc_from_cmd,
    input wire [`DATA_TYPE] imm_from_cmd,
    input wire [`ROB_ID_TYPE] rob_id_from_cmd,

    // from & to RS_EX
    input wire valid_sign_from_rs_ex,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_ex,
    input wire [`DATA_TYPE] data_from_rs_ex,
    output reg [`OPNUM_TYPE] opnum_to_rs_ex,
    output reg [`DATA_TYPE] V1_to_rs_ex,
    output reg [`DATA_TYPE] V2_to_rs_ex,
    output reg [`DATA_TYPE] pc_to_rs_ex,
    output reg [`DATA_TYPE] imm_to_rs_ex,
    
    // from LS_EX
    input wire valid_sign_from_ls_ex,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_ex,
    input wire [`DATA_TYPE] data_from_ls_ex,

    // from ROB
    input wire rollback_sign_from_rob,

    // to fetcher
    output wire full_sign_to_if,

    // global output
    output reg [`ROB_ID_TYPE] rob_id
);

endmodule
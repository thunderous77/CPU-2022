`include "riscv\src\defines.v"

module LS (
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
    input wire [`DATA_TYPE] imm_from_cmd,
    input wire [`ROB_ID_TYPE] rob_id_from_cmd,

    // from ROB
    input wire rollback_sign_from_rob,
    input wire commit_sign_from_rob,
    input wire [`ROB_ID_TYPE] rob_id_from_rob,

    // from RS_EX
    input wire [`ROB_ID_TYPE] rob_id_from_rs_ex,
    input wire [`DATA_TYPE] data_from_rs_ex,
    output reg [`OPNUM_TYPE] opnum_to_rs_ex,

    // from & to LS_EX
    input wire full_sign_from_ls_ex,
    input wire valid_sign_from_ls_ex,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_ex,
    input wire [`DATA_TYPE] data_from_ls_ex,
    output reg enable_sign_to_ls_ex,
    output reg [`OPNUM_TYPE] opnum_to_ls_ex,
    output reg [`ADDR_TYPE] address_to_ls_ex,
    output reg [`DATA_TYPE] store_data_to_ls_ex,

    // to fetcher
    output wire full_sign_to_fch,

    // global output
    output reg [`ROB_ID_TYPE] rob_id
);

endmodule
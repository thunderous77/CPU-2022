`include "riscv\src\defines.v"

module RS_EX (
    // from rs
    input wire [`OPNUM_TYPE] opnum_from_rs,
    input wire [`DATA_TYPE] V1_from_rs,
    input wire [`DATA_TYPE] V2_from_rs,
    input wire [`DATA_TYPE] imm_from_rs,
    input wire [`ADDR_TYPE] pc_from_rs,

    // global output
    output reg [`DATA_TYPE] data,
    output reg [`ADDR_TYPE] target_pc,
    output reg jump_sign,
    output reg valid_sign
);

endmodule
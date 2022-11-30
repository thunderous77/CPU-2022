`include "riscv\src\defines.v"

module Register (
    input wire clk,
    input wire rst,

    // from & to cmd
    input wire enable_sign_from_cmd,
    input wire [`REG_POS_TYPE] rd_from_cmd,
    input wire [`ROB_ID_TYPE] rd_rob_id_from_cmd,
    input wire [`REG_POS_TYPE] rs1_from_cmd,
    input wire [`REG_POS_TYPE] rs2_from_cmd,
    output wire [`DATA_TYPE] V1_to_cmd,
    output wire [`DATA_TYPE] V2_to_cmd,
    output wire [`ROB_ID_TYPE] Q1_to_cmd,
    output wire [`ROB_ID_TYPE] Q2_to_cmd,

    // from ROB
    input wire commit_sign_from_rob,
    input wire rollback_sign_from_rob,
    input wire [`DATA_TYPE] V_from_rob,
    input wire [`ROB_ID_TYPE] Q_from_rob,
    input wire [`REG_POS_TYPE] rd_from_rob

);

    // register store
    reg [`ROB_ID_TYPE] Q [`REG_SIZE-1:0];
    reg [`DATA_TYPE] V [`REG_SIZE-1:0];

    wire commit_data_valid_sign = (enable_sign_from_cmd && rd_from_rob == rd_from_cmd) ? `FALSE : (Q[rd_from_rob] == Q_from_rob ? `TRUE : `FALSE);

    assign Q1_to_cmd = (rd_from_rob == rs1_from_cmd && commit_data_valid_sign) ? `ZERO_ROB : (rd_from_cmd == rs1_from_cmd ? rd_rob_id_from_cmd : (rollback_sign_from_rob ? `ZERO_ROB : Q[rs1_from_cmd]));
    assign Q2_to_cmd = (rd_from_rob == rs2_from_cmd && commit_data_valid_sign) ? `ZERO_ROB : (rd_from_cmd == rs2_from_cmd ? rd_rob_id_from_cmd : (rollback_sign_from_rob ? `ZERO_ROB : Q[rs2_from_cmd]));
    assign V1_to_cmd = (rd_from_rob == rs1_from_cmd) ? V_from_rob : V[rs1_from_cmd];
    assign V2_to_cmd = (rd_from_rob == rs2_from_cmd) ? V_from_rob : V[rs2_from_cmd];

    always @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < `REG_SIZE; i = i + 1) begin
                Q[i] <= `ZERO_ROB;
                V[i] <= `NULL;
            end
        end
        else begin
            if (rollback_sign_from_rob) begin
                for (integer i = 0; i < `REG_SIZE; i = i + 1) Q[i] <= `ZERO_ROB;
            end
            // reorder
            else if (enable_sign_from_cmd && rd_from_cmd != `ZERO_REG) begin
                Q[rd_from_cmd] <= rd_rob_id_from_cmd;
            end 

            if (commit_sign_from_rob) begin
                if (rd_from_rob != `ZERO_REG) begin
                    V[rd_from_rob] <= V_from_rob;
                    if (commit_data_valid_sign) Q[rd_from_rob] <= `ZERO_ROB;
                end
            end
        end
    end
endmodule
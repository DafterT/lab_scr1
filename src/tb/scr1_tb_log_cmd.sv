module scr1_tb_log_cmd();

  always_ff @(posedge scr1_top_tb_ahb.i_top.i_imem_ahb.clk) begin
    if (scr1_top_tb_ahb.i_top.i_imem_ahb.imem_resp == 2'b01) begin
      // valid data from AHB router
      if (
        (scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[6  : 0]  == 7'b1100011) && // opcode for branches (BEQ/BNE/...)
        (scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[14 : 12] == 3'b000)        // funct3 for BEQ
      ) begin
        // detect BEQ command
        $display("BEQ: opcode=%b funct3=%b rs1=%b rs2=%b imm[12]=%b imm[11]=%b imm[10:5]=%b imm[4:1]=%b (imm[0]=0)",
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[6:0],
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[14:12],
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[19:15],
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[24:20],
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[31],       // imm[12]
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[7],        // imm[11]
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[30:25],    // imm[10:5]
          scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[11:8],     // imm[4:1]
        );
      end
    end
  end

endmodule
module scr1_tb_log_cmd();

  always_ff @(posedge scr1_top_tb_ahb.i_top.i_imem_ahb.clk) begin
    if (scr1_top_tb_ahb.i_top.i_imem_ahb.imem_resp == 2'b01) begin
      // valid data from AHB router
      if (
        (scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[6  : 0]  == 7'b1100011) && // opcode for branches (BEQ/BNE/...)
        (scr1_top_tb_ahb.i_top.i_imem_ahb.imem_rdata[14 : 12] == 3'b000)        // funct3 for BEQ
      ) begin
        // detect BEQ command
        $display("Detect BEQ command");
      end
    end
  end

endmodule

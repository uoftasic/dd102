// 06_needs_g2012.sv — CORRECT SYSTEMVERILOG. Breaks without -g2012.
// `always_comb` is a SystemVerilog keyword. Plain `iverilog` defaults to an
// older Verilog and does not know it. The error text never mentions the flag.
//   iverilog        -o /dev/null syntax/06_needs_g2012.sv   -> fails
//   iverilog -g2012 -o /dev/null syntax/06_needs_g2012.sv   -> exit 0
module needs_g2012 (input logic a, input logic b, output logic y);
    always_comb begin
        y = a ^ b;
    end
endmodule

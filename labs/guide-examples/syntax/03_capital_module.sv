// 03_capital_module.sv — BROKEN ON PURPOSE.
// `Module` with a capital M. SystemVerilog keywords are lowercase, always.
Module capital_module (input logic a, output logic y);
    assign y = ~a;
endmodule

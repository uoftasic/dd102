// 04_unknown_module.sv — BROKEN ON PURPOSE.
// Instantiates half_adder without compiling a file that defines it.
// This is the error you get from forgetting a filename on the command line.
module unknown_module (input logic a, input logic b, output logic s, output logic c);
    half_adder ha (.a(a), .b(b), .sum(s), .carry(c));
endmodule

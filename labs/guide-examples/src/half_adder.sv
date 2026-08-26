// half_adder.sv — the DD101 Lab 03 subcircuit, as a module.
module half_adder (
    input  logic a,
    input  logic b,
    output logic sum,
    output logic carry
);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

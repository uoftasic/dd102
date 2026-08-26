// full_adder_flat.sv — the same adder written as one expression per output.
// No internal wires, no half adders. Two lines of logic.
module full_adder_flat (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

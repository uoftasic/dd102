// broken/full_adder.sv — DELIBERATELY WRONG. One character is different
// from src/full_adder.sv: the Or gate on the last line is an And.
// `make eight-broken` runs the same testbench against this file so you can
// read a FAIL you caused on purpose.
module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    logic ha1_sum, ha1_carry, ha2_carry;

    assign ha1_sum   = a ^ b;
    assign ha1_carry = a & b;
    assign sum       = ha1_sum ^ cin;
    assign ha2_carry = ha1_sum & cin;
    assign cout      = ha1_carry & ha2_carry;   // <-- & where the drawing has an Or
endmodule

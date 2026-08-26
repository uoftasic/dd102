// full_adder.sv — your DD101 drawing, transcribed one wire at a time.
//
// Ports first: the same five labels that are on your paper.
// Then one `assign` per wire, in the order the signal travels.
module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    // The two wires between the half adders. They have names on your
    // drawing too — these are those names.
    logic ha1_sum, ha1_carry, ha2_carry;

    assign ha1_sum   = a ^ b;              // first half adder, sum
    assign ha1_carry = a & b;              // first half adder, carry
    assign sum       = ha1_sum ^ cin;      // second half adder, sum
    assign ha2_carry = ha1_sum & cin;      // second half adder, carry
    assign cout      = ha1_carry | ha2_carry;   // the Or gate
endmodule

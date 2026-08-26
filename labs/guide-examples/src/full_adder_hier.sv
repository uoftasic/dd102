// full_adder_hier.sv — the drawing taken literally: two half adder BOXES
// and an Or. Needs half_adder.sv compiled alongside it.
module full_adder_hier (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    logic ha1_sum, ha1_carry, ha2_carry;

    half_adder ha1 (.a(a),       .b(b),   .sum(ha1_sum), .carry(ha1_carry));
    half_adder ha2 (.a(ha1_sum), .b(cin), .sum(sum),     .carry(ha2_carry));

    assign cout = ha1_carry | ha2_carry;
endmodule

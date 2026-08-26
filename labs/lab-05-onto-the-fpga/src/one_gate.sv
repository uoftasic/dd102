// one_gate.sv — the smallest design that is still a design.
module one_gate (
    input  logic a,
    input  logic b,
    output logic y
);
    assign y = a & b;
endmodule

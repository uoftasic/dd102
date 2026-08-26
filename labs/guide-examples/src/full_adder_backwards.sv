// full_adder_backwards.sv — src/full_adder.sv with the five assign lines
// written in exactly the reverse order. Nothing else is different.
// `make backwards` runs it. It passes, and it costs the same 33.7824 um^2.
// The lines are not steps. They are solder joints, and all five are live
// at the same time.
module full_adder_backwards (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    logic ha1_sum, ha1_carry, ha2_carry;

    assign cout      = ha1_carry | ha2_carry;
    assign ha2_carry = ha1_sum & cin;
    assign sum       = ha1_sum ^ cin;
    assign ha1_carry = a & b;
    assign ha1_sum   = a ^ b;
endmodule

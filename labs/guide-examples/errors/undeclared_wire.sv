// COMPILES AND SIMULATES CORRECTLY. SYNTHESIZES WITH A WARNING. ON PURPOSE.
// This is src/full_adder.sv with the `logic ha1_sum, ha1_carry, ha2_carry;`
// declaration deleted. Icarus says nothing at all. Yosys warns.
//   iverilog -g2012 -o /dev/null errors/undeclared_wire.sv     -> exit 0, silent
//   yosys -p "read_verilog -sv errors/undeclared_wire.sv; synth -top undeclared_wire"
module undeclared_wire (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    assign ha1_sum   = a ^ b;
    assign ha1_carry = a & b;
    assign sum       = ha1_sum ^ cin;
    assign ha2_carry = ha1_sum & cin;
    assign cout      = ha1_carry | ha2_carry;
endmodule

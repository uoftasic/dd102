// SIMULATES FINE. DOES NOT SYNTHESIZE. ON PURPOSE.
// An always_comb block that does not assign its outputs on every path.
// Icarus compiles it without a word; Yosys refuses it.
//   iverilog -g2012 -o /dev/null errors/forgot_a_branch.sv     -> exit 0
//   yosys -p "read_verilog -sv errors/forgot_a_branch.sv; synth -top forgot_a_branch"
module forgot_a_branch (
    input  logic a, b, cin,
    output logic sum, cout
);
    always_comb begin
        if (cin) begin
            sum  = a ^ b ^ cin;
            cout = (a & b) | (cin & (a ^ b));
        end
        // nothing here says what sum and cout are when cin is 0
    end
endmodule

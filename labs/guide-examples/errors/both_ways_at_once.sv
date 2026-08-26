// DOES NOT COMPILE, ON PURPOSE.
// `sum` is driven by an always_comb block AND by a continuous assign.
// Two drivers, spelled two different ways. Same rule, same refusal.
//   iverilog -g2012 -o /dev/null errors/both_ways_at_once.sv
module both_ways_at_once (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    always_comb begin
        sum  = a ^ b ^ cin;
        cout = (a & b) | (cin & (a ^ b));
    end

    assign sum = a ^ b;
endmodule

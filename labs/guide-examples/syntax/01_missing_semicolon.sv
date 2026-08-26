// 01_missing_semicolon.sv — BROKEN ON PURPOSE.
// The assign on line 4 has no semicolon. Icarus reports line 5.
module missing_semicolon (input logic a, input logic b, output logic y);
    assign y = a & b
endmodule

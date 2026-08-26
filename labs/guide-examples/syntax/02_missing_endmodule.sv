// 02_missing_endmodule.sv — BROKEN ON PURPOSE.
// There is no `endmodule`. The file is 5 lines long and Icarus reports line 6 --
// one past the end, because that is where it ran out of file still waiting.
module missing_endmodule (input logic a, output logic y);
    assign y = ~a;

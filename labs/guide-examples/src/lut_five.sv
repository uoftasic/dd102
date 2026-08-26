// lut_five.sv — the same simple AND as lut_simple.sv, with ONE more input.
// Nothing else changes. The LUT count does.
// Printed in the guide as an excerpt; this is the whole file.
//   yosys -p "read_verilog -sv src/lut_five.sv; synth_ice40 -top lut_five; stat"
module lut_five (
    input  logic a, b, c, d, e,
    output logic y
);
    assign y = a & b & c & d & e;
endmodule

// lut_weird.sv — a four-input function with no name and no pattern.
// Deliberately awkward: it exists to cost exactly as much as the other two.
// Printed in the guide as an excerpt; this is the whole file.
//   yosys -p "read_verilog -sv src/lut_weird.sv; synth_ice40 -top lut_weird; stat"
module lut_weird (
    input  logic a, b, c, d,
    output logic y
);
    assign y = (a ^ b) ? (c & ~d) : (~c | d);
endmodule

// lut_parity.sv — four-input XOR. "Is an odd number of these inputs high?"
// Printed in the guide as an excerpt; this is the whole file.
//   yosys -p "read_verilog -sv src/lut_parity.sv; synth_ice40 -top lut_parity; stat"
module lut_parity (
    input  logic a, b, c, d,
    output logic y
);
    assign y = a ^ b ^ c ^ d;
endmodule

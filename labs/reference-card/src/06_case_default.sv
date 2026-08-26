// 06_case_default.sv — `case` with a `default`, inside always_comb.
//
// A case is a truth table you can read. `default:` is the row that catches
// everything you did not write down, and leaving it out is how you get
// hardware that remembers things you never asked it to remember.
//   iverilog -g2012 -o 06.vvp src/06_case_default.sv && vvp 06.vvp
module decoder (
    input  logic [1:0] sel,
    output logic [3:0] onehot
);
    always_comb begin
        case (sel)
            2'b00:   onehot = 4'b0001;
            2'b01:   onehot = 4'b0010;
            2'b10:   onehot = 4'b0100;
            2'b11:   onehot = 4'b1000;
            default: onehot = 4'b0000;
        endcase
    end
endmodule

module card06;
    logic [1:0] sel;
    logic [3:0] onehot;
    decoder dut (.sel(sel), .onehot(onehot));
    initial begin
        $write("06_case_default:");
        for (int s = 0; s < 4; s++) begin
            sel = s[1:0]; #1;
            $write(" %b->%b", sel, onehot);
        end
        $display("");
    end
endmodule

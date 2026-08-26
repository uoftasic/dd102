// tb/tb_exhaustive_fixed.sv  --  the identical 512 inputs, aimed at add5.
//
// This is tb/tb_exhaustive.sv with three characters' worth of difference: it
// instantiates add5 instead of add4, and it compares {cout, sum} -- five bits
// -- against the five-bit expected value, instead of comparing four bits
// against five.
//
// Shipped, complete, nothing for you to fill in.

`timescale 1ns/1ps

module tb_exhaustive_fixed;

    logic [3:0] a, b;
    logic       cin;
    logic [3:0] sum;
    logic       cout;
    logic [4:0] expected;

    int checked  = 0;
    int errors   = 0;
    int err_cin0 = 0;
    int err_cin1 = 0;
    int shown    = 0;

    int ai, bi, ci;

    add5 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    initial begin
        $display("tb_exhaustive_fixed: all 512 inputs of add5");

        for (ai = 0; ai < 16; ai = ai + 1) begin
            for (bi = 0; bi < 16; bi = bi + 1) begin
                for (ci = 0; ci < 2; ci = ci + 1) begin
                    a        = ai[3:0];
                    b        = bi[3:0];
                    cin      = ci[0];
                    expected = ai + bi + ci;
                    #1;
                    checked = checked + 1;
                    if ({cout, sum} !== expected) begin
                        errors = errors + 1;
                        if (ci == 0) err_cin0 = err_cin0 + 1;
                        else         err_cin1 = err_cin1 + 1;
                        if (shown < 5) begin
                            shown = shown + 1;
                            $display("  MISMATCH  %0d + %0d + %0d : add5 said %0d, the answer is %0d",
                                     ai, bi, ci, sum, expected);
                        end
                    end
                end
            end
        end

        if (errors > shown)
            $display("  ... and %0d more. Only the first %0d are printed.", errors - shown, shown);

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        $display("  with cin=0 : %0d", err_cin0);
        $display("  with cin=1 : %0d", err_cin1);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end

endmodule

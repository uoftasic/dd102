// tb/tb_lazy.sv  --  YOUR FILE. This is the one you edit.
//
// Three cases are in. Three are yours. Pick numbers you would actually use to
// convince yourself a 4-bit adder works, write them in, and run `make lazy`.
//
// Nothing here is a trick. The expected value is computed honestly, in five
// bits, so nothing gets rounded off on this side of the comparison.

`timescale 1ns/1ps

module tb_lazy;

    logic [3:0] a, b;
    logic       cin;
    logic [3:0] sum;
    logic [4:0] expected;       // five bits, so the expectation itself never overflows

    int checked = 0;
    int errors  = 0;

    add4 dut (.a(a), .b(b), .cin(cin), .sum(sum));

    task try_one(input logic [3:0] ia, input logic [3:0] ib, input logic icin);
        a        = ia;
        b        = ib;
        cin      = icin;
        expected = ia + ib + icin;
        #1;
        checked = checked + 1;
        if ({1'b0, sum} !== expected) begin
            errors = errors + 1;
            $display("  MISMATCH  %0d + %0d + %0d : add4 said %0d, the answer is %0d",
                     ia, ib, icin, sum, expected);
        end
    endtask

    initial begin
        $display("tb_lazy: a few cases somebody thought were representative");

        //      a      b     cin
        try_one(4'd1,  4'd2, 1'b0);      // 1 + 2 = 3
        try_one(4'd3,  4'd4, 1'b0);      // 3 + 4 = 7
        try_one(4'd5,  4'd2, 1'b1);      // 5 + 2 + 1 = 8

        // TODO: three more. Your choice. Convince yourself.

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end

endmodule

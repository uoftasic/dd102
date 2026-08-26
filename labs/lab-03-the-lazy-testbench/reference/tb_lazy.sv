// reference/tb_lazy.sv  --  six cases a careful person would pick.
//
// Open this only after you have written your own three. The interesting thing
// is not whether yours match these; it is that almost any six numbers a person
// picks by hand land in the same place these do.

`timescale 1ns/1ps

module tb_lazy;

    logic [3:0] a, b;
    logic       cin;
    logic [3:0] sum;
    logic [4:0] expected;

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

        //      a      b      cin
        try_one(4'd1,  4'd2,  1'b0);     // 1 + 2 = 3
        try_one(4'd3,  4'd4,  1'b0);     // 3 + 4 = 7
        try_one(4'd5,  4'd2,  1'b1);     // 5 + 2 + 1 = 8
        try_one(4'd0,  4'd0,  1'b0);     // the zero case, because you always do
        try_one(4'd6,  4'd9,  1'b0);     // 6 + 9 = 15, the biggest number there is
        try_one(4'd7,  4'd7,  1'b1);     // 7 + 7 + 1 = 15, with the carry in used

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end

endmodule

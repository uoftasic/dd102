// tb/tb_full_adder.sv  --  YOUR FILE. This is the one you edit.
//
// It works exactly as shipped: `make` will run it and it will say PASS.
// It says PASS after checking ONE row out of eight. That is the problem.
//
// Your job is the seven `check(...)` calls that are missing. Everything else
// -- the wires, the instance, the counters, the verdict -- is done.
//
// A testbench is not magic and it is not a new language. It is a module with
// no inputs and no outputs that pokes wires and looks at what came back.

`timescale 1ns/1ps

module tb_full_adder;

    // The wires that run between this testbench and the thing being tested.
    logic a, b, cin;      // we drive these
    logic sum, cout;      // the adder drives these

    int checked = 0;      // how many rows we looked at
    int errors  = 0;      // how many of them were wrong

    // The Device Under Test. Same five port names as src/full_adder.sv.
    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    // One row of the truth table: set the inputs, wait, compare, complain.
    task check(input logic ia, input logic ib, input logic icin,
               input logic want_cout, input logic want_sum);
        a   = ia;
        b   = ib;
        cin = icin;
        #1;                       // let the gates settle before looking
        checked = checked + 1;
        if (sum !== want_sum || cout !== want_cout) begin
            errors = errors + 1;
            $display("  MISMATCH  a=%b b=%b cin=%b : got cout=%b sum=%b, want cout=%b sum=%b",
                     ia, ib, icin, cout, sum, want_cout, want_sum);
        end
    endtask

    initial begin
        $display("tb_full_adder: checking module full_adder");

        //    a  b  cin   cout  sum
        check(0, 0,  0,    0,    0);

        // TODO: seven more rows. They are already written down -- they are the
        // other seven lines of the truth table you filled in by hand in DD101.
        //
        // Keep the column order: a, b, cin, cout, sum.

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end

endmodule

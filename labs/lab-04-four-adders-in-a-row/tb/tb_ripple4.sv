// tb_ripple4.sv — every input a 4-bit adder can ever see. 16 x 16 x 2 = 512.
`timescale 1ns / 1ps

module tb_ripple4;

    logic [3:0] a, b;
    logic       cin;
    logic [3:0] sum;
    logic       cout;

    ripple4 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    logic [4:0] want;
    int  bad   = 0;
    int  shown = 0;
    time first_bad = 0;

    initial begin
        $timeformat(-9, 0, " ns", 6);
        $dumpfile("ripple4.vcd");
        $dumpvars(0, tb_ripple4);

        for (int i = 0; i < 16; i++)
        for (int j = 0; j < 16; j++)
        for (int k = 0; k < 2;  k++) begin
            a = i[3:0]; b = j[3:0]; cin = k[0];
            #10;
            want = a + b + cin;
            if ({cout, sum} !== want) begin
                if (bad == 0) first_bad = $time;
                bad++;
                if (shown < 5) begin
                    $display("  a=%0d b=%0d cin=%0d   want %0d   got %0d",
                             a, b, cin, want, {cout, sum});
                    shown++;
                end
            end
            #10;
        end

        $display("");
        if (bad == 0) begin
            $display("PASS  0 mismatches out of 512");
        end else begin
            if (bad > 5) $display("  ... and %0d more not shown", bad - 5);
            $display("FAIL  %0d mismatches out of 512, first at t = %0t", bad, first_bad);
        end
        $finish;
    end
endmodule

// Ripple-Carry Adder (N-bit) RCAN
// Instantiate via:
// rcan #(.N(32)) adder (
// .a(a), 
// .b(b),
// .cin(1'b0)
// .s(s),
// .cout(cout)
// );
// logic [1:0] a: a is a 2-bit vector.
// logic a[1:0]: a is not a 2-bit vector. a[1], a[0] are seperate entities
module rcan #(parameter int N = 64)
(
input logic[N-1:0] a,
input logic[N-1:0] b,
input logic cin,
output logic[N-1:0] s,
output logic cout
);
genvar i;
logic[N:0] carry;
assign carry[0] = cin;
assign cout = carry[N];
generate
    for(i=0; i<N; i++) begin : gen_fa
        fa fa_i(
            .a(a[i]),
            .b(b[i]),
            .cin(carry[i]),
            .s(s[i]),
            .cout(carry[i+1])
        );
    end 
endgenerate


endmodule
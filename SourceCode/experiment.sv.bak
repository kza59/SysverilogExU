module experiment #(parameter int N = 32)(
input logic [N-1:0] a,b,
output logic y
);
always_comb begin
generate
for (int i = 0; i < N; i++) begin
y &= a[i];
end
endgenerate
end


endmodule
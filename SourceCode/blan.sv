// Block Lookahead Adder (N bit) BLAN
// Block size configurable
module blan #(
    parameter int N = 4,
    parameter int B = 4
)
(
input logic [N-1:0] a,
input logic [N-1:0] b,
input logic cin,
output logic [N-1:0] s,
output logic cout
);

// Lookahead blocks of size B
// c1 = g0 + c0p0 = a0b0 + cin(a0 + b0)                             = a0b0 + cina0 + cinb0
// c2 = g1 + c1p1 = a1b1 + (a0b0 + cin(a0 + b0))(a1 + b1)           = a1b1 + a1a0b0 + b1b0a0 + a1a0cin + b1a0cin + a1b0cin + b1b0cin
// Generate linearly
// c1 =                                             g0 + p0c0
// c2 = g1 + (g0 + c0p0)p1 =                        g1 + p1g0 + p1p0c0
// c3 = g2 + (g1 + g0p1 + p1p0c0)p2 =               g2 + p2g1 + p2p1g0 + p2p1p0c0
// c4 = g3 + (g2 + p2g1 + p2p1g0 + p2p1p0c0)p3 =    g3 + p3g2 + p3p2g1 + p3p2p1g0 + p3p2p1p0c0
genvar i;
logic [N:0] carry;
logic [N-1:0] g,p;
assign cout = carry[N];
assign carry[0] = cin;
genvar blk;
generate
	for(i = 0; i < N; i++) begin : bitwisepgs
		always_comb begin
		g[i] = a[i] & b[i];
		p[i] = a[i] ^ b[i];
		end
	end
endgenerate

generate
	for (blk = 0; blk < N/B ; blk++) begin : blockwise
	// eg: 16 bits, 4 lookahead blocks
			always_comb begin
				for (int i = 1; i <= B; i++) begin
					logic [B:0] terms;
					logic int_term;
					logic trailing;
					logic final_term;	
					int l;
					
					// leading term
					terms[0] = g[i-1];
					
					// intermediate terms
					for (int j = 1; j < i; j++) begin
						int_term = p[blk*B + i-1];
						for (int l = i-2; l >= i-j; l--) begin
							int_term &= p[blk*B + l];
						end
						int_term &= g[blk*B + i-1-j];
						terms[j] = int_term;
					end
					
					// trailing term
					trailing = carry[blk*B];
					for(int k = i-1; k >= 0; k--) begin
						trailing &= p[k];
					end
					
					// final term
					final_term = trailing;
					for (int b = 0; b < i; b++) begin
						final_term |= terms[b];
					end
					carry[blk*B+i] = final_term;
				end
			end
	end
endgenerate

generate
	// eqn is s[i] = p[i] ^ carry[i]
	always_comb begin
		for (int i = 0; i < N; i++) begin : sumbits
			s[i] = p[i] ^ carry[i];
		end
	end
endgenerate

endmodule
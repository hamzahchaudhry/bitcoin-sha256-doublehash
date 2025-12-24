module sha256_compress (
    input  logic         clk,
    input  logic         reset,
    input  logic         start,
    input  logic [511:0] chunk,
    input  logic [255:0] state_in,
    output logic [255:0] state_out,
    output logic         finish
);

  /* constants */
  localparam logic [31:0] K[0:63] = '{
    32'h428a2f98,
    32'h71374491,
    32'hb5c0fbcf,
    32'he9b5dba5,
    32'h3956c25b,
    32'h59f111f1,
    32'h923f82a4,
    32'hab1c5ed5,
    32'hd807aa98,
    32'h12835b01,
    32'h243185be,
    32'h550c7dc3,
    32'h72be5d74,
    32'h80deb1fe,
    32'h9bdc06a7,
    32'hc19bf174,
    32'he49b69c1,
    32'hefbe4786,
    32'h0fc19dc6,
    32'h240ca1cc,
    32'h2de92c6f,
    32'h4a7484aa,
    32'h5cb0a9dc,
    32'h76f988da,
    32'h983e5152,
    32'ha831c66d,
    32'hb00327c8,
    32'hbf597fc7,
    32'hc6e00bf3,
    32'hd5a79147,
    32'h06ca6351,
    32'h14292967,
    32'h27b70a85,
    32'h2e1b2138,
    32'h4d2c6dfc,
    32'h53380d13,
    32'h650a7354,
    32'h766a0abb,
    32'h81c2c92e,
    32'h92722c85,
    32'ha2bfe8a1,
    32'ha81a664b,
    32'hc24b8b70,
    32'hc76c51a3,
    32'hd192e819,
    32'hd6990624,
    32'hf40e3585,
    32'h106aa070,
    32'h19a4c116,
    32'h1e376c08,
    32'h2748774c,
    32'h34b0bcb5,
    32'h391c0cb3,
    32'h4ed8aa4a,
    32'h5b9cca4f,
    32'h682e6ff3,
    32'h748f82ee,
    32'h78a5636f,
    32'h84c87814,
    32'h8cc70208,
    32'h90befffa,
    32'ha4506ceb,
    32'hbef9a3f7,
    32'hc67178f2
  };

  /* helper functions */
  function automatic logic [31:0] rotr(input logic [31:0] x, input int n);
    rotr = (x >> n) | (x << (32 - n));
  endfunction

  function automatic logic [31:0] shr(input logic [31:0] x, input int n);
    shr = (x >> n);
  endfunction

  function automatic logic [31:0] Ch(input logic [31:0] x, input logic [31:0] y,
                                     input logic [31:0] z);
    Ch = (x & y) ^ (~x & z);
  endfunction

  function automatic logic [31:0] Maj(input logic [31:0] x, input logic [31:0] y,
                                      input logic [31:0] z);
    Maj = (x & y) ^ (x & z) ^ (y & z);
  endfunction

  function automatic logic [31:0] SIG0(input logic [31:0] x);
    SIG0 = rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
  endfunction

  function automatic logic [31:0] SIG1(input logic [31:0] x);
    SIG1 = rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
  endfunction

  function automatic logic [31:0] sig0(input logic [31:0] x);
    sig0 = rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3);
  endfunction

  function automatic logic [31:0] sig1(input logic [31:0] x);
    sig1 = rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10);
  endfunction

  /* state machine */
  localparam logic [2:0] IDLE = 3'b000;
  localparam logic [2:0] LOAD = 3'b001;
  localparam logic [2:0] ROUND = 3'b010;
  localparam logic [2:0] FINISH = 3'b100;

  logic [2:0] state;
  logic round;
  assign round  = state[1];
  assign finish = state[2];

  logic [31:0] a, b, c, d, e, f, g, h;
  logic [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
  logic [31:0] W[64];
  logic [5:0] t;

  logic [31:0] w_new;
  logic [31:0] Wt;
  logic [31:0] T1, T2;


  /* message schedule word */
  always_comb begin
    w_new = 32'd0;
    Wt = 32'd0;

    if (round) begin
      if (t < 6'd16) begin
        Wt = W[t];
      end else begin
        w_new = sig1(W[t-2]) + W[t-7] + sig0(W[t-15]) + W[t-16];
        Wt = w_new;
      end
    end
  end

  /* round combinational */
  always_comb begin
    T1 = 32'd0;
    T2 = 32'd0;

    if (round) begin
      T1 = h + SIG1(e) + Ch(e, f, g) + K[t] + Wt;
      T2 = SIG0(a) + Maj(a, b, c);
    end
  end

  /* add compressed chunk to hash value */
  assign state_out = {
    (H0 + a), (H1 + b), (H2 + c), (H3 + d), (H4 + e), (H5 + f), (H6 + g), (H7 + h)
  };

  /* main sequential logic */
  integer i;
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      t <= 6'd0;

      a <= 32'd0;
      b <= 32'd0;
      c <= 32'd0;
      d <= 32'd0;
      e <= 32'd0;
      f <= 32'd0;
      g <= 32'd0;
      h <= 32'd0;

      H0 <= 32'd0;
      H1 <= 32'd0;
      H2 <= 32'd0;
      H3 <= 32'd0;
      H4 <= 32'd0;
      H5 <= 32'd0;
      H6 <= 32'd0;
      H7 <= 32'd0;

    end else begin
      case (state)
        IDLE: state <= start ? LOAD : IDLE;

        LOAD: begin
          /* latch input state words */
          H0 <= state_in[255:224];
          H1 <= state_in[223:192];
          H2 <= state_in[191:160];
          H3 <= state_in[159:128];
          H4 <= state_in[127:96];
          H5 <= state_in[95:64];
          H6 <= state_in[63:32];
          H7 <= state_in[31:0];

          /* init working vars a..h = H0..H7 */
          a  <= state_in[255:224];
          b  <= state_in[223:192];
          c  <= state_in[191:160];
          d  <= state_in[159:128];
          e  <= state_in[127:96];
          f  <= state_in[95:64];
          g  <= state_in[63:32];
          h  <= state_in[31:0];

          /* load W[0..15] from chunk */
          for (i = 0; i < 16; i++) begin
            W[i] <= chunk[511-(32*i)-:32];
          end

          t <= 6'd0;
          state <= ROUND;
        end

        ROUND: begin
          /* for t>=16, store newly generated schedule word */
          if (t >= 6'd16 && t <= 6'd63) begin
            W[t] <= w_new;
          end

          /* update working vars a..h */
          h <= g;
          g <= f;
          f <= e;
          e <= d + T1;
          d <= c;
          c <= b;
          b <= a;
          a <= T1 + T2;

          if (t == 6'd63) begin
            state <= FINISH;
          end else begin
            t <= t + 6'd1;
          end
        end

        FINISH:  state <= IDLE;
        default: state <= IDLE;
      endcase
    end
  end

endmodule

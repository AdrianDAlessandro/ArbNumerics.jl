for (A,F) in ((:log, :arb_log), (:log1p, :arb_log1p), (:exp, :arb_exp), (:expm1, :arb_expm1),
              (:sin, :arb_sin), (:cos, :arb_cos), (:tan, :arb_tan),
              (:csc, :arb_csc), (:sec, :arb_sec), (:cot, :arb_cot),
              (:sinpi, :arb_sin_pi), (:cospi, :arb_cos_pi), (:sinc, :arb_sinc),
              (:tanpi, :arb_tan_pi), (:cotpi, :arb_cot_pi), (:sincpi, :arb_sinc_pi),
              (:asin, :arb_asin), (:acos, :arb_acos), (:atan, :arb_atan),
              (:sinh, :arb_sinh), (:cosh, :arb_cosh), (:tanh, :arb_tanh),
              (:csch, :arb_csch), (:sech, :arb_sech), (:coth, :arb_coth),
              (:asinh, :arb_asinh), (:acosh, :arb_acosh), (:atanh, :arb_atanh),
             )
    @eval begin
        function ($A)(x::ArbReal{P}, prec::Int=P) where {P}
            z = ArbReal{P}()
            ccall(@libarb($F), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Clong), z, x, prec)
            return z
         end
    end
end

atan(y::ArbReal{P}, x::ArbReal{P}) where {P} = atan2(y, x)

const Cint0 = zero(Cint)


for (A,F) in ((:log, :acb_log), (:log1p, :acb_log1p), (:exp, :acb_exp), (:expm1, :acb_expm1),
              (:sin, :acb_sin), (:cos, :acb_cos), (:tan, :acb_tan),
              (:csc, :acb_csc), (:sec, :acb_sec), (:cot, :acb_cot),
              (:sinpi, :acb_sin_pi), (:cospi, :acb_cos_pi), (:sinc, :acb_sinc),
              (:tanpi, :acb_tan_pi), (:cotpi, :acb_cot_pi), (:sincpi, :acb_sinc_pi),
              (:asin, :acb_asin), (:acos, :acb_acos), (:atan, :acb_atan),
              (:sinh, :acb_sinh), (:cosh, :acb_cosh), (:tanh, :acb_tanh),
              (:csch, :acb_csch), (:sech, :acb_sech), (:coth, :acb_coth),
              (:asinh, :acb_asinh), (:acosh, :acb_acosh), (:atanh, :acb_atanh),
             )
    @eval begin
        function ($A)(x::ArbComplex{P}, prec::Int=P) where {P}
            z = ArbComplex{P}()
            ccall(@libarb($F), Cvoid, (Ref{ArbComplex}, Ref{ArbComplex}, Clong), z, x, prec)
            return z
         end
    end
end

for (A,F) in ((:loghypot, :arb_log_hypot), (:atan2, :arb_atan2))
    @eval begin
        function ($A)(x::ArbFloat{P}, y::ArbFloat{P}, prec::Int=P) where {P}
            z = ArbReal{P}()
            xb = ArbReal{P}(x)
            yb = ArbReal{P}(y)
            ccall(@libarb($F), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Clong), z, xb, prec)
            return midpoint_byref(z)
         end
    end
end

for (A,F) in ((:loghypot, :arb_log_hypot), (:atan2, :arb_atan2) )
    @eval begin
        function ($A)(x::ArbReal{P}, y::ArbReal{P}, prec::Int=P) where {P}
            z = ArbReal{P}()
            ccall(@libarb($F), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Ref{ArbReal}, Clong), z, x, y, prec)
            return z
         end
    end
end


for (A,F) in ((:loghypot, :acb_log_hypot),)
    @eval begin
        function ($A)(x::ArbComplex{P}, y::ArbComplex{P}, prec::Int=P) where {P}
            z = ArbComplex{P}()
            ccall(@libarb($F), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Ref{ArbReal}, Clong), z, x, y, prec)
            return z
         end
    end
end


for (A,F) in ((:log, :arb_log), (:log1p, :arb_log1p), (:exp, :arb_exp), (:expm1, :arb_expm1),
              (:sin, :arb_sin), (:cos, :arb_cos), (:tan, :arb_tan),
              (:csc, :arb_csc), (:sec, :arb_sec), (:cot, :arb_cot),
              (:sinpi, :arb_sin_pi), (:cospi, :arb_cos_pi), (:sinc, :arb_sinc),
              (:tanpi, :arb_tan_pi), (:cotpi, :arb_cot_pi), (:sincpi, :arb_sinc_pi),
              (:asin, :arb_asin), (:acos, :arb_acos), (:atan, :arb_atan),
              (:sinh, :arb_sinh), (:cosh, :arb_cosh), (:tanh, :arb_tanh),
              (:csch, :arb_csch), (:sech, :arb_sech), (:coth, :arb_coth),
              (:asinh, :arb_asinh), (:acosh, :arb_acosh), (:atanh, :arb_atanh),
             )
    @eval begin
        function ($A)(x::ArbFloat{P}, prec::Int=P) where {P}
            z = ArbReal{P}()
            xb = ArbReal{P}(x)
            ccall(@libarb($F), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Clong), z, xb, prec)
            return midpoint_byref(z)
         end
    end
end

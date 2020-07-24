
function arb_set_round(x::ArbReal{P}, N::Int) where {P}
    y = ArbReal(0.0,bits=N)
    ccall(ArbNumerics.@libarb(arb_set_round), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Cint), y, x, N)
    return y
end

function arf_set_round(x::ArbFloat{P}, N::Int, rounding::Cint) where {P}
    y = ArbFloat(0.0,bits=N)
    res = ccall(ArbNumerics.@libarb(arf_set_round), Cint, (Ref{ArbFloat}, Ref{ArbFloat}, Cint, Cint), y, x, N, rounding)
    return y
end
arf_set_round(x::ArbFloat{P}, N::Int) where {P} = arf_set_round(x, N, ARF_RND_NEAR)

function rounding_precision(a::ArbReal{P}) where {P}
    xtrabits = extrabits()
    W = P + xtrabits
    setextrabits(0)
    setprecision(ArbFloat, W)
    lo = ArbFloat(midpoint(lowerbound(a)))
    hi = ArbFloat(midpoint(upperbound(a)))
    if lo==hi
        res = W
    else
        minprec = MINIMUM_PRECISION_BASE2
        maxprec = W-1
        midprec = minprec + ((maxprec-minprec)>>1)
        arf_set_round(lo, maxprec) == arf_set_round(hi, maxprec) && return maxprec
        arf_set_round(lo, minprec) != arf_set_round(hi, minprec) && return minprec
        res = 0
        if arf_set_round(lo, midprec) == arf_set_round(hi, midprec)
            for p = midprec:maxprec
                if arf_set_round(lo,p) != arf_set_round(hi,p)
                    res = p - 1
                    break
                end
            end
        else
            for p = midprec:-1:minprec
                if arf_set_round(lo,p) == arf_set_round(hi,p)
                    res = p + 1
                    break
                end
            end
        end
    end
    setprecision(ArbFloat, P)
    setextrabits(xtrabits)
    return max(MINIMUM_PRECISION_BASE2, res)
end

function clearest(a::ArbReal{P}) where {P}
    prec = rounding_precision(a)
    # as ArbFloat(lowerbound(a), bits=prec) == ArbFloat(upperbound(a), bits=prec)
    #    ArbFloat(midpoint(a), bits=prec) (also) is correct, and conservative
    x = ArbFloat(midpoint(a), bits=prec)
    return ArbReal(x)
end

function clearest(a::ArbComplex{P}) where {P}
    return ArbComplex(roundbest(real(a)), roundbest(imag(a)))
end

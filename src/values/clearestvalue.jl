const FMPR_RND_DOWN = Cint(0)
const ARF_RND_DOWN = FMPR_RND_DOWN
const ARB_RND_DOWN = ARF_RND_DOWN
const FMPR_RND_UP = Cint(1)
const ARF_RND_UP = FMPR_RND_UP
const ARB_RND_UP = ARF_RND_UP
const FMPR_RND_FLOOR = Cint(2)
const ARF_RND_FLOOR = FMPR_RND_FLOOR
const ARB_RND_FLOOR = ARF_RND_FLOOR
const FMPR_RND_CEIL = Cint(3)
const ARF_RND_CEIL = FMPR_RND_CEIL
const ARB_RND_CEIL = ARF_RND_CEIL    
const FMPR_RND_NEAR = Cint(4)
const ARF_RND_NEAR = FMPR_RND_NEAR
const ARB_RND_NEAR = ARF_RND_NEAR

const ARB_RND = ARF_RND_DOWN

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

function rounding_precision(lo::ArbFloat{P}, hi::ArbFloat{P}) where {P}
    xtrabits = extrabits()
    W = P + xtrabits
    setextrabits(0)
    setprecision(ArbFloat, W)
    flo = ArbFloat(lo, bits=W)
    fhi = ArbFloat(hi, bits=W)
    if flo==fhi
        res = W
    else
        minprec = MINIMUM_PRECISION_BASE2
        maxprec = W-1
        midprec = minprec + ((maxprec-minprec)>>1)
        arf_set_round(flo, maxprec) == arf_set_round(fhi, maxprec) && return maxprec
        arf_set_round(flo, minprec) != arf_set_round(fhi, minprec) && return missing
        res = 0
        if arf_set_round(flo, midprec) == arf_set_round(fhi, midprec)
            for p = midprec:maxprec
                if arf_set_round(flo,p) != arf_set_round(fhi,p)
                    res = p - 1
                    break
                end
            end
        else
            for p = midprec:-1:minprec
                if arf_set_round(flo,p) == arf_set_round(fhi,p)
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
    lo = ArbFloat(lowerbound(a))
    hi = ArbFloat(upperbound(a))
    prec = rounding_precision(lo, hi)
    res = arb_set_round(midpoint(a), prec)
    return setball(res)
end

clearest(a::ArbFloat{P}) where {P} = a

function clearest(a::ArbComplex{P}) where {P}
    return ArbComplex(roundbest(real(a)), roundbest(imag(a)))
end

clearest(a::AbstractFloat) = a

# this many digits[bits] (are given by) that many bits[digits]
# sum([abs(i-maximin_digits(maximin_bits(i))) for i=24:4000])

const log10of2 = log10(2)
const log2of10 = log2(10)

@inline maximin_digits(nbits) = floor(Int, log10of2*nbits + 0.125)   # match on round trip
@inline maximin_bits(ndigits) = floor(Int, log2of10*ndigits + 2.625) # at least enough, at most 3 more on round trip

@inline function digits4bits(nbits)
    bits = log10of2 * nbits
    bits += 0.125
    floor(Int, bits)
end

@inline function bits4digits(ndigits)
    digs = log2of10 * ndigits
    digs += 2.625
    floor(Int, digs)
end

#     working_precision exceeds evinced_precision

# additional precision (more of the significant bits)
#    absorbs some kinds of numerical jitter
#    before any undesired resonance occurs
const BitsOfStability  = 9

# additional accuracy (more bits of the significand)
#    may compensate for 1,2, or 3 ulp enclosure widenings
const BitsOfAbsorbtion = 15

const ExtraBits = BitsOfStability + BitsOfAbsorbtion

@inline workingbits(evincedbits) = evincedbits + ExtraBits
@inline evincedbits(workingbits) = workingbits - ExtraBits


# default precision
const MINIMUM_PRECISION = 24
const DEFAULT_PRECISION = [workingbits(128 - ExtraBits)]

# these typed significands have this many signficant bits

workingprecision(::Type{Mag}) = 30 # bits of significand

workingprecision(::Type{ArbFloat}) = DEFAULT_PRECISION[1]
workingprecision(::Type{ArbReal}) = DEFAULT_PRECISION[1]
workingprecision(::Type{ArbComplex}) = DEFAULT_PRECISION[1]

workingprecision(::Type{ArbFloat{P}}) where {P} = P
workingprecision(::Type{ArbReal{P}}) where {P} = P
workingprecision(::Type{ArbComplex{P}}) where {P} = P

workingprecision(x::ArbFloat{P}) where {P} = P
workingprecision(x::ArbReal{P}) where {P} = P
workingprecision(x::ArbComplex{P}) where {P} = P

# these typed significands have this many signficant bits shown

precision(::Type{Mag}) = 30 # bits of significand
precision(::Type{ArbFloat}) = evincedbits(DEFAULT_PRECISION[1])
precision(::Type{ArbReal}) = evincedbits(DEFAULT_PRECISION[1])
precision(::Type{ArbComplex}) = evincedbits(DEFAULT_PRECISION[1])

precision(::Type{ArbFloat{P}}) where {P} = evincedbits(P)
precision(::Type{ArbReal{P}}) where {P} = evincedbits(P)
precision(::Type{ArbComplex{P}}) where {P} = evincedbits(P)

precision(x::ArbFloat{P}) where {P} = evincedbits(P)
precision(x::ArbReal{P}) where {P} = evincedbits(P)
precision(x::ArbComplex{P}) where {P} = evincedbits(P)

function setprecision(::Type{T}, n::Int) where {T<:Union{ArbFloat,ArbReal,ArbComplex}}
    global DEFAULT_PRECISION
    n <= MINIMUM_PRECISION && throw(DomainError("bit precision must be >= $MINIMUM_PRECISION"))
    DEFAULT_PRECISION[1] = workingbits(n)
    return n
end

function setworkingprecision(::Type{T}, n::Int) where {T<:Union{ArbFloat,ArbReal,ArbComplex}}
    global DEFAULT_PRECISION
    n <= workingbits(MINIMUM_PRECISION) && throw(DomainError("working bit precision must be >= $(workingbits(MINIMUM_PRECISION))"))
    DEFAULT_PRECISION[1] = n
    return n
end

"""
from ArbReal docs:

A variable of type arf_t holds an arbitrary-precision binary floating-point number:
that is, a rational number of the form x⋅2y where x,y∈Z and x is odd, or one of
the special values zero, plus infinity, minus infinity, or NaN (not-a-number).
There is currently no support for negative zero, unsigned infinity, or a NaN with a payload.
""" ArbFloat

mutable struct ArbFloat{P} <: AbstractFloat    # P is the precision in bits
    exp::Int        # fmpz         exponent of 2 (2^exp)
    size::UInt      # mp_size_t    nwords and sign (lsb holds sign of significand)
    d1::UInt        # significand  unsigned, immediate value or the initial span
    d2::UInt        #   (d1, d2)   the final part indicating the significand, or 0

    function ArbFloat{P}() where {P}
        z = new{P}()
        ccall(@libarb(arf_init), Cvoid, (Ref{ArbFloat},), z)
        finalizer(arf_clear, z)
        return z
    end
end

arf_clear(x::ArbFloat{P}) where {P} = ccall(@libarb(arf_clear), Cvoid, (Ref{ArbFloat},), x)

ArbFloat{P}(x::ArbFloat{P}) where {P} = x
ArbFloat(x::ArbFloat{P}) where {P} = x

ArbFloat{P}(x::Missing) where {P} = missing
ArbFloat(x::Missing) = missing


@inline sign_bit(x::ArbFloat{P}) where {P} = isodd(x.size)

ArbFloat(x, prec::Int) = prec>=MINIMUM_PRECISION ? ArbFloat{workingbits(prec)}(x) : throw(DomainError("bit precision $prec < $MINIMUM_PRECISION"))

swap(x::ArbFloat{P}, y::ArbFloat{P}) where {P} = ccall(@libarb(arf_swap), Cvoid, (Ref{ArbFloat}, Ref{ArbFloat}), x, y)

function copy(x::ArbFloat{P}) where {P}
    z = ArbFloat{P}()
    ccall(@libarb(arf_set), Cvoid, (Ref{ArbFloat}, Ref{ArbFloat}), z, x)
    return z
end

function copy(x::ArbFloat{P}, bitprecision::Int, roundingmode::RoundingMode) where {P}
    z = ArbFloat{P}()
    rounding = match_rounding_mode(roundingmode)
    rounddir = ccall(@libarb(arf_set_round), Cint, (Ref{ArbFloat}, Ref{ArbFloat}, Clong, Cint), z, x, bitprecision, rounding)
    return z
end

copy(x::ArbFloat{P}, roundingmode::RoundingMode) where {P} = copy(x, P, roundingmode)
copy(x::ArbFloat{P}, bitprecision::Int) where {P} = copy(x, bitprecision, RoundNearest)


function ArbFloat{P}(x::Int64) where {P}
    z = ArbFloat{P}()
    ccall(@libarb(arf_set_si), Cvoid, (Ref{ArbFloat}, Clong), z, x)
    return z
end
ArbFloat{P}(x::T) where {P, T<:Union{Int8, Int16, Int32}} = ArbFloat{P}(Int64(x))

function ArbFloat{P}(x::UInt64) where {P}
    z = ArbFloat{P}()
    ccall(@libarb(arf_set_ui), Cvoid, (Ref{ArbFloat}, Culong), z, x)
    return z
end
ArbFloat{P}(x::T) where {P, T<:Union{UInt8, UInt16, UInt32}} = ArbFloat{P}(UInt64(x))

function ArbFloat{P}(x::Float64) where {P}
    z = ArbFloat{P}()
    ccall(@libarb(arf_set_d), Cvoid, (Ref{ArbFloat}, Cdouble), z, x)
    return z
end
ArbFloat{P}(x::T) where {P, T<:Union{Float16, Float32}} = ArbFloat{P}(Float64(x))

function ArbFloat{P}(x::BigFloat) where {P}
    z = ArbFloat{P}()
    ccall(@libarb(arf_set_mpfr), Cvoid, (Ref{ArbFloat}, Ref{BigFloat}), z, x)
    return z
end
ArbFloat{P}(x::BigInt) where {P} = ArbFloat{P}(BigFloat(x))
ArbFloat{P}(x::Rational{T}) where {P, T<:Signed} = ArbFloat{P}(BigFloat(x))

function ArbFloat{P}(x::Irrational{S}) where {P,S}
    prec = precision(BigFloat)
    newprec = max(prec, P + 32)
    setprecision(BigFloat, newprec)
    y = BigFloat(x)
    z = ArbFloat{P}(y)
    setprecision(BigFloat, prec)
    return z
end

Int64(x::ArbFloat{P}) where {P} = Int64(x, RoundNearest)
function Int64(x::ArbFloat{P}, roundingmode::RoundingMode) where {P}
    rounding = match_rounding_mode(roundingmode)
    z = ccall(@libarb(arf_get_si), Clong, (Ref{ArbFloat}, Cint), x, rounding)
    return z
end
Int32(x::ArbFloat{P}) where {P} = Int32(Int64(x))
Int32(x::ArbFloat{P}, roundingmode::RoundingMode) where {P} = Int32(Int64(x), roundingmode)
Int16(x::ArbFloat{P}) where {P} = Int16(Int64(x))
Int16(x::ArbFloat{P}, roundingmode::RoundingMode) where {P} = Int16(Int64(x), roundingmode)

BigFloat(x::ArbFloat{P}) where {P} = BigFloat(x, RoundNearest)
function BigFloat(x::ArbFloat{P}, roundingmode::RoundingMode) where {P}
    rounding = match_rounding_mode(roundingmode)
    z = BigFloat(0, workingprecision(x))
    roundingdir = ccall(@libarb(arf_get_mpfr), Cint, (Ref{BigFloat}, Ref{ArbFloat}, Cint), z, x, rounding)
    return z
end
BigFloat(x::ArbFloat{P}, bitprecision::Int) where {P} = BigFloat(x, bitprecision, RoundNearest)
function BigFloat(x::ArbFloat{P}, bitprecision::Int, roundingmode::RoundingMode) where {P}
    rounding = match_rounding_mode(roundingmode)
    z = BigFloat(0, bitprecision)
    roundingdir = ccall(@libarb(arf_get_mpfr), Cint, (Ref{BigFloat}, Ref{ArbFloat}, Cint), z, x, rounding)
    return z
end

BigInt(x::ArbFloat{P}) where {P} = BigInt(trunc(BigFloat(x)))

for (F,A) in ((:floor, :arf_floor), (:ceil, :arf_ceil))
    @eval begin
        function $F(x::ArbFloat{P}) where {P}
            z = ArbFloat{P}()
            ccall(@libarb($A), Cvoid, (Ref{ArbFloat}, Ref{ArbFloat}), z, x)
            return z
        end
    end
end

trunc(x::ArbFloat{P}) where {P} = signbit(x) ? ceil(x) : floor(x)


midpoint(x::ArbFloat{P}) where {P} = x
radius(x::ArbFloat{P}) where {P} = zero(ArbFloat{P})

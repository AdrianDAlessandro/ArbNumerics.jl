abstract type AbstractArbVector{P, T}  <: AbstractVector{T} end

export DFT, InverseDFT

mutable struct ArbComplexVector{P} <: AbstractArbVector{P, ArbComplex}
    length::Int
    data::Ptr{ArbComplex{P}}

    function ArbComplexVector{P}(length::Int) where {P}
        z = new{P}() 
        acb_vec_init(z, length)
        finalizer(acb_vec_clear, z)
        return z
    end
end

ArbComplexVector(x::ArbComplexVector{P}) where {P} = x
ArbComplexVector{P}(x::ArbComplexVector{P}) where {P} = x

@inline function acb_vec_clear(x::ArbComplexVector{P}) where {P}
    ccall(@libarb(_acb_vec_clear), Cvoid, (Ref{ArbComplex{P}}, Cint ), x.data, x.length)
end

@inline function acb_vec_init(x::ArbComplexVector{P}, length::I) where {P, I<:Signed}
    x.data = ccall(@libarb(_acb_vec_init), Ptr{ArbComplex{P}}, (Int32,), length)
    x.length = length
end

@inline function ArbComplexVector(length::Int)
    P = workingprecision(ArbComplex)
	return ArbComplexVector{P}(length)
end


function ArbComplexVector{P}(fpm::Array{ArbComplex{P},1}) where {P}
    length = size(fpm)[1]
    arv = ArbComplexVector{P}(length)
    @inbounds for i in 1:length
                arv[i]=fpm[i]
              end
    return arv
end

function ArbComplexVector(fpm::Array{ArbComplex{P},1}) where {P}
    length = size(fpm)[1]
    arv = ArbComplexVector{P}(length)
    @inbounds for i in 1:length
                arv[i]=fpm[i]
              end
    return arv
end

@inline function ArbComplexVector(fpm::Array{ArbComplex,1})
    P = workingprecision(ArbComplex)
    length = size(fpm)[1]
    arv = ArbComplexVector{P}(length)
    @inbounds for i in 1:length
                arv[i]=fpm[i]
              end
    return arv
end


function Base.getindex(V::ArbComplexVector{P}, i) where {P}
    @assert(i>0 && i<=V.length)
    return unsafe_load(V.data, i)
end

function Base.setindex!(V::ArbComplexVector{P}, x::ArbComplex{P}, i) where {P}
    @assert(i>0 && i<=V.length)
    return unsafe_store!(V.data, x, i)
end

@inline Base.size(x::ArbComplexVector{P}) where {P} = (x.length,)

function DFT(x::ArbComplexVector{P}) where {P}
    length = x.length
    transf = ArbComplexVector{P}(length)
    # we call the acb_dft void acb_dft(acb_ptr w, acb_srcptr v, slong n, slong prec)
    ccall(@libarb(acb_dft), Cvoid, (Ref{ArbComplex{P}}, Ref{ArbComplex{P}}, Cint, Cint ), transf.data, x.data, x.length, P)
    return Array{ArbComplex{P},1}(transf)
end

function InverseDFT(x::ArbComplexVector{P}) where {P}
    length = x.length
    transf = ArbComplexVector{P}(length)
    # we call the acb_dft void acb_dft_inverse(acb_ptr w, acb_srcptr v, slong n, slong prec)
    ccall(@libarb(acb_dft_inverse), Cvoid, (Ref{ArbComplex{P}}, Ref{ArbComplex{P}}, Cint, Cint ), transf.data, x.data, x.length, P)
    return Array{ArbComplex{P},1}(transf)
end


DFT(x::Array{ArbComplex{P},1}) where {P} = DFT(ArbComplexVector{P}(x))
DFT(x::Array{ArbComplex,1}) = DFT(ArbComplexVector(x))

InverseDFT(x::Array{ArbComplex{P},1}) where {P} = InverseDFT(ArbComplexVector{P}(x))
InverseDFT(x::Array{ArbComplex,1}) = InverseDFT(ArbComplexVector(x))

 
@inline function radius(V::ArbComplexVector{P}) where {P}
    return ArbComplexVector([radius(x) for x in V])
end

@inline function midpoint(V::ArbComplexVector{P}) where {P}
    return ArbComplexVector([midpoint(x) for x in V])
end

@inline function real(V::ArbComplexVector{P}) where {P}
    return [real(x) for x in V]
end

@inline function imag(V::ArbComplexVector{P}) where {P}
    return [imag(x) for x in V]
end


#=
	typedef struct
	{
	    arb_ptr entries;
	    slong r;
	    slong c;
	    arb_ptr * rows;
	}
	arb_mat_struct;
=#

const ArbMatIdx0 = zero(Int32)

mutable struct ArbRealMatrix{P} <: AbstractArbMatrix{P, ArbReal}
    eachcell::Ptr{ArbReal{P}}
    rowcount::Int
    colcount::Int
    eachrow::Ptr{Ptr{ArbReal{P}}}

    function ArbRealMatrix{P}(rowcount::Int, colcount::Int) where {P}
        z = new{P}() # z = new{P}(Ptr{ArbReal{P}}(0), 0, 0, Ptr{Ptr{ArbReal{P}}}(0))
        arb_mat_init(z, rowcount, colcount)
        finalizer(arb_mat_clear, z)
        return z
    end
end

ArbRealMatrix{P}(x::ArbRealMatrix{P}) where {P} = x

(::Type{Array{ArbReal{P},2}})(::UndefInitializer, nrows::Int, ncols::Int) where {P} =
ArbRealMatrix{P}(nrows, ncols)

@inline function arb_mat_clear(x::ArbRealMatrix{P}) where {P}
    ccall(@libarb(arb_mat_clear), Cvoid, (Ref{ArbRealMatrix}, ), x)
end

@inline function arb_mat_init(x::ArbRealMatrix{P}, rowcount::I, colcount::I) where {P, I<:Signed}
    ccall(@libarb(arb_mat_init), Cvoid, (Ref{ArbRealMatrix}, Cint, Cint),
                                         x, rowcount, colcount)
end

@inline function ArbRealMatrix(nrows::Int, ncols::Int)
	P = workingprecision(ArbReal)
	return ArbRealMatrix{P}(nrows, ncols)
end

function ArbRealMatrix(fpm::Array{F,2}) where {F<:AbstractFloat}
    nrows, ncols = size(fpm)
	arm = ArbRealMatrix(nrows, ncols)
    for r = 1:nrows
		for c = 1:ncols
			arm[r,c] = fpm[r,c]
	    end
	end
	return arm
end

function ArbRealMatrix{P}(fpm::Array{F,2}) where {P, F<:AbstractFloat}
    nrows, ncols = size(fpm)
	arm = ArbRealMatrix{P}(nrows, ncols)
    for r = 1:nrows
		for c = 1:ncols
			arm[r,c] = fpm[r,c]
	    end
	end
	return arm
end


@inline rowcount(x::ArbRealMatrix{P}) where {P} = getfield(x, :rowcount)
@inline colcount(x::ArbRealMatrix{P}) where {P} = getfield(x, :colcount)
@inline eachcell(x::ArbRealMatrix{P}) where {P} = getfield(x, :eachcell)
@inline eachrow(x::ArbRealMatrix{P}) where {P} = getfield(x, :eachrow)


@inline cellvalue(x::ArbRealMatrix{P}, row::Int, col::Int) where {P} = eachrow(x)[row][col-1]

Base.zeros(::Type{ArbReal{P}},rowcount::SI, colcount::SI) where {P, SI<:Signed} =
    ArbRealMatrix{P}(rowcount, colcount)

Base.zeros(::Type{ArbReal},rowcount::SI, colcount::SI) where {P, SI<:Signed} =
    ArbRealMatrix(rowcount, colcount)

function Base.reshape(x::Vector{ArbReal{P}}, rc::Tuple{Int, Int}) where {P}
   n = length(x)
   nrows, ncols = rc
   n === nrows*ncols || throw(ErrorException("length($n) != rows*cols($rc[1] * $rc[2])"))

    m = ArbRealMatrix{P}(nrows, ncols)
    m[:] = x

    return m
end

@inline Base.isempty(x::ArbRealMatrix{P}) where {P} =
    rowcount(x) === ArbMatIdx0 || colcount(x) === ArbMatIdx0

@inline Base.size(x::ArbRealMatrix{P}) where {P} = (rowcount(x), colcount(x))

@inline function issquare(x::ArbRealMatrix{P}) where {P}
	return rowcount(x) === colcount(x)
end

@inline function Base.getindex(x::ArbRealMatrix{P}, linearidx::Int) where {P}
    rowidx, colidx = linear_to_cartesian(rowcount(x), linearidx)
    return getindex(x, rowidx, colidx)
end

@inline function Base.getindex(x::ArbRealMatrix{P}, rowidx::Int, colidx::Int) where {P}
    checkbounds(x, rowidx, colidx)
    return getindexˌ(x, rowidx, colidx)
end

@inline function getindexˌ(x::ArbRealMatrix{P}, rowidx::Int, colidx::Int) where {P}
    z = ArbReal{P}()
    GC.@preserve x begin
        v = ccall(@libarb(arb_mat_entry_ptr), Ptr{ArbReal},
                  (Ref{ArbRealMatrix}, Int, Int), x, rowidx - 1, colidx - 1)
        ccall(@libarb(arb_set), Cvoid, (Ref{ArbReal}, Ptr{ArbReal}), z, v)
    end
    return z
end


function Base.setindex!(x::ArbRealMatrix{P}, z::ArbReal{P}, linearidx::Int) where {P}
    rowidx, colidx = linear_to_cartesian(rowcount(x), linearidx)
    return setindex!(x, z, rowidx, colidx)
end

Base.setindex!(x::ArbRealMatrix{P1}, z::ArbReal{P2}, linearidx::Int) where {P1,P2} =
    setindex!(x, ArbReal{P1}(z), linearidx)

Base.setindex!(x::ArbRealMatrix{P}, z::ArbFloat{P}, linearidx::Int) where {P} =
    setindex!(x, ArbReal{P}(z), linearidx)

Base.setindex!(x::ArbRealMatrix{P1}, z::ArbFloat{P2}, linearidx::Int) where {P1,P2} =
    setindex!(x, ArbReal{P1}(ArbFloat{P1}(z)), linearidx)

Base.setindex!(x::ArbRealMatrix{P}, z::F, linearidx::Int) where {P, F<:Union{Signed,IEEEFloat}} =
    setindex!(x, ArbReal{P}(z), linearidx)

Base.setindex!(x::ArbRealMatrix{P}, z::R, linearidx::Int) where {P, R<:Real} =
    setindex!(x, ArbReal{P}(BigFloat(z)), linearidx)


function Base.setindex!(x::ArbRealMatrix{P}, z::ArbReal{P},
                        rowidx::Int, colidx::Int) where {P}
    checkbounds(x, rowidx, colidx)
    return setindexˌ!(x, z, rowidx, colidx)
end

Base.setindex!(x::ArbRealMatrix{P1}, z::ArbReal{P2}, rowidx::Int, colidx::Int) where {P1,P2} =
    setindex!(x, ArbReal{P1}(z), rowidx, colidx)

Base.setindex!(x::ArbRealMatrix{P}, z::ArbFloat{P}, rowidx::Int, colidx::Int) where {P} =
    setindex!(x, ArbReal{P}(z), rowidx, colidx)

Base.setindex!(x::ArbRealMatrix{P1}, z::ArbFloat{P2}, rowidx::Int, colidx::Int) where {P1,P2} =
    setindex!(x, ArbReal{P1}(ArbFloat{P1}(z)), rowidx, colidx)

Base.setindex!(x::ArbRealMatrix{P}, z::F, rowidx::Int, colidx::Int) where {P, F<:Union{Signed,IEEEFloat}} =
    setindex!(x, ArbReal{P}(z), rowidx, colidx)

Base.setindex!(x::ArbRealMatrix{P}, z::R, rowidx::Int, colidx::Int) where {P, R<:Real} =
    setindex!(x, ArbReal{P}(BigFloat(z)), rowidx, colidx)


@inline function setindexˌ!(x::ArbRealMatrix{P}, z::ArbReal{P},
                            rowidx::Int, colidx::Int) where {P}
    GC.@preserve x begin
        ptr = ccall(@libarb(arb_mat_entry_ptr), Ptr{ArbReal},
        	        (Ref{ArbRealMatrix}, Cint, Cint), x, rowidx-1, colidx-1)
        ccall(@libarb(arb_set), Cvoid, (Ptr{ArbReal}, Ref{ArbReal}), ptr, z)
    end
    return z
end

#=
    Matrix{::ArbT{ArbPreciFount, colcount)

=#

Base.Matrix{ArbReal{P}}(undef::UndefInitializer, r::I, c::I) where {P, I<:Integer} = ArbRealMatrix{P}(m, n)
Base.zeros(::Type{ArbReal{P}}, r::I, c::I) where {P, I<:Integer} = ArbRealMatrix{P}(m,n)



# operators over a matrix


function transpose(src::ArbRealMatrix{P}) where {P}
    if issquare(src)
    	dest = copy(src)
    else
    	dest = ArbRealMatrix{P}(colcount(src), rowcount(src))
    end

    ccall(@libarb(arb_mat_transpose), Cvoid,
          (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}), dest, src)
    return dest
end

function transpose!(x::ArbRealMatrix{P}) where {P}
    checksquare(x)
    ccall(@libarb(arb_mat_transpose), Cvoid, (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}), x, x)
    return x
end

function transpose!(dest::ArbRealMatrix{P}, src::ArbRealMatrix{P}) where {P}
    checkcompat(dest, src)
    ccall(@libarb(arb_mat_transpose), Cvoid, (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}), dest, src)
    return dest
end



function norm(m::ArbRealMatrix{P}) where {P}
    z = ArbReal{P}()
    ccall(@libarb(arb_mat_frobenius_norm), Cvoid,
    	  (Ref{ArbReal}, Ref{ArbRealMatrix}, Cint), z, m, P)
    return z
end


function tr(x::ArbRealMatrix{P}) where {P}
    checksquare(x)
    return trˌ(x)
end

function trˌ(x::ArbRealMatrix{P}) where {P}
    z = ArbReal{P}()
    ccall(@libarb(arb_mat_trace), Cvoid,
    	  (Ref{ArbReal}, Ref{ArbRealMatrix}, Cint), z, x, P)
    return z
end


function det(x::ArbRealMatrix{P}) where {P}
    checksquare(x)
    return detˌ(x)
end

function detˌ(x::ArbRealMatrix{P}) where {P}
    z = ArbReal{P}()
    ccall(@libarb(arb_mat_det), Cvoid,
          (Ref{ArbReal}, Ref{ArbRealMatrix}, Cint), z, x, P)
    return z
end

"""
    determinant(<:ArbMatrix)
Computes the determinant using a more stable, albeit slower
algorithm than that used for `det`.
"""
function determinant(x::ArbRealMatrix{P}) where {P}
    checksquare(x)
    P2 = P + P>>1
    z = ArbReal{P2}()
    ccall(@libarb(arb_mat_det_precond), Cvoid,
          (Ref{ArbReal}, Ref{ArbRealMatrix}, Cint), z, x, P2)
    return ArbReal{P}(z)
end


function inv(x::ArbRealMatrix{P}) where {P}
    checksquare(x)
    return invˌ(x)
end

function invˌ(x::ArbRealMatrix{P}) where {P}
    z = ArbRealMatrix{P}(rowcount(x), colcount(x))
    ok = ccall(@libarb(arb_mat_inv), Cint, (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}, Cint), z, x, P)
    ok !== Cint(0) && return z
    throw(ErrorException("cannot invert $(x)"))
end

"""
    inverse(ArbMatrix)
A version of `inv` with greater accuracy.
"""
function inverse(x::ArbRealMatrix{P}) where {P}
    checksquare(x)
    P2 = P + P>>1
    z = ArbRealMatrix{P2}(rowcount(x), colcount(x))
    ok = ccall(@libarb(arb_mat_inv), Cint, (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}, Cint), z, x, P2)
    ok !== Cint(0) && return z
    throw(ErrorException("cannot invert $(x)"))
end


# matrix multiply

function Base.mul!(z::ArbRealMatrix{P}, x::ArbRealMatrix{P}, y::ArbRealMatrix{P})
    ccall(@libarb(arb_mat_mul), Cvoid, (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}, Ref{ArbRealMatrix}, Cint), z, x, y, P)
    return nothing
end

function matmul(x::ArbRealMatrix{P}, y::ArbRealMatrix{P}) where {P}
    z = ArbRealMatrix{P}(rowcount(x), colcount(y))
    ccall(@libarb(arb_mat_mul), Cvoid, (Ref{ArbRealMatrix}, Ref{ArbRealMatrix}, Ref{ArbRealMatrix}, Cint), z, x, y, P)
    return z
end	

function Base.:(*)(x::ArbRealMatrix{P}, y::ArbRealMatrix{P}) where {P}
    checkmulable(x, y)
    return matmul(x, y)
end

Base.:(*)(x::Array{ArbReal{P},2}, y::Array{ArbReal{P},2}) where {P} =
    ArbRealMatrix{P}(x) * ArbRealMatrix{P}(y)


# checks for validity

@inline function checkbounds(x::ArbRealMatrix{P}, r::Int, c::Int) where {P}
    withinbounds = 0 < r <= rowcount(x) && 0 < c <= colcount(x)
    withinbounds && return nothing
    throw(BoundsError("($r, $c) not in 1:$(rowcount(x)), 1:$(colcount(x))"))
end

@inline function checkbounds(x::ArbRealMatrix{P}, linear_rc::Int) where {P}
    withinbounds = 0 < linear_rc <= rowcount(x) * colcount(x)
    withinbounds && return nothing
    throw(BoundsError("($rc) not in 1:$(rowcount(x) * colcount(x))"))
end

@inline function checksquare(x::ArbRealMatrix{P}) where {P}
    issquare(x) && return nothing
    throw(DomainError("matrix is not square ($rowcount(x), $colcount(x))"))
end

@inline function checkcompat(x::ArbRealMatrix{P}, y::ArbRealMatrix{P}) where {P}
    compat = (rowcount(x) === colcount(y) && rowcount(y) === colcount(x))
    compat && return nothing
    throw(DomainError("incompatible matrices: ($rowcount(x), $colcount(x)), ($rowcount(y), $colcount(y))"))
end

@inline function checkmulable(x::ArbRealMatrix{P}, y::ArbRealMatrix{P}) where {P}
    mulable = colcount(x) === rowcount(y)
    mulable && return nothing
    throw(ErrorException("Dimension Mismatach: ($rowcount(x), $colcount(x)), ($rowcount(y), $colcount(y))"))
end

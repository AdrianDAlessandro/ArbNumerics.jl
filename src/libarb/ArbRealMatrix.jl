# heavily influenced by and mostly of the Arb C interface used in Nemo.jl

linearindex_from_rowcol(nrows::Int, row::Int, col::Int) = row + (col-1)*nrows
linearindex_from_rowcol(m::M, row::Int, col::Int) where {T,M<:AbstractMatrix{T}} = row + (col-1)*size(m)[1]

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

mutable struct ArbRealMatrix{P} <: AbstractMatrix{ArbReal{P}}
   entries::Ptr{ArbReal{P}}
   nrows::Int
   ncols::Int
   rows::Ptr{Ptr{ArbReal{P}}}
   
    
   function ArbRealMatrix{P}(nrows::Int, ncols::Int) where {P}
       z = new{P}() # z = new{P}(Ptr{ArbReal{P}}(0), 0, 0, Ptr{Ptr{ArbReal{P}}}(0))
       arb_mat_init(z, nrows, ncols)
       finalizer(arb_mat_clear, z)
       return z
   end
end

function arb_mat_clear(x::ArbRealMatrix) where {P}
    ccall(@libarb(arb_mat_clear), Cvoid, (Ref{ArbRealMatrix}, ), x)
    return nothing
end

function arb_mat_init(x::ArbRealMatrix{P}, nrows::Int, ncols::Int) where {P}
    ccall(@libarb(arb_mat_init), Cvoid, (Ref{ArbRealMatrix}, Cint, Cint), x, nrows, ncols)
    return nothing
end


function arb_mat_entry_ptr(x::ArbRealMatrix{P}, rowidx::Int, colidx::Int)
    ptrtoArbReal = ccall(@libarb(arb_mat_entry_ptr), Ptr{ArbReal}, (Ref{ArbRealMatrix}, Cint, Cint), x, rowidx, colidx)
    return ptrtoArbReal
end
    
Base.size(x::ArbRealMatrix{P}) where {P} = (x.nrows, x.ncols)

function getindex!(z::arb, x::arb_mat, r::Int, c::Int)
  GC.@preserve x begin
     v = ccall((:arb_mat_entry_ptr, :libarb), Ptr{arb},
                 (Ref{arb_mat}, Int, Int), x, r - 1, c - 1)
     ccall((:arb_set, :libarb), Nothing, (Ref{arb}, Ptr{arb}), z, v)
  end
  return z
end

function Base.getindex(x::ArbRealMatrix{P}, rowidx::Int, colidx::Int) where {P}
    (0 < rowidx <= x.nrows && 0 < colidx <= x.ncols) ||
    throw(DomainError("rowidx $rowidx (1:$(x.nrows)), colidx $colidx (1:$(x.ncols))"))
    
    z = ArbReal{P}()
    GC.@preserve x begin
        ptr = ccall(@libarb(arb_mat_entry_ptr), Ptr{ArbReal}, (Ref{ArbRealMatrix}, Cint, Cint), x, rowidx-1, colidx-1)
        ccall(@libarb(arb_set), Cvoid, (Ref{ArbReal}, Ptr{ArbReal}), z, ptr)
    end
    return z
end

function Base.setindex!(x::ArbRealMatrix{P}, z::ArbReal{P}, linearidx::Int) where {P}
    (0 < linearidx <= x.nrows * x.ncols) ||
    throw(DomainError("linearidx $linearidx (1:$(x.nrows * x.ncols))"))
    
    z = ArbReal{P}()
    GC.@preserve x begin
        ptr = ccall(@libarb(arb_mat_entry_ptr), Ptr{ArbReal}, (Ref{ArbRealMatrix}, Cint, Cint), x, rowidx-1, colidx-1)
        ccall(@libarb(arb_set), Cvoid, (Ptr{ArbReal}, Ref{ArbReal}), ptr, z)
        end
    return z
end

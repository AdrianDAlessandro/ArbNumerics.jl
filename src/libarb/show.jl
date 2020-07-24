function show(io::IO, x::Mag)
    str = string(Float64(x))
    print(io, str)
end

function showinf(io::IO, x::ArbFloat{P}) where {P}
    str = sign(x) >= 0 ? "Inf" : "-Inf"
    print(io, str)
end
function showinf(io::IO, x::ArbReal{P}) where {P}
    str = sign(x) >= 0 ? "Inf" : "-Inf"
    print(io, str)
end
function showinf(io::IO, x::ArbComplex{P}) where {P}
    str = sign(real(x)) >= 0 ? "Inf" : "-Inf"
    i = imag(x)
    if isinf(i)
        str = string(str, (sign(i >= 0) ? " + Inf*im" : " - Inf*im"))
    elseif sign(i) >= 0
        str = string(str," + ", string(i), "im")
    else
        str = string(str," - ", string(abs(i)), "im")
    end    
    print(io, str)
end

function show(io::IO, x::ArbFloat{P}) where {P}
    isinf(x) && return showinf(io, x)
    str = string(x)
    print(io, str)mm
end
showall(io::IO, x::ArbFloat{P}) where {P} = print(io, stringall(x))

function show(io::IO, x::ArbReal{P}; rad::Bool=false, midpt::Bool=false) where {P}
    isinf(x) && return showinf(io, x)
    str = string(x, midpt=midpt, rad=rad)
    print(io, str)
end
showall(io::IO, x::ArbReal{P}; rad::Bool=true, midpt::Bool=true) where {P} = print(io, stringall(x; rad=rad, midpt=midpt))

function show(io::IO, x::ArbComplex{P}; rad::Bool=false, midpt::Bool=false) where {P}
    isinf(x) && return showinf(io, x)
    str = string(x, rad=rad, midpt=midpt)
    print(io, str)
end
showall(io::IO, x::ArbComplex{P}; rad::Bool=true, midpt::Bool=true) where {P} = print(io, stringall(x, rad=rad, midpt=midpt))

function show(x::ArbFloat{P}) where {P}
    str = string(x)
    print(Base.stdout, str)
end
showall(x::ArbFloat{P}) where {P} = print(Base.stdout, stringall(x))

function show(x::ArbReal{P}; rad::Bool=false, midpt::Bool=false) where {P}
    str = string(x, rad=rad, midpt=midpt)
    print(Base.stdout, str)
end
showall(x::ArbReal{P}; rad::Bool=true, midpt::Bool=true) where {P} = print(stdout, stringall(x, rad=rad, midpt=midpt))

function show(x::ArbComplex{P}; rad::Bool=false, midpt::Bool=false) where {P}
    str = string(x, rad=rad, midpt=midpt)
    print(Base.stdout, str)
end
showall(x::ArbComplex{P}; rad::Bool=true, midpt::Bool=true) where {P} = print(stdout, stringall(x, rad=rad, midpt=midpt))

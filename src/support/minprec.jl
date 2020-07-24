# protect minimum precision
minprecerror() = throw(DomainError("minimum precision is $MINIMUM_PRECISION_BASE2 bits"))

for T in (:Float32, :Float64, :Int16, :Int32, :Int64, :Int128, :BigFloat)
  for N in collect(0:23)
    @eval ArbFloat{$N}(x::$T) = minprecerror()
    @eval ArbReal{$N}(x::$T) = minprecerror()
    @eval ArbComplex{$N}(x::$T) = minprecerror()
    @eval ArbComplex{$N}(x::$T, y::$T) = minprecerror()
  end
end

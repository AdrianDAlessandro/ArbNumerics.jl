sing ArbNumbers
using Test

setprecision(BigFloat, 512)

DIGITS = 78;
afpi = ArbFloat(pi, bits4digits(DIGITS))
abpi = ArbBall(pi, bits4digits(DIGITS))

@test DIGITS == length(string(afpi)) - 1 # (-1 for the decimal point) 
@test DIGITS == length(string(abpi)) - 1 # (-1 for the decimal point) 

float64  = 0.125
bigfloat = BigFloat(float64)
arbball  = ArbBall(float64, 64)

for fn in (:sin, :cos, :tan, :csc, :sec, :cot,
           :asin, :acos, :atan)
    @eval v1 = parse(Float64, string($fn(bigfloat)))
    @eval v2 = parse(Float64, string(midpoint($fn(arbball))))
    @test v1 == v2
end

float64  = 1.125
bigfloat = BigFloat(float64)
arbball  = ArbBall(float64, 64)

for fn in (:sqrt, :log, :log1p, :exp, :expm1)
    @eval v1 = parse(Float64, string($fn(bigfloat)))
    @eval v2 = parse(Float64, string(midpoint($fn(arbball))))
    @test v1 == v2
end

mutable struct acb_calc_integrate_opt_struct
    deg_limit::Clong
    eval_limit::Clong
    depth_limit::Clong
    use_heap::Cint
    verbose::Cint

    function acb_calc_integrate_opt_struct(
        deg_limit::Integer, eval_limit::Integer, depth_limit::Integer,
        use_heap::Integer=0, verbose::Integer=0)
      return new(deg_limit, eval_limit, depth_limit, use_heap, verbose)
    end

    function acb_calc_integrate_opt_struct()
      opts = new()
      ccall(@libarb(acb_calc_integrate_opt_init), Cvoid,
        (Ref{acb_calc_integrate_opt_struct},), opts)
      return opts
    end
end

function acb_calc_func(out::PtrToArbComplex, inp::PtrToArbComplex,
        param::Ptr{Cvoid}, order::Cint, prec::Cint)
    @assert iszero(order) || isone(order) # ← we'd need to verify holomorphicity
    x = unsafe_load(convert(Ptr{ArbComplex{Int(prec)}}, inp))
    f = unsafe_pointer_to_objref(param)
    @debug "Evaluating at" x f(x)
    ccall(@libarb(acb_set), Cvoid, (PtrToArbComplex, Ref{ArbComplex}), out, f(x))
    return zero(Cint)
end

acb_calc_func_cfun() = @cfunction(acb_calc_func, Cint,
        (PtrToArbComplex, PtrToArbComplex, Ptr{Cvoid}, Cint, Cint))

function acb_calc_integrate(res::ArbComplex, cfunc, param,
    a::ArbComplex, b::ArbComplex, rel_goal::Integer, abs_tol::Mag,
    options::acb_calc_integrate_opt_struct, prec::Integer)
    status = ccall(@libarb(acb_calc_integrate), Cint,
        (Ref{ArbComplex}, # res
        Ptr{Cvoid}, # cfun
        Any, # param
        Ref{ArbComplex}, # a
        Ref{ArbComplex}, # b
        Cint, # rel_goal
        Ref{Mag}, # abs_tol
        Ref{acb_calc_integrate_opt_struct}, # options
        Cint, # prec
        ),
        res, cfunc, param, a, b, rel_goal, abs_tol, options, prec)
    return status
end

"""
    integrate(f, a::Number, b::Number;
        [rtol=0.0 [, atol=2.0^-workingprecision(ArbComplex) [, opts::acb_calc_integrate_opt_struct = acb_calc_integrate_opt_struct()]]])
Computes a rigorous enclosure (as `ArbComplex`) of the integral

∫ₐᵇ f(t) dt

where f is any (holomorphic) julia function. From Arb docs:
> The integral follows a straight-line path between the complex numbers `a` and
> `b`. For finite results, `a`, `b` must be finite and `f` must be bounded on
> the path of integration. To compute improper integrals, the user should
> therefore truncate the path of integration manually (or make a regularizing
> change of variables, if possible).

Parameters:
 * `rtol` relative tolerance
 * `atol` absolute tolerance
 * `opts` an instance of `acb_calc_integrate_opt_struct` controlling the algorithmic aspects of integration.

NOTE: `integrate` does not guarantee to satisfy provided tolerances. For more
information please consider arblib documentation.

NOTE: It's users responsibility to verify holomorphicity of `f`.
"""
function integrate(f, a::Number, b::Number;
    rtol=0.0, atol=2.0^-workingprecision(ArbComplex),
    opts::acb_calc_integrate_opt_struct = acb_calc_integrate_opt_struct())
    res = zero(ArbComplex)

    status = integrate!(res, f, a, b;
        rtol=rtol, atol=atol, opts=opts)

    # status:
    # ARB_CALC_SUCCESS = 0
    # ARB_CALC_NO_CONVERGENCE = 2
    if status == 2
        @warn "Arb integrate did not achived convergence, the result might be incorrect"
    end
    return res
end

"""
    integrate!(res, f, a, b; [rtol, atol, opts])
Compute the integral of `f` on the stright-line path between `a` and `b`,
storing the result in `res`. See the documentation of `integrate` for more
information on the parameters.
"""
function integrate!(res::ArbComplex, f, a::Number, b::Number;
    rtol=0.0, atol=2.0^-workingprecision(ArbComplex),
    opts::acb_calc_integrate_opt_struct=acb_calc_integrate_opt_struct())

    A, B = ArbComplex(a), ArbComplex(b)
    prec = min(workingprecision(A), workingprecision(B))

    if rtol <= zero(rtol)
        rel_goal = prec
    else
        # rel_goal = r where rel_tol ~2^-r
        rel_goal = -(ArbFloat(rtol).exp)
    end

    return acb_calc_integrate(res, acb_calc_func_cfun(),
        f, A, B, rel_goal, Mag(atol), opts, prec)
end

# @libarb(arb_init)::Ptr{Nothing}
macro libarb(libfn)
    (dlsym(libarb, :($libfn)))
end
macro libflint(libfn)
    (dlsym(libflint, :($libfn)))
end
macro libmpfr(libfn)
    (dlsym(libmpfr, :($libfn)))
end
macro libarb(libgmp)
    (dlsym(libgmp, :($libfn)))
end

# arblib(:arb_init)::Ptr{Nothing}
macro arblib(libsym)
    :(dlsym(libarb, $libsym))
end
macro flintlib(libsym)
    :(dlsym(libflint, $libsym))
end
macro mpfrlib(libsym)
    :(dlsym(libmpfr, $libsym))
end
macro gmplib(libsym)
    :(dlsym(libgmp, $libsym))
end

################################################################################
#
#   gkz.jl : functions for Granger, Kleinjung, Zumbrägel algorithm
#
################################################################################

# Types for GKZ algorithm

"""
    GkzContext

Important elements in the context of the GKZ algorithm over a field ``F_{q^n}``.

# Cautions

* This should never be called as a constructor, see `gkzContext` instead.

# Fields

* `characteristic::Integer` : characteristic of the field
* `baseField::FinField` : the field ``F_q``
* `h0` and `h1` are polynomials such that ``h1*X^q - h0`` as a degree `n`
  irreducible factor, which will be the `definingPolynomial`
* `gen` is a generator of the group of invertible elements of the field, by
  default, it is taken at random *without* warranty that it is indeed a
  generator.
"""
immutable GkzContext
    characteristic::Integer
    baseField::FinField
    h0::PolyElem
    h1::PolyElem
    definingPolynomial::PolyElem
    gen::PolyElem
end

"""
    gkzContext(p::Integer, l::Integer, n::Integer, check::Bool = false)

Construct the field ``F_{q^n}`` where ``q = p^l`` in the context of the GKZ
algorithm.
"""
function gkzContext(p::Integer, l::Integer, n::Integer, check::Bool = false)

    # We create the base field ``F_q``
    z = string("z", l)
    F = FiniteField(p, l, z)[1]

    # And we find the parameters 
    h0, h1, definingPolynomial, gen = findParameters(F, n, check)

    return GkzContext(p, F, h0, h1, definingPolynomial, gen)
end

"""
    findParameters(F::FinField, n::Integer, check::Bool = false)
    
Find suitable parameters in order to perform the GKZ algorithm.
"""
function findParameters(F::FinField, n::Integer, check::Bool = false)

    # We set our polynomials
    q = length(F)
    polyRing, T = PolynomialRing(F, "T")
    h0, h1, definingPolynomial = polyRing(), polyRing(), polyRing()

    # And we search suitable polynomials h0, h1
    boo = true
    while boo
        h0 = randomElem(F)*T + randomElem(F)
        h1 = T^2 + randomElem(F)*T
        fact = factor(h1*T^q - h0)
        for f in fact
            if degree(f[1]) == n
                boo = false
                definingPolynomial = f[1]
                break
            end
        end
    end

    # Finally we find a generator
    gen = T + randomElem(F)

    if check
        while !isGenerator(gen, q^n, definingPolynomial)
            gen = T + randomElem(F)
        end
    else
        while !miniCheck(gen, q^n, definingPolynomial)
            gen = T + randomElem(F)
        end
    end

    return h0, h1, definingPolynomial, gen
end

# Ascent phase in the GKZ algorithm

"""
    ascent(Q::fq_nmod_poly)

Find an irreducible factor of degree two of `Q` in an extension.
"""
function ascent(Q::fq_nmod_poly)

    # We compute d such that deg(Q) = 2^d
    d::Int = log2(degree(Q))

    # Then we embed `Q` in degree two extensions and keep only one factor of
    # degree 2^(d-1), and we do the same with this factor, until we have a
    # factor of degree 2.

    F = base_ring(Q)
    deg = degree(F)
    c::Int = characteristic(F)
    P = Q

    for j in 1:d-1

        # We create the name of the variable of the extension
        z = string("z", deg*2^j)

        # We create the extension
        Fext = FiniteField(c, deg*2^j, z)[1]

        # We embed the polynomial in that extension
        img = findImg(Fext, F)
        F = Fext
        T = string("T", deg*2^j)
        R = PolynomialRing(Fext, T)[1]

        # And we compute a factor
        P = anyFactor(R(P, img))
    end

    return P
end

"""
    latticeBasis(Q::fq_nmod_poly, h0::fq_nmod_poly, h1::fq_nmod_poly)

Find a basis of the latice L_Q of the form (u0, X + u1), (X + v0, v1).

``L_Q = {(w0, w1) \in F_{q^k}[X]^2 | w0h0 + w1h1 = 0 (mod Q)}``
"""
function latticeBasis(Q::fq_nmod_poly, h0::fq_nmod_poly, h1::fq_nmod_poly)

    # We compute our variables a, a0, a1, b, b0, b1
    h0b = h0 % Q
    h1b = h1 % Q

    Qb = monic(Q)
    a, b = -coeff(Qb, 1), -coeff(Qb, 0)
    
    a0, b0 = coeff(h0b, 1), coeff(h0b, 0)
    a1, b1 = coeff(h1b, 1), coeff(h1b, 0)

    # We set some variables
    t = (a0*b1-b0*a1)^(-1)
    u = a0^(-1)

    # We compute the result
    v1 = (b0*u*(a*a0+b0) - a0*b)*a0*t
    u1 = (b0*u*(a*a1+b1) - a1*b)*a0*t
    v0 = -u*(a1*v1 + a*a0 + b0)
    u0 = -u*(a1*u1 + a*a1 + b1)

    return u0, u1, v0, v1
end

"""
    onTheFlyAbc(Q::fq_nmod_poly, h0::fq_nmod_poly, h1::fq_nmod_poly)

Perform the 'on-the-fly' elimination of degree 2 elements.

In other words, return a, b, c such that the polynomial P = X^(q+1) + aX^q + bX + c
splits completely in the base field of `Q` and such that h1*P (mod h1*X^q - h0)
= 0 mod Q.
"""
function onTheFlyAbc(Q::fq_nmod_poly, h0::fq_nmod_poly, h1::fq_nmod_poly)

    # We set some usefull variables
    R = parent(Q)
    T = gen(R)
    F = base_ring(Q)
    f = base_ring(h0)
    q::Int = length(f)

    # We work with embeddings of h0 and h1
    img = findImg(F, f)

    # We pick B such that T^(q+1) - BT + B splits completely
    B = randomSplitElem(R, q)

    # We find ui's and vi's such that (u0, T+u1), (T+v0, v1) is a basis of the
    # lattice L_Q = {(w0, w1) | w0h0 + w1h1 = 0 (mod Q)}
    u0, u1, v0, v1 = latticeBasis(Q, R(h0, img), R(h1, img))

    # We write the polynomial arising from the conditions wanted
    P = (-u0^q*T^q+T-v0^q)^(q+1)-B*(-u0*T^2+(u1-v0)*T+v1)^q
    
    # We find a root
    r = anyRoot(P)

    # If there is no root, we try the process with an other B
    while r == nothing
        B = randomSplitElem(R, q)
        P = (-u0^q*T^q+T-v0^q)^(q+1)-B*(-u0*T^2+(u1-v0)*T+v1)^q
        r = anyRoot(P)
    end

    # And we return a, b, c
    return r*u0+v0, r, r*u1+v1
end

function norm(Q::fq_nmod_poly, q::Integer)
    conj = parent(Q)([coeff(Q, i)^q for i in 0:degree(Q)])
    return Q*conj
end

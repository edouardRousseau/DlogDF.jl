################################################################################
#
#   basics.jl : basic functions
#
################################################################################

export dlogSmallField

# Arithmetic in finite fields

function Nemo.powmod(x::Nemo.fq_nmod_poly, n::Nemo.fmpz, y::Nemo.fq_nmod_poly)
   check_parent(x,y)
   z = parent(x)()

   if n < 0
      g, x = gcdinv(x, y)
      if g != 1
         error("Element not invertible")
      end
      n = -n
   end

   ccall((:fq_nmod_poly_powmod_fmpz_binexp, :libflint), Void,
         (Ptr{fq_nmod_poly}, Ptr{fq_nmod_poly}, Ptr{fmpz}, Ptr{fq_nmod_poly},
         Ptr{FqNmodFiniteField}), &z, &x, &n, &y, &base_ring(parent(x)))
  return z
end

Nemo.powmod(x::Nemo.fq_nmod_poly, n::Integer, y::Nemo.fq_nmod_poly) = Nemo.powmod(x,
                                                                        ZZ(n), y)
function powmodPreinv(x::Nemo.fq_nmod_poly, n::Nemo.fmpz, y::Nemo.fq_nmod_poly,
                     p::Nemo.fq_nmod_poly)
   check_parent(x,y)
   z = parent(x)()

   if n < 0
      g, x = gcdinv(x, y)
      if g != 1
         error("Element not invertible")
      end
      n = -n
   end

   ccall((:fq_nmod_poly_powmod_fmpz_binexp_preinv, :libflint), Void,
         (Ptr{fq_nmod_poly}, Ptr{fq_nmod_poly}, Ptr{fmpz}, Ptr{fq_nmod_poly},
          Ptr{fq_nmod_poly}, Ptr{FqNmodFiniteField}), &z, &x, &n, &y, &p, 
          &base_ring(parent(x)))

  return z
end

# Iterator over finite fields
# The elements are iterated in the order 0, 1, ..., q-1, x, 1 + x, 2 + x,
# ..., (q-1) + (q-1)x + ... + (q-1)x^(n-1), where x is the generator of F_q^n

function Base.start(F::Nemo.FqNmodFiniteField)
    n = F.mod_length - 1
    return zeros(Int, n)
end

function Base.next(F::Nemo.FqNmodFiniteField, state::Array{Int, 1})
    q = F.p - 1
    n = F.mod_length - 1
    x = gen(F)
    nex = deepcopy(state)
    i = 1
    l = n

    if nex[1] < q
        nex[1] += 1
    else
        for i in 1:n
            if nex[i] != q
                l = i
                break
            end
        end

        for i in 1:(l-1)
            nex[i] = 0
        end
        nex[l] += 1
    end

    res = sum(Nemo.fq_nmod[state[i]*x^(i-1) for i in 1:n])
    return (res, nex)
end

function Base.done(F::Nemo.FqNmodFiniteField, state::Array{Int, 1})
    return state[end] == F.p
end

function Base.eltype(::Type{Nemo.FqNmodFiniteField})
    return Nemo.fq_nmod
end

function Base.length(F::Nemo.FqNmodFiniteField)
    return BigInt((F.p))^(F.mod_length - 1)
end

# Discrete log in a small subfield

"""
    dlogSmallField{T}(carac::Integer, degExt::Integer, gen::T, elem::T,
                           defPol::T)

Compute the discrete logarithm of `elem` in the basis `gen`.

This strategy works if `elem` is in fact in the medium subfield.
"""
function dlogSmallField{T}(carac::Integer, degExt::Integer, gen::T, elem::T,
                           defPol::T)

    # We compute the norm of `gen`
    q = BigInt(carac)^2
    c = div(q^degExt-1, q-1)
    n = powmod(gen, c, defPol)

    # Then we find the logarithm of `elem` is the basis `n`
    i = 1
    while powmod(n, i, defPol) != elem
        i += 1
    end

    # Amd we translate the result in basis `gen`
    return (i*c)%(q^degExt-1)
end

# Basic functions for embedding of finite fields

"""
    modulusCoeffs(F::FqNmodFiniteField)

Return the coefficients of the modulus defining the field `F`.
"""
function modulusCoeffs(F::FqNmodFiniteField)

    # We compute -x^d, where x is the generator of `F` and d its degree
    deg = degree(F)
    tail = -gen(F)^deg

    # Then we read the result, since we know that -x^d = P(x), with the
    # modulus defining `F` being T^d + P(T)
    coeffs = Array(Int, deg+1)
    for j in 1:deg
        coeffs[j] = coeff(tail, j-1)
    end

    coeffs[end] = 1

    return coeffs
end

"""
    anyFactor{T <: PolyElem}(P::T)

Return a factor of the polynomial `P`.
"""
function anyFactor{T <: PolyElem}(P::T)

    # We factor P
    fact = factor(P)

    # And we return the first encountered factor
    for f in fact
        return f[1]
    end
end

"""
    findImg(F::FqNmodFiniteField, f::FqNmodFiniteField)

Find the image of the generator of `f` in `F`.
"""
function findImg(F::FqNmodFiniteField, f::FqNmodFiniteField)

    df = degree(f)
    if degree(F)%df != 0
        error("There is no embedding: check the degrees of the fields involved")
    
    elseif characteristic(f) != characteristic(F)
        error("Fields must be of the same characteristic")
    end

    # Then we compute the image of the generator of the field in which `a`
    # lives, by finding a root of the polynomial defining `f` over F
    coeffs = modulusCoeffs(f)
    R, T = PolynomialRing(F, "T")
    fact = factor(R(coeffs))
    img = F()
    res = F()
    for r in fact
        img = -coeff(r[1],0)
        break
    end

    return img
end

"""
    (F::FqNmodFiniteField)(a::fq_nmod)

Coercion function between finite fields.

This function will compute the image of the generator every time.
"""
function (F::FqNmodFiniteField)(a::fq_nmod)

    # We compute the image of the generator of the field in which `a` lives
    f = parent(a)
    img = findImg(F, f)

    # And we compute the final result by linearity
    df = degree(f)
    res = F()

    for j in 0:df-1
        res += coeff(a, j)*img^j
    end

    return res
end

"""
    (F::FqNmodFiniteField)(a::fq_nmod, img::fq_nmod)
    
Coercion function between finite fields.

The element `img` is the image of the generator of the field where `a` is living
in the field `F`.
"""
function (F::FqNmodFiniteField)(a::fq_nmod, img::fq_nmod)
    res = F()
    df = degree(parent(a))

    for j in 0:df-1
        res += coeff(a, j)*img^j
    end

    return res
end

"""
    (R::FqNmodPolyRing)(p::fq_nmod_poly)

Coercion function between polynomial rings over finite fields.

This is a coefficient-wise coercion.
"""
function (R::FqNmodPolyRing)(p::fq_nmod_poly)

    # We first coerce each coefficient
    F = base_ring(R)
    coeffs = [F(coeff(p, i)) for i in 0:degree(p)]

    # And we return the polynomial corresponding to these coefficients
    return R(coeffs)
end

"""
    (R::FqNmodPolyRing)(p::fq_nmod_poly, img::fq_nmod)

Coercion function between polynomial rings over finite fields.

This is a coefficient-wise coercion.
"""
function (R::FqNmodPolyRing)(p::fq_nmod_poly, img::fq_nmod)

    # We first coerce each coefficient
    F = base_ring(R)
    coeffs = [F(coeff(p, i), img) for i in 0:degree(p)]

    # And we return the polynomial corresponding to these coefficients
    return R(coeffs)
end

# Functions checking if an element is a generator

"""
    isGenerator(gen::RingElem, card::Integer, defPol::PolyElem)

Return `true` if gen is a generator of the group of the inversible elements of
the finite field of cardinal `card`. Return `false` otherwise.
"""
function isGenerator(gen::RingElem, card::Integer, defPol::PolyElem)
    # We compute the factorisation of card-1 
    fact = factor(card-1)
    d::Integer = 0

    # If gen is not a generator, there is a integer d < card-1 of that form for
    # which we have gen^d = 1
    for x in fact
        d = (card-1)//x[1]
        if powmod(gen, d, defPol) == 1
            return false
        end
    end
    return true
end

"""
    miniCheck(gen::RingElem, card::Integer, defPol::PolyElem)

Check that `gen` is not trivially not generator.

By trivially not generator, we mean that ``gen^(k/d) = 1``, for ``k`` the cardinal of
the group of the invertible elements of the field, and ``d`` a small divisor of this
cardinal. 

Passing this test does *not* guarantee that `gen` is a generator.
"""
function miniCheck(gen::RingElem, card::Integer, defPol::PolyElem)

    # We find the small primes dividing our cardinal
    d::Integer = 0
    l::Int = ceil(Integer, log2(card))
    A = Array{Int, 1}()
    for i in primes(l)
        if card%i == 1
            push!(A, i)
        end
    end

    # And we test the generator on those primes
    for x in A
        d = (card-1)//x
        if powmod(gen, d, defPol) == 1
            return false
        end
    end
    return true
end

# Functions on polynomials

"""
    monic(Q::PolyElem)

Return the normalized polynomial, assuming that the leading coefficient is
invertible.
"""
function monic(Q::PolyElem)
    
    # We compute the degree
    d = degree(Q)

    # And we divide every coefficient by the leading coefficient
    return parent(Q)([coeff(Q, d)^(-1)*coeff(Q, i) for i in 0:d])
end

"""
    anyRoot(Q::PolyElem)

Return a couple (`bool`, `root`), where `root` is a root of `Q` and `bool` is
`true` if there is a root, otherwise it is `false` and `root` is set to zero.

# Notes
* Type stability in the output helps the compiler to optimize the code, that is
  why we choose to always output a couple with the same type here, and to output
  ``root = 0`` even if zero is not a root.

* This algorithm does *a lot* more than finding a root (it actually factors the
  input polynomial)
"""
function anyRoot(Q::PolyElem)

    # We factor the polynomial
    fact = factor(Q)

    # And we look for a degree one factor
    for f in fact

        # If there is one, we return the associated root
        if degree(f[1]) == 1
            return true, -coeff(f[1],0)
        end
    end

    # Otherwise we know there is no root
    return false, zero(base_ring(Q))
end

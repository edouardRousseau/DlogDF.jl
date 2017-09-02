using Nemo, DlogGF, Base.Test

function testRandomSuite()
    print("randomElem, randomList, randomPolynomial, randomIrrPolynomial, randomSplitElem... ")

    F, x = FiniteField(5, 2, "x")

    @test parent(DlogGF.randomElem(F)) == F
    @test length(DlogGF.randomList(F, 10)) == 10
    @test parent(DlogGF.randomList(F, 5)[1]) == F

    R, T = PolynomialRing(F, "T")

    @test degree(DlogGF.randomPolynomial(R, 34)) == 34
    @test parent(DlogGF.randomPolynomial(R, 34)) == R

    @test length(factor(DlogGF.randomIrrPolynomial(R, 10))) == 1
    @test degree(DlogGF.randomIrrPolynomial(R, 10)) == 10
    @test parent(DlogGF.randomIrrPolynomial(R, 10)) == R

    @test length(factor(DlogGF.randomIrrPolynomial(R, 18))) == 1
    @test degree(DlogGF.randomIrrPolynomial(R, 18)) == 18
    @test parent(DlogGF.randomIrrPolynomial(R, 18)) == R

    q = 3^5
    G, y = FiniteField(3, 40, "y")
    S, U = PolynomialRing(G, "U")
    B = DlogGF.randomSplitElem(S, q)
    P = U^(q+1) - B*U + B
    fact = factor(P)
    boo = true

    for f in fact
        if degree(f[1]) != 1
            boo = false
            break
        end
    end

    @test boo

    println("PASS")
end

function testSmsrField()
    print("smsrField... ")

    K = DlogGF.smsrField(5, 4)

    @test K.cardinality == 5^8
    @test length(factor(K.definingPolynomial)) == 1
    @test K.characteristic == 5
    @test K.extensionDegree == 4

    println("PASS")
end

function testHomogeneEq()
    print("homogene, makeEquation, fillMatrixBGJT!... ")
    K = DlogGF.smsrField(5, 5, 1, true)
    F = base_ring(K.h0)
    x = gen(F)
    R, T = PolynomialRing(F, "T")
    P = (3)*T^3+(x+3)*T^2+(3*x+1)*T+(4*x+1)
    m = DlogGF.pglCosets(x)[8]
    polDef = K.definingPolynomial

    @test DlogGF.homogene(T, T^2, T^3) == T^2
    @test DlogGF.homogene(T - 2, T^2, T^3) == T^2 - 2*T^3
    @test DlogGF.homogene(R(x), T^2, T^3) == x^5

    tmp = R()
    for j in 0:degree(P)
        tmp += coeff(P, j)^5*T^(5*j)
    end

    tmp %= polDef

    a, b, c, d = m[1,1], m[1,2], m[2,1], m[2,2]
    tmp = ((a^5*tmp+b^5)*(c*P+d)-(a*P+b)*(c^5*tmp+d^5))%polDef
    tmp2 = DlogGF.makeEquation(m, P, K.h0, K.h1)*gcdinv(K.h1,polDef)[2]^3
    tmp2 %= polDef
    @test tmp == tmp2

    S = MatrixSpace(ZZ, 5^2+1, 1)
    M = S()
    u = DlogGF.fillMatrixBGJT!(M, 1, m, F)
    i = 1
    tmp3=R(1)
    for y in F
        if M[i, 1] == 1
            tmp3 *= P-y
        end
        i += 1
    end
    tmp3 %= polDef
    @test tmp2 == u*tmp3


    P = T^3 + (x+1)*T^2 +4*x*T+3

    K = DlogGF.smsrField(17, 17, 1, true)
    F = base_ring(K.h0)
    x = gen(F)
    R, T = PolynomialRing(F, "T")
    polDef = K.definingPolynomial
    P = (14*x+1)*T^5+(16*x+6)*T^4+(4*x+10)*T^3+(11*x+6)*T^2+(2*x+2)*T+(8*x+16)
    tmp = R()
    for j in 0:degree(P)
        tmp += coeff(P, j)^17*T^(17*j)
    end

    tmp %= polDef
    m = DlogGF.pglCosets(x)[19]
    a, b, c, d = m[1,1], m[1,2], m[2,1], m[2,2]
    tmp = ((a^17*tmp+b^17)*(c*P+d)-(a*P+b)*(c^17*tmp+d^17))%polDef
    tmp2 = DlogGF.makeEquation(m, P, K.h0, K.h1)*gcdinv(K.h1,polDef)[2]^5
    tmp2 %= polDef
    @test tmp == tmp2

    S = MatrixSpace(ZZ, 17^2+1, 1)
    M = S()
    u = DlogGF.fillMatrixBGJT!(M, 1, m, F)
    i = 1
    tmp3=R(1)
    for y in F
        if M[i, 1] == 1
            tmp3 *= P-y
        end
        i += 1
    end
    tmp3 %= polDef
    @test tmp2 == u*tmp3

    P = (5*x+16)*T^15+(10*x+1)*T^14+(6*x+4)*T^13+(15*x+15)*T^12+(7*x+6)*T^11+(12*x+12)*T^10+(5*x+10)*T^9+(12*x+3)*T^8+(15*x+2)*T^7+(9*x+11)*T^6+(15*x+4)*T^5+(13*x+11)*T^4+(9*x+2)*T^3+(10*x+2)*T^2+(14*x+13)*T+(x)
    tmp = R()
    for j in 0:degree(P)
        tmp += coeff(P, j)^17*T^(17*j)
    end

    tmp %= polDef
    m = DlogGF.pglCosets(x)[19]
    a, b, c, d = m[1,1], m[1,2], m[2,1], m[2,2]
    tmp = ((a^17*tmp+b^17)*(c*P+d)-(a*P+b)*(c^17*tmp+d^17))%polDef
    tmp2 = DlogGF.makeEquation(m, P, K.h0, K.h1)*gcdinv(K.h1,polDef)[2]^15
    tmp2 %= polDef
    @test tmp == tmp2

    S = MatrixSpace(ZZ, 17^2+1, 1)
    M = S()
    u = DlogGF.fillMatrixBGJT!(M, 1, m, F)
    i = 1
    tmp3=R(1)
    for y in F
        if M[i, 1] == 1
            tmp3 *= P-y
        end
        i += 1
    end
    tmp3 %= polDef
    @test tmp2 == u*tmp3

    println("PASS")
end

function testIsSmooth()
    print("isSmooth... ")

    F, x = FiniteField(5, 2, "x")
    R, T = PolynomialRing(F, "T")
    P = (x)*T^20+(2*x+2)*T^19+(x+1)*T^18+(3*x)*T^17+(4*x)*T^16+(3*x+4)*T^15+(x+3)*T^14+(2*x)*T^13+(4*x)*T^12+(x+4)*T^11+(3*x+1)*T^10+(4*x+3)*T^9+(4*x+3)*T^8+(2*x)*T^7+(x)*T^6+(2*x+2)*T^5+(x)*T^4+(4*x+2)*T^3+(2*x+3)*T^2+(2)*T

    @test DlogGF.isSmooth(P, 2) == false
    @test DlogGF.isSmooth(P, 6) == true
    @test DlogGF.isSmooth(T, 1) == true

    println("PASS")
end

function testFactorsList()
    print("factorsList... ")

    F, x = FiniteField(5, 2, "x")
    R, T = PolynomialRing(F, "T")
    L = DlogGF.factorsList(T)

    @test typeof(L) == DlogGF.FactorsList
    @test L.factors == [T]
    @test L.coefs == [1]

    push!(L, T^2, ZZ(2))

    @test L.factors == [T, T^2]
    @test L.coefs == [1, 2]

    push!(L, T, ZZ(3))

    @test L.factors == [T, T^2]
    @test L.coefs == [4, 2]

    deleteat!(L, 1)

    @test L.factors == [T^2]
    @test L.coefs == [2]

    println("PASS")
end

function testPohligHellman()
    print("pohligHellmanPrime, pohligHellman... ")

    K = DlogGF.smsrField(13, 13, 1, true)
    g = K.gen
    c = K.cardinality
    defPol = K.definingPolynomial

    @test DlogGF.pohligHellman(c, g, powmod(g, 147, defPol), defPol) == (147, 8904)
    @test DlogGF.pohligHellman(c, g, powmod(g, 5913, defPol), defPol) == (5913, 8904)
    @test DlogGF.pohligHellman(c, g, powmod(g, 81426, defPol), defPol) == (1290, 8904)

    K = DlogGF.smsrField(17, 17, 1, true)
    g = K.gen
    c = K.cardinality
    defPol = K.definingPolynomial

    @test DlogGF.pohligHellman(c, g, powmod(g, 814, defPol), defPol) == (238, 288)
    @test DlogGF.pohligHellman(c, g, powmod(g, 135, defPol), defPol) == (135, 288)
    @test DlogGF.pohligHellman(c, g, powmod(g, 79, defPol), defPol) == (79, 288)

    K = DlogGF.smsrField(7, 7, 1, true)
    g = K.gen
    c = K.cardinality
    defPol = K.definingPolynomial

    @test DlogGF.pohligHellman(c, g, powmod(g, 514, defPol), defPol) == (514, 1392)
    @test DlogGF.pohligHellman(c, g, powmod(g, 2941, defPol), defPol) == (157, 1392)
    @test DlogGF.pohligHellman(c, g, powmod(g, 602, defPol), defPol) == (602, 1392)

    println("PASS")
end

function testIsGenerator()
    print("isGenerator, miniCheck... ")

    K = DlogGF.smsrField(3, 3, 1, true)
    g = K.gen
    c = K.cardinality
    R = parent(g)
    defPol = K.definingPolynomial

    @test DlogGF.isGenerator(R(1), c, defPol) == false
    @test DlogGF.isGenerator(g, c, defPol) == true
    @test DlogGF.isGenerator(g^2, c, defPol) == false
    @test DlogGF.miniCheck(g, c, defPol) == true
    @test DlogGF.miniCheck(g^2, c, defPol) == false
    @test DlogGF.miniCheck(R(1), c, defPol) == false

    println("PASS")
end

function testDlogSmallField()
    print("dlogSmallField... ")

    K = DlogGF.smsrField(7, 7, 1, true)
    g = K.gen
    F = base_ring(g)
    R = parent(g)
    x = gen(F)
    q = K.characteristic
    k = K.extensionDegree
    defPol = K.definingPolynomial

    elem = R(1+x)
    d = DlogGF.dlogSmallField(q, k, g, elem, defPol)
    @test powmod(g, d, defPol) == elem
    elem = R(x)
    d = DlogGF.dlogSmallField(q, k, g, elem, defPol)
    @test powmod(g, d, defPol) == elem
    elem = R(2)
    d = DlogGF.dlogSmallField(q, k, g, elem, defPol)
    @test DlogGF.powmod(g, d, defPol) == elem
    elem = R(x+2)
    d = DlogGF.dlogSmallField(q, k, g, elem, defPol)
    @test powmod(g, d, defPol) == elem

    println("PASS")
end

function testPglCosets()
    print("pglCosets... ")

    F, x = FiniteField(5, 2, "x")
    
    cosets = DlogGF.pglCosets(x)

    @test length(cosets) >= 5^3 + 5

    @test parent(cosets[8][1, 2]) == F

    boo = true

    for a in cosets
        if rank(a) != 2
            boo = true
        end
    end

    @test boo

    println("PASS")
end


function testLinearDlog()
    print("linearDlog, dlogBGJT... ")

    F, x = FiniteField(17, 2, "x")
    R, T = PolynomialRing(F, "T")
    K = DlogGF.SmsrField(17,17,684326450885775034048946719925754910487329,(9*x+11)*T+(11*x+5),T+(15*x+7),T^17+(15*x+6)*T^16+(2*x+11)*T^15+(15*x+6)*T^14+(2*x+11)*T^13+(15*x+6)*T^12+(2*x+11)*T^11+(15*x+6)*T^10+(2*x+11)*T^9+(15*x+6)*T^8+(2*x+11)*T^7+(15*x+6)*T^6+(2*x+11)*T^5+(15*x+6)*T^4+(2*x+11)*T^3+(15*x+6)*T^2+(2*x+11)*T+(6*x+12),T+(10*x+8))
    g = K.gen
    k = K.extensionDegree
    h0 = K.h0
    h1 = K.h1
    card = K.cardinality
    defPol = K.definingPolynomial

    dlogs = DlogGF.linearDlog(g, k, h0, h1, card, defPol)

    i = dlogs[T + 12*x+5]
    @test powmod(g, i, defPol) == T + 12*x+5

    i = dlogs[T + 3*x]
    @test powmod(g, i, defPol) == T + 3*x

    i = dlogs[T + 8*x+11]
    @test powmod(g, i, defPol) == T + 8*x+11

    i = dlogs[T + 10*x+1]
    @test powmod(g, i, defPol) == T + 10*x+1

    i = dlogs[T + x+4]
    @test powmod(g, i, defPol) == T + x+4

    P = (14*x+6)*T^2+(14*x+6)*T+(10*x+2)
    d = DlogGF.dlogBGJT(P, K, dlogs)
    @test powmod(K.gen, d, defPol) == P

    P = (10*x+6)*T^2+(10*x+4)*T+(13*x+5)
    d = DlogGF.dlogBGJT(P, K, dlogs)
    @test powmod(K.gen, d, defPol) == P

    P = (9*x+12)*T^2+(13*x+13)*T+(2*x+14)
    d = DlogGF.dlogBGJT(P, K, dlogs)
    @test powmod(K.gen, d, defPol) == P

    P = (13*x)*T^2+(9*x+4)*T+(11*x+4)
    d = DlogGF.dlogBGJT(P, K, dlogs)
    @test powmod(K.gen, d, defPol) == P

    println("PASS")
end

function testGkzContext()
    print("gkzContext... ")

    K = DlogGF.gkzContext(3, 5, 10)
    F, z5 = FiniteField(3, 5, "z5")

    @test length(factor(K.definingPolynomial)) == 1
    @test characteristic(base_ring(K.h0)) == 3
    @test base_ring(K.h0) == F
    @test degree(K.definingPolynomial) == 10

    println("PASS")
end

function testAscent()
    print("ascent...")

    F3_5, z5 = FiniteField(3, 5, "z5")
    R3_5, T = PolynomialRing(F3_5, "T5")
    P = (z5^3+z5^2)*T^16+(z5^3+z5^2+2*z5+2)*T^15+(2*z5^4+2*z5^3+z5+1)*T^14+(2*z5^4+2*z5^2+2*z5)*T^13+(2*z5^4+2*z5^2+z5+2)*T^12+(z5^4+z5^3+z5^2+z5+2)*T^11+(z5^4+z5^2+z5)*T^10+(2*z5^2+2)*T^9+(2*z5^3+2*z5+1)*T^8+(z5^3+2*z5^2+2*z5+2)*T^7+(2*z5^4+z5^2+2*z5+1)*T^6+(z5^4+z5^3+z5^2+z5+2)*T^5+(2*z5^3+2*z5+1)*T^4+(z5^4+2*z5^3+z5^2+1)*T^3+(2*z5^4+2*z5^3+z5+2)*T^2+(2*z5^4+2*z5^3)*T+(2*z5^2)
    Q = DlogGF.ascent(P)

    F3_10, z10 = FiniteField(3, 10, "z10")
    F3_20, z20 = FiniteField(3, 20, "z20")
    F3_40, z40 = FiniteField(3, 40, "z40")

    R3_10 = PolynomialRing(F3_10, "T10")[1]
    R3_20 = PolynomialRing(F3_20, "T20")[1]
    R3_40 = PolynomialRing(F3_40, "T40")[1]


    @test length(factor(Q)) == 1
    @test R3_40(R3_20(R3_10(P))) % Q == 0 
    
    P = (2*z5^4+2*z5)*T^16+(z5^3+z5+2)*T^15+(2*z5^4+2*z5^3+2*z5^2+2*z5+2)*T^14+(2*z5^4+z5^3+2*z5^2+z5)*T^13+(2*z5^4+z5^2+1)*T^12+(2*z5^4+2*z5^3+2*z5^2+z5)*T^11+(2*z5^3+z5^2+2)*T^10+(z5^4+2*z5^3+2*z5^2+z5+1)*T^9+(2*z5^4+z5^2)*T^8+(2*z5)*T^7+(2*z5^4+z5^2+2*z5+1)*T^6+(2*z5^4+2*z5)*T^5+(2*z5^4+2*z5^3)*T^4+(2*z5^4+z5^3+2*z5^2+2*z5)*T^3+(z5^3+2)*T^2+(2*z5^4+2*z5^3+1)*T+(z5^4+z5^3+z5^2+2*z5+1)
    Q = DlogGF.ascent(P)

    @test length(factor(Q)) == 1
    @test R3_40(R3_20(R3_10(P))) % Q == 0 

    println("PASS")
end

function testLatticeBasis()
    print("latticeBasis... ")

    F, z5 = FiniteField(3, 5, "z5")
    R, T = PolynomialRing(F, "T")
    h0 = (2*z5+2)*T+(2*z5^4+z5^3+2*z5^2+z5)
    h1 = T^2+(2*z5^4+z5+1)*T
    Q = (2*z5^4+2*z5^3+2*z5^2+z5+2)*T^2+(2*z5^4+2*z5^3+z5+2)*T+(2*z5^3+z5^2+2*z5+1)
    u0, u1, v0, v1 = DlogGF.latticeBasis(Q, h0, h1)

    @test ((T+v0)*h0+(v1)*h1)%Q == 0
    @test ((u0)*h0+(T+u1)*h1)%Q == 0

    Q = (z5^4+2*z5^3+z5^2+2*z5+2)*T^2+(z5^4+2*z5^2+z5+2)*T+(2*z5^3+z5^2)
    u0, u1, v0, v1 = DlogGF.latticeBasis(Q, h0, h1)

    @test ((T+v0)*h0+(v1)*h1)%Q == 0
    @test ((u0)*h0+(T+u1)*h1)%Q == 0

    Q = (z5^4+1)*T^2+(2*z5^2+z5)*T+(2*z5^3+z5^2)
    u0, u1, v0, v1 = DlogGF.latticeBasis(Q, h0, h1)

    @test ((T+v0)*h0+(v1)*h1)%Q == 0
    @test ((u0)*h0+(T+u1)*h1)%Q == 0

    println("PASS")
end

function testProject()
    print("projectLinAlg, projectLinAlgPoly... ")

    F3_5, z5 = FiniteField(3, 5, "z5")
    F3_20, z20 = FiniteField(3, 20, "z20")
    img = DlogGF.findImg(F3_20, F3_5)

    a = z5^2+z5+1
    b = z5^4+2*z5^2+2
    c = z5^4+z5^3+z5^2+z5+1
    d = 2*z5^4+z5^3+z5^2+2*z5
    f = z5^4+z5^3+2*z5^2+2

    M, piv = DlogGF.projectFindInv(F3_20, F3_5)
    
    @test DlogGF.projectLinAlg(F3_5, F3_20(a, img), M, piv) == a
    @test DlogGF.projectLinAlg(F3_5, F3_20(b, img), M, piv) == b
    @test DlogGF.projectLinAlg(F3_5, F3_20(c, img), M, piv) == c
    @test DlogGF.projectLinAlg(F3_5, F3_20(d, img), M, piv) == d
    @test DlogGF.projectLinAlg(F3_5, F3_20(f, img), M, piv) == f

    R3_20, T20 = PolynomialRing(F3_20, "T20")
    F3_40, z40 = FiniteField(3, 40, "z40")
    R3_40, T40 = PolynomialRing(F3_40, "T40")

    P = (z20^19+z20^18+2*z20^17+2*z20^15+z20^13+2*z20^12+2*z20^11+2*z20^10+2*z20^9+2*z20^8+2*z20^6+z20^5+2*z20^3+z20^2+z20+1)*T20^5+(2*z20^19+z20^17+2*z20^15+z20^14+2*z20^13+z20^12+2*z20^11+z20^9+z20^6+z20^5+z20^4+z20^2+2*z20)*T20^4+(z20^19+2*z20^16+2*z20^14+z20^13+2*z20^12+z20^11+z20^10+z20^9+z20^8+2*z20^7+z20^5+2*z20^3+1)*T20^3+(z20^19+z20^16+2*z20^15+2*z20^14+2*z20^13+z20^11+z20^10+z20^8+2*z20+1)*T20^2+(z20^18+z20^17+z20^15+z20^14+2*z20^11+2*z20^10+z20^9+2*z20^8+2*z20^6+2*z20^4+z20^3+2*z20^2)*T20+(z20^18+z20^17+2*z20^16+z20^15+z20^13+z20^12+z20^11+z20^10+2*z20^9+2*z20^6+2*z20^5+2*z20^4+2*z20^3+z20+2)

   Q = (z20^18+2*z20^17+2*z20^16+2*z20^15+z20^14+z20^13+z20^12+z20^10+z20^8+2*z20^7+z20^5+z20^4+2*z20^3+z20+2)*T20^5+(z20^18+2*z20^15+z20^14+2*z20^11+2*z20^9+2*z20^7+z20^5+z20^4+2*z20^3+z20^2+2*z20)*T20^4+(z20^19+z20^18+z20^17+z20^15+2*z20^14+z20^12+z20^11+2*z20^10+2*z20^9+2*z20^8+z20^6+z20^5+z20^4)*T20^3+(z20^19+2*z20^18+z20^16+z20^15+2*z20^13+2*z20^12+z20^11+2*z20^8+2*z20^7+z20^4+z20^3+2*z20^2+2*z20+1)*T20^2+(z20^19+2*z20^18+z20^15+z20^14+2*z20^13+2*z20^11+2*z20^10+z20^9+z20^7+2*z20^6+z20^4+z20^3+2*z20^2+1)*T20+(z20^19+z20^17+z20^16+2*z20^15+z20^14+2*z20^13+2*z20^12+2*z20^9+z20^8+2*z20^7+z20^6+2*z20^5+2*z20^3+2*z20^2+2*z20+2)

  R = (2*z20^19+z20^18+2*z20^17+z20^15+2*z20^12+z20^9+z20^6+z20^4+z20^3+2*z20^2+2*z20)*T20^5+(z20^19+2*z20^18+2*z20^17+2*z20^16+2*z20^15+2*z20^14+2*z20^13+2*z20^11+z20^10+z20^9+z20^8+z20^7+z20^6+z20^3+2*z20^2+z20+1)*T20^4+(2*z20^19+2*z20^16+2*z20^15+2*z20^14+z20^13+2*z20^11+z20^8+z20^7+z20^5+2*z20^4+2*z20^3+z20^2+2*z20)*T20^3+(z20^18+z20^17+z20^15+z20^14+z20^12+2*z20^10+z20^8+z20^7+z20^6+z20^5+2*z20^4+z20^3+z20^2+2*z20)*T20^2+(z20^19+2*z20^18+z20^17+z20^15+2*z20^14+2*z20^13+2*z20^11+2*z20^10+z20^9+z20^8+2*z20^7+2*z20^6+z20^4+z20^3+z20+2)*T20+(z20^17+z20^16+2*z20^15+2*z20^14+z20^13+z20^11+2*z20^10+2*z20^9+2*z20^8+2*z20^7+z20^4+2*z20^3+z20+2)

  M, piv = DlogGF.projectFindInv(F3_40, F3_20)
  img = DlogGF.findImg(F3_40, F3_20)

  @test DlogGF.projectLinAlgPoly(R3_20, R3_40(P, img), M, piv) == P
  @test DlogGF.projectLinAlgPoly(R3_20, R3_40(Q, img), M, piv) == Q
  @test DlogGF.projectLinAlgPoly(R3_20, R3_40(R, img), M, piv) == R
 
    println("PASS")
end

function testOnTheFly()
    print("onTheFlyAbc, onTheFlyElimination... ")

    K = DlogGF.gkzContext(3, 3, 20)
    F3_3, z3 = FiniteField(3, 3, "z3")
    R3_3, T3 = PolynomialRing(F3_3, "T3")
    P = (2*z3^2)*T3^8+(2*z3^2+2*z3+1)*T3^7+(2*z3^2+2*z3+1)*T3^6+(2*z3^2+2*z3+2)*T3^5+(z3^2+z3)*T3^4+(2*z3)*T3^3+(z3+2)*T3^2+(2*z3^2+2*z3+2)*T3+(z3^2+2*z3+1)
    Q = DlogGF.ascent(P)
    R = parent(Q)
    T = gen(R)
    q = 3^3
    h0 = R(K.h0)
    h1 = R(K.h1)

    a, b, c = DlogGF.onTheFlyAbc(Q, h0, h1, q)

    ρ = T^(q+1) + a*T^q + b*T + c

    β = true
    for f in factor(ρ)
        if degree(f[1]) != 1
            β = false
            break
        end
    end

    @test β
    @test ((T+a)*h0+(b*T+c)*h1)%Q == 0

    P = (2*z3^2+z3+1)*T3^8+(z3^2+2*z3)*T3^7+(2*z3^2+z3+2)*T3^6+(z3^2+2*z3+1)*T3^5+(2*z3)*T3^4+(z3+2)*T3^3+(z3^2+z3)*T3^2+(2*z3^2+z3+2)*T3+(2*z3^2+1)
    Q = DlogGF.ascent(P)

    a, b, c = DlogGF.onTheFlyAbc(Q, h0, h1, q)

    ρ = T^(q+1) + a*T^q + b*T + c

    β = true
    for f in factor(ρ)
        if degree(f[1]) != 1
            β = false
            break
        end
    end

    @test β
    @test ((T+a)*h0+(b*T+c)*h1)%Q == 0

    P = (z3^2+2)*T3^8+(2*z3^2+1)*T3^7+(z3+2)*T3^5+(z3+1)*T3^4+(z3^2+2*z3+1)*T3^3+(2*z3^2)*T3^2+(z3^2+2*z3)*T3+(2)
    Q = DlogGF.ascent(P)

    a, b, c = DlogGF.onTheFlyAbc(Q, h0, h1, q)

    ρ = T^(q+1) + a*T^q + b*T + c

    β = true
    for f in factor(ρ)
        if degree(f[1]) != 1
            β = false
            break
        end
    end

    @test β
    @test ((T+a)*h0+(b*T+c)*h1)%Q == 0

    P = (z3^2+2*z3+1)*T3^8+(2*z3^2+z3)*T3^7+(z3+2)*T3^6+(z3^2+2*z3+2)*T3^5+(z3^2)*T3^4+(z3+1)*T3^3+(z3)*T3+(z3+1)
    Q = DlogGF.ascent(P)

    A = DlogGF.onTheFlyElimination(Q, h0, h1, q)
    product = h1
    for j in 1:(q+1)
        product *= A[j]
    end
    
    @test (product - A[end]*Q) % (h1*T^q-h0) == 0

    P = (2*z3^2+2*z3)*T3^8+(2*z3+1)*T3^7+(2*z3+1)*T3^6+(z3^2+z3+2)*T3^5+(z3+1)*T3^4+(2*z3+1)*T3^3+(2*z3)*T3^2+(2*z3+2)*T3+(2*z3^2+2)
    Q = DlogGF.ascent(P)

    A = DlogGF.onTheFlyElimination(Q, h0, h1, q)
    product = h1
    for j in 1:(q+1)
        product *= A[j]
    end
    
    @test (product - A[end]*Q) % (h1*T^q-h0) == 0

    println("PASS")
end

function testDescent()
    print("descentGKZ ... ")

    K = DlogGF.gkzContext(3, 3, 20)
    q = 3^3
    F3_3, z3 = FiniteField(3, 3, "z3")
    R3_3, T3 = PolynomialRing(F3_3, "T3")
    H = K.h1*T3^q-K.h0


    P = T3^8+(z3+1)*T3^6+T3^5+(2*z3^2+z3+2)*T3^4+(z3^2+2*z3+1)*T3^3+(z3^2+z3)*T3^2+(2*z3^2)*T3+(2*z3)
    Q, t0, t1 = DlogGF.ascent(P, K.h0, K.h1)
    L = DlogGF.descentGKZ(Q, t0, t1, R3_3)
    product = one(R3_3)
    
    for j in 1:length(L)
        poly = L[j][1]
        coef = L[j][2]
        if coef < 0
            poly = gcdinv(poly, H)[2]
            coef = -coef
        end
        product = mulmod(product, poly^coef, H)
    end
    
    @test product == P

    println("PASS")
end

function testFactorBase()
    print("factorBaseDeg2... ")

    K = DlogGF.gkzContext(3, 3, 20)
    dlogs = DlogGF.factorBaseDeg2(K)

    R = parent(K.h0)
    X = gen(R)
    z = gen(base_ring(R))
    defPol = K.definingPolynomial

    P = X^2+(z^2+1)*X+(2*z^2+z+2)
    Q = X^2+(2)*X+(2*z+1)
    S = X^2+(2*z+1)
    T = X^2+(z^2+z+1)*X+(2*z^2+2*z)

    @test powmod(K.gen, dlogs[X], defPol) == X
    @test powmod(K.gen, dlogs[X+1], defPol) == X+1
    @test powmod(K.gen, dlogs[X+2], defPol) == X+2
    @test powmod(K.gen, dlogs[X+z], defPol) == X+z
    @test powmod(K.gen, dlogs[P], defPol) == P
    @test powmod(K.gen, dlogs[Q], defPol) == Q 
    @test powmod(K.gen, dlogs[S], defPol) == S
    @test powmod(K.gen, dlogs[T], defPol) == T

    println("PASS")
end

function testAll()

    testRandomSuite()
    testSmsrField()
    testIsGenerator()
    testHomogeneEq()
    testIsSmooth()
    testFactorsList()
    testPohligHellman()
    testDlogSmallField()
    testPglCosets()
    testLinearDlog()
    testGkzContext()
    testAscent()
    testLatticeBasis()
    testProject()
    testOnTheFly()
    testDescent()
    testFactorBase()

    println("\nAll tests passed successfully.\n")
end

testAll()

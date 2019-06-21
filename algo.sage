from sage.combinat.gray_codes import combinations

def systematique_form(G):
    M = copy(G)
    a = M.pivots()
    b = [ i+1 for i in a ]
    c = b + [ i for i in range(1, M.ncols()) if i not in b]
    c = Permutation(c)
    M.permute_columns(c)
    return M.echelon_form()

def infomation_set(G):

    M = copy(G)
    k = G.nrows()
    num_info_set = 0
    L = M.matrix_from_columns(range(num_info_set*k,G.ncols())).echelon_form()

    while L.rank() == k:

      a = L.pivots()
      b = range(0,num_info_set*k) + [num_info_set*k + i for i in a]
      c = b
      for i in range(G.ncols()):
        if i in b:
          pass
        else:
          c = c + [i]
      d = [i + 1 for i in c]
      d = Permutation(d)
      M.permute_columns(d)
      num_info_set += 1
      L = M.matrix_from_columns(range(num_info_set*k,G.ncols())).echelon_form()

    return (M,num_info_set)


def infomation_set_brouwer(G, maxiter = 200):

    k = G.nrows()
    n = G.ncols()
    M, num_info_set = infomation_set(G)
    q = n//k
    i = 0

    while i < maxiter and num_info_set != q :

      M_inter = copy(G)
      p = Permutations(n).random_element()
      M_inter.permute_columns(p)
      M_inter, num_info_set_inter = infomation_set(M_inter)

      if num_info_set_inter > num_info_set :
        M = copy(M_inter)
        num_info_set = num_info_set_inter

      i += 1

    return (M,num_info_set)


def infomation_set_brouwer_zimmer(G, maxiter = 200):

    k = G.nrows()
    n = G.ncols()
    M, num_info_set = infomation_set(G)
    R = M.matrix_from_columns(range(num_info_set*k,n))
    q = n//k
    r = n%k
    i = 0

    while i < maxiter and num_info_set != q and R.rank() != r:

      M_inter = copy(G)
      p = Permutations(n).random_element()
      M_inter.permute_columns(p)
      M_inter, num_info_set_inter = infomation_set(M_inter)
      R_inter = M_inter.matrix_from_columns(range(num_info_set_inter*k,n))

      if num_info_set_inter > num_info_set :
        M = copy(M_inter)
        R = copy(R_inter)
        num_info_set = num_info_set_inter
        i += 1
        continue

      if num_info_set_inter < num_info_set :
        i += 1
        continue

      if num_info_set == num_info_set_inter :

        if R.rank() >= R_inter.rank() :
          i += 1
          continue

        else :
          M = copy(M_inter)
          R = copy(R_inter)
          i += 1
          continue

      if num_info_set_inter == q and R_inter.rank() == r :
        M = copy(M_inter)
        num_info_set = num_info_set_inter
        break

    return (M,num_info_set)


def list_of_system_gen_mat(M,m,k):

    L = []
    for i in range(m):
      A = M.matrix_from_columns(range(i*k , i*k + k))
      L = L + [A.inverse()*M]
      
    return L

def incr_vector(X,F):
  V = copy(X)
  V = vector(V)
  s = V.support()
  g = F.multiplicative_generator()
  q = F.cardinality()

  if V[s[len(s)-1]] != g**(q-2) :
    L = [t for t in range(q) if g**t == V[s[len(s)-1]] ]
    V[s[len(s)-1]] = g**(L[0]+1)
  else :
    V[s[len(s)-1]] = g**0
    V_inter = [V[i] for i in range(s[len(s)-1])]
    V_inter = vector(V_inter)
    V_inter = incr_vector(V_inter,F) 
    V = list(V_inter) + [V[i] for i in range(s[len(s)-1],len(V))]
    V = vector(V)
  return V

def minimum_distance_brouwer(C):

    G1 = C.generator_matrix()
    n,k = C.length(), C.dimension()
    F = C.base_field()
    g = F.multiplicative_generator()
    q = F.cardinality()
    G2, num_info_set = infomation_set_brouwer(G1,3)
    L = list_of_system_gen_mat(G2,num_info_set,k)
    ub = n - k + 1
    lb = num_info_set
    w = 1

    print("The number of disjoint information set is : {} ".format(num_info_set))

    if F == GF(2) :
      while w <= k and lb < ub :
        for m in range(0,num_info_set) : # pour calculer G22 = L[m]
          
          X = zero_vector(k)
          for e in range(w):
            X[e] = g**0

          A = zero_vector(n)
          for i in range(w):
            A += L[m].row(i)
          ub = min(ub, A.hamming_weight())
          if ub <= lb :
            return ub
          
          for i,j in combinations(k,w):
            X[i] = 0; X[j] = g**0
            A = zero_vector(n)
            for i in X.support() :
              A += L[m].row(i)
            
            ub = min(ub, A.hamming_weight())
            if ub <= lb :
              return ub
          lb += 1
        w += 1
      return ub

    while w <= k and lb < ub :

      for m in range(0,num_info_set) : # pour calculer G22 = L[m]

        X = zero_vector(k)
        for e in range(w):
          X[e] = g**0

        A = zero_vector(n)
        for i in range(w):
          A += L[m].row(i)
        ub = min(ub, A.hamming_weight())
        if ub <= lb :
          return ub
        
        a = [0]*w
        for i in range(1,(q-1)**w):
          a_anc = copy(a)
          a = Z(i).digits(q-1,padto=w)
          a.reverse()
          X = [g**i for i in a] + [0]*(k-w)
          X = vector(X)

          for i in (vector(a)- vector(a_anc)).support() : 
            A += (g^a[i] - g^a_anc[i])*L[m].row(i)

          ub = min(ub, A.hamming_weight()) 
          if ub <= lb :
            return ub

        for v in range(w) :
          X[v] = g**0

        for i,j in combinations(k,w):

          X[i] = 0; X[j] = g**0
          S = X.support()
          A = zero_vector(n)
          for i in S :
            A += L[m].row(i)

          ub = min(ub, A.hamming_weight())
          if ub <= lb :
            return ub
          
          for i in range(1,(q-1)**w):
            a_anc = copy(a)
            a = Z(i).digits(q-1,padto=w)
            a.reverse()
            c = 0
            for z in S :
              X[z] = g**(a[c])
              c = c + 1
            
            for i in (vector(a)- vector(a_anc)).support() :
              A += (g^a[i] - g^a_anc[i])*L[m].row(i)
            
            ub = min(ub, A.hamming_weight()) 
            if ub <= lb :
              return ub

          for v in S :
            X[v] = g**0

        lb += 1
      w += 1
    return ub

C = codes.random_linear_code(GF(2),100,11)
#C = codes.random_linear_code(GF(2),100,25)
#time C.minimum_distance()
#time minimum_distance_brouwer(C)
G = C.generator_matrix()
X= (1,0,1,0,1,0,0)
Z = IntegerRing()

# http://doc.sagemath.org/html/en/reference/combinat/sage/combinat/permutation.html?highlight=permutation#module-sage.combinat.permutation
# https://www.diveinto.org/python3/advanced-iterators.html


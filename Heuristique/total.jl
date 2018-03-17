include("glouton.jl")
include("local_search.jl")

Path = "../data/tests/test07.txt"

n,a = read_txt(Path)
G = Glouton(Path)

local_search(a, adjacency_matrix(G), true, true)

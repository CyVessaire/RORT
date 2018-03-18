include("glouton.jl")
include("local_search.jl")

Path = "testdata.txt"
n,a = read_txt(Path)
G = Glouton(Path)

local_search(a, adjacency_matrix(G), true, true)

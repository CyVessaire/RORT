include("glouton.jl")
include("local_search.jl")

for i in 1:9
    Path = "../data/tests/rand1$i.txt"
    n,a = read_txt(Path)

    println(i)
    @time(G = Glouton(Path, false))
    @time(local_search(a, adjacency_matrix(G), true, false))
end

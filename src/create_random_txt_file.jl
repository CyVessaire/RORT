using LightGraphs

for i=1:9
    str = "../data/tests/rand3$(i).txt"
    println(str)

    n = 3000

    G = erdos_renyi(n, 1/1000)

    Dists = dijkstra_shortest_paths(G, 1, allpaths=true).dists
    for i in 2:n
        if Dists[i] > n
            add_edge!(G, 1, i)
            println("edge added")
            Dists = dijkstra_shortest_paths(G, 1, allpaths=true).dists
        end
    end

    Dists = dijkstra_shortest_paths(G, 1, allpaths=true).dists
    for i in 2:n
        if Dists[i] > n
            println("error")
        end
    end

    a = adjacency_matrix(G)
    a = full(a)

    println(size(a))

    open(str, "w") do io
        writedlm(io, a, ' ')
    end
end

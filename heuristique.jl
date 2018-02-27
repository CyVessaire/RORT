using LightGraphs

G1 = Graph(7) # graph with 3 vertices

# make a triangle
add_edge!(G1, 1, 2)
add_edge!(G1, 1, 3)
add_edge!(G1, 2, 3)
add_edge!(G1, 4, 5)
add_edge!(G1, 5, 6)
add_edge!(G1, 6, 4)
add_edge!(G1, 1, 7)
add_edge!(G1, 2, 4)

# gplot(G1, nodelabel=1:3)
# println(nv(G1))
# println(neighbors(G1,1))

function isthmes_recur!(G, u, visited, disc, low, parent, time, ISM)
    visited[u] = true
    disc[u] = time
    low[u] = time
    time += 1
    for i in neighbors(G, u)
        v = i
        if !(visited[v])
            parent[v] = u
            isthmes_recur!(G, v, visited, disc, low, parent, time, ISM)
            low[u] = minimum([low[u], low[v]])
            if (low[v] > disc[u])
                push!(ISM, tuple(u,v))
            end
        elseif (v != parent[u])
            low[u] = minimum([low[u], disc[v]])
        end
    end
end

function get_isthmes(G)
    V = nv(G)
    visited = Array{Bool, 1}(V)
    disc = Array{Int, 1}(V)
    low = Array{Int, 1}(V)
    parent = Array{Int, 1}(V)
    ISM = Array{Tuple{Int,Int}, 1}(0)
    for v in vertices(G)
        visited[v] = false
        parent[v] = 0
    end
    for v in vertices(G)
        if !visited[v]
            isthmes_recur!(G, v, visited, disc, low, parent, 0, ISM)
        end
    end
    println(ISM)
end

get_isthmes(G1)

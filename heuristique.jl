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

G2 = deepcopy(G1)
add_edge!(G2, 7, 6)

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
    return ISM
end

get_isthmes(G1)
get_isthmes(G2)

function GetArticulationPoints!(G, i, visited, d, low, depth, parent, artic)
    visited[i] = true
    depth[i] = d
    low[i] = d
    childCount = 0
    isArticulation = false
    d += 1
    for ni in neighbors(G, i)
        if !(visited[ni])
            parent[ni] = i
            childCount = childCount + 1
            GetArticulationPoints!(G, ni, visited, d, low, depth, parent, artic)
            low[i] = minimum([low[i], low[ni]])
            if low[ni] >= depth[i]
                isArticulation = true
            end
        elseif ni != parent[i]
            low[i] = minimum([low[i], depth[ni]])
        end
    end
    if (parent[i] != 0 && isArticulation) || (parent[i] == 0 && childCount > 1)
        push!(artic ,i)
    end
end

function get_artics(G)
    V = nv(G)
    visited = Array{Bool, 1}(V)
    depth = Array{Int, 1}(V)
    low = Array{Int, 1}(V)
    parent = Array{Int, 1}(V)
    artics = Array{Int, 1}(0)
    for v in vertices(G)
        visited[v] = false
        parent[v] = 0
    end
    for v in vertices(G)
        if !visited[v]
            GetArticulationPoints!(G, v, visited, 0, low, depth, parent, artics)
        end
    end
    println(artics)
    return artics
end

get_artics(G1)
get_artics(G2)

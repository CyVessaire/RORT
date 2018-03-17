using JuMP
using LightGraphs
using GraphPlot
# G1 = Graph(7) # graph with 7 vertices
#
# # make a triangle
# add_edge!(G1, 1, 2)
# add_edge!(G1, 1, 3)
# add_edge!(G1, 2, 3)
# add_edge!(G1, 4, 5)
# add_edge!(G1, 5, 6)
# add_edge!(G1, 6, 4)
# add_edge!(G1, 1, 7)
# add_edge!(G1, 2, 4)
#
# G2 = deepcopy(G1)
# add_edge!(G2, 7, 6)

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

# read from the file the adjacence matrix && size
function read_txt(Path)
        A = readdlm(Path, ' ')

        B = A[1:size(A,1)-1,:]

        n = size(B,1)
        a = round.(Int,B)
        # println(a)

        return(n,a)
end

function create_graph(matrix)
    G = Graph(matrix)
    return G
end

# G is a graph object
# n is the number of nodes
# node is the list of nodes
function Glouton(Path)
    #read data
    n,a = read_txt(Path)
    # create graph G and lists we will use for discovery
    G = create_graph(a)
    # no node is selected yet.
    nodes = zeros(Int,n)
    # all nodes are not discovered yet.
    undiscovered = nodes + 1
    # preprocessing  des noeuds de branchement et des isthmes
    branchements = get_artics(G)
    isthmes = get_isthmes(G)
    # list all nodes involved in isthmes
    ISMnodes = []
    for edge in isthmes
        if !(edge[1] in ISMnodes)
            push!(ISMnodes, edge[1])
        end
        if !(edge[2] in ISMnodes)
            push!(ISMnodes, edge[2])
        end
    end
    # gerer les affectations des nodes
    for node in branchements
            nodes[node] = 1
    end
    for ism in isthmes
        nodes[ism[1]] = 1
        nodes[ism[2]] = 1
    end
    # gere les decouvertes de voisins
    for node in branchements
        undiscovered[node] = 0
        discovery = neighbors_discovery(n, a, undiscovered,  node)
        for target in discovery
            undiscovered[target] = 0
        end
    end
    for ism in isthmes
        undiscovered[ism[1]] = 0
        discovery = neighbors_discovery(n, a, undiscovered,  ism[1])
        for target in discovery
            undiscovered[target] = 0
        end
        undiscovered[ism[2]] = 0
        discovery = neighbors_discovery(n, a, undiscovered,  ism[2])
        for target in discovery
            undiscovered[target] = 0
        end
    end

    # continue l'heuristique avec les autres.
    # tant que des nodes sont pas découvertes, je continue à rajouter des nodes.
    while (sum(undiscovered) > 0)
        bestnode = find_best_node(n, a, undiscovered, nodes)
        discovery = neighbors_discovery(n, a, undiscovered,  bestnode)
        nodes[bestnode] = 1
        for target in discovery
            undiscovered[target] = 0
        end
    end

    println(undiscovered)
    println(nodes)

    # j'ai la liste des noeuds selectionnes pas l'algo ( dans laquelle il y a les noeuds de branchement).
    # Il se trouve que ces noeud sont ordonnés par nombre de feueilles decouvertes.
    # on va creer un squelette à partir de plus cours chemins a partir du premier element de cette liste, vers les autres.
    # puis on va rajouter les feuilles en parcourant
    covered = zeros(Int, n)
    newG_tree = Graph(n)
    root = get_root(nodes, n, G)
    print(root)
    covered[root] = 1
    paths = Dijkstra_paths(G, root)
    println(paths)
    for selected in 1:n
        if(nodes[selected] == 1 && selected != root)
            covered[selected] = 1
            thispath = paths[selected]
            println(thispath)
            for j in 2:length(thispath)
                add_edge!(newG_tree, thispath[j-1], thispath[j])
                covered[thispath[j-1]] = 1
                covered[thispath[j]] = 1
            end
        end
    end

    #maintenant on va ajouter a cet arbre, le nodes qui n'ont pas été sélectionées.
    for selected in 1:n
        println(neighbors(newG_tree, selected))
        degree = length(neighbors(newG_tree, selected))
        # degree = degree(newG, selected)
        println(degree  )
        # if nodes[selected] == 1 && (degree >= 3 || degree == 1)
        if nodes[selected] == 1
            # theseneighbors = G.vertices[selected].neighbors
            theseneighbors = neighbors(G, selected)
            println(theseneighbors)
            for thisneighbor in theseneighbors
                if covered[thisneighbor] == 0
                    add_edge!(newG_tree, selected, thisneighbor)
                    covered[thisneighbor] = 1
                end
            end
        end
    end
    println(adjacency_matrix(newG_tree))
    return newG_tree
end


# return the first selected node, can be upgraded to selecting the one of max degree
function get_root(nodes, n, G)
    for i in 1:n
        if nodes[i] ==1
            return i
        end
    end
end
function neighbors_discovery(n, a, undiscovered,  node)
    neighbors = []
    for othernode in 1:n
        if (othernode != node) && (a[othernode, node] == 1) && (undiscovered[othernode] == 1)
            push!(neighbors, othernode)
        end
    end
    return neighbors
end

function find_best_node(n, a, undiscovered, nodes)
    bestnode = -1
    bestdiscovery
    for thisnode in 1:n
        discovery = size(neighbors_discovery(n, a, undiscovered,  node))
        if discovery > bestdiscovery
            bestnode = thisnode
        end
    end
    return bestnode
end

# return the path to go from source to each point in the graph
function Dijkstra_paths(Graph, source)
    Dijkstra = dijkstra_shortest_paths(Graph, source, allpaths=true)
    Paths = []
    for destination in 1:length(Dijkstra.dists)
        # print("Path from ")
        # println(destination)
        thispath = []
        distance = Dijkstra.dists[destination]
        # print("distance is ")
        # println(distance)
        while (distance != 0)
            unshift!(thispath, destination)
            # println(destination)
            destination = Dijkstra.parents[destination]
            distance = Dijkstra.dists[destination]
        end
        unshift!(thispath, destination)
        # println(thispath)
        push!(Paths, thispath)
    end
    # println(Paths)
    return Paths
end

G = Glouton("test01.txt")
# G = Graph(6)
# println(G)
# println(adjacency_matrix(G))
# gplot(G)

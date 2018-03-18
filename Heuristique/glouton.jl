

using JuMP
using LightGraphs
using GraphPlot

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

function get_isthmes(G,verbose)
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
    if verbose
        println(ISM)
    end
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

function get_artics(G,verbose)
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
    if verbose
        println(artics)
    end
    return artics
end

# read from the file the adjacence matrix && size
function read_txt(Path)
        A = readdlm(Path, ' ')

        B = A[1:size(A,1),:]

        n = size(B,2)
        a = round.(Int,B[1:n,1:n])

        return(n,a)
end

function create_graph(matrix)
    G = Graph(matrix)
    return G
end

# G is a graph object
# n is the number of nodes
# node is the list of nodes
function Glouton(Path, verbose = false)
    #read data
    n,a = read_txt(Path)
    if verbose
        println(n)
        println(a)
    end
    # create graph G and lists we will use for discovery
    G = create_graph(a)
    # no node is selected yet.
    nodes = zeros(Int,n)
    # all nodes are not discovered yet.
    undiscovered = nodes + 1
    if verbose
        println("initialisation with isthmes and branchement")
    end
    # preprocessing  des noeuds de branchement et des isthmes
    branchements = get_artics(G, verbose)
    isthmes = get_isthmes(G, verbose)
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
    if verbose
        println("search for good points")
    # continue l'heuristique avec les autres.
    # tant que des nodes sont pas découvertes, je continue à rajouter des nodes.
        print(undiscovered)
    end
    while (sum(undiscovered) > 0)
        # print("Encore:")
        # print(sum(undiscovered))
        # println("points a decouvrir")
        bestnode = find_best_node(n, a, undiscovered, nodes)
        if verbose
            println(bestnode)
        end
        if bestnode != -1
            discovery = neighbors_discovery(n, a, undiscovered,  bestnode)
            if verbose
                print(discovery)
            end
            nodes[bestnode] = 1
            for target in discovery
                undiscovered[target] = 0
            end
        end
    end
    if verbose
        println(undiscovered)
        println(nodes)
    end
    # j'ai la liste des noeuds selectionnes pas l'algo ( dans laquelle il y a les noeuds de branchement).
    # Il se trouve que ces noeud sont ordonnés par nombre de feueilles decouvertes.
    # on va creer un squelette à partir de plus cours chemins a partir du premier element de cette liste, vers les autres.
    # puis on va rajouter les feuilles en parcourant
    if verbose
        println("building the skeleton of the tree")
    end
    covered = zeros(Int, n)
    newG_tree = Graph(n)
    root = get_root(nodes, n, G)
    if verbose
        print(root)
    end
    covered[root] = 1
    paths = Dijkstra_paths(G, root)
    if verbose
        println(paths)
    end
    for selected in 1:n
        if(nodes[selected] == 1 && selected != root)
            covered[selected] = 1
            thispath = paths[selected]
            if verbose
                println(thispath)
            end
            for j in 2:length(thispath)
                add_edge!(newG_tree, thispath[j-1], thispath[j])
                covered[thispath[j-1]] = 1
                covered[thispath[j]] = 1
            end
        end
    end

    if verbose
        println("building the rest of the tree")
    end
    #maintenant on va ajouter a cet arbre, le nodes qui n'ont pas été sélectionées.
    for selected in 1:n
        if verbose
            println(neighbors(newG_tree, selected))
        end
        degree = length(neighbors(newG_tree, selected))
        # degree = degree(newG, selected)
        if verbose
            println(degree )
        end
        # if nodes[selected] == 1 && (degree >= 3 || degree == 1)
        if nodes[selected] == 1
            # theseneighbors = G.vertices[selected].neighbors
            theseneighbors = neighbors(G, selected)
            if verbose
                println(theseneighbors)
            end
            for thisneighbor in theseneighbors
                if covered[thisneighbor] == 0
                    add_edge!(newG_tree, selected, thisneighbor)
                    covered[thisneighbor] = 1
                end
            end
        end
    end
    if verbose
        println(adjacency_matrix(newG_tree))
    end
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
    bestdiscovery = -1
    for thisnode in 1:n
        discovery = length(neighbors_discovery(n, a, undiscovered,  thisnode))
        if discovery > bestdiscovery
            bestdiscovery = discovery
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

G = Glouton("testdata.txt")
# G = Graph(6)
# println(G)
# println(adjacency_matrix(G))
# gplot(G)

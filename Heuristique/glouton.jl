using JuMP

# read from the file the adjacence matrix && size
function read_txt(Path)
        A = readdlm(Path, ' ')

        B = A[1:size(A,1)-1,:]

        n = size(B,1)
        a = round.(Int,B)
        println(a)

        return(n,a)
end

function Heuristique(Path)
    n,a = read_txt(Path)
    # no node is selected yet.
    nodes = round.(Int, zeros(n))
    # all nodes are not discovered yet.
    undiscovered = nodes + 1
    # preprocessing  des noeuds de branchement et des isthmes
    branchements = branchement_search(nodes, n, a)
    isthmes = isthmes_search(nodes, n, a)
    # gerer les affectations des nodes
    for node in branchements
        nodes[node] = 1
    end
    for node in isthmes
        nodes[node] = 1
    end
    # gere les decouvertes de voisins
    for node in branchements
        undiscovered[node] = 0
        discovery = neighbors_discovery(n, a, undiscovered,  node)
        for target in discovery
            undiscovered[target] = 0
        end
    end
    for node in isthmes
        undiscovered[node] = 0
        discovery = neighbors_discovery(n, a, undiscovered,  node)
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
end


function branchement_search(nodes, n, a)

end


function isthmes_search(nodes, n, a)

end


function neighbors_discovery(n, a, undiscovered,  node)
    neighbors = []
    for othernode in 1:n
        if (othernode != nodes) && (a[othernode, node] == 1) && (undiscovered[othernode] == 1)
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

function

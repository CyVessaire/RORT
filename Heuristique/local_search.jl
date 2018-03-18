using LightGraphs
using GraphPlot

# fonction sortant une liste contenant les sommets "noeuds"
# i.e ayant plus de 3 voisins dans l'arbre. La liste est de la forme:
# L= [[noeud, nombres_voisins_arbres]]

function detect_nodes(adj_ini, adj_tree)
    n = size(adj_ini, 1)
    L = []
    for i in 1:n
        count = 0
        for j in 1:n
            if adj_tree[i,j] == 1
                count += 1
            end
        end
        if count > 2
            L = vcat(L,transpose([i, count]))
        end
    end
    return L
end

function detect_leaf(adj_tree)
    n = size(adj_tree, 1)
    L = []
    for i in 1:n
        count = 0
        for j in 1:n
            if adj_tree[i,j] == 1
                count += 1
            end
        end
        if count == 1
            append!(L,i)
        end
    end
    return L
end

# fonction testant la possibilité de supprimer l'arête (node_1, node_2), où
# node_1 est le noeud de l'arbre dont on cherche à supprimer une arête sortante
# leaf étant une liste de feuille, list_node étant la liste de noeud de l'arbre

function test_delete_edge(adj_ini, adj_tree, node_1, node_2, leaf, list_node, apply)
    test = [false, false, false, false]

    if apply
        L = []
    end

    # teste si node_2 devient une feuille
    if test_leaf(adj_ini, adj_tree, node_1, node_2)
        for j in leaf
            # teste si il existe une arête entre une feuille de l'arbre ini
            # et node_2

            if adj_ini[node_2,j] == 1
                adj_bis = copy(adj_tree)
                adj_bis[node_1, node_2] = adj_bis[node_2, node_1] = 0
                adj_bis[j, node_2] = adj_bis[node_2, j] = 1

                G = Graph(adj_bis)
                Dists = dijkstra_shortest_paths(G, node_1, allpaths=true).dists
                n = size(adj_ini, 1)
                if Dists[node_2] <= n
                    test[1] = true
                    if apply
                        L = vcat(L,transpose([node_2,j]))
                    end
                end
            end
        end
        if apply && test[1]
            return test, L
        end

        for j in list_node[:,1]
            # teste si il existe une arête entre un noeud de l'arbre ini
            # et node_2
            if j == node_1
                continue
            end

            if adj_ini[node_2,j] == 1

                adj_bis = copy(adj_tree)
                adj_bis[node_1, node_2] = adj_bis[node_2, node_1] = 0
                adj_bis[j, node_2] = adj_bis[node_2, j] = 1

                G = Graph(adj_bis)
                Dists = dijkstra_shortest_paths(G, node_1, allpaths=true).dists
                n = size(adj_ini, 1)

                if Dists[node_2] <= n
                    test[2] = true
                    if apply
                        L = vcat(L,transpose([node_2,j]))
                    end
                end
            end
        end
        if apply && test[2]
            return test, L
        end

    # teste si node_2 est un noeud
    elseif test_node(adj_ini, adj_tree, list_node, node_2)
        # node_2 est un noeud de l'arbre
        # on regarde si on peut relier node_2 avec une feuille de la composante connexe induite
        # ou si on peut relier des noeuds de 2 composantes connexes distinctes
        adj_bis = copy(adj_tree)
        adj_bis[node_1, node_2] = adj_bis[node_2, node_1] = 0

        G = Graph(adj_bis)
        Dists = dijkstra_shortest_paths(G, node_1, allpaths=true).dists

        n = size(adj_ini, 1)

        list_leaf_comp_node_1 = []
        for i in leaf
            if Dists[i] <= n
                append!(list_leaf_comp_node_1,i)
            end
        end

        Dists = dijkstra_shortest_paths(G, node_2, allpaths=true).dists

        list_leaf_comp_node_2 = []
        for i in leaf
            if Dists[i] <= n
                append!(list_leaf_comp_node_2,i)
            end
        end

        for j in list_leaf_comp_node_1
            if adj_ini[node_2, j] == 1
                test[3] = true
                if apply
                    L = vcat(L,transpose([node_2,j]))
                end
            end
        end
        if apply && test[3]
            return test, L
        end

        list_node_comp_node_1 = []
        list_node_comp_node_2 = []

        for i in list_node[:,1]
            if Dists[i] <= n
                append!(list_node_comp_node_1,i)
            else
                append!(list_node_comp_node_2,i)
            end
        end

        for j in list_leaf_comp_node_1
            for i in list_leaf_comp_node_2
                if adj_ini[i, j] == 1
                    test[4] = true
                    if apply
                        L = vcat(L,transpose([i,j]))
                    end
                end
            end
        end

        if apply && test[4]
            return test, L
        end
    end

    if apply
        return test, L
    end

    return test
end

# fonction testant que le sommet node_2 devient une "feuille", i.e. un sommet de degré 1
# en supprimant l'arête node_1 node_2 dans la forêt d'arbre résultante

function test_leaf(adj_ini, adj_tree, node_1, node_2)
    n = size(adj_ini, 1)
    count = 0
    for j in 1:n
        if j == node_1
            continue
        else
            if adj_tree[node_2, j] == 1
                count += 1
            end
        end
    end
    if count > 1
        return false
    else
        return true
    end
end

function test_node(adj_ini, adj_tree, list_node, node_2)
    n = size(adj_ini, 1)
    test_node = false
    for i in list_node[:,1]
        if node_2 == i
            test_node = true
            break
        end
    end
    return test_node
end

function apply_modif(node_1, node_2, adj_tree, test, liste, list_node, leaf, verbose)
    remove = false
    k = 0
    a = 0
    b = 0
    if test[1]
        L = liste[rand(1:end),:]
        if verbose
            println("deleted arc ($node_1 , $node_2), and created arc ($L)")
        end
        adj_tree[node_1, node_2] = adj_tree[node_2, node_1] = 0
        adj_tree[L[1],L[2]] = adj_tree[L[2],L[1]] = 1
        a = L[1]
        b = L[2]
        filter!(x->x≠L[1], leaf)
        filter!(x->x≠L[2], leaf)
        for i in 1:size(list_node,1)
            if list_node[i,1] == node_1
                list_node[i,2] -= 1
                if list_node[i,2] < 3
                    k = i
                    remove = true
                end
            end
        end
        if remove
            if verbose
                println("delete row $k")
                println("Liste node = $list_node")
            end
            list_node = list_node[setdiff(1:end, k), :]
            if verbose
                println("Thus, Liste node = $list_node")
            end
        end

    elseif test[2]
        L = liste[rand(1:end),:]
        if verbose
            println("deleted arc ($node_1 , $node_2), and created arc ($L)")
        end
        adj_tree[node_1, node_2] = adj_tree[node_2, node_1] = 0
        adj_tree[L[1],L[2]] = adj_tree[L[2],L[1]] = 1
        a = L[1]
        b = L[2]
        filter!(x->x≠L[1], leaf)
        for i in 1:size(list_node,1)
            if list_node[i,1] == node_1
                list_node[i,2] -= 1
                if list_node[i,2] < 3
                    k = i
                    remove = true
                end
            elseif list_node[i,1] == L[2]
                list_node[i,2] += 1
            end
        end
        if remove
            if verbose
                println("delete row $k")
                println("Liste node = $list_node")
            end
            list_node = list_node[setdiff(1:end, k), :]
            if verbose
                println("Thus, Liste node = $list_node")
            end
        end

    elseif test[3]
        L = liste[rand(1:end),:]
        if verbose
            println("deleted arc ($node_1 , $node_2), and created arc ($L)")
        end
        adj_tree[node_1, node_2] = adj_tree[node_2, node_1] = 0
        adj_tree[L[1],L[2]] = adj_tree[L[2],L[1]] = 1
        a = L[1]
        b = L[2]
        for i in 1:size(list_node,1)
            if list_node[i,1] == node_1
                list_node[i,2] -= 1
                if list_node[i,2] < 3
                    k = i
                    remove = true
                end
            elseif list_node[i,1] == L[1]
                list_node[i,2] += 1
            end
        end
        if remove
            if verbose
                println("delete row $k")
                println("Liste node = $list_node")
            end
            list_node = list_node[setdiff(1:end, k), :]
            if verbose
                println("Thus, Liste node = $list_node")
            end
        end
        filter!(x->x≠L[2], leaf)

    elseif test[4]
        L = liste[rand(1:end),:]
        if verbose
            println("deleted arc ($node_1 , $node_2), and created arc ($L)")
        end
        adj_tree[node_1, node_2] = adj_tree[node_2, node_1] = 0
        adj_tree[L[1],L[2]] = adj_tree[L[2],L[1]] = 1
        a = L[1]
        b = L[2]
        for i in 1:size(list_node,1)
            if list_node[i,1] == node_1
                list_node[i,2] -= 1
                if list_node[i,2] < 3
                    k = i
                    remove = true
                end
            elseif list_node[i,1] == L[1]
                list_node[i,2] += 1
            elseif list_node[i,1] == L[2]
                list_node[i,2] += 1
            end
        end
        if remove
            if verbose
                println("delete row $k")
                println("Liste node = $list_node")
            end
            list_node = list_node[setdiff(1:end, k), :]
            if verbose
                println("Thus, Liste node = $list_node")
            end
        end
    end
    return a,b
end


function local_search(adj_ini, adj_tree, apply, verbose)
    loop = true
    tabou = zeros(5, 2)

    n = size(adj_ini, 1)
    iter_max = 10*n
    k = 0
    if verbose
        println("Tree:")
        println(adj_tree)
    end

    G = Graph(adj_tree)
    Dists = dijkstra_shortest_paths(G, 1, allpaths=true).dists

    for i in 1:n
        if Dists[i] > n
            println("NOT A TREE")
            return
        end
    end


    while(loop)
        if k == iter_max
            println("Iter max attained, current solution : ")
            println("Tree:")
            println(adj_tree)
            v = size(nodes, 1)
            println("Value = $v")
            break
        end
        k += 1
        loop = false
        nodes = detect_nodes(adj_ini, adj_tree) #get the list of node

        if size(nodes, 1) == 0
            v = size(nodes, 1)
            println("Value = $v")
            println("Tree:")
            println(adj_tree)
            println("Value = $v")
            break
        end

        nodes = sortrows(nodes, by=x->x[2])

        leaf = detect_leaf(adj_tree)
        if verbose
            println("Liste node = $nodes")
            println("Liste leaf = $leaf")
        end

        for i in nodes[:,1] #take the first coordinate of the nodes list (the second is the count number)
            for j in 1:n
                if (j == i || adj_tree[i,j] == 0)
                    continue
                end
                cont = false
                for k in 1:size(tabou,1)
                    if ((tabou[k,1] == i && tabou[k,2] == j) || (tabou[k,1] == j && tabou[k,2] == i))
                        cont = true
                        break
                    end
                end
                if cont
                    continue
                end

                test = test_delete_edge(adj_ini, adj_tree, i, j, leaf, nodes, apply)
                app = false
                for k in 1:size(test[1],1)
                    if test[1][k]
                        app = apply
                    end
                end
                if app
                    if verbose
                        println("Vector test : ", test[1])
                        println("Possibilities : ", test[2])
                        println("i = ", i ," and j = ", j)
                    end
                end
                if app
                    a,b = apply_modif(i, j, adj_tree, test[1], test[2], nodes, leaf, verbose)
                    loop = true

                    tabou = tabou[setdiff(1:end, 1), :]
                    tabou = vcat(tabou, [a b])

                    if verbose
                        println(tabou)
                    end

                    G = Graph(adj_tree)
                    Dists = dijkstra_shortest_paths(G, 1, allpaths=true).dists

                    for i in 1:n
                        if Dists[i] > n
                            println("NOT A TREE")
                            println(i)
                            println("Tree:")
                            println(adj_tree)
                            return adj_tree
                        end
                    end

                    break
                end
            end
            if loop
                if verbose
                    println("Tree:")
                    println(adj_tree)
                end
                break
            end
        end
        if !loop
            if verbose
                println("Last Tree:")
                println(adj_tree)
                println("No more amelioration possible")
            end
            v = size(nodes, 1)
            println("Value = $v")
            return adj_tree
        end
    end
    v = size(nodes, 1)
    println("Value = $v")
    return adj_tree
end
#
# #create a test : K7 adj matrix
# a = ones(Int,7,7) - eye(Int,7)
#
# b = zeros(7,7)
# b[1,2] = b[2,1] = 1
# b[1,3] = b[3,1] = 1
# b[1,4] = b[4,1] = 1
# b[2,5] = b[5,2] = 1
# b[2,6] = b[6,2] = 1
# b[2,7] = b[7,2] = 1
# b = round.(Int,b)
#
# println(a)
# println(b)
#
# #verify the correct sort by
#
# # d = [1 5; 2 3; 8 6]
# # println(sort!(d[:,2]))
# # println(d)
# # d = sortrows(d, by=x->x[2])
# # println(d)
# # println(size(d,1))
#
# local_search(a, b, true, true)

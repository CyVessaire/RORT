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
            L.append([i,count])
        end
    end
    return L
end

# fonction testant la possibilité de supprimer l'arête (node_1, node_2), où
# node_1 est le noeud de l'arbre dont on cherche à supprimer une arête sortante
# leaf étant une liste de feuille, list_node état la liste de noeud de l'arbre

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
                test[1] = true
                if apply
                    L.append([node_2,j])
                end
            end
        end
        if apply && test[1]
            return test, L
        end

        for j in list_node
            # teste si il existe une arête entre un noeud de l'arbre ini
            # et node_2
            if adj_ini[node_2,j] == 1
                test[2] = true
                if apply
                    L.append([node_2,j])
                end
            end
        end
        if apply && test[2]
            return test, L
        end
    # teste si node_2 est un noeud
    elseif test_node(adj_ini, adj_tree, node_1, node_2)
        # node_2 est un noeud de l'arbre
        # on regarde si on peut relier node_2 avec une feuille de la composante connexe induite
        # ou si on peut relier des noeuds de 2 composantes connexes distinctes

        G = graph(adj_tree)
        Dists = dijkstra_shortest_paths(G, node_1, allpaths=true).dists

        list_leaf_comp_node_1 = []
        for i in leaf
            if Dists[i] <= n
                list_leaf_comp_node_1.append(i)
            end
        end

        for j in list_leaf_comp_node_1
            if adj_ini[node_2, j] == 1
                test[3] = true
                if apply
                    L.append([node_2,j])
                end
            end
        end
        if apply && test[3]
            return test, L
        end

        list_node_comp_node_1 = []
        list_node_comp_node_2 = []

        for i in list_node
            if Dists[i] <= n
                list_node_comp_node_1.append(i)
            else
                list_node_comp_node_2.append(i)
            end
        end

        for j in list_leaf_comp_node_1
            for i in list_leaf_comp_node_2
                if adj_ini[i, j] == 1
                    test[4] = true
                    if apply
                        L.append([i,j])
                    end
                end
            end
        end

        if apply && test[4]
            return test, L
        end
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

function test_node(adj_ini, adj_tree, node_1, node_2)
    n = size(adj_ini, 1)
    test_node = false
    for i in list_node
        if node_2 == i
            test_node = true
            break
        end
    end
    return test_node
end

function apply_modif(node_1, node_2, adj_tree, test, liste, list_node, leaf)
    if test[1]
        L = liste[rand(1:end)]
        adj_tree[node_1, node_2] = 0
        adj_tree[L[1],L[2]] = 1
        filter!(x->x≠L[1], leaf)
        filter!(x->x≠L[2], leaf)
        for i in list_node
            if i[1] == node_1
                i[2] -= 1
                if i[2] < 3
                    filter!(x->x≠i, list_node)
                end
            end
        end

    elseif test[2]
        L = liste[rand(1:end)]
        adj_tree[node_1, node_2] = 0
        adj_tree[L[1],L[2]] = 1
        filter!(x->x≠L[1], leaf)
        for i in list_node
            if i[1] == node_1
                i[2] -= 1
                if i[2] < 3
                    filter!(x->x≠i, list_node)
                end
            elseif i[1] == L[2]
                i[2] += 1
            end
        end

    elseif test[3]
        L = liste[rand(1:end)]
        adj_tree[node_1, node_2] = 0
        adj_tree[L[1],L[2]] = 1
        for i in list_node
            if i[1] == node_1
                i[2] -= 1
                if i[2] < 3
                    filter!(x->x≠i, list_node)
                end
            elseif i[1] == L[1]
                i[2] += 1
            end
        end
        filter!(x->x≠L[2], leaf)

    elseif test[4]
        L = liste[rand(1:end)]
        adj_tree[node_1, node_2] = 0
        adj_tree[L[1],L[2]] = 1
        for i in list_node
            if i[1] == node_1
                i[2] -= 1
                if i[2] < 3
                    filter!(x->x≠i, list_node)
                end
            elseif i[1] == L[1]
                i[2] += 1
            elseif i[1] == L[2]
                i[2] += 1
            end
        end
    end
end

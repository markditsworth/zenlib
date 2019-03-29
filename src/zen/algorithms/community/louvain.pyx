from zen.graph cimport Graph

cimport zen.algorithms.community.communityset as cs
import zen.algorithms.community.community_common as common

import numpy as np
cimport numpy as np
from cpython cimport bool

cdef sum_in_out(Graph G, int n, np.ndarray counts, np.ndarray comms, bool weighted):
    cdef:
        float sum_in = 0.0, sum_out = 0.0, amt = 0.0
        int j,eidx,m

    for j in range(G.node_info[n].degree):
        eidx = G.node_info[n].elist[j]
        if n == G.edge_info[eidx].u:
            m = G.edge_info[eidx].v
        else:
            m = G.edge_info[eidx].u

        if weighted:
            amt = G.edge_info[eidx].weight
        else:
            amt = 1.0

        if comms[n] == comms[m]:
            sum_in += amt
        else:
            sum_out += amt

    return (sum_in, sum_out)

cdef void initialize_counts(Graph G, np.ndarray counts, np.ndarray comms, bool weighted):
    cdef int n
    for n in range(G.next_node_idx):
        if not G.node_info[n].exists:
            continue

        in_out = sum_in_out(G, n, counts, comms, weighted)
        counts[n,0] += (in_out[0] / 2.0)
        counts[n,1] += (counts[n,0] + in_out[1])

cdef void comm_add_node(Graph G, int comm, int n, np.ndarray counts, np.ndarray comms,
                    bool weighted):
    comms[n] = comm

    in_out = sum_in_out(G, n, counts, comms, weighted)
    
    counts[comm,0] += (in_out[0] / 2.0)
    counts[comm,1] += (counts[comm,0] + in_out[1])

cdef void comm_remove_node(Graph G, int n, np.ndarray counts, np.ndarray comms, 
                            bool weighted):

    cdef int comm = comms[n]    
    in_out = sum_in_out(G, n, counts, comms, weighted)
    
    counts[comm,0] -= (in_out[0] / 2.0)
    counts[comm,1] -= (counts[comm,0] + in_out[1])

    comms[n] = -1

cdef float mod_gain(Graph G, int node, int new_comm, float sum_edges, bool weighted, 
            k, np.ndarray counts, np.ndarray comms):
    # Compute the modularity gain obtained by adding ``node`` to ``new_comm``.
    # For this, we used some cached values: the number of edges in the graph,
    # and the number / sum of weights incident to ``node`` (``k``).
    # The formula is straight from the paper

    cdef:
        float denom, a, b, c, d, e

    denom = 2.0 * sum_edges
    a = (counts[new_comm,0] + 2.0 * sum_incident(G, node, weighted, comms, new_comm)) / denom
    b = (counts[new_comm,1] + k) / denom
    c = counts[new_comm,0] / denom
    d = counts[new_comm,1] / denom
    e = k / denom

    return ((a - (b * b)) - (c - (d * d) - (e * e)))

cdef float sum_incident(Graph G, int node, bool weighted, np.ndarray comms, 
                        int in_community=-1):
    # Sum of the edges (or edge weights) incident to a node. If in_community is
    # not -1, only account for neighbors which are part of that community.

    cdef:
        float total = 0.0
        float amt

        int j,eidx,m

    for j in range(G.node_info[node].degree):
        eidx = G.node_info[node].elist[j]
        if node == G.edge_info[eidx].u:
            m = G.edge_info[eidx].v
        else:
            m = G.edge_info[eidx].u

        if in_community != -1 and comms[m] != in_community:
            continue        

        amt = 1.0
        if weighted:
            amt = G.edge_info[eidx].weight 
        total += amt

    return total

cdef bool optimize_modularity(Graph G, float sum_edges, np.ndarray counts, 
                                np.ndarray comms, bool weighted):
    # Optimize the modularity of the communities over the graph by moving nodes
    # to the neighbor's community which provides the greatest increase. This
    # goes on until no more moves are possible.

    cdef:
        bool moved = True # Has a node moved over this iteration
        bool improvement = False # Did we improve modularity over this iteration 

        float max_delta_mod, delta_mod

        float k # Sum of incident edges to a node

        # Node iterators
        int n, eidx, j, m

        int best_community, old_community, comm_m

    while moved:
        moved = False
        for n in range(G.next_node_idx):
            if not G.node_info[n].exists:
                continue

            best_community = comms[n] # Best by default: no change
            old_community = comms[n]
            max_delta_mod = 0.0 # Minimal delta accepted: no change

            k = sum_incident(G, n, weighted, comms)

            comm_remove_node(G, n, counts, comms, weighted)
            for j in range(G.node_info[n].degree): #G.neighbors_(n):
                eidx = G.node_info[n].elist[j]
                if n == G.edge_info[eidx].u:
                    m = G.edge_info[eidx].v
                else:
                    m = G.edge_info[eidx].u

                if m == n: #Ignore self-loops
                    continue

                comm_m = comms[m]
                delta_mod = mod_gain(G, n, comm_m, sum_edges, weighted, k, 
                                    counts, comms)

                if delta_mod > max_delta_mod:
                    max_delta_mod = delta_mod
                    best_community = comms[m]
                    

            if best_community != old_community:
                moved = True
                improvement = True

            comm_add_node(G, best_community, n, counts, comms, weighted)

    return improvement

cdef Graph create_metagraph(Graph old_graph, np.ndarray comms, bool weighted):
    # In the metagraph, nodes are communities from the old graph. Edges connect
    # communities whose nodes are connected in the old graph ; internal edges
    # in the old graph correspond to self-loops in the metagraph. Edges are
    # weighted by the sum of the edge weights they represent in the old graph.

    # TODO: This can be further optimized

    community_dict = {}

    cdef: 
        int n
        int neigh
        int cidx
        int neigh_cidx
        float amt
        int j,eidx
        Graph G = Graph()

    for n in range(old_graph.next_node_idx): 
        if not old_graph.node_info[n].exists:
            continue

        cidx = comms[n]
        if cidx not in community_dict:
            community_dict[cidx] = [n]
        else:
            community_dict[cidx].append(n)

    for cidx, comm in community_dict.iteritems():

        if cidx not in G:
            G.add_node(cidx)
        for n in comm:
            for j in range(old_graph.node_info[n].degree): #old_graph.neighbors_(n):
                eidx = old_graph.node_info[n].elist[j]
                if n == old_graph.edge_info[eidx].u:
                    neigh = old_graph.edge_info[eidx].v
                else:
                    neigh = old_graph.edge_info[eidx].u

                amt = 1.0
                if weighted:
                    amt = old_graph.edge_info[old_graph.edge_idx_(n, neigh)].weight
                neigh_cidx = comms[neigh]

                if neigh_cidx not in G:
                    G.add_node(neigh_cidx)

                if not G.has_edge(cidx, neigh_cidx):
                    G.add_edge(cidx, neigh_cidx, None, amt)
                else:
                    G.set_weight(cidx, neigh_cidx, G.weight(cidx, neigh_cidx) + amt)

    # Only self-loops count double
    for edge in range(G.next_edge_idx): #G.edges_(-1, False, True):
        if not G.edge_info[edge].exists:
            continue

        if G.edge_info[edge].u != G.edge_info[edge].v:
            G.edge_info[edge].weight = G.edge_info[edge].weight / 2.0
        #if G.endpoints_(edge[0])[0] != G.endpoints_(edge[0])[1]:
            #G.set_weight_(edge[0], edge[1] / 2.0)

    return G

def louvain(G, **kwargs):
    """
    Detect communities in a network using the Louvain algorithm described in
    [BLO2008]_. It assigns every node to its own community, and then tries to
    improve the modularity of the network by moving each node to the communities
    of its neighbors. Once no more increase is possible, a meta-network is built
    from these communities (the nodes being the communities themselves and the
    edges being the sum of the edges between members of these communities) and
    the process is repeated. This continues until no improvement in modularity
    is possible.

    **Keyword Args**

        * ``use_weights [=False]`` (bool): whether to take the weights of the
        network into account.

        * ``num_iterations [=None]`` (int): if not ``None``, the algorithm will
        stop after this many iterations of building meta-networks. This can be
        used to examine a community structure at different levels of resolution
        (i.e. a low number will return fine-grained communities, while a large
        number will return more general communities).

    **Returns**

        A :py:module:CommunitySet containing the communities detected in the 
        graph.

    ..[BLO2008]
        Blondel, V. et al 2008. Fast unfolding of communities in large networks.
            Journal of Statistical Mechanics, Vol. 2008, Issue 10.

    """
    use_weights = kwargs.pop("use_weights", False)
    num_iterations = kwargs.pop("num_iterations", -1)

    # handle extra arguments
    if len(kwargs) > 0:
        raise ValueError, 'Arguments not supported: %s' % ','.join(kwargs.keys())

    if type(G) == Graph:
        return louvain_undirected(<Graph>G,use_weights,num_iterations)
    else:
        raise ValueError, 'Graph type %s not supported' % type(G).__name__

cdef louvain_undirected(Graph G,bool weighted,int num_iterations):

    cdef:
        int count_iter = 1, i, length, num_communities

        # Used for indirection in the 
        int n, comm, meta_idx

        float sum_edges # Sum of edge / edge weights in the graph
        
        # Community assignments and incidence counts
        np.ndarray [np.int_t] comms, meta_comms
        np.ndarray [np.float_t, ndim=2] counts, meta_counts

        Graph meta

    sum_edges = 0.0
    if weighted:
        for i in G.next_edge_idx:
            if not G.edge_info[i].exists:
                continue

            sum_edges += G.edge_info[i].weight
    else:
        sum_edges = len(G.edges())

    length = G.max_node_idx + 1
    comms = np.empty(length, dtype=np.int_)
    for i in range(length):
        comms[i] = i

    counts = np.zeros((length, 2), dtype=np.float_)
    initialize_counts(G, counts, comms, weighted)

    improved = optimize_modularity(G, sum_edges, counts, comms, weighted)
    
    # Initial "meta" values
    meta_comms = comms
    meta = G
    while improved and (num_iterations == -1 or count_iter < num_iterations):       
        meta = create_metagraph(meta, meta_comms, weighted)
        weighted = True # The weight in metagraphs is always significant
        length = meta.max_node_idx + 1
        meta_comms = np.empty(length, dtype=np.int_)
        for i in range(length):
            meta_comms[i] = i

        meta_counts = np.zeros((length, 2), dtype=np.float_)
        initialize_counts(meta, meta_counts, meta_comms, weighted)

        sum_edges = 0.0
        for i in range(meta.next_edge_idx):
            if not meta.edge_info[i].exists:
                continue
            sum_edges += meta.edge_info[i].weight

        improved = optimize_modularity(meta, sum_edges, meta_counts,
                                        meta_comms, weighted)

        for n in range(G.next_node_idx): 
            if not G.node_info[n].exists:
                continue

            comm = comms[n]
            meta_idx = meta.node_idx(comm)
            comms[n] = meta_comms[meta_idx]

        count_iter += 1

    num_communities = common.normalize_communities(G,comms)

    return cs.CommunitySet(G, comms, num_communities)


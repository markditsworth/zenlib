import numpy as np
cimport numpy as np

cdef struct NodeInfo:
    bint exists
    
    int degree
    int* elist
    int capacity
    
cdef struct EdgeInfo:
    bint exists
    int u
    int v
    double weight
    
cdef class Graph:
    
    # attributes
    cdef readonly double node_grow_factor
    cdef readonly double edge_list_grow_factor
    cdef readonly double edge_grow_factor
    
    cdef long num_changes
    cdef readonly int num_nodes
    cdef readonly int node_capacity
    cdef int next_node_idx
    cdef readonly int max_node_idx
    cdef NodeInfo* node_info
    cdef node_idx_lookup
    cdef node_obj_lookup
    cdef node_data_lookup
    cdef int first_free_node
    
    cdef readonly int num_edges
    cdef readonly int edge_capacity
    cdef int next_edge_idx
    cdef readonly max_edge_idx
    cdef EdgeInfo* edge_info
    cdef edge_data_lookup
    cdef int first_free_edge
    
    cdef readonly int edge_list_capacity
    
    cdef readonly bint num_graph_listeners
    cdef readonly graph_listeners
    
    # methods
    cdef inner_validate(self,bint validate)
    
    cpdef copy(Graph self)
    
    cdef __copy_graph_self_into(Graph self, Graph G)
    
    cpdef np.ndarray[np.float_t] matrix(self)
    
    cpdef bint is_directed(Graph self)

    cpdef components(Graph self)
    
    cpdef bint is_compact(Graph self)
    
    cpdef compact(Graph self)
        
    cpdef np.ndarray[np.int_t] add_nodes(Graph self,int num_nodes,node_obj_fxn=*)
    
    cpdef int add_node(Graph self,nobj=*,data=*) except -1
    
    cdef add_to_free_node_list(self,int nidx)
    
    cdef remove_from_free_node_list(self,int nidx)
    
    cpdef add_node_x(Graph self,int node_idx,int edge_list_capacity,nobj,data)
    
    cpdef is_valid_node_idx(Graph self, int nidx)

    cpdef int node_idx(Graph self,nobj) except -1
    
    cpdef node_object(Graph self,int nidx)
    
    cpdef set_node_object(self,curr_node_obj,new_node_obj)
    
    cpdef set_node_object_(self,node_idx,node_obj)
    
    cpdef set_node_data(Graph self,nobj,data)
    
    cpdef node_data(Graph self,nobj)
    
    cpdef set_node_data_(Graph self,int nidx,data)
    
    cpdef node_data_(Graph self,int nidx)
    
    cpdef nodes_iter(Graph self,data=*)
    
    cpdef nodes_iter_(Graph self,obj=*,data=*)
    
    cpdef nodes(Graph self,data=*)
        
    cpdef nodes_(Graph self,obj=*,data=*)
    
    cpdef rm_node(Graph self,nobj)
    
    cpdef rm_node_(Graph self,int nidx)
    
    cpdef degree(Graph self,nobj)

    cpdef degree_(Graph self,int nidx)
    
    cdef add_to_free_edge_list(self,int eidx)
    
    cdef remove_from_free_edge_list(self,int eidx)
    
    cpdef int add_edge(Graph self, u, v, data=*, double weight=*) except -1
    
    cpdef int add_edge_(Graph self, int u, int v, data=*, double weight=*) except -1
    
    cpdef add_edge_x(self, int eidx, int u, int v, data, double weight)
    
    cdef int __endpoint(Graph self, EdgeInfo ei, int this_nidx)
    
    cdef int find_elist_insert_pos(Graph self, int* elist, int elist_len, int this_nidx, int nidx)
    
    cdef __insert_edge_into_edgelist(Graph self, int u, int eidx, int v)
    
    cdef __remove_edge_from_edgelist(Graph self, int u, int eidx, int v)
    
    cpdef rm_edge(Graph self,u,v)
    
    cpdef rm_edge_(Graph self,int eidx)
    
    cpdef endpoints(Graph self,int eidx)
    
    cpdef endpoints_(Graph self,int eidx)
    
    cpdef endpoint(Graph self,int eidx,u)
    
    cpdef int endpoint_(Graph self,int eidx,int u) except -1
    
    cpdef set_weight(Graph self,u,v,double w)
    
    cpdef set_weight_(Graph self,int eidx,double w)
    
    cpdef double weight(Graph self,u,v)
    
    cpdef double weight_(Graph self,int eidx)
    
    cpdef set_edge_data(Graph self,u,v,data)
        
    cpdef edge_data(Graph self,u,v)
    
    cpdef set_edge_data_(Graph self,int eidx,data)
    
    cpdef edge_data_(Graph self,int eidx)
    
    cpdef bint has_edge(Graph self,u,v)
        
    cpdef bint has_edge_(Graph self,int u,int v)
    
    cpdef edge_idx(Graph self, u, v)
    
    cpdef edge_idx_(Graph self, int u, int v)
    
    cpdef edges_iter(Graph self,nobj=*,bint data=*,bint weight=*)
    
    cpdef edges_iter_(Graph self,int nidx=*,bint data=*,bint weight=*)
    
    cpdef edges(Graph self,nobj=*,bint data=*,bint weight=*)
        
    cpdef edges_(Graph self,int nidx=*,bint data=*,bint weight=*)

    cpdef grp_edges_iter(Graph self,nbunch,bint data=*,bint weight=*)
    
    cpdef grp_edges_iter_(Graph self,nbunch,bint data=*,bint weight=*)
    
    cpdef neighbors(Graph self,nobj,data=*)
    
    cpdef neighbors_(Graph self,int nidx,obj=*,data=*)
    
    cpdef neighbors_iter(Graph self,nobj,data=*)
    
    cpdef neighbors_iter_(Graph self,int nidx,obj=*,data=*)
    
    cpdef grp_neighbors_iter(Graph self,nbunch,data=*)
    
    cpdef grp_neighbors_iter_(Graph self,nbunch,obj=*,data=*)

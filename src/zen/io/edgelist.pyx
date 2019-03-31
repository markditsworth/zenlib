"""
The ``zen.io.edgelist`` module (available as ``zen.edgelist``) supports the reading and writing of the edgelist format. The edgelist format
allocates a single line to each edge.  The line has the format: 

``<n1> <n2> [<w>]``

where ``<n1>`` and ``<n2>`` are node identifiers at the endpoints of the edge and ``<w>`` is the optional weight parameter.  Most often the weight is completely omitted.

Both directed and undirected networks can be specified in this format: when reading a directed network, ``<n1>`` is taken to be the source and ``<n2>`` is taken to be the target of the edge.  Since the directedness of the network is not explicitly indicated in the format, it is up to the code reading the file to decide whether or not to read the data assuming that each edge has a direction.

.. autofunction:: zen.io.edgelist.read(filename[,node_obj_fxn=str,directed=False,ignore_duplicate_edges=False,merge_graph=None,weighted=False])

.. autofunction:: zen.io.edgelist.write(G,filename[,use_weights=False,use_node_indices=False])

"""

from zen.digraph cimport DiGraph
from zen.graph cimport Graph
from zen.exceptions import ZenException

from cpython cimport bool

__all__ = ['read','write']

# include reading capabilities
cdef extern from "stdio.h" nogil:
        ctypedef struct FILE
        
        FILE* fopen(char* filename, char* mode)
        int fclose(FILE* stream)
        int fscanf(FILE* stream, char* format, ...)
        char* fgets(char* s, int n, FILE* stream)
        bint feof(FILE* stream)
        bint isspace(int c)
        int ferror(FILE* stream)
        
def write(G,filename,**kwargs):
        """
        Write the graph in edgelist format to the file specified.
        
        **Args**:
        
                * ``G`` (either :py:class:`zen.Graph` or :py:class:`zen.DiGraph`): the graph to write out in edgelist format.
                * ``filename`` (str): the name of the file to write the edgelist to.
        
        **KwArgs**:
        
                * ``use_weights [=False]`` (boolean): write the weights out as a third value for each edge
                * ``use_node_indices [=False]`` (boolean): write node indices rather than the string representation
                  of the node object as the node identifier.
        """
        if type(G) != DiGraph and type(G) != Graph:
                raise ZenException, 'Only Graphs and DiGraphs are supported by edgelist.write'
        
        # parse arguments
        use_weights = bool(kwargs.pop('use_weights',False))
        use_node_indices = bool(kwargs.pop('use_node_indices',False))

        if len(kwargs) > 0:
                raise ZenException, 'Unknown keyword arguments: %s' % ', '.join(kwargs.keys())
                        
        __inner_write(G,filename,use_weights,use_node_indices)
        
cpdef __inner_write(G,filename,bool use_weights,bool use_node_indices):
                
        fh = open(filename,'w')
                
        if use_node_indices:
                if not use_weights:
                        for eid in G.edges_iter_():
                                fh.write('%d %d\n' % G.endpoints_(eid))
                else:
                        for eid,w in G.edges_iter_(weight=True):
                                epts = G.endpoints_(eid)
                                fh.write('%d %d %f\n' % (epts[0],epts[1],w))
        else:
                if not use_weights:
                        for x,y in G.edges_iter():
                                fh.write('%s %s\n' % (str(x),str(y)))
                else:
                        for x,y,w in G.edges_iter(weight=True):
                                fh.write('%s %s %f\n' % (str(x),str(y),w))
                
        fh.close()

def read(filename,**kwargs):
        """
        Read in edgelist formatted network data into a Zen graph object.
        
        **Args**:
                
                * ``filename`` (str): the name of the file the edgelist data is stored in.
                
        **KwArgs**:
        
                * ``node_obj_fxn [=str]``: the function that converts the string node identifier read from the file
                  into the node object
                * ``directed [=False]`` (boolean): whether the edges should be interpreted as directed (if so, a DiGraph object
                  will be returned)
                * ``ignore_duplicate_edges [=False]`` (boolean): ignore duplicate edges that may occur.  This incurs a performance
                  hit since every edge must be checked before being inserted.
                * ``merge_graph [=None]`` (:py:class:`zen.Graph` or :py:class:`zen.DiGraph`): merge the edges read into the 
                  existing graph object provided. In this case, the merge_graph is returned (rather than a new graph object).
                * ``weighted [=False]`` (boolean): a third column of numbers will be expected in the file and will be interpreted 
                  as edge weights.
                
        **Returns**:
                :py:class:`zen.Graph` or :py:class:`zen.DiGraph`. The graph object that the network data was loaded into.
        """
        
        # get arguments
        node_obj_fxn = kwargs.pop('node_obj_fxn',str)
        directed = kwargs.pop('directed',None)
        ignore_duplicate_edges = kwargs.pop('ignore_duplicate_edges',False)
        merge_graph = kwargs.pop('merge_graph',None)
        weighted = kwargs.pop('weighted',False)
        
        if len(kwargs) > 0:
                raise ZenException, 'Unknown keyword arguments: %s' % ', '.join(kwargs.keys())
        
        return __inner_read(bytes(filename,'utf-8'),directed,node_obj_fxn,ignore_duplicate_edges,merge_graph,weighted)
        
cpdef __inner_read(char* filename,directed,node_obj_fxn,bool ignore_duplicate_edges,G,weighted):        
        if G is not None and directed is not None:
                raise Exception, 'A graph and the directed argument cannot both be specified'
                
        if G is not None:
                directed = G.is_directed()
        else:
                if directed is True:
                        G = DiGraph()
                else:
                        G = Graph()
        
        cdef FILE* fh
        cdef int MAX_LINE_LEN = 100
        
        # make the string buffer
        str_buffer = b'0'*MAX_LINE_LEN
        
        cdef char* buffer = str_buffer

        # open the file
        fh = fopen(filename,'r') #added b here
        
        if fh == NULL:
                raise Exception, 'Unable to open file %s' % filename
        
        # read all the lines    
        cdef int start1, start2, end1, end2, start3, end3
        cdef int nidx1,nidx2
        cdef double w
        cdef int line_no = 0
        cdef int buf_len
        cdef int i
        while not feof(fh):
                line_no += 1
                
                start1 = 0; start2 = 0; end1 = 0; end2 = 0
                
                result = fgets(buffer,MAX_LINE_LEN,fh)
                
                # if the result is NULL, we've hit the end of the file
                if result is NULL:
                        # get out of the reading loop
                        break
                        
                if buffer[0] == '#': 
                        continue # ignore comments until line with number of properties

                buf_len = len(buffer)
                
                # check the success
                if not feof(fh) and buffer[buf_len-1] != '\n':
                        raise Exception, 'Line %d exceeded maximum line length (%d)' % (line_no,MAX_LINE_LEN)

                # find the first element
                for i in range(buf_len):
                        if not isspace(<int>buffer[i]):
                                break
                start1 = i
                for i in range(start1+1,buf_len):
                        if isspace(<int>buffer[i]):
                                break
                end1 = i
                
                for i in range(end1+1,buf_len):
                        if not isspace(<int>buffer[i]):
                                break
                start2 = i
                for i in range(start2+1,buf_len):
                        if isspace(<int>buffer[i]):
                                break
                end2 = i
                
                if weighted:
                        for i in range(end2+1,buf_len):
                                if not isspace(<int>buffer[i]):
                                        break
                        start3 = i
                        for i in range(start3+1,buf_len):
                                if isspace(<int>buffer[i]):
                                        break
                        end3 = i
                        
                        if end3 == buf_len-1 and not isspace(<int>buffer[end3]):
                                end3 += 1
                                
                        w = float(buffer[start3:end3])
                else:           
                        if end2 == buf_len-1 and not isspace(<int>buffer[end2]):
                                end2 += 1
                
                if start1 >= end1 or start2 >= end2 or (weighted and start3 >= end3):
                        raise Exception, 'Line %d was incorrectly formatted: %s' % (line_no,buffer)
                        
                n1 = node_obj_fxn(buffer[start1:end1])
                n2 = node_obj_fxn(buffer[start2:end2])
                
                if not ignore_duplicate_edges:
                        G.add_edge(n1,n2,weight=w) if weighted else G.add_edge(n1,n2)
                else:
                        if n1 in G:
                                nidx1 = G.node_idx(n1)
                        else:
                                nidx1 = G.add_node(n1)
                                assert(isinstance(n1,str))
                
                        if n2 in G:
                                nidx2 = G.node_idx(n2)
                        else:
                                nidx2 = G.add_node(n2)
                
                        if not G.has_edge_(nidx1,nidx2):
                                G.add_edge_(nidx1,nidx2,weight=w) if weighted else G.add_edge_(nidx1,nidx2)

        fclose(fh)
        
        return G

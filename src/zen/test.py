import unittest

# import all unit tests

# base
from zen.tests.graph import *
from zen.tests.digraph import *
from zen.tests.hypergraph import *
from zen.tests.bipartite import *

# generating functions
from zen.tests.generating_er import *
from zen.tests.generating_ba import *
from zen.tests.generating_duplication import *
from zen.tests.generating_local import *

# io
from zen.tests.edgelist import *
from zen.tests.memlist import *
from zen.tests.rdot import *
from zen.tests.scn import *
from zen.tests.bel import *
#from tests.gml import *

# analysis & properties
from zen.tests.properties import *
from zen.tests.clustering import *
from zen.tests.centrality import *
from zen.tests.components import *

# shortest paths
from zen.tests.shortest_path import *
from zen.tests.floyd_warshall import *
from zen.tests.bellman_ford import *
from zen.tests.dijkstra import *
from zen.tests.unweighted_sssp import *

# flow algorithms
from zen.tests.flow import *

# matching algorithms
from zen.tests.max_matching import *
 
# graph generation
from zen.tests.randomize import *
 
# spanning algorithms
from zen.tests.spanning import *

# control stuff
from zen.tests.profiles import *
from zen.tests.reachability import *
 
# utilities
from zen.tests.fiboheap import *
 
# modularity
from zen.tests.modularity import *

#layout
from zen.tests.layout import *

# drawing
from zen.tests.drawing import *

# built-in data
from zen.tests.data import *

# community detection
from zen.tests.community import *
from zen.tests.communityset import *
from zen.tests.lpa import *

if __name__ == '__main__':
	unittest.main()

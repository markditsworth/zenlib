import unittest
import random
import types
import networkx

import pylab
from zen import *
import zen.drawing.mpl

class DrawingTestCase(unittest.TestCase):
        
        def test_afghan(self):
                G = DiGraph()
                G.add_edge(1,2)
                G.add_edge(2,3)
                
                v = layout.fruchterman_reingold(G.skeleton())
                v.set_default_shape(['circle',(0.05,)])
                pylab.ioff()
                pylab.figure()
                mpl.draw(v)

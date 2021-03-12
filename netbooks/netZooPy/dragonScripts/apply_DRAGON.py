import numpy as np
from netZooPy.dragon import *
#import copy
#import random
#from sklearn import metrics
#import copy
#import numpy as np

XA = np.load("../../data/XA.npy")#[:,0:20]
XB = np.load("../../data/XB.npy")#[:,0:10]
pA = XA.shape[1]
pB = XB.shape[1]
n = XA.shape[0]

XA_std = np.std(XA, axis=0)      #this was newly added
XA_mean = np.mean(XA, axis=0)      #this was newly added
XA = (XA - XA_mean) / XA_std      #this was newly added

XB_std = np.std(XB, axis=0)      #this was newly added
XB_mean = np.mean(XB, axis=0)      #this was newly added
XB = (XB - XB_mean) / XB_std      #this was newly added

lams, _ = estimate_penalty_parameters_dragon(XA, XB)
print('lambdas = ',lams)

r = get_partial_correlation_dragon(XA, XB, lams)
np.save("par_cor.npy", r)

adj_p_vals, p_vals = estimate_p_values_dragon(r, n, pA, pB, lams)
np.save("../../data/adj_p_vals.npy", adj_p_vals)
np.save("../../data/p_vals.npy", p_vals)

import numpy as np
from netZooPy.dragon import *

X = np.load("../../data/X.npy")
X_std = np.std(X, axis=0)
X_mean = np.mean(X, axis=0)
X = (X - X_mean) / X_std

p = X.shape[1]
n = X.shape[0]
lam = estimate_penalty_GeneNet(X)
print('lambda = ',lam)

r = get_partial_correlation(X, lam)
adj_p_vals, p_vals = estimate_p_values(r, n=n, lambda0=lam)

np.save("../../data/par_cor.npy", r)
np.save("../../data/adj_p_vals.npy", adj_p_vals)
np.save("../../data/p_vals.npy", p_vals)

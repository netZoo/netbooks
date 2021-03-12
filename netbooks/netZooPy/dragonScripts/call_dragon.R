call.GGM <- function(X){
  npySave("../data/X.npy", X)
  p <- ncol(X)
  system('python3 dragonScripts/apply_GGM.py', wait=TRUE) 
  par.cor <- npyLoad("../data/par_cor.npy")
  adj_p_vals <- npyLoad("../data/adj_p_vals.npy")
  p_vals <- npyLoad("../data/p_vals.npy")
  #p_vals <- p_vals + t(p_vals)
  
  features <- colnames(X)
  mat1 <- matrix(features, length(features), length(features)) 
  mat2 <- t(mat1)
  indices <- upper.tri(mat1)
  
  fullmat <- data.frame(adj_p_vals = adj_p_vals[indices],
                        p_vals = p_vals[indices],
                          par_cor = par.cor[indices], 
                          feature1 = mat1[indices], 
                          feature2 = mat2[indices])
  
  fullmat <- fullmat[order(abs(fullmat[,"par_cor"]), decreasing = TRUE),]
  return(list(parcor = par.cor, p_vals = p_vals, res=fullmat))
}



call.dragon <- function(XA, XB){
  npySave("../data/XA.npy", XA)
  pA <- ncol(XA)
  npySave("../data/XB.npy", XB)
  pB <- ncol(XB)
  system('python3 dragonScripts/apply_DRAGON.py', wait=TRUE) 
  par.cor <- npyLoad("../data/par_cor.npy")
  adj_p_vals <- npyLoad("../data/adj_p_vals.npy")
  p_vals <- npyLoad("../data/p_vals.npy")
  
  #p_vals <- p_vals + t(p_vals)
  
  features <- c(colnames(XA),colnames(XB))
  mat1 <- matrix(features, length(features), length(features)) 
  mat2 <- t(mat1)
  indices <- upper.tri(mat1)
  indices1 <- upper.tri(matrix(NA, ncol(XA), ncol(XA)))
  indices2 <- upper.tri(matrix(NA, ncol(XB), ncol(XB)))
  
  fullmat11 <- data.frame(adj_p_vals = adj_p_vals[1:pA,1:pA][indices1],
                          p_vals = p_vals[1:pA,1:pA][indices1],
                          par_cor = par.cor[1:pA,1:pA][indices1], 
                          feature1 = mat1[1:pA,1:pA][indices1], 
                          feature2 = mat2[1:pA,1:pA][indices1])
  fullmat12 <- data.frame(adj_p_vals = as.vector(adj_p_vals[1:pA,(pA+1):(pA+pB)]),
                          p_vals = as.vector(p_vals[1:pA,(pA+1):(pA+pB)]),
                          par_cor = as.vector(par.cor[1:pA,(pA+1):(pA+pB)]), 
                          feature1 = as.vector(mat1[1:pA,(pA+1):(pA+pB)]), 
                          feature2 = as.vector(mat2[1:pA,(pA+1):(pA+pB)]))
  fullmat22 <- data.frame(adj_p_vals = adj_p_vals[(pA+1):(pA+pB),(pA+1):(pA+pB)][indices2], 
                          p_vals = p_vals[(pA+1):(pA+pB),(pA+1):(pA+pB)][indices2], 
                          par_cor = par.cor[(pA+1):(pA+pB),(pA+1):(pA+pB)][indices2], 
                          feature1 = mat1[(pA+1):(pA+pB),(pA+1):(pA+pB)][indices2], 
                          feature2 = mat2[(pA+1):(pA+pB),(pA+1):(pA+pB)][indices2])
  
  fullmat11 <- fullmat11[order(abs(fullmat11[,"par_cor"]), decreasing = TRUE),]
  fullmat12 <- fullmat12[order(abs(fullmat12[,"par_cor"]), decreasing = TRUE),]
  fullmat22 <- fullmat22[order(abs(fullmat22[,"par_cor"]), decreasing = TRUE),]
  return(list(parcor = par.cor, p_vals = p_vals, resAA=fullmat11, resAB=fullmat12, resBB=fullmat22))
}




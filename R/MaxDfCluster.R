MaxDfCluster = function(maxdf)
{
  n = nrow(maxdf)
  clusters = 2
  c_index = NULL
  maxdf_cluster = NULL
  for(i in c(2:n-1))
      {
        temp_cluster = cclust(maxdf, centers = i, iter.max = 50)
        temp_c_index = clustIndex(y = temp_cluster, x= maxdf, "cindex")
        c_index = c(c_index, temp_c_index)
        
  }
  return(c_index)
}

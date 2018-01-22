stim_num = 14

#Scale data
maxdf_all_pca = maxdf_all
# maxdf_all_pca = scale(maxdf_all_pca, center=FALSE, scale=apply(maxdf_all_pca, 2, sd))
maxdf_all_pca = scale(maxdf_all_pca, center=TRUE, scale=TRUE)
maxdf_all_pca = data.frame(t(maxdf_all_pca))

#H cluster 
d = dist(maxdf_all_pca,method = "euclidean") #maxdf_all_pca, rows are stim, cols are cells
d_fit = hclust(d, method= "ward.D2")
plot(d_fit)
groups = cutree(d_fit, k=5)
rect.hclust(d_fit,k=11,border="red")
maxdf_ordered_h = maxdf_all[,d_fit$order]
maxdf_ordered_h.m = data.frame(melt(as.matrix(maxdf_ordered_h)))
maxdf_ordered_h.m = cbind(maxdf_ordered_h.m,rep(groups[d_fit$order],each=stim_num))
colnames(maxdf_ordered_h.m) = c("cell", "stim", 'df', 'cluster')
maxdf_ordered_h.m$cluster=as.factor(maxdf_ordered_h.m$cluster)
ggplot(data = maxdf_ordered_h.m, aes(x = stim, y = cell, fill = df, color = cluster)) + geom_tile(size = 0.1)+
  scale_fill_gradient(low="white", high="red", limits = c(0,0.6), oob = squish)
  # +theme(axis.text.x = element_text(angle = 330, hjust = 0, color = "grey50", size = 20), 
  #       axis.text.y = element_text(size = 18), legend.text = element_text(size = 16),
  #       panel.background = element_rect(fill = "NA"), legend.key.size = unit(1.5,"cm"), legend.text = element_text(size = 12))


#k means


set.seed(12)

maxdf_cluster= kmeans(maxdf_all_pca, centers =5, nstart = 20) #maxdf_all_pca, rows are stim, cols are cells
maxdf_cluster$cluster = as.factor(maxdf_cluster$cluster)
maxdf_ordered = t(maxdf_all)[order(maxdf_cluster$cluster),]
maxdf_ordered.m = data.frame(melt(as.matrix(maxdf_ordered)))
maxdf_ordered.m = cbind(maxdf_ordered.m, rep(maxdf_cluster$cluster[order(maxdf_cluster$cluster)], stim_num))
colnames(maxdf_ordered.m) = c("cell", "stim", 'df', 'cluster')
ggplot(data = maxdf_ordered.m, aes(x = cell, y = stim, fill = df, color = cluster)) + geom_tile(size = 0)+
  scale_fill_gradient(low="white", high="red", limits = c(0,0.6), oob = squish)
  # +theme(axis.text.x = element_text(angle = 330, hjust = 0, color = "grey50", size = 20), 
  #       axis.text.y = element_text(size = 0), legend.text = element_text(size = 16),
  #       panel.background = element_rect(fill = "NA"), legend.key.size = unit(1.5,"cm"), legend.text = element_text(size = 12))

#PCA
maxdf_pca = princomp(maxdf_all_pca)
pca_scores = maxdf_pca$scores
maxdf_all_pca_scores = data.frame(pca_scores[,1:3],maxdf_cluster$cluster)
ggplot(data=maxdf_all_pca_scores, aes(x=Comp.1, y=Comp.2, color=maxdf_cluster$cluster))+geom_point()

#plot 3d
library(plot3D)
x = maxdf_all_pca_scores$Comp.1
y = maxdf_all_pca_scores$Comp.2
z = maxdf_all_pca_scores$Comp.3
scatter3D(x,y,z, bty = "g",pch=16,cex = 2, colvar = as.integer(maxdf_all_pca_scores$maxdf_cluster.cluster),
          col = c("#8b82dd","#394518","#e41fbd","#82367c","#b897f7","#33d188","#572ee8","#2194a9","#915d45","#adef3d"), 
           colkey = list(at = c(1:10), side = 1, addlines = TRUE, length = 0.5, width = 0.5), theta = -315,phi= 0
          ,xlab = "Comp.1", ylab="Comp.2", zlab="Comp.3")

colors = c("#8b82dd","#394518","#e41fbd","#82367c","#b897f7","#33d188","#572ee8","#2194a9","#915d45","#adef3d")
colors <- colors[as.numeric(maxdf_all_pca_scores$maxdf_cluster.cluster)]



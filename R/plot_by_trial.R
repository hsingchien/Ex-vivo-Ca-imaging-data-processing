source('D:/OneDrive - University of Texas Southwestern/R functions/multiplot.R')
plot_list = list()
k = 1
for(i in splitbyvalves)
{
  i$exp = as.factor(i$exp)
  bg_exp = tapply(i$df, i$exp, function(x){mean(x[1:16])})
  for(j in c(1:length(unique(i$exp)))) # j = 1 : number of files
  {
    i[i$exp==j,3] = (i[i$exp==j,3]-bg_exp[[j]])/(1+bg_exp[[j]])
  }
  title = i$valve[1]
  p = ggplot(i, aes(color = exp, x = time, y = df))+ geom_rect(xmin = 1, xmax=9, ymin=-1, ymax = 2.5,fill = "gray", alpha=0.02, color=NA) + geom_line(size= 0.5) + ggtitle(title) + theme(panel.background=element_rect(fill=NA,colour=NA),panel.grid.major.y=element_line(linetype="dotted",color="gray",size=0.2),plot.title = element_text(size = 10), legend.position = "none",
  axis.title= element_text(size = 0))
  plot_list[[k]] = p
  k = k+1
}
png(paste0(getwd(),'/','multi.png'))
multip = multiplot(plotlist = plot_list, cols = 3)
dev.off()


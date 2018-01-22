library(ggplot2)
library(reshape2)
library(scales)

k = 1
maxdf_all = data.frame(matrix(nrow = 14, ncol = 0))
for(i in list.files(pattern = "*.csv"))
{
  print(i)
  temp = read.csv(i,header= T)
  #########################
  if(dim(temp)[1] != 14)
  {
  temp = temp[temp[,1] != 'Mix',]
  }
  ########################
  # if(dim(temp)[1] != 15)
  # {
  #   next
  # }

  # ###########################
  maxdf_all = data.frame(maxdf_all,temp[,2])
  i = sub(".csv", "", i)
  i = sub("-Gad2-", "", i)
  i = sub("CST_", "", i)
  print(i)
  colnames(maxdf_all)[dim(maxdf_all)[2]] = i
  k = k+1
}

row.names(maxdf_all) = temp[,1]
maxdf_all.m = melt(as.matrix(maxdf_all))
colnames(maxdf_all.m) = c("stim", 'cell', 'df')
htmap = ggplot(data = maxdf_all.m, aes(y = stim, x = cell, fill = df)) + geom_tile()+
scale_fill_gradient(low="white", high="black", limits = c(0, 6), oob = squish)+
  theme(axis.text.x = element_text(angle = 300, hjust = 0, colour = "grey50", size = 6), 
        axis.text.y = element_text(size = 10), legend.text = element_text(size = 20),
        panel.background = element_rect(fill = "NA"))
ggsave('heatmap.png', htmap)
sweeptime = 8.27
datalist = list()
stimlist = c('ACSF','FFeces','FUrine','A7864','A6940','A7010','E0893','E1050','E4105','P3817','P3865','P8168','Q3910','Q1570','MeOH')
for (i in list.files(patter="*.csv")) {
  temp = read.csv(i,header=FALSE)
  colnames(temp) = c('valve','df','time','sweep')
  for (j in 2:max(temp$sweep)) {
    if(j%%2){
      temp[temp$sweep==j,1]=rep(temp[temp$sweep==j-1,1][5], length(temp[temp$sweep==j,1]))
    }
  }
  temp$valve = factor(temp$valve, labels=stimlist)
  datalist[[match(i,list.files(pattern="*.csv"))]]=temp
}
total = list()
k = 1
for (i in datalist){
  temp = split(i, i$valve)
  A <- function(x) {x[,3]=x[,3]-sweeptime*floor(x[1,3]/sweeptime)
      return(x)}   # 8.27 is time of each sweep 
  temp = lapply(temp, A)
  
  s = do.call('rbind',temp)
  s = cbind(rep(k,dim(s)[1]),s)
  colnames(s)[1]='exp'
  total[[k]] = s
  k = k+1
}
output = do.call('rbind', total)
output = output[output$valve!='ACSF',]
splitbyvalves = split(output, output$valve)
splitbyvalves = splitbyvalves[2:length(splitbyvalves)]
output = list()
k = 1
for (i in splitbyvalves) {
  byexp = split(i,i$exp)
  framenum = min(do.call('rbind',lapply(byexp, dim))[,1])
  A <- function(x) x[1:framenum,]
  temp = lapply(byexp,A)
  sumtemp = temp[[1]]
  for (i in 2:length(temp)) {
    sumtemp = sumtemp + temp[[i]]  
  }
  output[[k]] = sumtemp/length(temp)
  output[[k]]$valve=temp[[1]]$valve
  k=k+1
}
all = do.call('rbind',output)


gplot = ggplot(data=all,aes(x=time,y=df,color=valve))+geom_rect(xmin = 0, xmax=5, ymin=-0.1, ymax =1.8,fill = "gray", alpha=0.02, color=NA)+geom_line()+coord_cartesian(ylim=c(-0.05,1.2),xlim=c(0,16.8))+theme(panel.background=element_rect(fill=NA,colour=NA),panel.grid.major.y=element_line(linetype="dotted",color="gray",size=0.2),legend.key=element_rect(fill=NA))+xlab("time/s")

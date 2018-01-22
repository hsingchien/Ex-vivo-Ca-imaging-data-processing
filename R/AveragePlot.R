library(ggplot2)
source('D:/OneDrive - University of Texas Southwestern/R functions/SummarySE.R')
sweeptime = 10.34 # either 10.34 or 8.27 
datalist = list()
  stimlist = c('ACSF','FFeces','FUrine','A7864','A6940','A7010','E0893','E1050','Mix','E4105','P3817','P3865','P8168','Q3910','Q1570','MeOH')
  for (i in list.files(pattern = "^ROI")) {
    temp = read.csv(i,header=FALSE)
    colnames(temp) = c('valve','df','time','sweep')
    for (j in 2:max(temp$sweep)) {
      if(j%%2){
        temp[temp$sweep==j,1]=rep(temp[temp$sweep==j-1,1][8], length(temp[temp$sweep==j,1]))
      }
    }
    temp$valve = factor(temp$valve, labels=stimlist)
    datalist[[match(i,list.files(pattern="^ROI"))]]=temp
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
  output = data.frame();
  for (i in splitbyvalves) {
    byexp = split(i,i$exp)
    framenum = min(do.call('rbind',lapply(byexp, dim))[,1])
    A <- function(x) x[1:framenum,]
    temp = lapply(byexp,A)
    avg = NULL
    mx = NULL
    for (j in 1:length(temp)) {
      tempwindow = temp[[j]][(temp[[j]]$time>5)&(temp[[j]]$time<=15),]
      avgdff = mean(tempwindow$df)
      avg = c(avg, avgdff)
      maxdff = max(tempwindow$df)
      mx = c(mx, maxdff)
    }
    output=rbind(output,cbind(rep(i$valve[1],length(byexp)),mx,avg))
  }
  # plot mean/max df bar plot
  colnames(output)=c('valve','maxdf','meandf')
  output$valve = factor(output$valve, labels=stimlist[2:length(stimlist)])
  summean = summarySE(data=output,measurevar = "meandf",groupvar="valve")
  summax = summarySE(data=output,measurevar = "maxdf", groupvars = "valve")
  maxplot = ggplot(summax,aes(x=valve,y=maxdf))+geom_bar(stat="identity",position = "identity")+geom_errorbar(aes(ymin=maxdf-se,ymax=maxdf+se),width=.1)
  meanplot = ggplot(summean,aes(x=valve,y=meandf))+geom_bar(stat="identity",position="identity")+geom_errorbar(aes(ymin=meandf-se,ymax=meandf+se),width=.1)

  #plot response curve
  dfoutput = list()
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
    dfoutput[[k]] = sumtemp/length(temp)
    dfoutput[[k]]$valve=temp[[1]]$valve
    k=k+1
  }
  all = do.call('rbind',dfoutput)
  
  dfoutput_copy = dfoutput
  dfoutput_normalized_by_sweep = list()
  k = 1
  maxdf = NULL
  valve_name = NULL
  for (i in dfoutput_copy) {
    bg = mean(i$df[i$time <= 1.5]) # use the pre-stimulus 1.5s as the bg for each valve
    i$df = (i$df-bg) / (1 + bg) ;
    maxdf_this_valve = max(i$df[i$time>5 & i$time<18])
    maxdf = c(maxdf, maxdf_this_valve)
    valve_name = c(valve_name, i$valve[1])
    dfoutput_normalized_by_sweep[[k]] = i
    k = k+1
  }
  maxdf = data.frame(maxdf)
  row.names(maxdf) = factor(valve_name,labels=stimlist[2:length(stimlist)])
  colnames(maxdf) = c("df")
  maxplot_normalized = ggplot(data = maxdf, aes(x = factor(valve_name,labels=stimlist[2:15]), y = df))+geom_bar(stat = "identity")
  write.csv(maxdf,"maxdf.csv")
  all_normalized = do.call('rbind',dfoutput_normalized_by_sweep)
  
  gplot_normalized = ggplot(data=all_normalized,aes(x=time,y=df,color=valve))+
  geom_rect(xmin = 0, xmax=8, ymin=-0.1, ymax = 1.5*max(maxdf),fill = "gray", alpha=0.02, color=NA)+
    geom_line(size = 1)+coord_cartesian(ylim=c(-0.05,max(maxdf)*1.1),xlim=c(0,2*sweeptime))+
    theme(panel.background=element_rect(fill=NA,colour=NA),panel.grid.major.y=
            element_line(linetype="dotted",color="gray",size=0.2),legend.key=element_rect(fill=NA), 
          text = element_text(size = 24))+xlab("time/s")
  
  gplot= ggplot(data=all,aes(x=time,y=df,color=valve))+
    geom_rect(xmin = 0, xmax=5, ymin=-0.05, ymax = 1.5*max(all$df),fill = "gray", alpha=0.02, color=NA)+
    geom_line(size = 0.75)+coord_cartesian(ylim=c(-0.05,max(all$df)*1.1),xlim=c(0,2*sweeptime))+
    theme(panel.background=element_rect(fill=NA,colour=NA),panel.grid.major.y=
            element_line(linetype="dotted",color="gray",size=0.2),legend.key=element_rect(fill=NA), 
          text = element_text(size = 16))+xlab("time/s")
  
  ggsave('gplot_norm.png',gplot_normalized)
  ggsave('gplot.png', gplot)

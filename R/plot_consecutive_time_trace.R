library(ggplot2)
library(stringr)
sweeptime = 8.27
stimlist = c('ACSF','FFeces','FUrine','A7864','A6940','A7010','E0893','E1050','KCL','E4105','P3817','P3865','P8168','Q3910','Q1570','MeOH')

for(f in list.files(pattern="*.csv"))
{
tmp = read.csv(f, header= F)
colnames(tmp) = c('stim','dF','time','run')
stimseq = unique(tmp$stim)[2:length(unique(tmp$stim))]
p = ggplot(data = tmp, aes(x=time,y=dF))+coord_cartesian(ylim=c(min(tmp$dF)-0.1, max(tmp$dF)+0.2))+theme(panel.background=element_rect(fill=NA,colour=NA),panel.grid.major.y=element_line(linetype="dotted",color="gray",size=0.2),
                    legend.position = "none", text = element_text(size = 24))+xlab("time/s")
i = sweeptime
xmax = seq(from=i+8, by=(2*sweeptime),to=max(tmp$time))
xmin = xmax-8
windows = cbind(xmin,xmax,ymin=rep(-Inf, length(xmin)),ymax=rep(Inf,length(xmin)))
windows = data.frame(windows)
row.names(windows) = stimlist[stimseq]
p = p + geom_rect(data=windows, inherit.aes = F, aes(xmin = xmin,xmax=xmax,ymin=ymin,ymax=ymax))+geom_line(size=1)
p = p + geom_text(data=windows, inherit.aes = F, aes(x=1/2*(xmin+xmax), y=max(tmp$dF)+0.1, label = rownames(windows)))
f=str_replace(f,"\\.csv","")
ggsave(paste0(f,'.eps'),width=10,height=6)
ggsave(paste0(f,'.png'),width=10,height=6)
}

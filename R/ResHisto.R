# plot a histgram for the response curve

d = NULL
no_nat = 0
nat_only = 0
nat_ster = 0
eff_stim = list()

for(i in list.files(pattern = "*effective stim.csv", recursive=T))
{
  # print(i)
  if(file.info(i)$size != 0){
  temp = read.table(i, header=FALSE)
  d = c(d,dim(temp)[1])
  temp = temp$V2
  temp = as.character(temp)
  temp = temp[temp!="Mix"]
  eff_stim = c(eff_stim,list(temp))
  print(temp)
  if(length(intersect(temp,c('FFeces','FUrine')))==0){
    no_nat = no_nat + 1;
  } else if(setequal(intersect(temp, c('FFeces','FUrine')),temp))
  {
   nat_only = nat_only + 1 
  } else
  {
    nat_ster = nat_ster + 1
  }
  write.table(t(temp),'effective stims sum.csv',append = TRUE, col.names =F, row.names = F)
  print(i)
  }
  else{
    print("")
  }}

d = data.frame(d)
colnames(d) = "count"

hist_p = ggplot(data=d,aes(d$count))+geom_histogram(binwidth = 1)
ggsave('hist_p.png')

#####################
# making pie chart
df = data.frame(type = c('nat_only','nat_ster','no_nat'), count = c(nat_only, nat_ster,no_nat))
pie = ggplot(data=df,aes(x="",y=count,fill=type))+geom_bar(width = 1,stat='identity')
pie + coord_polar("y", start = 0)
ggsave('pie_chart.png')
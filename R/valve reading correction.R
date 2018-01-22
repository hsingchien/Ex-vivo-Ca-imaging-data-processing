library(stringr)
filename = 'ROI_4_stim6.csv' ## select the right template, usually ROI_1
valves = read.csv(paste0('ROI_4/', filename),header=F)[,1]
for(f in dir())
{
  target = paste0(f,'/', f,str_extract(filename,'_stim\\d+.csv'))
  if(file.exists(target))
  {
    temp = read.csv(target,header=FALSE)
    temp[,1] = valves
    write.table(x = temp, file = target,sep=',',row.names = F,col.names = F)
  }
}

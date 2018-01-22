# test if the valve read is right
datalist = list()
output = NULL
for (i in list.files(pattern = "*.csv")) {
  temp = read.csv(i,header=FALSE)
  colnames(temp) = c('valve','df','time','sweep')
  if (length(unique(temp$valve))!=16){
    output = c(output,i)
  }
}
for (i in output){
  a = read.csv(i,header=F)
  print(i)
  print(unique(a$V1))
}

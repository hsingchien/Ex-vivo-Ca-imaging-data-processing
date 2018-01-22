# calculate lifetime sparseness by experiment
lifetimesparse = function(x) {
  sparseness = (1-mean(x)^2/(1/length(x)*sum(x^2)))/(1-1/length(x))
  return(sparseness)
}


lifetimeresponse = NULL
for (val in splitbyvalves)
{
  tempvalve = val[val$time>5,]
  val_less_than_2 = val[val$time<=2,]
  tempmax = tapply(tempvalve$df, tempvalve$exp,max)
  bg = tapply(val_less_than_2$df,val_less_than_2$exp,mean)
  tempmax = (tempmax-bg)/(1+tempmax)
  lifetimeresponse = cbind(lifetimeresponse, tempmax)
}

lifetimesparsenessbyexp = apply(lifetimeresponse, 1, FUN = lifetimesparse)
lifetimesparsenessbyexp = data.frame(1:max(splitbyvalves[[1]]$exp), lifetimesparsenessbyexp)
colnames(lifetimesparsenessbyexp) = c('exp',"sparseness")
lgplot = ggplot(data = lifetimesparsenessbyexp, aes(x = exp, y = sparseness)) + geom_bar(stat="identity",width = 0.5)+theme(text
=element_text(size = 20))+xlab("experiment#")+coord_cartesian(ylim = c(0,0.8))

weighted.var.se <- function(x, w, na.rm=FALSE)
  #  Computes the variance of a weighted mean following Cochran 1977 definition
{
  if (na.rm) { w <- w[i <- !is.na(x)]; x <- x[i] }
  n = length(w)
  xWbar = weighted.mean(x,w,na.rm=na.rm)
  wbar = mean(w)
  out = n/((n-1)*sum(w)^2)*(sum((w*x-wbar*xWbar)^2)-2*xWbar*sum((w-wbar)*(w*x-wbar*xWbar))+xWbar^2*sum((w-wbar)^2))
  return(out)
}
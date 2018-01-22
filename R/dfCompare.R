## do this with the matrix obtained from plotting average curve and plot by trial.
# step 1 find the strongest stimulator by max average df
v_max = which.max(maxdf$df)
# step 2 find the 50% df window in average curve. the longest consecutive sequence
time_window = which(all_normalized[all_normalized$valve == stimlist[v_max+1],]$df > 0.5*maxdf$df[v_max])
# find the longest consecutive time window
diff_tw = diff(time_window)
br_pts = which(diff_tw != 1)
if(length(br_pts) > 1){
  if(br_pts[1] != 1){br_pts = c(1,br_pts)}
  if(br_pts[length(br_pts)]!= length(diff_tw)){br_pts = c(br_pts,length(diff_tw))}
} else {br_pts = c(1,length(diff_tw))}
conse_len = diff(br_pts)
conse_start = br_pts[which.max(conse_len)]+1
conse_end = br_pts[which.max(conse_len)+1]
time_window = time_window[conse_start:conse_end]
# step 3 calculate the integration(sum) over the time window, list by experiments
dfsum_by_valve_exp = data.frame(matrix(nrow = 0, ncol = 3))
for(i in splitbyvalves)
{
  i$exp = as.factor(i$exp)
  bg_exp = tapply(i$df, i$exp, function(x){mean(x[1:15])})
  for(j in c(1:length(unique(i$exp)))) # j = 1 : number of files
  {
    i[i$exp==j,3] = (i[i$exp==j,3]-bg_exp[[j]])/(1+bg_exp[[j]])
  }
  tmp = tapply(i$df,i$exp, function(x){sum(x[time_window])}) 
  dfsum_by_valve_exp = rbind(dfsum_by_valve_exp, cbind(rep(i$valve[1],length(unique(i$exp))), seq(1,length(unique(i$exp))), 
                                                       tmp))
}

# step 4 perform non-paired t-test with MeOH respectively
head(dfsum_by_valve_exp)
colnames(dfsum_by_valve_exp)=c("valve", 'exp','df')
dfsum_by_valve_exp$valve = factor(dfsum_by_valve_exp$valve,labels = stimlist[2:length(stimlist)])
rs = tapply(X = dfsum_by_valve_exp$df, dfsum_by_valve_exp$valve,
            function(x){t.test(x,dfsum_by_valve_exp$df[dfsum_by_valve_exp$valve == "MeOH"],alternative = "greater")$p.value})
# st is the statistics of t test, serve for heatmap
st = tapply(X = dfsum_by_valve_exp$df, dfsum_by_valve_exp$valve,
            function(x){t.test(x,dfsum_by_valve_exp$df[dfsum_by_valve_exp$valve == "MeOH"],alternative = "greater")$statistic})
logp = log(rs)
logp = (logp-logp[length(logp)])/logp[length(logp)]
# rsd is mean/sd
rsd = tapply(X = dfsum_by_valve_exp$df, dfsum_by_valve_exp$valve,
             function(x){mean(x)/sd(x)})
# step 5 identify the effective stimuli
df_p = data.frame(rs,maxdf)
pos_stim = rownames(df_p[(df_p$rs < 0.05 & df_p$df >= 0.1)|(df_p$rs < 0.1 & df_p$df >= 0.3),]) # p value < 0.025 and an arbitrary threshold of dF = 0.1
write.table(pos_stim, "effective stim.csv",col.names = FALSE)
write.csv(data.frame(st),'statistics.csv')
write.csv(data.frame(logp),'logp.csv')
write.csv(data.frame(rsd),'rsd.csv')
pos_stim


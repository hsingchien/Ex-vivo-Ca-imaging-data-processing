stimtime = ten_hz_stim_time


maxdf_copy = stimtime[1,]
i = 2
while(i != dim(stimtime)[1])
{
  if(abs(stimtime[i,1]-stimtime[i-1,1]) > 0.04)
  {
    maxdf_copy = rbind(maxdf_copy,stimtime[i,])
  }
  i = i + 1
}

stimtime = five_hz_stim_time
df = five_hz_df
i = 1
maxdf = NULL
while(i != dim(stimtime)[1])
{
  beg = stimtime[i,1]
  end = stimtime[i+1,1]
  val = max(df[df$V2 > beg & df$V2 <= end, 1])
  maxdf = c(maxdf, val)
  i = i + 1
}

five_hz_maxdf = data.frame(five_hz_maxdf,rep('5_hz', 48))
colnames(five_hz_maxdf) = c('df', 'freq')
ten_hz_maxdf = data.frame(ten_hz_maxdf,rep('10_hz', 98))
colnames(ten_hz_maxdf) = c('df', 'freq')
max_df = rbind(one_hz_maxdf,five_hz_maxdf,ten_hz_maxdf)
max_df = cbind(c(1:9,1:48,1:98), max_df)
colnames(max_df) = c('num', 'df', 'freq')
ggplot(data=max_df, aes(x = num, y = df, color = freq)) + geom_line(size = 2)
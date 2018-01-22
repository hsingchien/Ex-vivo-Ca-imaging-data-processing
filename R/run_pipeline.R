# set wd to cell folder first
wd = getwd()
#STEP0 delete sick data
ROI_list = c(2,2)
Stim_list = c('10','8')

for(i in 1:length(ROI_list))
{
  bad_ROI = paste0('ROI_', ROI_list[i])
  bad_file = paste0(bad_ROI,'_stim',Stim_list[i],'.csv')
  file.remove(paste0(wd, '/', bad_ROI,'/',bad_file))
}
#STEP1   extract plot, maxdf file out for each ROI
for(f in list.files(path = wd, pattern = "ROI*"))
{
  cur_wd = paste0(wd,'/',f)
  setwd(cur_wd)
  if(is.na(match('maxdf.csv', list.files(cur_wd))) & length(list.files(pattern = '^ROI'))>=3)
    {
    print(f)
    source('D:/OneDrive - University of Texas Southwestern/R functions/AveragePlot.R', echo=F)
    source('D:/OneDrive - University of Texas Southwestern/R functions/plot_by_trial.R', echo=F)
    source('D:/OneDrive - University of Texas Southwestern/R functions/dfCompare.R', echo=F)
    save.image()
  }
}
setwd(wd)

#STEP2   rename maxdf files and move them to one folder
wd = getwd()
dir.create(paste0(wd,'/','maxdf'))
dir.create(paste0(wd,'/','logp_sum'))
dir.create(paste0(wd,'/','statistics_sum'))
dir.create(paste0(wd,'/','rsd_sum'))
for(f in list.files(path = wd))
{
  date = '20180103'
  cell = 'cell2'
  ctype = 'Cst'
  sex = "M"
  AAV = 'AAV9'
  newname = paste0(date,'-',sex,'-',AAV,'-',ctype,'-',cell,'-',f)
  if(!is.na(match('maxdf.csv', list.files(paste0(wd, '/', f)))))
  {
    file.copy(from = paste0(wd,'/',f,'/maxdf.csv'), to = paste0(wd,'/maxdf/', newname,'.csv'))
    # file.rename(from = paste0(wd,'/',f,'/',oldname), to=paste0(wd,'/', f, '/', newname,'.csv'))
  }
  if(!is.na(match('statistics.csv', list.files(paste0(wd, '/', f)))))
  {
    # file.rename(from = paste0(wd,'/',f,'/','statistics.csv'), to=paste0(wd,'/', f, '/', newname,'_st.csv'))
    file.copy(from = paste0(wd,'/',f,'/statistics.csv'), to = paste0(wd,'/statistics_sum/', newname,'_st.csv'))
  }
  if(!is.na(match('logp.csv', list.files(paste0(wd, '/', f)))))
  {
    # file.rename(from = paste0(wd,'/',f,'/','logp.csv'), to=paste0(wd,'/', f, '/', newname,'_lgp.csv'))
    file.copy(from = paste0(wd,'/',f,'/logp.csv'), to = paste0(wd,'/logp_sum/', newname,'_lgp.csv'))
  }
  if(!is.na(match('rsd.csv', list.files(paste0(wd, '/', f)))))
  {
    # file.rename(from = paste0(wd,'/',f,'/','logp.csv'), to=paste0(wd,'/', f, '/', newname,'_lgp.csv'))
    file.copy(from = paste0(wd,'/',f,'/rsd.csv'), to = paste0(wd,'/rsd_sum/', newname,'_rsd.csv'))
  }
}

#STEP3 make a heat map for this recording for reference
setwd(paste0(wd,'/', 'maxdf'))
source('D:/OneDrive - University of Texas Southwestern/R functions/heatmap_maxdf.R', echo=F)
setwd(paste0(wd,'/', 'logp_sum'))
source('D:/OneDrive - University of Texas Southwestern/R functions/heatmap_logp.R', echo=F)

#STEP4 make histogram
setwd(wd)
source('D:/OneDrive - University of Texas Southwestern/R functions/ResHisto.R')

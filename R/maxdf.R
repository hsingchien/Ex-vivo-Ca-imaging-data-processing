library(stringr)
wd = getwd()
for(c in dir()){                                 #'cell'
  for(f in dir(path = paste0(c,'/')))            #'ROI_#'
  {
    fn = paste0(c,'/',f,'/maxdf.csv')
    if(file.exists(fn)){
      f1 = str_extract(wd, '2017.*')
      newname = paste0(wd,'/',c,'/',f,'/',f1,'-',c,'-',f,'.csv') # filename is '2017####-DJ-cell#-ROI#.csv'
      file.rename(fn, newname)
    }
    newpath = 'D:/OneDrive - University of Texas Southwestern/LAB/EGC project data/Ex-vivo/all_maxes/DJ/'
    file.copy(newname, newpath)
  }}
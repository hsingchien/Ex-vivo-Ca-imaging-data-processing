## delete non-data files(not start with 'ROI')

for(i in list.files(pattern = "*.csv", recursive = T))
{
  l = stringr::str_locate(i,'/')
  if(!grepl('^ROI', substr(i,l+1,nchar(i))))
  {
    file.remove(i)
  }
}

## rename data files
for(i in list.files(pattern = "*.csv",recursive = T))
{
  l = stringr::str_locate(i,'/')
  if(grepl('^cell', substr(i,l+1,nchar(i))))
  {
    file.rename(from=i, to=gsub('cell','ROI_',i))
  }
}

## rename z images
for(i in list.files(pattern="*.tif"))
{
  l = stringr::str_locate_all(i,'_')[[1]]
  newname = paste0(substr(i,start=1,stop=l[dim(l)[1],2]-1),'.tif')
  file.rename(from=i,to=newname)
}
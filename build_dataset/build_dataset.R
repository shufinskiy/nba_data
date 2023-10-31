build_season_data <- function(season, folder = '../loading/datasets', seasontype = 'rg', data = 'nbastats', save = FALSE){
  l <- list.files(paste(folder, season, seasontype, data, sep = '/'), full.names = TRUE)
  df <- data.table::rbindlist(lapply(l, data.table::fread), fill = TRUE)
  if(save){
    seasontype <- if (seasontype == 'rg') '_' else '_po_'
    data.table::fwrite(df, paste0(data, seasontype,  season, '.csv'))
  } else {
    return(df)
  }
}

dataset_for_github <- function(files, tar_file, compression = 'xz', compression_level = 9, tar = 'tar'){
  tar(tar_file, files = files, compression = 'xz', compression_level = 9, tar = 'tar')
  if(file.copy(tar_file, paste0('../datasets/', tar_file))){
    file.remove(tar_file)
  }
}

for(season in seq(2023, 2023)){
  seasontype <- 'rg'
  if(season < 2000){
    datatype <- c('nbastats', 'shotdetail')
  } else if(season < 2016){
    datatype <- c('nbastats', 'shotdetail', 'pbpstats')
  } else {
    datatype <- c('nbastats', 'shotdetail', 'pbpstats', 'datanba')
  }
  for(data in datatype){
    build_season_data(season = season, seasontype = seasontype, data = data, save=TRUE)
    seasontype <- if (seasontype == 'rg') '_' else '_po_'
    dataset_for_github(files = paste0(data, seasontype, season, '.csv'), tar_file = paste0(data, seasontype, season, '.tar.xz'))
    seasontype <- if (seasontype == '_') 'rg' else 'po'
  }
}

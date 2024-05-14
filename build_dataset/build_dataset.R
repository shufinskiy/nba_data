build_season_data <- function(season, folder = '../loading/datasets', seasontype = 'rg', league = 'nba', data = 'nbastats', save = FALSE){
  l <- list.files(paste(folder, season, seasontype, league, data, sep = '/'), full.names = TRUE)
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

check_datatype <- function(season, folder = '../loading/datasets', seasontype = 'rg', league = 'nba', data = 'nbastats'){
  check_dir <- dir.exists(paste(folder, season, seasontype, league, data, sep = '/'))
  return(check_dir)
}

dt <- 'cdnnba'
seasontype <- 'rg'

for(season in seq(2020, 2023)){
  if(season < 2000){
    datatype <- c('nbastats', 'nbastatsv3', 'shotdetail')
  } else if(season < 2016){
    datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats')
  } else if(season < 2019){
    datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba')
  } else {
    datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba', 'cdnnba')
  }
  if(!is.na(dt)){
    datatype <- dt
  }
  for(data in datatype){
    dt_exists <- check_datatype(season = season, seasontype = seasontype, data = data)
    if(dt_exists){
      build_season_data(season = season, seasontype = seasontype, data = data, save=TRUE)
      seasontype <- if (seasontype == 'rg') '_' else '_po_'
      dataset_for_github(files = paste0(data, seasontype, season, '.csv'), tar_file = paste0(data, seasontype, season, '.tar.xz'))
      seasontype <- if (seasontype == '_') 'rg' else 'po'
    }
  }
}

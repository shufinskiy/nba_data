#' Loading a dataset from github
#'
#' @description
#' Loading a nba play-by-play dataset from github repository https://github.com/shufinskiy/nba_data
#'
#' @param seasons Sequence or integer of the year of start of season
#' @param data Sequence or string of data types to load
#' @param seasontype Part of season: rg - Regular Season, po - Playoffs
#' @param league Name league: NBA or WNBA
#' @param untar do need to untar loaded archive
#' @return None
#'
#' @importFrom utils download.file
#' @export
load_nba_data <- function(path = getwd(),
                          seasons = seq(1996, 2023),
                          data = c("datanba", "nbastats", "pbpstats", "shotdetail", "cdnnba", "nbastatsv3"),
                          seasontype = 'rg',
                          league = 'nba',
                          untar = FALSE){

  if(seasontype == 'rg'){
    df <- expand.grid(data, seasons)
    need_data <- paste(df$Var1, df$Var2, sep = "_")
  } else if(seasontype == 'po'){
    df <- expand.grid(data, 'po', seasons)
    need_data <- paste(df$Var1, df$Var2, df$Var3, sep = "_")
  } else {
    df_rg <- expand.grid(data, seasons)
    df_po <- expand.grid(data, 'po', seasons)
    need_data <- c(paste(df_rg$Var1, df_rg$Var2, sep = "_"), paste(df_po$Var1, df_po$Var2, df_po$Var3, sep = "_"))
  }
  if(tolower(league) == 'wnba'){
    need_data <- sapply(need_data, function(x){paste0('wnba_', x)}, USE.NAMES = FALSE)
  }

  temp <- tempfile()
  download.file("https://raw.githubusercontent.com/shufinskiy/nba_data/main/list_data.txt", temp)
  f <- readLines(temp)
  unlink(temp)

  v <- unlist(strsplit(f, "="))

  name_v <- v[seq(1, length(v), 2)]
  element_v <- v[seq(2, length(v), 2)]

  need_name <- name_v[which(name_v %in% need_data)]
  need_element <- element_v[which(name_v %in% need_data)]

  if(!dir.exists(path)){
    dir.create(path)
  }

  for(i in seq_along(need_element)){
    destfile <- paste0(path, '/', need_name[i], ".tar.xz")
    download.file(need_element[i], destfile = destfile)
    if(untar){
      untar(destfile, paste0(need_name[i], ".csv"), exdir = path)
      unlink(destfile)
    }
  }
}

#' Loading a dataset from github
#'
#' @description
#' Loading a nba play-by-play dataset from github repository https://github.com/shufinskiy/nba_data
#'
#' @param seasons Sequence or integer of the year of start of season. Not used if in_memory = True
#' @param data Sequence or string of data types to load
#' @param seasontype Part of season: rg - Regular Season, po - Playoffs
#' @param league Name league: NBA or WNBA
#' @param in_memory Upload data without saving to hard disk
#' @param untar do need to untar loaded archive. Not used if in_memory = True
#' @return None
#'
#' @importFrom utils download.file
#' @export
load_nba_data <- function(path = getwd(),
                          seasons = seq(1996, 2024),
                          data = c("datanba", "nbastats", "pbpstats", "shotdetail", 
                                   "cdnnba", "nbastatsv3", "matchups"),
                          seasontype = 'rg',
                          league = 'nba',
                          in_memory = FALSE,
                          untar = FALSE){
  
  path <- normalizePath(path, mustWork = FALSE)
  
  if (length(data) > 1 & in_memory){
    stop("Parameter in_memory=True available only when loading a single data type")
  }
  
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
  if (in_memory){
    df <- data.frame()
  }
  for(i in seq_along(need_element)){
    if (in_memory){
      temp_file <- tempfile(fileext = ".tar.xz")
      download.file(need_element[i], destfile = temp_file, mode = "wb")
      temp_dir <- tempdir()
      temp_csv <- tempfile(fileext = ".csv", tmpdir = temp_dir)
      untar(temp_file, exdir = temp_dir, files = paste0(
        gsub(".tar.xz", "", basename(need_element[i])),".csv"
      ))
      csv_file <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE)
      if (length(csv_file) > 0) {
        tmp_df <- read.csv(csv_file)
        df <- rbind(df, tmp_df)
      } else {
        stop("No CSV file found after extraction.")
      }

      unlink(temp_file)
      unlink(csv_file)
      unlink(temp_dir)
    } else {
      destfile <- paste0(path, '/', need_name[i], ".tar.xz")
      download.file(need_element[i], destfile = destfile)
      if(untar){
        untar(destfile, paste0(need_name[i], ".csv"), exdir = path)
        unlink(destfile)
      }
    }
  }
  if (in_memory){
    return(df)
  }
}

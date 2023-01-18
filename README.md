### Dataset NBA Regular season play-by-play data and shotdetails from 1996/1997 to 2021/22

## Description

## Motivation

## Download

You can download dataset several ways:

**Clone git repository to your device**
```
git clone https://github.com/shufinskiy/nba_data.git
```

**Download using a programming language**

You can write your own loading functions or use ones I wrote for R and Python languages.

**R:**
```r
get_nba_data <- function(seasons = seq(1996, 2021), data = c("datanba", "nbastats", "pbpstats", "shotdetail"), untar = FALSE){
  df <- expand.grid(data, seasons)
  
  need_data <- paste(df$Var1, df$Var2, sep = "_")
  
  temp <- tempfile()
  download.file("https://raw.githubusercontent.com/shufinskiy/nba_data/main/list_data.txt", temp)
  f <- readLines(temp)
  unlink(temp)
  
  v <- unlist(strsplit(f, "="))
  
  name_v <- v[seq(1, length(v), 2)]
  element_v <- v[seq(2, length(v), 2)]
  
  need_name <- name_v[which(name_v %in% need_data)]
  need_element <- element_v[which(name_v %in% need_data)]
  
  for(i in seq_along(need_element)){
    destfile <- paste0(need_name[i], ".tar.xz")
    download.file(need_element[i], destfile = destfile)
    if(untar){
      untar(destfile, paste0(need_name[i], ".csv"))
      unlink(destfile)
    }
  }  
}
```

**Python:**
```python
import urllib.request
import tarfile
from pathlib import Path
from itertools import product

def get_nba_data(seasons=range(1996, 2022), 
                 data=("datanba", "nbastats", "pbpstats", "shotdetail"),
                 untar=False):
    if isinstance(seasons, int):
        seasons = (seasons,)
    need_data = tuple(["_".join([data, str(season)]) for (data, season) in product(data, seasons)])
    with urllib.request.urlopen("https://raw.githubusercontent.com/shufinskiy/nba_data/main/list_data.txt") as f:
        v = f.read().decode('utf-8').strip()
    
    name_v = [string.split("=")[0] for string in v.split("\n")]
    element_v = [string.split("=")[1] for string in v.split("\n")]
    
    need_name = [name for name in name_v if name in need_data]
    need_element = [element for (name, element) in zip(name_v, element_v) if name in need_data]
    
    for i in range(len(need_name)):
        t = urllib.request.urlopen(need_element[i])
        with open("".join([need_name[i], ".tar.xz"]), 'wb') as f:
            f.write(t.read())
        if untar:
            with tarfile.open("".join([need_name[i], ".tar.xz"])) as f:
                f.extract("".join([need_name[i], ".csv"]),'./')
            
            Path("".join([need_name[i], ".tar.xz"])).unlink()
```

**Download from Google Drive**

You can also download full version of the dataset from [GoogleDrive](https://drive.google.com/file/d/1SqLZC_OlWkJyv4sJV3N8IpFZMTv9zvef/view?usp=sharing).

#### Contact me:

If you have questions or proposal about dataset, you can write me convenient for you in a way.

<div id="header" align="left">
  <div id="badges">
    <a href="https://www.linkedin.com/in/vladislav-shufinskiy/">
      <img src="https://img.shields.io/badge/LinkedIn-blue?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn Badge"/>
    </a>
    <a href="https://t.me/brains14482">
      <img src="https://img.shields.io/badge/Telegram-blue?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram Badge"/>
    </a>
    <a href="https://twitter.com/vshufinskiy">
      <img src="https://img.shields.io/badge/Twitter-blue?style=for-the-badge&logo=twitter&logoColor=white" alt="Twitter Badge"/>
    </a>
  </div>
</div>

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
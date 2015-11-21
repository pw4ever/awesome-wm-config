amixer scontents |awk '/\%/{print $5}'|  tr -d '\n'  | sed 's/[][]//g' 

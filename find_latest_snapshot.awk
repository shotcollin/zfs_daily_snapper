BEGIN {

}
{
  if ( ! filesystemArr[$1] )
    filesystemArr[$1]=$2
  else
    if ( filesystemArr[$1] < $2 )
      filesystemArr[$1]=$2
}
END {
  for ( key in filesystemArr )
    print key " " filesystemArr[key]
}
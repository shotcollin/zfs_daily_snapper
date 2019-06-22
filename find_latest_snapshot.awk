{
  atPos=index($1, "@")
  filesystempath=substr($1, 0, atPos - 1)
  snapshotname=substr($1, atPos + 1)
  snapshotdate=$2
  snapshotarray[snapshotname] = snapshotdate
  if ( ! filesystemArr[filesystempath] )
    filesystemArr[filesystempath] = snapshotarray[]
  else
    if ( filesystemArr[filesystempath][snapshotname] < snapshotdate )
      filesystemArr[filesystempath] = snapshotarray
}
END {
  for ( key in filesystemArr )
    for ( value in filesystemArr[key] )
    print key "@" value " " filesystemArr[key][value]
}
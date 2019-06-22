{
  levels=split($0, patharray, "/")
  if ( length(pathslist[levels]) > 0 ) {
    pathslist[levels] = pathslist[levels] "\n" $0
  } else {
    pathslist[levels] = $0
  }
}
END {
  for ( key in pathslist )
    print pathslist[key]
}
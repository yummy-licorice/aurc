import terminal

proc logError*(message: string): void =
  stdout.styledWriteLine(fgRed, "ERROR: ", fgWhite, message)
  quit(1)

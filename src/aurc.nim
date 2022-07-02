import
  #tables,
  strutils,
  osproc,
  strformat,
  httpclient,
  distros,
  terminal,
  os
  #errors

if detectOs(Windows) or detectOs(MacOSX):
  echo "aurc will not work on windows or macos"
  quit 1

let cacheDir = getHomeDir() & ".aurc/cache/"
if not dirExists(cacheDir):
  createDir(cacheDir)

proc cleanup(package: string): void =
  removeDir(cacheDir & package)
  
proc makepkg(package: string, flags: string): int =
  return execCmd(fmt"cd {cacheDir}{package} && makepkg {flags}")  
  
proc installAur(package: string): void =
  stdout.styledWriteLine(fgGreen, package & ": ", fgWhite, "Downloading PKGBUILD")
  discard execCmd(fmt"git clone https://aur.archlinux.org/{package}.git {cacheDir}{package}")
  stdout.styledWriteLine(fgGreen, package & ": ", fgWhite, "Starting Build")
  let buildStatus: int = makepkg(package, "-si")
  if buildStatus == 1:
    echo "Build for package (" & package & ") has failed\nYou can try again with one of the options below or you can cancel"
    echo """
    [1] Retry
    [2] Skip checksums
    [3] Skip PGP
    [4] Skip check()
    [5] Cancel
    """
    let buildOpt = readChar(stdin)
    if buildOpt == '1':
      discard makepkg(package, "-si")
    elif buildOpt == '2':
      discard makepkg(package, "-si --skipchecksums")
    elif buildOpt == '3':
      discard makepkg(package, "-si --skippgpcheck")
    elif buildOpt == '4':
      discard makepkg(package, "-si --skipinteg")
    else:
      cleanup(package)
      quit()

proc inAur(package: string): void =
  try:
    var client = newHttpClient()
    discard getContent(client, "https://aur.archlinux.org/packages/" & package)
    installAur(package)
  except:
    echo "Package not found"


proc inRepos(package: string): void =
  let code: int = execCmdEx(fmt"sudo pacman -S {package}")[1]
  if code == 1:
    inAur(package)
  else:
    echo execCmdEx(fmt"sudo pacman -S {package}")[0]

proc alreadyInstalled(package: string): void =
  let code: int = execCmdEx(fmt"pacman -Q {package}")[1]
  if code == 0:
    echo "Package already installed"
  else:
    inRepos(package)
 

var packages = newSeq[string](0)
var flags = newSeq[string](0)

for arg in 1..paramCount():
  var flag = paramStr(arg)
  if flag.startsWith("--"):
    if flag == "--help":
      echo "aurc - Install packages from AUR"
      echo "Usage: aurc [options] <package>"
      echo "Options:"
      echo "  -a, --ask     Ask before installing" 
      quit(0) 
    else: 
      flag.removePrefix("--")
      flags.add(flag)
  elif flag.startsWith("-"):
    if flag == "-h":
      echo "aurc - Install packages from AUR"
      echo "Usage: aurc [options] <package>"
      echo "Options:"
      echo "  -a, --ask     Ask before installing" 
      quit(0) 
    else: 
      flag.removePrefix("-")
      flags.add(flag)
  else: 
    packages.add(flag) 
#echo packages 
#echo flags

var ask: bool
for flag in flags:
  if flag == "ask":
    ask = true
  else:
    echo "Unknown flag: " & flag
    quit(1)

if ask:
  stdout.write("Continue with transaction (Y/n): ")
  let choice = readLine(stdin).strip()
  if choice == "" or choice == "y" or choice == "Y":
    for package in packages:
      alreadyInstalled(package)
else:
  for package in packages:
    alreadyInstalled(package)




































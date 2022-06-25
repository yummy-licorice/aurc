import
  tables,
  clapfn,
  strutils,
  osproc,
  strformat,
  httpclient,
  distros,
  terminal,
  os,
  errors

if detectOs(Windows) or detectOs(MacOSX):
  echo "aurc will not work on windows or macos"
  quit 1

const cacheDir = getHomeDir() & ".aurc/cache/"
if not dirExists(cacheDir):
  createDir(cacheDir)

var parser = ArgumentParser(programName: "aurc",
                            description: "aurc", version: "1.0.0",
                            author: "Infinitybeond1 <ripluke#5044>")


parser.addRequiredArgument(name = "package", help = "Which package to install")
parser.addSwitchArgument(shortName = "-a", longName = "--ask", default = false,
                         help = "Ask before starting transaction")
#parser.addSwitchArgument(shortName="-q", longName="--quiet", default=false,
#                         help="Mute makepkg output")


let args = parser.parse()

proc cleanup(package: string): void =
  removeDir(cacheDir & package)
  
proc installAur(package: string): void =
  try:
    stdout.styledWriteLine(fgGreen, package & ": ", fgWhite, "Downloading PKGBUILD")
    discard execCmd(fmt"git clone https://aur.archlinux.org/{package}.git {cacheDir}{package}")
    stdout.styledWriteLine(fgGreen, package & ": ", fgWhite, "Starting Build")
    discard execCmd(fmt"cd {cacheDir}{package} && makepkg -si")
    cleanup(package)

  except:
    logError("build failed")

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

if args["ask"].parseBool():
  stdout.write("Continue with transaction (Y/n): ")
  let choice = readLine(stdin).strip()
  if choice == "" or choice == "y" or choice == "Y":
    inRepos(args["package"])
else:
  inRepos(args["package"])



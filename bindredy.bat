color 1F
rem Rebuilding RedyCode.exe from .\projects\RedyCode\source\RedyCode.exw...
set eudir=.\euphoria
set euinc=.\euphoria\include

.\euphoria\bin\eubind.exe ".\projects\RedyCode\source\RedyCode.exw" -icon ".\redy_icon.ico" -i ".\euphoria\include" -eudir ".\euphoria"

move ".\projects\RedyCode\source\RedyCode.exe" ".\RedyCode.exe"

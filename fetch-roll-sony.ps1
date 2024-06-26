<#
.SYNOPSIS
用于备份索尼相机底片目录，默认备份到当前目录。

.PARAMETER b
备份路径，默认为当前目录。

.EXAMPLE
PS> .\fetch-roll-sony.ps1 -b ".\"
使用 "-b" 选项运行脚本，并指定备份路径为 ".\"。默认为当前目录。
#>
param(
  [Alias("b")]
  # 备份路径
  [string]$backupPath = ".\"
)
function doCopy {
  param (
    $src,
    $dest
  )
  robocopy $src $dest /e /xo /copyall /xd 'PRIVATE'
  $videoFolderPath = ("" + $src + "\PRIVATE")
  $videoFolder = Get-Item "$videoFolderPath"
  $lastWriteTimeString = $videoFolder.LastWriteTime.ToString('yyMMddHHmm')
  $archiveName = "PRIVATE-" + $lastWriteTimeString
  # 将视频目录复制至归档目录
  robocopy ($src + 'PRIVATE\') ($dest + '\' + $archiveName + '\') /e /xo /copyall
}
function doArchive {
  $videoFolderPath = "$backupPath\PRIVATE\"
  # 检查视频目录是否存在
  if (((Test-Path -Path $videoFolderPath))) {
    $videoFolder = Get-Item "$videoFolderPath"
    $lastWriteTimeString = $videoFolder.LastWriteTime.ToString('yyMMddHHmm')
    $archiveName = "PRIVATE-" + $lastWriteTimeString
    Write-Output "Video directory is found. Archiving."
    Write-Output "Video directory archive sign: "$lastWriteTimeString
    # 归档视频目录，如果两最后写入时间相同，则视为同一目录
    Move-Item -Path $videoFolderPath -Destination ($backupPath + '\' + $archiveName) 
  }
  else {
    # 目录不存在，跳过
    Write-Output "The video directory does not exist. Archive skipping."
  }
}

$rollDrives = New-Object System.Collections.ArrayList
# 获取所有盘符
$drives = Get-PSDrive -PSProvider FileSystem
# 遍历每个盘符
foreach ($drive in $drives) {
  # 寻找索尼相机卡，拼接文件路径
  $file = Join-Path -Path $drive.Root -ChildPath "/PRIVATE/SONY/SONYCARD.IND"
  # 判断文件是否存在
  if (Test-Path -Path $file) {
    # 底片盘路径
    $rollDrives.Add($drive.Root)
  }
}
# 检查是否找到了相机卡
if (($null -eq $rollDrives) -or ($rollDrives.count -eq 0)) {
  # 输出错误信息
  Write-Output "Camara roll drive is not found."
  timeout /t -1
}
else {
  doArchive
  foreach ($rollDrive in $rollDrives) {
    # 复制新文件
    doCopy $rollDrive $backupPath
  }
  timeout /t -1
}

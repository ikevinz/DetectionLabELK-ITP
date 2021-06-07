

$exfil_dir="C:\Windows\System32\winevt\Logs"
$exfil_ext="*.evtx"
$loot_dir= "C:\Users\Backup"
If(!(test-path $loot_dir))
{
      New-Item -ItemType Directory -Force -Path $loot_dir
}


#run robocopy to copy Security.evtx out
robocopy $exfil_dir $loot_dir $exfil_ext /S /MT /Z /tee /log:$loot_dir\robocopy.log
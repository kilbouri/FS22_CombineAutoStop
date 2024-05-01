$ZipName = "./FS22_CombineAutoStop.zip";
$ModDir = "Documents/My Games/FarmingSimulator2022/mods"

Compress-Archive **/ $ZipName && Move-Item $ZipName "$env:USERPROFILE/$ModDir/$ZipName" -Force;

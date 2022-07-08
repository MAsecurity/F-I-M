Write-Host " "
Write-Host "What would you like to do? "
Write-Host " "
Write-Host "    A) Collect a new baseline? "
Write-Host "    B) Begin monitoring files with saved baseline?"

$response = Read-Host -Prompt "Please enter either 'A' or 'B'"
Write-Host " "

Function Calculate-filehash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA256
    return $filehash
}
Function Erase-baseline-if-it-exists() {
    $baselineexists = Test-Path -Path .\baseline.txt
    if($baselineexists) {
        Remove-Item -Path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    #delete baseline.txt if it already exists
    Erase-baseline-if-it-exists
    #Calcuating Hash from the Target Files and store them in baseline.txt
    #Collect all files in the target folder (Example -> Files)
    $files = Get-ChildItem -Path .\Files
    #For each file, calculate the hash, and write to the baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-filehash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }



}
elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}
    #Load file |hash from baseline.txt and store them in a dictionary 
    $filepathsandhashes = Get-Content -Path .\baseline.txt
    foreach ($f in $filepathsandhashes) {
        $filehashdictionary.add($f.Split("|")[0], $f.Split("|")[1])
    }

    
    # Begin continuosly monitoring files with saved baseline
    while ($true) {
        Start-Sleep -Seconds 1
        $files = Get-ChildItem -Path .\Files
        #for each file, calculate the hash and write to baseline.txt
        foreach ($f in $files) {
            $hash = Calculate-filehash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                #A new File has beeen created
                Write-host "$($hash.Path) has been created!" -ForegroundColor DarkGreen

            }
            else {

                if($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # The file has not changed
                }
                else {
                    # Warning the integrity of the File has been compromised!!
                    Write-Host "$($hash.Path) has changed!" -ForegroundColor Yellow
            }
           }

        }
        foreach ($key in $fileHashDictionary.Keys) {
            $baselinefilestillexists = Test-Path -Path $key
            if (-Not $baselinefilestillexists) {
                #one of the baseline files has been deleted 
                Write-Host "$($key) has been deleted!" -ForegroundColor Red
            }
        }
     }

}
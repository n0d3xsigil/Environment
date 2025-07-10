$inputValue = Read-Host -Prompt "Please enter the string you want to convert"

$droppedSpaces = $inputValue.ToLower() -replace ' ', ''

$droppedCharacters = $droppedSpaces -replace '[^a-zA-Z0-9]',''

$finalOutput = "- [$inputValue](#$droppedCharacters)"

Write-Host $finalOutput

$finalOutput | Set-Clipboard

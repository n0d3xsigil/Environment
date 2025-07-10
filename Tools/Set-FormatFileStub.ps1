$inputValue = Read-Host -Prompt "Please enter the string you want to convert"

$droppedSpaces = $inputValue -replace ' ', ''

$droppedCharacters = $droppedSpaces -replace '[^a-zA-Z0-9-]',''

$finalOutput = "- [$inputValue](Rooms/$droppedCharacters.md)"

Write-Host $finalOutput

$finalOutput | Set-Clipboard

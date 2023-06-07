[CmdletBinding()]
param
(
  [Parameter(Mandatory, ValueFromPipeline)]
  [System.IO.FileInfo[]]$File
)
begin {
  class commandUsage {
    [string]$Name
    [string]$Type
    [string]$Source
    [int]$Count = 0
    [System.Collections.Generic.List[string]]$Usages = [System.Collections.Generic.List[string]]::new()
  }
  $result = [System.Collections.Generic.Dictionary[string, commandUsage]]::new()
}
process {
  foreach ($f in $File) {
    $script = Get-Command -Name $f.FullName
    Get-AstStatement -Ast $script.ScriptBlock.Ast -Type CommandAst | ForEach-Object -Process {
      $commandName = $_.CommandElements[0].ToString()
      if ($result.ContainsKey($commandName)) {
        $result[$commandName].Count++
        $result[$commandName].Usages.Add("At line: $($_.CommandElements[0].Extent.StartLineNumber)/column: $($_.CommandElements[0].Extent.StartColumnNumber)")
      } else {
        $commandUsage = [commandUsage]::new()
        $commandUsage.Name = $commandName
        $commandUsage.Usages.Add("At line: $($_.CommandElements[0].Extent.StartLineNumber)/column: $($_.CommandElements[0].Extent.StartColumnNumber)")
        $commandUsage.Count++

        #Resolve source
        try {
          $cmdFound = Get-Command -Name $commandName -ErrorAction Stop
          $commandUsage.Type = $cmdFound.CommandType
          $commandUsage.Source = $cmdFound.Source
        } catch {
          $commandUsage.Type = 'Unknown'
          $commandUsage.Source = 'Unknown'
        }

        #Append to result
        $result.Add($commandName, $commandUsage)
      }
    }
  }
}
end {
  $result.Values
}

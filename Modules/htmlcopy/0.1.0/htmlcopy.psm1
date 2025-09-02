function htmlcopy {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string] $InputObject
    )

    begin {
        $sb = [System.Text.StringBuilder]::new()
    }

    process {
        $null = $sb.AppendLine($InputObject)
    }

    end {
        $data = $sb.ToString().TrimEnd()

        if (-not $data) {
            Write-Error "No input received"
            return
        }

        Add-Type -AssemblyName System.Windows.Forms
        $clip = New-Object Windows.Forms.DataObject
        $clip.SetData("HTML Format", $data)
        [Windows.Forms.Clipboard]::SetDataObject($clip, $true)
    }
}

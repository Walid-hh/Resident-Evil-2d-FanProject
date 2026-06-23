$ErrorActionPreference = "Stop"

$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "godot" }
if (-not $env:GODOT_BIN -and -not (Get-Command $godot -ErrorAction SilentlyContinue)) {
	Write-Error "Godot was not found on PATH. Set GODOT_BIN to the local Godot 4.6 executable and run this script again."
}

& $godot -s addons/gut/gut_cmdln.gd --path $PWD -gdir=res://test/unit -gexit
exit $LASTEXITCODE

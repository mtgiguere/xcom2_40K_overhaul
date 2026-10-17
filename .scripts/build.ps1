Param(
    [string] $srcDirectory,  # the path that contains the .XCOM_sln
    [string] $sdkPath,       # path ending in "XCOM 2 War of the Chosen SDK"
    [string] $gamePath,      # path ending in "XCom2-WarOfTheChosen"
    [string] $config,        # build configuration: default | debug
    [string] $highlanderSrc  # optional override: path to the Community Highlander "Src" folder
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "X2ModBuildCommon\build_common.ps1"
Write-Host "Sourcing $common"
. ($common)

$builder = [BuildProject]::new("Astartes", $srcDirectory, $sdkPath, $gamePath)

# Compile against the Community Highlander. Default: the Workshop copy that sits next to the game install.
if ([string]::IsNullOrEmpty($highlanderSrc)) {
    $steamapps = Resolve-Path (Join-Path $gamePath "..\..\..")
    $highlanderSrc = Join-Path $steamapps "workshop\content\268500\1134256495\Src"
}
if (-not (Test-Path $highlanderSrc)) {
    ThrowFailure "Community Highlander source not found at '$highlanderSrc'. Subscribe to X2WOTCCommunityHighlander or pass -highlanderSrc."
}
Write-Host "Including Highlander source from $highlanderSrc"
$builder.IncludeSrc($highlanderSrc)

switch ($config)
{
    "debug"   { $builder.EnableDebug() }
    "default" { }
    ""        { ThrowFailure "Missing build configuration" }
    default   { ThrowFailure "Unknown build configuration $config" }
}

$builder.InvokeBuild()

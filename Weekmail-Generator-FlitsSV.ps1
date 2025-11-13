# Script parameter voor dry-run modus
param([switch]$DryRun)

# Windows Forms aanhalen voor de InputBox
Add-Type -AssemblyName Microsoft.VisualBasic

# --- Configuratie voor Team: FlitsSV ---

# Doelpad (waar het nieuwe bestand wordt geplaatst)
$destinationPath = "\\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\FlitsSV\SitePages\"

# Bronpad (waar het sjabloonbestand zich bevindt)
$sourcePath = "\\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\FlitsSV\SitePages\Sjabloon\"

# Naam van het sjabloonbestand
$templateFile = "SjabloonWM-SVFlits.aspx"

# Team naam voor in bestandsnaam en titel
$teamName = "FlitsSV"

# --- SharePoint REST API Configuratie ---

# De $siteUrl moet verwijzen naar de subsite die de 'SitePages' bibliotheek bevat.
$siteUrl = "https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen"

# UNC-pad wat we moeten 'wegknippen' om de server-relatieve URL te krijgen
$uncPrefix = '\\som.org.om.local@SSL\DavWWWRoot'
# Het HTTP-equivalent van het UNC-pad
$httpPrefix = 'https://som.org.om.local'

# --- Hulpfunctie voor robuuste pad-conversie ---
function Convert-ToServerRelativeUrl {
    param([string]$UncPath, [string]$UncPrefix)
    
    # Normaliseer beide paden (verwijder trailing slashes)
    $normalizedPath = $UncPath.TrimEnd('\')
    $normalizedPrefix = $UncPrefix.TrimEnd('\')
    
    if ($normalizedPath.StartsWith($normalizedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $normalizedPath.Substring($normalizedPrefix.Length)
        $serverRelativeUrl = $relativePath -replace '\\', '/'
        
        # Zorg dat het begint met '/'
        if (-not $serverRelativeUrl.StartsWith('/')) {
            $serverRelativeUrl = '/' + $serverRelativeUrl
        }
        
        return $serverRelativeUrl
    } else {
        throw "Kan UNC-pad niet converteren: '$UncPath' begint niet met '$UncPrefix'"
    }
}

# --- Functie om Titel bij te werken (REST API) ---
function Update-SharePointTitleREST (
    [string]$ApiSiteUrl,
    [string]$ServerRelativeFileUrl,
    [string]$NewTitle
) {
    Write-Host "Titel bijwerken via REST API op site: $ApiSiteUrl"
    
    if ($DryRun) {
        Write-Host "[DRY-RUN] Zou SharePoint REST API aanroepen:"
        Write-Host "[DRY-RUN] - Site: $ApiSiteUrl"
        Write-Host "[DRY-RUN] - Bestand: $ServerRelativeFileUrl"
        Write-Host "[DRY-RUN] - Nieuwe titel: $NewTitle"
        return
    }
    
    try {
        # STAP 1: Haal de Form Digest Value op (nodig voor schrijfacties)
        $digestUrl = "$ApiSiteUrl/_api/contextinfo"
        
        Write-Host "Context ophalen van: $digestUrl"
        $digestResponse = Invoke-RestMethod -Uri $digestUrl -Method Post -UseDefaultCredentials -Headers @{ 
            "Accept" = "application/json;odata=verbose" 
        } -ErrorAction Stop
        
        # Defensieve check van response structuur
        if (-not $digestResponse -or -not $digestResponse.d -or -not $digestResponse.d.GetContextWebInformation) {
            throw "Onverwachte response structuur van contextinfo endpoint"
        }
        
        $formDigestValue = $digestResponse.d.GetContextWebInformation.FormDigestValue
        if (-not $formDigestValue) {
            throw "FormDigestValue niet gevonden in response"
        }
        Write-Host "Form Digest verkregen."

        # STAP 2: Haal de metadata van het zojuist gemaakte bestand op
        $fileApiUrl = "$ApiSiteUrl/_api/web/GetFileByServerRelativeUrl('$ServerRelativeFileUrl')/ListItemAllFields"
        
        Write-Host "Bestandsitem ophalen van: $fileApiUrl"
        $itemResponse = Invoke-RestMethod -Uri $fileApiUrl -Method Get -UseDefaultCredentials -Headers @{ 
            "Accept" = "application/json;odata=verbose" 
        } -ErrorAction Stop
        
        # Defensieve check van response structuur
        if (-not $itemResponse -or -not $itemResponse.d -or -not $itemResponse.d.__metadata) {
            throw "Onverwachte response structuur van file metadata endpoint"
        }
        
        $itemMetadata = $itemResponse.d.__metadata
        if (-not $itemMetadata.type -or -not $itemMetadata.uri) {
            throw "Vereiste metadata (type/uri) niet gevonden in response"
        }
        Write-Host "Metadata van bestand opgehaald (Type: $($itemMetadata.type))"

        # STAP 3: Bereid de update-payload (JSON) voor
        $payload = @{
            "__metadata" = @{ "type" = $itemMetadata.type }
            "Title"      = $NewTitle
        }
        $jsonPayload = $payload | ConvertTo-Json -Depth 3

        # STAP 4: Voer de update (MERGE) uit
        $updateUrl = $itemMetadata.uri
        
        Write-Host "Update uitvoeren naar: $updateUrl"
        Invoke-RestMethod -Uri $updateUrl -Method Post -UseDefaultCredentials -Headers @{
            "Accept"             = "application/json;odata=verbose"
            "X-RequestDigest"    = $formDigestValue
            "X-HTTP-Method"      = "MERGE"
            "If-Match"           = $itemMetadata.etag
            "Content-Type"       = "application/json;odata=verbose"
        } -Body $jsonPayload

        Write-Host "SharePoint Titel succesvol bijgewerkt naar: $NewTitle"

    } catch {
        $outerException = $_
        Write-Host "FOUT bij het bijwerken van de SharePoint Titel via REST API:"
        Write-Host $outerException.Exception.Message
        if ($outerException.Exception.Response) {
            try {
                $stream = $outerException.Exception.Response.GetResponseStream()
                $reader = [System.IO.StreamReader]::new($stream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "Response Body: $errorBody"
                $reader.Dispose()
                $stream.Dispose()
            } catch {
                Write-Host "Kon response body niet lezen: $($_.Exception.Message)"
            }
        }
    }
}

# --- Functie om het bestand te maken ---
function New-WeekmailFile {
    param(
        [Parameter(Mandatory=$true)]
        [int]$jaar,
        
        [Parameter(Mandatory=$true)]
        [int]$weekNumber
    )
    
    # Definieer een ID voor de progressiebalk, zodat we hem kunnen bijwerken
    $progressId = 1
    $activity = "Weekmail aanmaken voor $teamName (Jaar: $jaar, Week: $weekNumber)"
    
    if ($DryRun) {
        Write-Host "=== DRY-RUN MODUS - Geen bestanden worden gewijzigd ==="
        $activity += " [DRY-RUN]"
    }

    # Bestandsnaam voor het nieuwe bestand
    $newFileName = "Weekmail---Jaar-$jaar---Week-$weekNumber---$teamName.aspx"

    # Volledige paden naar het sjabloonbestand en het nieuwe bestand
    $templateFilePath = Join-Path -Path $sourcePath -ChildPath $templateFile
    $newFilePath = Join-Path -Path $destinationPath -ChildPath $newFileName

    if (Test-Path -Path $templateFilePath) {
        
        # --- CONTROLE OP BESTAAND BESTAND ---
        if ((Test-Path -Path $newFilePath) -and -not $DryRun) {
            Write-Host "WAARSCHUWING: Bestand bestaat al: $newFilePath"
            $overwriteChoice = [Microsoft.VisualBasic.Interaction]::InputBox("Bestand bestaat al. Overschrijven? (ja/nee)", "Bestand overschrijven", "nee")
            if ($overwriteChoice.ToLower() -ne "ja") {
                Write-Host "Bewerking geannuleerd door gebruiker."
                return
            }
        }
        
        # --- STAP 1: BESTAND KOPIËREN ---
        Write-Progress -Id $progressId -Activity $activity -Status "Stap 1/5: Sjabloon kopiëren..." -PercentComplete 0
        Write-Host "Bestand kopiëren..."
        
        if ($DryRun) {
            Write-Host "[DRY-RUN] Zou kopiëren: $templateFilePath -> $newFilePath"
            if (Test-Path -Path $newFilePath) {
                Write-Host "[DRY-RUN] (Bestand bestaat al en zou worden overschreven)"
            }
        } else {
            Copy-Item -Path $templateFilePath -Destination $newFilePath -Force
            Write-Host "Bestand gekopieerd naar: $newFilePath"
        }

        # --- STAP 2: INHOUD VAN BESTAND AANPASSEN (PLACEHOLDERS VERVANGEN) ---
        try {
            Write-Progress -Id $progressId -Activity $activity -Status "Stap 2/5: Placeholders in bestand vervangen..." -PercentComplete 20
            
            Write-Host "Placeholders in het nieuwe bestand vervangen..."
            
            if ($DryRun) {
                Write-Host "[DRY-RUN] Zou vervangen: {{jaartal}} -> $jaar, {{weeknummer}} -> $weekNumber"
            } else {
                (Get-Content -Path $newFilePath -Raw -Encoding UTF8) -replace '{{jaartal}}', $jaar -replace '{{weeknummer}}', $weekNumber | Set-Content -Path $newFilePath -Encoding UTF8
                Write-Host "Placeholders succesvol vervangen."
            }
        } catch {
            Write-Host "FOUT bij het vervangen van placeholders in het bestand:"
            Write-Host $_.Exception.Message
        }

        # --- STAP 3: WACHTEN OP SHAREPOINT (MET PROGRESSIEBALK) ---
        Write-Host "Wachten op SharePoint-verwerking..."
        $wachtTijd = 10 # Totaal 10 seconden wachten
        for ($i = 1; $i -le $wachtTijd; $i++) {
            $percent = 40 + ($i * 2) # Telt op van 40% naar 60%
            Write-Progress -Id $progressId -Activity $activity -Status "Stap 3/5: Wachten op SharePoint ($i/$wachtTijd sec)..." -PercentComplete $percent
            Start-Sleep -Seconds 1
        }

        # --- STAP 4: TITEL-KOLOM BIJWERKEN (MET DE JUISTE SUBSITE-CONTEXT) ---
        Write-Progress -Id $progressId -Activity $activity -Status "Stap 4/5: SharePoint Titel-kolom bijwerken (API)..." -PercentComplete 60
        
        $newSharePointTitle = "Weekmail $weekNumber ($jaar) - $teamName"
        
        try {
            $serverRelativeUrl = Convert-ToServerRelativeUrl -UncPath $newFilePath -UncPrefix $uncPrefix
            Write-Host "Server-relative URL: $serverRelativeUrl"
        } catch {
            Write-Host "FOUT bij pad-conversie: $($_.Exception.Message)"
            Write-Host "UNC-pad: $newFilePath"
            Write-Host "UNC-prefix: $uncPrefix"
            return
        }

        if ($DryRun) {
            Write-Host "[DRY-RUN] Zou SharePoint titel bijwerken naar: $newSharePointTitle"
            Write-Host "[DRY-RUN] Server-relative URL: $serverRelativeUrl"
        } else {
            Update-SharePointTitleREST -ApiSiteUrl $siteUrl -ServerRelativeFileUrl $serverRelativeUrl -NewTitle $newSharePointTitle
        }

        # --- STAP 5: BROWSER OPENEN (zoals voorheen) ---
        Write-Progress -Id $progressId -Activity $activity -Status "Stap 5/5: Pagina openen in browser..." -PercentComplete 80
        
        try {
            $httpPath = $newFilePath -replace [regex]::Escape($uncPrefix), $httpPrefix
            $httpPath = $httpPath -replace '\\', '/'
            
            # Valideer dat het een geldige URL is
            if (-not [Uri]::IsWellFormedUriString($httpPath, [UriKind]::Absolute)) {
                throw "Gegenereerde URL is niet geldig: $httpPath"
            }
            
            if ($DryRun) {
                Write-Host "[DRY-RUN] Zou browser openen naar: $httpPath"
            } else {
                Write-Host "Nieuwe pagina openen in browser: $httpPath"
                Start-Process $httpPath
            }
        } catch {
            Write-Host "FOUT bij HTTP-pad conversie: $($_.Exception.Message)"
            Write-Host "Kan browser niet openen voor: $newFilePath"
        }
        
        Write-Progress -Id $progressId -Activity $activity -Status "Klaar!" -Completed

    } else {
        Write-Host "Sjabloonbestand niet gevonden: $templateFilePath"
    }
}

# --- Gebruikersinvoer ---
Write-Host "=== Weekmail Generator voor Team: $teamName ==="

# Vraag het jaartal op
$jaarInput = [Microsoft.VisualBasic.Interaction]::InputBox("Voor welk jaar wil je de weekmail voor $teamName aanmaken?", "Jaartal Invoer", (Get-Date).Year)

if ($jaarInput -eq "" -or -not ($jaarInput -match '^\d{4}$')) {
    Write-Host "Geen geldig jaartal ingevoerd. Script wordt afgesloten."
    exit
}

# Vraag het weeknummer op
$weekInput = [Microsoft.VisualBasic.Interaction]::InputBox("In welke week ga je deze weekmail voor $teamName publiceren? Schrijf het weeknummer op:", "Weeknummer Invoer", "")

if ($weekInput -eq "" -or -not ($weekInput -match '^\d+$')) {
    Write-Host "Geen geldig weeknummer ingevoerd. Script wordt afgesloten."
    exit
}

# Zet de invoer om naar correcte types
$jaar = [int]$jaarInput
$weekNumber = [int]$weekInput

# Validatie van invoerwaarden
if ($jaar -lt 2020 -or $jaar -gt 2030) {
    Write-Host "WAARSCHUWING: Jaar buiten verwacht bereik (2020-2030): $jaar"
}
if ($weekNumber -lt 1 -or $weekNumber -gt 53) {
    Write-Host "WAARSCHUWING: Weeknummer buiten bereik (1-53): $weekNumber"
}

# Maak het bestand aan
New-WeekmailFile -jaar $jaar -weekNumber $weekNumber
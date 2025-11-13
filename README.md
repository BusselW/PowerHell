# PowerHell - Weekmail Generator Script

Dit PowerShell-script automatiseert het aanmaken van weekmail-pagina's in SharePoint door een sjabloon te kopiëren, placeholders te vervangen, en de SharePoint-metadata bij te werken.

## 🎯 Wat doet dit script?

Het script maakt automatisch nieuwe weekmail-pagina's aan op basis van een voorgedefinieerd sjabloon. Het voert de volgende stappen uit:

1. **Sjabloon kopiëren** - Kopieert een ASPX-sjabloonbestand naar een nieuwe locatie
2. **Placeholders vervangen** - Vervangt `{{jaartal}}` en `{{weeknummer}}` in het bestand
3. **SharePoint-metadata bijwerken** - Stelt de titel-kolom in SharePoint in via REST API
4. **Browser openen** - Opent de nieuwe pagina automatisch in de browser

## 📋 Vereisten

### Software
- **Windows PowerShell 5.1** of hoger
- **Microsoft.VisualBasic** assembly (voor InputBox dialogen)
- **Internettoegang** tot SharePoint-omgeving

### Toegang
- **UNC-toegang** tot SharePoint-mappen via `\\som.org.om.local@SSL\DavWWWRoot\`
- **SharePoint-rechten** voor het maken en bewerken van pagina's
- **Windows-authenticatie** die werkt met SharePoint REST API

### Mapstructuur
Het script verwacht de volgende mappenstructuur:

```
\\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\SitePages\
├── Sjabloon\
│   └── SjabloonWM-Beoordelen.aspx    # Het sjabloonbestand
└── [Hier komen de nieuwe weekmails]   # Doellocatie voor nieuwe bestanden
```

## 🚀 Gebruik

### Basis gebruik
```powershell
# Normaal uitvoeren
.\Oki

# Dry-run modus (geen wijzigingen, alleen tonen wat er zou gebeuren)
.\Oki -DryRun
```

### Stap-voor-stap proces

#### Stap 1: Script starten
- Voer het script uit in PowerShell
- Het script vraagt om invoer via popup-dialogen

#### Stap 2: Jaartal invoeren
- **Prompt**: "Voor welk jaar wil je de weekmail aanmaken?"
- **Standaard**: Huidige jaar
- **Validatie**: Moet 4 cijfers zijn (bijvoorbeeld: 2025)
- **Waarschuwing**: Bij jaar buiten 2020-2030

#### Stap 3: Weeknummer invoeren
- **Prompt**: "In welke week ga je deze weekmail publiceren?"
- **Validatie**: Moet numeriek zijn
- **Waarschuwing**: Bij weeknummer buiten 1-53

#### Stap 4: Automatische verwerking
Het script voert nu automatisch deze stappen uit:

##### 🔄 **Stap 1/5: Sjabloon kopiëren**
- Controleert of sjabloonbestand bestaat
- Vraagt bevestiging bij bestaande bestanden
- Kopieert `SjabloonWM-Beoordelen.aspx` naar nieuwe locatie
- **Nieuwe naam**: `Weekmail---Jaar-[JAAR]---Week-[WEEK]---Verkeersborden.aspx`

##### ✏️ **Stap 2/5: Placeholders vervangen**
- Opent het gekopieerde bestand
- Vervangt `{{jaartal}}` → ingevoerde jaar
- Vervangt `{{weeknummer}}` → ingevoerd weeknummer
- Bewaart bestand met UTF-8 encoding

##### ⏳ **Stap 3/5: Wachten op SharePoint**
- Wacht 10 seconden voor SharePoint-synchronisatie
- Toont voortgangsbalk tijdens wachttijd

##### 🔗 **Stap 4/5: SharePoint-titel bijwerken**
- Verbindt met SharePoint REST API
- Haalt authenticatie-token op
- Werkt titel-kolom bij naar: `"Weekmail [WEEK] ([JAAR]) - Verkeersborden"`
- Gebruikt server-relative URL voor bestandsidentificatie

##### 🌐 **Stap 5/5: Browser openen**
- Converteert UNC-pad naar HTTP-URL
- Opent nieuwe pagina automatisch in standaardbrowser
- **URL-formaat**: `https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen/SitePages/...`

## ⚙️ Configuratie

### Aanpasbare instellingen (aan het begin van het script):

```powershell
# Doelpad voor nieuwe bestanden
$destinationPath = "\\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\SitePages\"

# Bronpad voor sjabloon
$sourcePath = "\\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\SitePages\Sjabloon\"

# Sjabloonbestand naam
$templateFile = "SjabloonWM-Beoordelen.aspx"

# SharePoint site URL (voor REST API)
$siteUrl = "https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen"
```

## 🛡️ Foutafhandeling

### Ingebouwde beveiligingen:
- **Bestandscontrole**: Vraagt bevestiging bij overschrijven bestaande bestanden
- **Pad-validatie**: Controleert UNC-naar-URL conversies
- **API-validatie**: Defensieve checks op SharePoint REST-responses
- **URL-validatie**: Controleert gegenereerde URLs voordat browser wordt geopend

### Veel voorkomende problemen:

#### "Sjabloonbestand niet gevonden"
- **Oorzaak**: Sjabloon bestaat niet op verwachte locatie
- **Oplossing**: Controleer `$sourcePath` en `$templateFile` instellingen

#### "Kan UNC-pad niet converteren"
- **Oorzaak**: Bestandspad komt niet overeen met `$uncPrefix`
- **Oplossing**: Controleer dat bestanden echt in de SharePoint-map staan

#### SharePoint REST API fouten
- **Oorzaak**: Authenticatie, rechten, of netwerkproblemen
- **Oplossing**: Controleer toegang tot SharePoint en internetverbinding

#### "Onverwachte response structuur"
- **Oorzaak**: SharePoint API-wijzigingen of verschillende versie
- **Oplossing**: Controleer SharePoint-versie en API-documentatie

## 🧪 Dry-Run Modus

Voor veilig testen gebruik je de `-DryRun` parameter:

```powershell
.\Oki -DryRun
```

In dry-run modus:
- ✅ Toont wat er zou gebeuren
- ✅ Controleert toegang tot bestanden
- ✅ Valideert invoerwaarden
- ❌ Maakt geen bestanden aan
- ❌ Roept geen SharePoint API aan
- ❌ Opent geen browser

## 📁 Voorbeelduitvoer

### Succesvol uitgevoerde run:
```
=== Weekmail aanmaken (Jaar: 2025, Week: 46) ===
Bestand kopiëren...
Bestand gekopieerd naar: \\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\SitePages\Weekmail---Jaar-2025---Week-46---Verkeersborden.aspx
Placeholders in het nieuwe bestand vervangen...
Placeholders succesvol vervangen.
Wachten op SharePoint-verwerking...
Titel bijwerken via REST API op site: https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen
Server-relative URL: /sites/MulderT/Onderdelen/Beoordelen/SitePages/Weekmail---Jaar-2025---Week-46---Verkeersborden.aspx
Context ophalen van: https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen/_api/contextinfo
Form Digest verkregen.
Bestandsitem ophalen van: https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen/_api/web/GetFileByServerRelativeUrl('/sites/MulderT/Onderdelen/Beoordelen/SitePages/Weekmail---Jaar-2025---Week-46---Verkeersborden.aspx')/ListItemAllFields
Metadata van bestand opgehaald (Type: SP.Data.SitePagesItem)
Update uitvoeren naar: https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen/_api/web/lists/getbytitle('SitePages')/items(123)
SharePoint Titel succesvol bijgewerkt naar: Weekmail 46 (2025) - Verkeersborden
Nieuwe pagina openen in browser: https://som.org.om.local/sites/MulderT/Onderdelen/Beoordelen/SitePages/Weekmail---Jaar-2025---Week-46---Verkeersborden.aspx
```

## 🔧 Aanpassingen maken

### Andere sjabloonnaam gebruiken:
Wijzig regel:
```powershell
$templateFile = "JouwNieuweSjabloon.aspx"
```

### Andere naamgeving voor nieuwe bestanden:
Wijzig in de `New-WeekmailFile` functie:
```powershell
$newFileName = "JouwNieuweNaam-$jaar-Week$weekNumber.aspx"
```

### Andere SharePoint-titel:
Wijzig regel:
```powershell
$newSharePointTitle = "Jouw nieuwe titel $weekNumber ($jaar)"
```

## 📞 Ondersteuning

Bij problemen controleer:
1. **Toegang tot SharePoint-mappen** via Windows Verkenner
2. **Internetverbinding** naar SharePoint-site
3. **PowerShell-versie** (minimaal 5.1)
4. **Windows-authenticatie** instellingen voor SharePoint

---

*Script versie: November 2025 - Verbeterd met robuuste foutafhandeling en pad-validatie*
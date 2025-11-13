# Team Scripts Overzicht - Weekmail Generators

Dit overzicht toont alle beschikbare weekmail generator scripts voor de verschillende teams.

## 📋 Beschikbare Team Scripts

| Team | Script Bestand | Sjabloon Bestand | Uitvoermap |
|------|----------------|------------------|------------|
| **Flex** | `Weekmail-Generator-Flex.ps1` | `sjabloonWM.aspx` | `\Flex\SitePages\` |
| **FlitsSV** | `Weekmail-Generator-FlitsSV.ps1` | `SjabloonWM-SVFlits.aspx` | `\FlitsSV\SitePages\` |
| **Parkeren** | `Weekmail-Generator-Parkeren.ps1` | `SjabloonWM.aspx` | `\Parkeren\SitePages\` |
| **Rijgedrag** | `Weekmail-Generator-Rijgedrag.ps1` | `SjabloonWM.aspx` | `\Rijgedrag\SitePages\` |
| **SVZichtPlicht** | `Weekmail-Generator-SVZichtPlicht.ps1` | `SjabloonWM.aspx` | `\SVZichtPlicht\SitePages\` |
| **Verkeersborden** | `Weekmail-Generator-Verkeersborden.ps1` | `SjabloonWM-Verkeersborden.aspx` | `\Verkeersborden\SitePages\` |

## 🚀 Gebruik van de Scripts

### Voor elk team:

```powershell
# Normaal uitvoeren
.\Weekmail-Generator-[TEAM].ps1

# Dry-run modus (veilig testen)
.\Weekmail-Generator-[TEAM].ps1 -DryRun
```

### Voorbeelden:

```powershell
# Voor team Flex
.\Weekmail-Generator-Flex.ps1

# Voor team Verkeersborden (dry-run)
.\Weekmail-Generator-Verkeersborden.ps1 -DryRun

# Voor team Parkeren
.\Weekmail-Generator-Parkeren.ps1
```

## 📁 Verwachte Mappenstructuur per Team

Elk team script verwacht de volgende structuur:

```
\\som.org.om.local@SSL\DavWWWRoot\sites\MulderT\Onderdelen\Beoordelen\
├── [TEAMNAAM]\
│   └── SitePages\
│       ├── Sjabloon\
│       │   └── [SJABLOON-BESTAND]     # Zie tabel hierboven
│       └── [Nieuwe weekmails hier]    # Uitvoerlocatie
```

## ⚙️ Configuratie Verschillen per Team

### Flex
- **Sjabloon**: `sjabloonWM.aspx`
- **Uitvoer**: `\Flex\SitePages\Sjabloon\` ⚠️ *Let op: uitvoer in Sjabloon map*

### FlitsSV  
- **Sjabloon**: `SjabloonWM-SVFlits.aspx`
- **Uitvoer**: `\FlitsSV\SitePages\`

### Parkeren
- **Sjabloon**: `SjabloonWM.aspx`
- **Uitvoer**: `\Parkeren\SitePages\`

### Rijgedrag
- **Sjabloon**: `SjabloonWM.aspx`
- **Uitvoer**: `\Rijgedrag\SitePages\`

### SVZichtPlicht
- **Sjabloon**: `SjabloonWM.aspx`
- **Uitvoer**: `\SVZichtPlicht\SitePages\`

### Verkeersborden
- **Sjabloon**: `SjabloonWM-Verkeersborden.aspx`
- **Uitvoer**: `\Verkeersborden\SitePages\`

## 🛡️ Beveiliging en Validatie

Alle scripts bevatten:
- ✅ **Bestandsoverschrijving controle** - Vraagt bevestiging bij bestaande bestanden
- ✅ **Pad-validatie** - Controleert UNC-naar-URL conversies
- ✅ **SharePoint API foutafhandeling** - Defensieve checks op responses
- ✅ **URL-validatie** - Controleert gegenereerde URLs
- ✅ **Dry-run modus** - Veilig testen zonder wijzigingen

## 📋 Uitvoerformaat

Elk script genereert bestanden met deze naamgeving:
```
Weekmail---Jaar-[JAAR]---Week-[WEEK]---[TEAMNAAM].aspx
```

**Voorbeelden:**
- `Weekmail---Jaar-2025---Week-46---Flex.aspx`
- `Weekmail---Jaar-2025---Week-46---Verkeersborden.aspx`
- `Weekmail---Jaar-2025---Week-46---FlitsSV.aspx`

## 🏷️ SharePoint Titels

De scripts stellen automatisch de SharePoint titel in als:
```
Weekmail [WEEK] ([JAAR]) - [TEAMNAAM]
```

**Voorbeelden:**
- `Weekmail 46 (2025) - Flex`
- `Weekmail 46 (2025) - Verkeersborden`
- `Weekmail 46 (2025) - FlitsSV`

## 📞 Ondersteuning

Bij problemen:
1. **Controleer toegang** tot team-specifieke SharePoint-mappen
2. **Gebruik dry-run modus** eerst: `.\script.ps1 -DryRun`
3. **Controleer sjabloon** bestaat in `\Sjabloon\` map
4. **Zie README.md** voor uitgebreide troubleshooting

---

*Alle scripts gebaseerd op het originele `Oki` script - Verbeterd met robuuste foutafhandeling en team-specifieke configuraties*
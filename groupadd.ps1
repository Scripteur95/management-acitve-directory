Import-Module ActiveDirectory

$root = "DC=scripting,DC=lan"
$usersContainer = "CN=Users,$root"

function Build-LdapPath {
    param([string]$ouInput)

    if ([string]::IsNullOrWhiteSpace($ouInput) -or $ouInput.ToLower() -eq "users" -or $ouInput.ToLower() -match "^scripting(\.lan)?$") {
        # Container Users par défaut
        return $usersContainer
    } else {
        # Construction classique OU=...,OU=...,DC=...
        $parts = $ouInput -split "\s+"
        $ouParts = $parts | ForEach-Object { "OU=$_" }
        [array]::Reverse($ouParts)
        return ($ouParts -join ",") + "," + $root
    }
}

function Create-Group {
    $groupName = Read-Host "Nom du groupe a creer"
    $groupScope = Read-Host "Portee du groupe (Global, Universal, DomainLocal) [Global par defaut]"
    if ([string]::IsNullOrWhiteSpace($groupScope)) { $groupScope = "Global" }
    elseif ($groupScope -notin @("Global", "Universal", "DomainLocal")) {
        Write-Host "Portée invalide, utilisation de 'Global' par defaut."
        $groupScope = "Global"
    }
    $groupCategory = Read-Host "Categorie du groupe (Security ou Distribution) [Security par defaut]"
    if ([string]::IsNullOrWhiteSpace($groupCategory)) { $groupCategory = "Security" }
    elseif ($groupCategory.ToLower() -notin @("security", "distribution")) {
        Write-Host "Catégorie invalide, utilisation de 'Security' par defaut."
        $groupCategory = "Security"
    }
    $ouInput = Read-Host "Nom OU (parent) ou laisser vide pour container Users par defaut"

    $ouPath = Build-LdapPath $ouInput

    # Vérifier que l'OU ou container existe (sauf si container Users)
    if ($ouPath -ne $usersContainer) {
        try {
            $ouExist = Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop
        } catch {
            Write-Host "L'OU spécifiée n'existe pas : $ouPath"
            return
        }
    }

    try {
        New-ADGroup -Name $groupName `
                    -GroupScope $groupScope `
                    -GroupCategory $groupCategory `
                    -Path $ouPath
        Write-Host "Groupe cree : $groupName dans $ouPath"
    } catch {
        Write-Host "Erreur creation groupe : $_"
    }
}

function Remove-Group {
    $groupName = Read-Host "Nom du groupe a supprimer"
    try {
        Remove-ADGroup -Identity $groupName -Confirm:$false
        Write-Host "Groupe supprime : $groupName"
    } catch {
        Write-Host "Erreur suppression groupe : $_"
    }
}

function Rename-Group {
    $oldName = Read-Host "Nom actuel du groupe"
    $newName = Read-Host "Nouveau nom du groupe"
    try {
        $group = Get-ADGroup -Identity $oldName -ErrorAction Stop
        Rename-ADObject -Identity $group.DistinguishedName -NewName $newName
        Write-Host "Groupe renommé de '$oldName' en '$newName'"
    } catch {
        Write-Host "Erreur renommage groupe : $_"
    }
}

function Export-Groups {
    $exportPath = Read-Host "Chemin complet du fichier CSV (ex: C:\\temp\\groups.csv)"
    try {
        Get-ADGroup -Filter * -SearchBase $root |
            Select-Object Name,GroupScope,GroupCategory |
            Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Export termine : $exportPath"
    } catch {
        Write-Host "Erreur export groupes : $_"
    }
}

function Show-Groups {
    Write-Host "`n=== Liste des Groupes ===`n"
    Get-ADGroup -Filter * -SearchBase $root | ForEach-Object {
        Write-Host "$($_.Name) - Scope: $($_.GroupScope) - Categorie: $($_.GroupCategory)"
    }
}

do {
    Write-Host "`n=== Gestion des Groupes Active Directory ==="
    Write-Host "1) Creer un groupe"
    Write-Host "2) Supprimer un groupe"
    Write-Host "3) Renommer un groupe"
    Write-Host "4) Exporter les groupes"
    Write-Host "5) Afficher la liste des groupes"
    Write-Host "Q) Quitter"
    $choix = Read-Host "Choix 1 2 3 4 5 ou Q pour quitter"

    switch ($choix.ToLower()) {
        "1" { Create-Group }
        "2" { Remove-Group }
        "3" { Rename-Group }
        "4" { Export-Groups }
        "5" { Show-Groups }
        "q" { Write-Host "Au revoir !"; break }
        default { Write-Host "Choix invalide." }
    }

} while ($true)

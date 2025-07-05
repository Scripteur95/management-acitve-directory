Import-Module ActiveDirectory

$root = "DC=scripting,DC=lan"
$usersContainer = "CN=Users,$root"

function Write-Header($text) {
    Clear-Host
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
}

function Pause() {
    Write-Host ""
    Write-Host "Appuyez sur une touche pour continuer..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Build-LdapPathOU {
    param([string]$ouInput)

    if ([string]::IsNullOrWhiteSpace($ouInput) -or $ouInput -match "^scripting(\.lan)?$") {
        return $root
    } else {
        $parts = $ouInput -split "\s+"
        $ouParts = $parts | ForEach-Object { "OU=$_" }
        [array]::Reverse($ouParts)
        return ($ouParts -join ",") + ",$root"
    }
}

function Build-LdapPath {
    param([string]$ouInput)

    if ([string]::IsNullOrWhiteSpace($ouInput) -or $ouInput.ToLower() -eq "users" -or $ouInput.ToLower() -match "^scripting(\.lan)?$") {
        return $usersContainer
    } else {
        $parts = $ouInput -split "\s+"
        $ouParts = $parts | ForEach-Object { "OU=$_" }
        [array]::Reverse($ouParts)
        return ($ouParts -join ",") + ",$root"
    }
}

# === Utilisateurs ===

function Create-User {
    Write-Header "Ajouter un utilisateur"
    $prenom = Read-Host "Prenom"
    $nom = Read-Host "Nom"
    $sam = Read-Host "Identifiant"
    if ([string]::IsNullOrWhiteSpace($sam) -or $sam.Contains(" ")) {
        Write-Host "Identifiant invalide"
        Pause
        return
    }
    $pwd = Read-Host "Mot de passe" -AsSecureString
    $ouInput = Read-Host "Nom OU (laisser vide pour container Users)"
    $ouPath = Build-LdapPath $ouInput

    try {
        New-ADUser -Name "$prenom $nom" -GivenName $prenom -Surname $nom -SamAccountName $sam -AccountPassword $pwd -Enabled $true -Path $ouPath
        Write-Host "Utilisateur cree"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Remove-User {
    Write-Header "Supprimer un utilisateur"
    $sam = Read-Host "Identifiant"
    try {
        Remove-ADUser -Identity $sam -Confirm:$false
        Write-Host "Utilisateur supprime"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Change-UserPassword {
    Write-Header "Modifier mot de passe"
    $sam = Read-Host "Identifiant"
    $newPwd = Read-Host "Nouveau mot de passe" -AsSecureString
    try {
        Set-ADAccountPassword -Identity $sam -NewPassword $newPwd -Reset
        Write-Host "Mot de passe modifie"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Show-Users {
    Write-Header "Liste des utilisateurs"
    Get-ADUser -Filter * -SearchBase $root | ForEach-Object {
        Write-Host "$($_.SamAccountName) - $($_.Name)"
    }
    Pause
}

function Export-Users {
    Write-Header "Exporter utilisateurs"
    $path = Read-Host "Chemin du fichier CSV"
    try {
        Get-ADUser -Filter * -SearchBase $root | Select-Object Name,SamAccountName,UserPrincipalName | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        Write-Host "Export termine"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

# === Groupes ===

function Create-Group {
    Write-Header "Creer un groupe"
    $name = Read-Host "Nom du groupe"
    $scope = Read-Host "Portee (Global/Universal/DomainLocal)"
    if ($scope -notin @("Global","Universal","DomainLocal")) { $scope = "Global" }
    $category = Read-Host "Categorie (Security/Distribution)"
    if ($category -notin @("Security","Distribution")) { $category = "Security" }
    $ouInput = Read-Host "Nom OU (laisser vide pour Users)"
    $ouPath = Build-LdapPath $ouInput

    try {
        New-ADGroup -Name $name -GroupScope $scope -GroupCategory $category -Path $ouPath
        Write-Host "Groupe cree"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Remove-Group {
    Write-Header "Supprimer un groupe"
    $name = Read-Host "Nom du groupe"
    try {
        Remove-ADGroup -Identity $name -Confirm:$false
        Write-Host "Groupe supprime"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Rename-Group {
    Write-Header "Renommer un groupe"
    $old = Read-Host "Nom actuel"
    $new = Read-Host "Nouveau nom"
    try {
        $group = Get-ADGroup -Identity $old -ErrorAction Stop
        Rename-ADObject -Identity $group.DistinguishedName -NewName $new
        Write-Host "Groupe renomme"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Show-Groups {
    Write-Header "Liste des groupes"
    Get-ADGroup -Filter * -SearchBase $root | ForEach-Object {
        Write-Host "$($_.Name) - $($_.GroupScope) - $($_.GroupCategory)"
    }
    Pause
}

function Export-Groups {
    Write-Header "Exporter groupes"
    $path = Read-Host "Chemin fichier CSV"
    try {
        Get-ADGroup -Filter * -SearchBase $root | Select-Object Name,GroupScope,GroupCategory | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        Write-Host "Export termine"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

# === OU ===

function Create-OU {
    Write-Header "Creer une OU"
    $name = Read-Host "Nom OU"
    $parent = Read-Host "Nom OU parent (vide pour racine)"
    $path = Build-LdapPathOU $parent
    try {
        New-ADOrganizationalUnit -Name $name -Path $path
        Write-Host "OU creee"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Remove-OU {
    Write-Header "Supprimer une OU"
    $ou = Read-Host "Chemin complet de l'OU (ex: OU=Test,OU=Parent)"
    $path = "$ou,$root"
    try {
        Remove-ADOrganizationalUnit -Identity $path -Confirm:$false
        Write-Host "OU supprimee"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Rename-OU {
    Write-Header "Renommer une OU"
    $old = Read-Host "OU actuelle (ex: OU=Old,OU=Parent)"
    $new = Read-Host "Nouveau nom"
    try {
        Rename-ADObject -Identity "$old,$root" -NewName $new
        Write-Host "OU renommee"
    } catch {
        Write-Host "Erreur: $_"
    }
    Pause
}

function Show-OUs {
    Write-Header "Liste des OU"
    Get-ADOrganizationalUnit -Filter * -SearchBase $root | ForEach-Object {
        Write-Host $_.DistinguishedName
    }
    Pause
}

# === Menus ===

function Menu-Users {
    do {
        Write-Host "\n--- Utilisateurs ---"
        Write-Host "1) Ajouter"
        Write-Host "2) Supprimer"
        Write-Host "3) Mot de passe"
        Write-Host "4) Export"
        Write-Host "5) Afficher"
        Write-Host "6) Retour menu principal"
        $c = Read-Host "Choix"
        switch ($c) {
            "1" { Create-User }
            "2" { Remove-User }
            "3" { Change-UserPassword }
            "4" { Export-Users }
            "5" { Show-Users }
            "6" { return }
            default { Write-Host "Choix invalide" }
        }
    } while ($true)
}

function Menu-Groups {
    do {
        Write-Host "\n--- Groupes ---"
        Write-Host "1) Ajouter"
        Write-Host "2) Supprimer"
        Write-Host "3) Renommer"
        Write-Host "4) Export"
        Write-Host "5) Afficher"
        Write-Host "6) Retour menu principal"
        $c = Read-Host "Choix"
        switch ($c) {
            "1" { Create-Group }
            "2" { Remove-Group }
            "3" { Rename-Group }
            "4" { Export-Groups }
            "5" { Show-Groups }
            "6" { return }
            default { Write-Host "Choix invalide" }
        }
    } while ($true)
}

function Menu-OUs {
    do {
        Write-Host "\n--- OU ---"
        Write-Host "1) Ajouter"
        Write-Host "2) Supprimer"
        Write-Host "3) Renommer"
        Write-Host "4) Afficher"
        Write-Host "6) Retour menu principal"
        $c = Read-Host "Choix"
        switch ($c) {
            "1" { Create-OU }
            "2" { Remove-OU }
            "3" { Rename-OU }
            "4" { Show-OUs }
            "6" { return }
            default { Write-Host "Choix invalide" }
        }
    } while ($true)
}

# === Principal ===

do {
    Write-Header "Menu Principal"
    Write-Host "1) Utilisateurs"
    Write-Host "2) Groupes"
    Write-Host "3) OU"
    Write-Host "6) Quitter"
    $main = Read-Host "Choix"
    switch ($main) {
        "1" { Menu-Users }
        "2" { Menu-Groups }
        "3" { Menu-OUs }
        "6" { break }
        default { Write-Host "Choix invalide" }
    }
} while ($true)

Import-Module ActiveDirectory

$root = "DC=scripting,DC=lan"
$usersContainer = "CN=Users,$root"

function Create-User {
    $prenom = Read-Host "Prenom"
    $nom = Read-Host "Nom"
    $samAccountName = Read-Host "Identifiant (samAccountName)"
    if ([string]::IsNullOrWhiteSpace($samAccountName) -or $samAccountName.Contains(" ")) {
        Write-Host "Identifiant invalide : ne doit pas etre vide ni contenir d'espaces."
        return
    }
    $password = Read-Host "Mot de passe" -AsSecureString

    try {
        New-ADUser -Name "$prenom $nom" `
            -GivenName $prenom `
            -Surname $nom `
            -SamAccountName $samAccountName `
            -AccountPassword $password `
            -Enabled $true `
            -Path $usersContainer

        Write-Host "Utilisateur cree dans le container 'Users' : $prenom $nom"

        $group = Get-ADGroup -Identity "Users" -ErrorAction SilentlyContinue
        if ($null -ne $group) {
            Add-ADGroupMember -Identity $group -Members $samAccountName
            Write-Host "Utilisateur ajoute au groupe 'Users'."
        } else {
            Write-Host "Groupe 'Users' introuvable. L'utilisateur a ete cree sans ajout au groupe."
        }
    } catch {
        Write-Host "Erreur creation utilisateur : $_"
    }
}

function Remove-User {
    $samAccountName = Read-Host "samAccountName de l'utilisateur a supprimer"
    try {
        Remove-ADUser -Identity $samAccountName -Confirm:$false
        Write-Host "Utilisateur supprime : $samAccountName"
    } catch {
        Write-Host "Erreur suppression : $_"
    }
}

function Change-UserPassword {
    $samAccountName = Read-Host "samAccountName de l'utilisateur"
    $newPassword = Read-Host "Nouveau mot de passe" -AsSecureString
    try {
        Set-ADAccountPassword -Identity $samAccountName -NewPassword $newPassword -Reset
        Write-Host "Mot de passe modifie pour : $samAccountName"
    } catch {
        Write-Host "Erreur modification mot de passe : $_"
    }
}

function Export-Users {
    $exportPath = Read-Host "Chemin complet du fichier CSV (ex: C:\\temp\\users.csv)"
    try {
        Get-ADUser -Filter * -SearchBase $root -Properties Name,SamAccountName,UserPrincipalName |
            Select-Object Name,SamAccountName,UserPrincipalName |
            Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Export termine : $exportPath"
    } catch {
        Write-Host "Erreur export : $_"
    }
}

function Show-Users {
    Write-Host "`n=== Liste des Utilisateurs ===`n"
    Get-ADUser -Filter * -SearchBase $root | ForEach-Object {
        Write-Host "$($_.SamAccountName) - $($_.Name)"
    }
}

do {
    Write-Host "`n=== Gestion des Utilisateurs Active Directory ==="
    Write-Host "1) Ajouter un utilisateur"
    Write-Host "2) Supprimer un utilisateur"
    Write-Host "3) Modifier mot de passe"
    Write-Host "4) Exporter les utilisateurs"
    Write-Host "5) Afficher la liste des utilisateurs"
    Write-Host "Q) Quitter"
    $choix = Read-Host "Choix 1 2 3 4 5 ou Q pour quitter"

    switch ($choix.ToLower()) {
        "1" { Create-User }
        "2" { Remove-User }
        "3" { Change-UserPassword }
        "4" { Export-Users }
        "5" { Show-Users }
        "q" { Write-Host "Au revoir !"; break }
        default { Write-Host "Choix invalide." }
    }

} while ($true)


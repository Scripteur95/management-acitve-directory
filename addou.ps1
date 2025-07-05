Import-Module ActiveDirectory

$root = "DC=scripting,DC=lan"

function Build-LdapPath {
    param([string[]]$parts)
    $ouParts = $parts | ForEach-Object { "OU=$_" }
    [array]::Reverse($ouParts)
    return ($ouParts -join ",") + "," + $root
}

function Remove-OURecursively {
    param([string]$ouDN)

    $children = Get-ADObject -Filter * -SearchBase $ouDN -SearchScope OneLevel

    foreach ($child in $children) {
        if ($child.ObjectClass -eq "organizationalUnit") {
            Remove-OURecursively -ouDN $child.DistinguishedName
        } else {
            Remove-ADObject -Identity $child.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    Set-ADOrganizationalUnit -Identity $ouDN -ProtectedFromAccidentalDeletion $false

    Remove-ADOrganizationalUnit -Identity $ouDN -Confirm:$false
}

do {
    Write-Host "`n=== Gestion Active Directory ==="
    Write-Host "1) Creer une OU"
    Write-Host "2) Supprimer une OU"
    Write-Host "3) Deplacer une OU"
    Write-Host "4) Exporter les utilisateurs"
    Write-Host "5) Afficher OU et utilisateurs"
    Write-Host "Q) Quitter"
    $choix = Read-Host "Choix 1 2 3 4 5 ou Q pour quitter"

    switch ($choix.ToLower()) {
        "1" {
            $ouName = Read-Host "Nom de l'OU a creer"
            $parentInput = Read-Host "Nom OU parent"
            if ([string]::IsNullOrWhiteSpace($parentInput) -or $parentInput -match "^scripting(\.lan)?$") {
                $path = $root
            } else {
                $parts = $parentInput -split "\s+"
                $path = Build-LdapPath $parts
            }

            try {
                New-ADOrganizationalUnit -Name $ouName -Path $path
                Write-Host "OU creee : $ouName"
            } catch {
                Write-Host "Erreur : $_"
            }
        }
        "2" {
            $ouName = Read-Host "Nom de l'OU a supprimer"
            $ous = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $root -SearchScope Subtree
            if ($ous.Count -eq 0) {
                Write-Host "OU introuvable : $ouName"
                continue
            }

            foreach ($ou in $ous) {
                try {
                    Remove-OURecursively -ouDN $ou.DistinguishedName
                    Write-Host "OU supprimee : $($ou.DistinguishedName)"
                } catch {
                    Write-Host "Erreur suppression : $_"
                }
            }
        }
        "3" {
            $ouName = Read-Host "Nom de l'OU a deplacer"
            $targetInput = Read-Host "Nom OU destination"

            $ous = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $root -SearchScope Subtree
            if ($ous.Count -eq 0) {
                Write-Host "OU introuvable : $ouName"
                continue
            }
            $ou = $ous[0]

            if ([string]::IsNullOrWhiteSpace($targetInput) -or $targetInput -match "^scripting(\.lan)?$") {
                $targetPath = $root
            } else {
                $parts = $targetInput -split "\s+"
                $targetPath = Build-LdapPath $parts

                $exists = Get-ADOrganizationalUnit -Filter * -Identity $targetPath -ErrorAction SilentlyContinue
                if ($null -eq $exists) {
                    Write-Host "OU destination inexistante."
                    continue
                }
            }

            try {
                Set-ADOrganizationalUnit -Identity $ou.DistinguishedName -ProtectedFromAccidentalDeletion $false
                Move-ADObject -Identity $ou.DistinguishedName -TargetPath $targetPath
                Write-Host "OU deplacee : $ouName"
            } catch {
                Write-Host "Erreur : $_"
            }
        }
        "4" {
            $exportPath = Read-Host "Chemin complet du fichier CSV (ex: C:\\temp\\users.csv)"
            try {
                Get-ADUser -Filter * -SearchBase $root -Properties Name,SamAccountName,UserPrincipalName |
                    Select-Object Name,SamAccountName,UserPrincipalName |
                    Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                Write-Host "Export termine : $exportPath"
            } catch {
                Write-Host "Erreur : $_"
            }
        }
        "5" {
            Write-Host "`n=== Liste des OU ===`n"
            Get-ADOrganizationalUnit -Filter * -SearchBase $root -SearchScope Subtree | ForEach-Object {
                Write-Host $_.DistinguishedName
            }
            Write-Host "`n=== Liste des Utilisateurs ===`n"
            Get-ADUser -Filter * -SearchBase $root | ForEach-Object {
                Write-Host "$($_.SamAccountName) - $($_.Name)"
            }
        }
        "q" {
            Write-Host "Au revoir !"
            break
        }
        default {
            Write-Host "Choix invalide."
        }
    }

} while ($true)

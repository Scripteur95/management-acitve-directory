# management-acitve-directory version beta
Bienvenue dans ce projet de scripts PowerShell pour la gestion et l’automatisation d’Active Directory.

---

## Sommaire

- [Installation de Git](#installation-de-git)  
- [Cloner ce dépôt](#cloner-ce-dépôt)  
- [Utilisation](#utilisation)  
- [Contribuer](#contribuer)  
- [Support](#support)

---

## Installation de Git

Avant d’utiliser ce projet, il est nécessaire d’avoir Git installé sur votre machine.

### Sur Windows Server 2022 TESTER SUR une VM POUR l INSTANT

1. Ouvrez **PowerShell en mode Administrateur**.
2. Exécutez le script suivant pour télécharger et installer Git (64-bit) automatiquement :

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"
$installerPath = "$env:TEMP\GitInstaller.exe"

Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/SILENT" -Wait
Remove-Item $installerPath
```
#Powershell en administrateur cloner le git :
```
git clone https://github.com/Scripteur95/management-acitve-directory
```
#donner les droit d'executer le script :
```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
##puis lancer le script :
```
cd C:\management-acitve-directory
./main.ps1
```

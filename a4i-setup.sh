#!/bin/bash

echo "
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║      🚀 A4I Setup - Addons Installation Script v0.1 🚀        ║
║                       Version : 0.1                           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"

# Check prerequisites
check_prerequisites() {
    echo "🔍 Vérification des prérequis..."
    echo "+---------------------------------------+"
    echo "|         Points de contrôle            |"
    echo "+---------------------------------------+"
    
    local status=0
    
    # Check OS
    echo -n "| 1. OS Ubuntu          | "
    if grep -q "Ubuntu" /etc/os-release; then
        echo "✅"
    else
        echo "❌"
        status=1
    fi
    
    # Check ubuntu version
    echo -n "| 2. Version supportée  | "
    version=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release)
    if [[ "$version" == "18.04" || "$version" == "20.04" || "$version" == "22.04" ]]; then
        echo "✅ ($version)"
    else
        echo "❌ ($version)"
        echo "|    Versions supportées : 18.04, 20.04, 22.04"
        status=1
    fi
    
    # Check OpenProd Home folder
    echo -n "| 3. Dossier OpenProd  | "
    if [ -d "/etc/openprod_home" ]; then
        echo "✅"
    else
        echo "❌"
        status=1
    fi
    
    echo "+-------------------------+"
    
    if [ $status -eq 0 ]; then
        echo "✅ Tous les prérequis sont satisfaits"
    else
        echo "❌ Certains prérequis ne sont pas satisfaits"
    fi
    return $status
}

# Check OpenProd server config file and update addons_path if not already present
check_openprod_config() {
    local config_file="$HOME/openprod-server.conf"
    local backup_file="$HOME/openprod-server.conf.backup"
    local addons_path="$root_folder"
    echo
    echo "🔍 Vérification de la configuration OpenProd..."
    echo "+---------------------------------------+"
    echo "|      Configuration OpenProd           |"
    echo "+---------------------------------------+"
    
    # Check OpenProd server config file
    echo -n "| 1. Fichier de configuration OpenProd   | "
    if [ ! -f "$config_file" ]; then
        echo "❌"
        echo "| ❌ Erreur: $config_file non trouvé"
        echo "+---------------------------------------+"
        return 1
    fi
    echo "✅"

    # Check if our path is already in addons_path
    echo -n "| 2. Addons path a4i-addons             | "
    if grep -q "addons_path.*$addons_path" "$config_file"; then
        echo "✅"
        echo "+---------------------------------------+"
        return 0
    fi
    echo "➕"

    # Create backup before modification
    echo -n "| 3. Backup of the configuration   | "
    if cp "$config_file" "$backup_file"; then
        echo "✅"
        echo "| ℹ️  Backup créée: $backup_file"
    else
        echo "❌"
        echo "| ❌ Erreur: Impossible de créer la backup"
        echo "+---------------------------------------+"
        return 1
    fi

    # Check OpenProd server config file
    echo -n "| 4. Configuration OpenProd       | "
    if ! grep -q "^\[options\]" "$config_file" || ! grep -q "^addons_path" "$config_file"; then
        echo "❌"
        echo "| ❌ Erreur: Configuration OpenProd invalide"
        echo "| ℹ️  Le fichier doit contenir [options] et addons_path"
        echo "+---------------------------------------+"
        return 1
    fi
    echo "✅"

    # Add our path to addons_path
    sed -i "s|^addons_path.*|&,$addons_path|" "$config_file"
    echo "| ✅ Chemin des addons A4I ajouté"
    echo "+---------------------------------------+"
    return 0
}

# Define root folder for modules
root_folder="$HOME/a4i-addons"
echo "ℹ️  Dossier racine des modules : $root_folder"
echo

# Create root folder if it doesn't exist
mkdir -p "$root_folder"

while true; do
    echo "+---------------------------------------+"
    echo "|            Menu Principal             |"
    echo "+---------------------------------------+"
    echo "| 1) Installation de module             |"
    echo "| 2) Mise à jour de module              |"
    echo "| S) Sortie                             |"
    echo "+---------------------------------------+"
    echo
    read -p "Votre choix : " menu_choice
    echo

    case $menu_choice in
        1)
            # Check prerequisites before continuing
            if ! check_prerequisites; then
                echo
                continue
            fi
            echo

            # Predefined list of modules
            declare -a module_order=(1 2 3 4)
            declare -A module_names=(
                [1]="Vehicle Fleet Manager (Gestion de flotte automobile) - Public"
                [2]="Administrative Contract (Contrat administratif) - Public"
                [3]="Cron monitoring (Monitoring des cron jobs) - Public"
                [4]="Docuseal (Signature électronique via Docuseal) - Private"
            )
            declare -A module_urls=(
                [1]="App4indus/vehicle_fleet_manager"
                [2]="App4indus/administrative_contract"
                [3]="App4indus/cron_monitoring"
                [4]="App4indus/docuseal"
            )

            # Display available modules
            echo "+------------------------------------------------------------------+"
            echo "|                           Modules A4I                            |"
            echo "+------------------------------------------------------------------+"
            for i in "${module_order[@]}"; do
                printf "| %s) %-13s \n" "$i" "${module_names[$i]}"
            done
            echo "| 0) Autre module                                                  |"
            echo "| R) Retour au menu                                                |"
            echo "+------------------------------------------------------------------+"
            echo

            # Select module
            read -p "Sélectionnez un module : " selection

            # Manage selection
            if [ "$selection" = "R" ] || [ "$selection" = "r" ]; then
                echo "Retour au menu principal..."
                echo
                continue
            elif [ "$selection" = "0" ]; then
                read -p "Entrez l'URL du dépôt GitHub (format: utilisateur/repo) : " repo
                read -p "Entrez le nom du module : " module_name
            else
                if [ -n "${module_urls[$selection]}" ]; then
                    repo=${module_urls[$selection]}
                    module_name=${module_names[$selection]}
                else
                    echo "❌ Sélection invalide"
                    echo
                    continue
                fi
            fi

            # Extract repo name for folder
            repo_name=$(echo "$repo" | cut -d'/' -f2)
            dest_folder="$root_folder/$repo_name"

            echo "Module sélectionné : $module_name"
            echo "Dossier d'installation : $dest_folder"
            echo

            # Demande du PAT (Personnal Acess Token)
            echo "🔑 GitHub Personal Access Token (PAT)"
            echo "   - Requis pour les dépôts privés"
            echo "   - Laissez vide pour les dépôts publics"
            read -p "> " pat

            # Build URL with PAT
            if [ -n "$pat" ]; then
                repo_url="https://$pat@github.com/$repo.git"
            else
                repo_url="https://github.com/$repo.git"
            fi

            # Check if destination folder exists
            if [ -d "$dest_folder/.git" ]; then
                echo "📦 Le module existe déjà. Mise à jour..."
                cd "$dest_folder"
                
                # Save local modifications if they exist 
                if [ -n "$(git status --porcelain)" ]; then
                    echo "💾 Local modifications detected. Saving..."
                    git stash
                fi
                
                # Update repo
                if git pull origin main || git pull origin master; then
                    echo "✅ Mise à jour réussie!"
                else
                    echo "❌ Erreur lors de la mise à jour"
                    echo
                    continue
                fi
            else
                echo "📥 Téléchargement du module..."
                # Clone repo
                if git clone "$repo_url" "$dest_folder"; then
                    echo "✅ Installation réussie!"
                    check_openprod_config
                else
                    echo "❌ Erreur lors de l'installation"
                    echo
                    continue
                fi
            fi

            if [ -n "$pat" ]; then
                history -c
            fi
            echo "Opération terminée."
            echo
            ;;
        2)
            # Check prerequisites before continuing
            if ! check_prerequisites; then
                echo
                continue
            fi
            echo

            # Check if modules are installed
            if [ ! -d "$root_folder" ] || [ -z "$(ls -A $root_folder)" ]; then
                echo "❌ Aucun module n'est installé dans $root_folder"
                echo
                continue
            fi

            # List of installed modules
            echo "+---------------------------------------+"
            echo "|         Modules installés             |"
            echo "+---------------------------------------+"
            
            # Create associative array for installed modules
            declare -A installed_modules
            i=1
            for d in "$root_folder"/*/ ; do
                if [ -d "$d/.git" ]; then
                    module_name=$(basename "$d")
                    installed_modules[$i]="$module_name"
                    printf "| %s) %-35s |\n" "$i" "$module_name"
                    ((i++))
                fi
            done
            echo "| R) Retour au menu                     |"
            echo "+---------------------------------------+"
            echo

            # Select module to update
            read -p "Sélectionnez un module à mettre à jour : " selection

            if [ "$selection" = "R" ] || [ "$selection" = "r" ]; then
                echo "Retour au menu principal..."
                echo
                continue
            fi

            if [ -n "${installed_modules[$selection]}" ]; then
                module_name=${installed_modules[$selection]}
                dest_folder="$root_folder/$module_name"
                
                echo "📦 Mise à jour du module : $module_name"
                cd "$dest_folder"
                
                # Save local modifications if they exist
                if [ -n "$(git status --porcelain)" ]; then
                    echo "💾 Des modifications locales ont été détectées. Sauvegarde..."
                    git stash
                fi
                
                # Update repo
                if git pull origin main || git pull origin master; then
                    echo "✅ Mise à jour réussie!"
                    check_openprod_config
                else
                    echo "❌ Erreur lors de la mise à jour"
                fi
            else
                echo "❌ Sélection invalide"
            fi
            echo
            ;;
        S | s)
            echo "Au revoir ! 👋"
            exit 0
            ;;
        *)
            echo "❌ Option invalide. Veuillez choisir 1, 2 ou S."
            echo
            ;;
    esac
done
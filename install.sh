#!/bin/bash

# install.sh
cd "$(dirname "$0")"
program_path=$(pwd)
cp etc/pong_bot.tmp etc/pong_bot.service
cp etc/mesh_bot.tmp etc/mesh_bot.service
cp etc/mesh_bot_reporting.tmp etc/mesh_bot_reporting.service

printf "\nMeshing Around Installer\n"
printf "\nThis script will install the Meshing Around bot and its dependencies works best in debian/ubuntu\n"
printf "\nChecking for dependencies\n"


# add user to groups for serial access
printf "\nAdding user to dialout and tty groups for serial access\n"
sudo usermod -a -G dialout $USER
sudo usermod -a -G tty $USER
sudo usermod -a -G bluetooth $USER

# check for pip
if ! command -v pip &> /dev/null
then
    printf "pip not found, please install pip with your OS\n"
    sudo apt-get install python3-pip
else
    printf "python pip found\n"
fi

# generate config file, check if it exists
if [ -f config.ini ]; then
    printf "\nConfig file already exists, moving to backup config.old\n"
    mv config.ini config.old
fi

cp config.template config.ini
printf "\nConfig file generated\n"


# set virtual environment and install dependencies
printf "\nMeshing Around Installer\n"

echo "Do you want to install the bot in a virtual environment? (y/n)"
read venv

if [ $venv == "y" ]; then
    # set virtual environment
    if ! python3 -m venv --help &> /dev/null; then
        printf "Python3 venv module not found, please install python3-venv with your OS\n"
        exit 1
    else
        echo "Creating virtual environment..."
        python3 -m venv venv
        source venv/bin/activate

        #check if python3 has venv module
        if [ -f venv/bin/activate ]; then
            printf "\nFpund virtual environment for python\n"
        else
            sudo apt-get install python3-venv
            printf "\nPython3 venv module not found, please install python3-venv with your OS if not already done. re-run the script\n"
            exit 1
        fi

        # config service files for virtual environment
        replace="s|python3 mesh_bot.py|/usr/bin/bash launch.sh mesh|g"
        sed -i "$replace" etc/mesh_bot.service
        replace="s|python3 pong_bot.py|/usr/bin/bash launch.sh pong|g"
        sed -i "$replace" etc/pong_bot.service

        # install dependencies
        pip install -U -r requirements.txt
    fi
else
    printf "\nSkipping virtual environment...\n"
    # install dependencies
    printf "Are you on Raspberry Pi(debian/ubuntu)?\nshould we add --break-system-packages to the pip install command? (y/n)"
    read rpi
    if [ $rpi == "y" ]; then
        pip install -U -r requirements.txt --break-system-packages
    else
        pip install -U -r requirements.txt
    fi
fi

printf "\n\n"
echo "Which bot do you want to install as a service? Pong Mesh or None? (pong/mesh/n)"
read bot

# set the correct path in the service file
replace="s|/dir/|$program_path/|g"
sed -i $replace etc/pong_bot.service
sed -i $replace etc/mesh_bot.service
sed -i $replace etc/mesh_bot_reporting.service
# set the correct user in the service file?
whoami=$(whoami)
replace="s|User=pi|User=$whoami|g"
sed -i $replace etc/pong_bot.service
sed -i $replace etc/mesh_bot.service
sed -i $replace etc/mesh_bot_reporting.service
replace="s|Group=pi|Group=$whoami|g"
sed -i $replace etc/pong_bot.service
sed -i $replace etc/mesh_bot.service
sed -i $replace etc/mesh_bot_reporting.service
sudo systemctl daemon-reload
printf "\n service files updated\n"

# ask if emoji font should be installed for linux
echo "Do you want to install the emoji font for debian/ubuntu linux? (y/n)"
read emoji
if [ $emoji == "y" ]; then
    sudo apt-get install -y fonts-noto-color-emoji
    echo "Emoji font installed!, reboot to load the font"
fi

if [ $bot == "pong" ]; then
    # install service for pong bot
    sudo cp etc/pong_bot.service /etc/systemd/system/
    sudo systemctl enable pong_bot.service
fi

if [ $bot == "mesh" ]; then
    # install service for mesh bot
    sudo cp etc/mesh_bot.service /etc/systemd/system/
    sudo systemctl enable mesh_bot.service
fi

if [ $bot == "n" ]; then
    if [ -f launch.sh ]; then
        printf "\nTo run the bot, use the command: ./launch.sh\n"
        ./launch.sh
    fi
fi

printf "\nOptionally if you want to install the LLM Ollama compnents we will execute the following commands\n"
printf "\ncurl -fsSL https://ollama.com/install.sh | sh\n"

# ask if the user wants to install the LLM Ollama components
echo "Do you want to install the LLM Ollama components? (y/n)"
read ollama
if [ $ollama == "y" ]; then
    curl -fsSL https://ollama.com/install.sh | sh

    # ask if want to install gemma2:2b
    printf "\n Ollama install done now we can install the Gemma2:2b components, multi GB download\n"
    echo "Do you want to install the Gemma2:2b components? (y/n)"
    read gemma
    if [ $gemma == "y" ]; then
        ollama pull gemma2:2b
    fi
fi

echo "Good time to reboot? (y/n)"
read reboot
if [ $reboot == "y" ]; then
    sudo reboot
fi

exit 0

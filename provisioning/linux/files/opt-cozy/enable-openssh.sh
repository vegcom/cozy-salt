#!/bin/bash
sudo apt update && sudo apt install openssh-server -y
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sudo systemctl enable ssh && sudo systemctl start ssh
echo "WSL SSH enabled on port 2222. From Win: ssh user@localhost -p 2222"
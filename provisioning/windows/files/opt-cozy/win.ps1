# Add docker contexts
docker context create wsl --default --docker "host=tcp://127.0.0.1:2375"
docker context use wsl
#!/bin/bash

FA_ENDPOINT=127.0.0.1:30003
FACTL_BIN="./fogatlasctl"
GREEN="\e[40;38;5;82m"
YELLOW="\033[40;38;5;11m"
RESET="\e[0m"
APP_NAME="whoami"

#set -x

echo -e "$GREEN This demo automates the deployment of two applications using FogAtlas CLI:
\t- First application does not specify network requirements
\t- Second application specifies network requirements $RESET"

echo -e "$YELLOW Please note that as explained in the main README, the use-case of video surveillance is just simulated.$RESET"

echo -e "$GREEN You can follow the steps of this demonstration on the FogAtlas topology UI at this URL:$RESET http://localhost:30005"
echo -e "Press Enter to continue"
read

# Application without network requirements
echo -e "$GREEN Current status of the infrastructre: FogAtlas components are deployed on CLOUD region $RESET"
$FACTL_BIN get --endpoint=$FA_ENDPOINT microservices
echo -e "Press Enter to continue"
read

# Application without network requirements
echo -e "$GREEN Deploying application app-cam1 ... $RESET"
$FACTL_BIN put --endpoint=$FA_ENDPOINT --id=app-cam1 --file=/vagrant/uc-app-cam1.json deployments
echo
sleep 5
echo -e "$GREEN Microservices for application app-cam1 are deployed on nodes according to requirements: on CLOUD region $RESET"
$FACTL_BIN get --endpoint=$FA_ENDPOINT microservices
echo -e "Press Enter to deploy the second application"
read

# Application with network requirements
echo -e "$GREEN Deploying application iot-app-cam1 ... $RESET"
$FACTL_BIN put --endpoint=$FA_ENDPOINT --id=iot-app-cam1 --file=/vagrant/uc-iot-app-cam1.json deployments
echo
sleep 5
echo -e "$GREEN Microservices for application iot-app-cam1 are deployed on nodes according to requirements: on CLOUD and EDGE regions $RESET"
$FACTL_BIN get --endpoint=$FA_ENDPOINT microservices


echo -e "Press Enter to clean-up the deployed applications"
read

echo -e "$GREEN Cleaning up deployed applications $RESET"
$FACTL_BIN patch --endpoint=$FA_ENDPOINT --id=app-cam1 --status=toundeploy deployments
$FACTL_BIN patch --endpoint=$FA_ENDPOINT --id=iot-app-cam1 --status=toundeploy deployments
#!/bin/bash
shopt -s expand_aliases

GREEN="\033[40;38;5;82m"
YELLOW="\033[40;38;5;11m"
RED="\033[40;38;5;9m"
RESET="\033[0m"

# Identify Operating System
LIUNX='linux'
MACOS='macos'
PLATFORM='unknown'
UNAMESTR=`uname`
if [[ "$UNAMESTR" == 'Linux' ]]; then
   PLATFORM=$LINUX
elif [[ "$UNAMESTR" == 'Darwin' ]]; then
   PLATFORM=$MACOS
fi

alias vssh='vagrant ssh --no-tty k8s-node-1'

VENV_NAME="fogatlas_demo"


function check_dep {
	DEP=ko
	if ( which VBoxManage >/dev/null ); then DEP=ok; else MIS_DEPS=('- virtualbox'); DEP=ko; fi
	if ( which vagrant >/dev/null ); then DEP=ok; else MIS_DEPS+=('- vagrant'); DEP=ko; fi
	if ( which pip >/dev/null ); then DEP=ok; else MIS_DEPS+=('- python-pip'); DEP=ko; fi
	if ( which virtualenv >/dev/null ); then DEP=ok; else MIS_DEPS+=('- virtualenv'); DEP=ko; fi
	if [[ "$DEP" == "ko" ]]; then
		echo -e "$RED KO: Cannot proceed due to preliminary dependencies not met.
		Please install following packages:"
		for d in ${MIS_DEPS[@]}; do
			echo $d
		done
		echo "$RESET"
		exit 0
	else
		echo -e "$GREEN OK: Required dependencies met $RESET"
	fi
}

# Preliminary checks
echo -e $GREEN"Preliminary check... $RESET"
# Customize linux
if [[ "$PLATFORM" == "$LINUX" ]]; then
	check_dep
	echo -e "$GREEN OK: $PLATFORM Opering System supported $RESET"
	export LC_ALL=C
# Customize macos
elif [[ "$PLATFORM" == "$MACOS" ]]; then
	check_dep
	echo -e "$GREEN OK: $PLATFORM Opering System supported $RESET"
# OS not supported
else
	echo -e "KO: $RED Operting System not yet supported"
	exit 0
fi
echo -e $GREEN"All $PLATFORM preliminary checks are met $RESET"

# Virtualenv
echo -e $GREEN"Creating a dedicated virtualenv: $VENV_NAME... $RESET"
virtualenv ${VENV_NAME}

echo -e $GREEN"Activating the dedicated virtualenv: $VENV_NAME... $RESET"
. ${VENV_NAME}/bin/activate

# Python dependencies
echo -e $GREEN"Intall python dependencies... $RESET"
pip install -r requirements.txt

set -e

echo -e $GREEN"Creating the Kubernetes cluster... $RESET"
vagrant up --provision --parallel

# Check the cluster is up-and-running
echo -e "$GREEN Ensure the k8s cluster is up-and-running... $RESET"
until ! vssh -c "kubectl get node | grep NotReady >> /dev/null"
do
	echo -e "$YELLOW Waiting for k8s cluster to start... $RESET"
    vssh -c "kubectl get node"
    sleep 5
done
echo -e $GREEN"k8s cluster ready. $RESET"

# FogAtlas
echo -e $GREEN"Installing Fogatlas into the Kubernetes cluster... $RESET"
vssh -c "kubectl label node k8s-node-2 tier=0 region=CLOUD --overwrite"
vssh -c "kubectl label node k8s-node-3 tier=1 region=EDGE --overwrite"
vssh -c "kubectl apply -f /vagrant/fogatlas.yaml"

until vssh -c "kubectl get pod -l component=fa-apiserver -o jsonpath='{.items[0].status.conditions[?(@.type==\"Ready\")].status}' | grep True >> /dev/null"
do
    echo -e "$YELLOW Waiting for Fogatlas API to start... $RESET"
    vssh -c "kubectl get pods"
    sleep 5
done

echo -e $GREEN"Downloading FogAtlas CLI binary... $RESET"
vssh -c "wget 'https://github.com/fogatlas/fogatlasctl/releases/download/v1.3.0/fogatlasctl-v1.3.0-linux' \
		-O fogatlasctl && \
		chmod a+x fogatlasctl"

echo -e $GREEN"Setting up demo infrastructure... $RESET"
vssh -c "./fogatlasctl putAll --endpoint=127.0.0.1:30003 --file=/vagrant/uc_infra_setup.yaml"

# Force restart of monitor to refresh application status and avoid timout due to infra not ready
vssh -c "kubectl delete pod -l component=fa-monitor > /dev/null"

deactivate
rm -rf $VENV_NAME

echo -e $GREEN"Fogatlas successfully installed. You can interact with FogAtlas on these endpoints:
\t$GREEN  - FogAtlas API:$RESET http://localhost:30003/api/v2.0.0
\t$GREEN  - FogAtlas API$RESET documentation: http://localhost:30004
\t$GREEN  - FogAtlas topology UI:$RESET http://localhost:30005\n"
echo -e "You can now run ./run_demo.sh to launch the self-contained demo"
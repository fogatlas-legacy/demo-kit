#!/bin/bash
shopt -s expand_aliases

alias vssh='vagrant ssh --no-tty k8s-node-1'
vssh -c "/vagrant/demo.sh"
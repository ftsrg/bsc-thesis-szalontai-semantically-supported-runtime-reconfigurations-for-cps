#!/bin/bash

echo "$(ls | grep -i makefile_)"


if [ -z "$2" ]
then
      make -f "$(ls | grep -i makefile_)" $1
else
      make -f "$(ls | grep -i makefile_)" $1 ARGS=$2
fi

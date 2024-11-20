#!/bin/bash
WORKSPACE=$(terraform workspace show)
if [ $WORKSPACE == "production" ]; then
  read -p "productionへの操作です。続けますか？(y/N): " REPLY
  if [ $REPLY != "y" ]; then
    exit 1
  fi
fi

AWS_PROFILE=$WORKSPACE terraform $* -var-file=variables-${WORKSPACE}.tfvars

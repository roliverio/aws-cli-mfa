#!/bin/bash
function getProfile(){
    PROFILE_MFA_SERIAL=`grep -m1 -A3 $1 ~/.aws/config | grep mfa_serial | cut -f3 -d' ' | head -n 1`
    echo "The specified profile MFA device serial is: $PROFILE_MFA_SERIAL"
    PROFILE_REGION=`grep -m1 -A3 $1 ~/.aws/config | grep region | cut -f3 -d' ' | head -n 1`
    echo "The specified profile region is: $PROFILE_REGION"
    PROFILE_ROLE_TO_ASSUME=`grep -m1 -A4 $1 ~/.aws/account-roles | grep role_arn | cut -f3 -d' ' | head -n 1`
    if [ ! -z $PROFILE_ROLE_TO_ASSUME ]; then
    echo "This profile has role assumption enabled, will try to get credentials under asssumed role"
    echo "The role to assume is: $PROFILE_ROLE_TO_ASSUME"
    ROLE_ENABLED=1
    fi
}

function getSession(){

    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_DEFAULT_REGION
    unset AWS_PROFILE
    
    # Getting credentials for profile
    json=$(aws sts get-session-token --profile $1 --serial-number $PROFILE_MFA_SERIAL --token-code $2)
    if [[ $? != 0 ]]; then
        return 2
    fi
    export AWS_ACCESS_KEY_ID=$(echo $json | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $json | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $json | jq -r '.Credentials.SessionToken')
    export AWS_PROFILE=$1

    if [[ $ROLE_ENABLED -eq 1 ]]; then
   
    # Assuming Role	 
    json=$(aws sts assume-role --role-arn $PROFILE_ROLE_TO_ASSUME --role-session-name "$1") 
    if [[ $? != 0 ]]; then
        return 2
    fi
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_DEFAULT_REGION
    unset AWS_PROFILE

    export AWS_ACCESS_KEY_ID=$(echo $json | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $json | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $json | jq -r '.Credentials.SessionToken')
    fi  

    echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> ~/.awsenv
    echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> ~/.awsenv
    echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> ~/.awsenv
    echo "AWS_DEFAULT_REGION=$PROFILE_REGION" >> ~/.awsenv
    echo "AWS_PROFILE=$1" >> ~/.awsenv
    echo "export AWS_ACCESS_KEY_ID" >> ~/.awsenv
    echo "export AWS_SECRET_ACCESS_KEY" >> ~/.awsenv
    echo "export AWS_SESSION_TOKEN" >> ~/.awsenv
    echo "export AWS_DEFAULT_REGION" >> ~/.awsenv
    echo "export AWS_PROFILE" >> ~/.awsenv
}
if [[ $# != 2 ]]; then
    echo "usage: . getsession.sh profileName tokenCode"
    exit 1
fi    
 touch ~/.awsenv
 > ~/.awsenv
 getProfile $1
 
 if [ -z $PROFILE_MFA_SERIAL ]; then
	   echo "Invalid AWS CLI profile, please check your ~/.aws/config and ensure mfa_serial is set"
	   echo "and, that the name is correct. Also, you should ensure that ~/.aws/credentials"
	   echo "contains the base AWS KEY and AWS SECRET KEY for the profile you're trying to use"
	   exit 1

  elif [ -z $PROFILE_REGION ]; then
	   echo "This profile has no region defined, please check your ~/.aws/config and ensure region"
	   echo "is set for the profile you're specifying, and, that the name is correct."
	   exit 1
   else
     getSession $1 $2
     
     echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
     echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
     echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
     echo "AWS_DEFAULT_REGION=$PROFILE_REGION"
     echo "AWS_PROFILE=$1"
     echo " "    
     echo "These are your credentials, you can copy/paste this values on your shell, or, alternatively"
     echo "run: source ~/.awsenv" 
     exit 0
 fi

# aws-cli-mfa

## linux/getsession.sh: 

Software requirements:

jq JSON parser: (Debian/Ubuntu: # apt-get install jq | CentOS / RH: yum install jq)
aws cli tools (Debian/Ubuntu: # apt-get install awscli | CentOS / RH: yum install awscli)
(as awscli version from repos over ubuntu xenial is somewhat outdated, we recommend installing awscli from snap)
:# snap install aws-cli --classic (remember to uninstall the awscli version from the repos)
  
To use this script, you should first configure your aws cli environment, taking advantage of the 
profile options of the aws cli tool:

### How

```shell
aws configure --profile mynewprofile
AWS Access Key ID [None]: _{Fill in your IAM base AWS Access Key}_
AWS Secret Access Key [None]: _{Fill in you IAM base AWS Secret Access key}_
Default region name [None]:_{You should set a default region for this profile}_
Default output format [None]:_{You can set a default output format (json/text/table), leave blank for default: json}_

```

- This will place a couple of files under the **~/.aws** directory, **~/.aws/config** and **~/.aws/credentials**

The credentials file holds the access key and secret access key related to the profile, as:

```shell
~/.aws/credentials
[mynewprofile]
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
```

- The config file houses defaults for every profile, as:

```shell
~/.aws/config:
[default]
output = json
[mynewprofile]
region = (If region was set earlier)
```
- Lastly, you should add a third file specifying wich accounts need the assume role function: **~/.aws/account-roles**, with their corresponding role (account number / role name)

```shell
[mynewprofile]
role_arn = arn:aws:iam::$ACCOUNT_NUMBER:role/$ROLE_NAME
```
- For the script to properly function, you'll have to add the **mfa_****serial** variable to the profile(s) that uses MFA:
 
```shell
~/.aws/config:
[default]
output = json
[mynewprofile]
region = (If region was set earlier)
mfa_serial = {ARN of the MFA device, for example: _arn:aws:iam::111111111111:mfa/my.iam.username_}
```

- Once this is in place, you'll need to run the script as in ``` ./getsession.sh``` _profilename_ _token_

  The profilename is the profile that you added earlier, and, the token, refers to the auth token given from your MFA device

  If the script executes successfully, you'll end up with an output like:

  * AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
  * AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  * AWS_SESSION_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  * AWS_DEFAULT_REGION=xx-xxx-xx
  * AWS_PROFILE=$profile

  And, a message to "source  ~/.awsenv" or, to directly copy paste these variables on the current environment. This will complete your
  MFA authentication for the AWS cli for the profile selected.

- Remember, you cannot work on multiple profiles at the same time on the same shell, you'll need to open a new terminal or run a new shell
  within a multiplexer such as tmux or screen

- Finally, the default token lasts 1 hour, and, you can optionally request a new set of credentials with a new token whenever you like.

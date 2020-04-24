#!/bin/bash
# Enable 'extglob' which allows us to perform string matches `@(*)` etc.
shopt -s extglob

# Color values used (https://misc.flogisoft.com/bash/tip_colors_and_formatting)
# \e[31m Red
# \e[32m Green
# \e[39m Reset / Default
# \e[90m Gray

# \e[38;5;226m Jexia yellow
# \e[38;5;244m Dark Gray

# Output some information to the user, they may find it useful for debugging
echo -e "Deploying your application with \e[38;5;226mJexia\e[39m CLI version: \e[34m$(jexia --version)\e[39m"
# Plug Jexia CLI to other developers
echo -e "\e[38;5;244mContribute to the CLI on GitHub: https://github.com/jexia/jexia-cli/\e[39m"

# Check mandatory variables
if [ $(expr length "${INPUT_EMAIL}") -eq 0 ]; then
    echo -e "\e[31mProcess could not be completed. You have not set your email.\e[39m"
    exit 1
fi
if [ $(expr length "${INPUT_PASSWORD}") -eq 0 ]; then
    echo -e "\e[31mProcess could not be completed. You have not set your password.\e[39m"
    exit 1
fi
if [ $(expr length "${INPUT_PROJECT_ID}") -eq 0 ]; then
    echo -e "\e[31mProcess could not be completed. You have not set your project ID.\e[39m"
    exit 1
fi
if [ $(expr length "${INPUT_APP_ID}") -eq 0 ]; then
    echo -e "\e[31mProcess could not be completed. You have not set your application ID.\e[39m"
    exit 1
fi

# Inform the user which account they are using
echo -e "Signing into account: \e[34m$INPUT_EMAIL\e[39m"

# Pass the email and password to Jexia's config file allowing us to skip the interactive inputs
mkdir ~/.jexia/
printf "email: $INPUT_EMAIL\npassword: $INPUT_PASSWORD" >>~/.jexia/config.yml

# Create the initial command as a string, this allows us to add flags later and then execute separately
COMMAND=$(echo "jexia app deploy --project $INPUT_PROJECT_ID --app $INPUT_APP_ID --format shell")

# If the user has set the `wait` input to true we add the `--wait` flag to the command
if [ $INPUT_WAIT = true ]; then
    # Display a warning as a user has a limited amount of minutes and minutes cost money. This should only be used when necessary
    echo -e "\e[33mWarning: '--wait' flag added. Jexia can take around 7 minutes to deploy. This will wait for the whole duration.\e[39m"
    COMMAND="${COMMAND} --wait"
fi

# If the user has passed an API Key value (ie var length is greater than 0) we add the flag and value
if [ $(expr length "${INPUT_API_KEY}") -gt 0 ]; then
    COMMAND="${COMMAND} --api-key ${INPUT_API_KEY}"
fi

# If the user has passed an API Secret value (ie var length is greater than 0) we add the flag and value
if [ $(expr length "${INPUT_API_SECRET}") -gt 0 ]; then
    COMMAND="${COMMAND} --api-secret ${INPUT_API_SECRET}"
fi

# Output the to the user we are deploying and inform them what command we a using, useful for debugging.
# Note: Outputting secrets is not recommended by GitHub even though these are automatically handled and replaced with `***`
# TODO: Add a flag allowing users to hide this by choice.
echo -e "Deploying with: \e[90m${COMMAND}\e[39m"

# Output a red colour to console as when executing the command some outputs (such as some errors) are not handled and sent to OUTPUT
printf '\e[31m'
# Run the command and send the response to OUTPUT
OUTPUT=$(eval " ${COMMAND}")
# Recolor console to default as all text pass this point is handled
printf '\e[39m\n'

# Get values from Jexia CLIs deploy command by searching for them in the string (using extglob)
STATUS=${OUTPUT//@(*status=\"|\"*)/}
ERROR_INFO=${OUTPUT//@(*info=\"|\"*)/}

# If statement output correct message and exit with the correct code
if [ "$STATUS" = "Success" ]; then
    echo -e "\e[32mDeployed successfully\e[39m"
    exit 0
elif [ "$STATUS" = "In progress" ]; then
    echo -e "\e[32mStarting deployment.\e[39m Not waiting for completion"
    exit 0
else
    echo -e "\e[31mDeploy failed. ${ERROR_INFO//\\/}\e[39m"

    # This will be useful if they expect to trigger this event frequently where Jexia may not have completed a previous deployment
    if [ $INPUT_SILENT_FAIL = true ]; then
        echo -e "\e[31mFailed silently, exit code 0\e[39m"
    else
        # This will be interpreted by GitHub as a fail
        exit 1
    fi

fi

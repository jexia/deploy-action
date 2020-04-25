#!/bin/bash

# Color values used (https://misc.flogisoft.com/bash/tip_colors_and_formatting)
INFO_COLOR="\e[34m"    # Blue
DARK_COLOR="\e[90m"    # Dark gray
RESET_COLOR="\e[39m"   # Normal / Default
JEXIA_COLOR="\e[93m"   # Light Yellow
ERROR_COLOR="\e[31m"   # Red
SUCCESS_COLOR="\e[32m" # Green

# A serious error is used to bypass the SILENT_FAIL flag, such as when credentials are wrong as the process would *never* pass
SERIOUS_ERROR=false
# Helper function to set the variable, prevents an incorrect assignment of a truthy value
serious_error () { SERIOUS_ERROR=true; }

# Output some information to the user, they may find it useful for debugging
echo -e "Deploying your application with ${JEXIA_COLOR}Jexia${RESET_COLOR} CLI version: ${INFO_COLOR}$(jexia --version)${RESET_COLOR}"
# Plug Jexia CLI to other developers
echo -e "${DARK_COLOR}Contribute to the CLI on GitHub: https://github.com/jexia/jexia-cli/${RESET_COLOR}"

# Check mandatory variables
if [ -z "${INPUT_EMAIL}" ]; then
    echo -e "${ERROR_COLOR}Process could not be completed. You have not set your email.${RESET_COLOR}"
    exit 1
fi
if [ -z "${INPUT_PASSWORD}" ]; then
    echo -e "${ERROR_COLOR}Process could not be completed. You have not set your password.${RESET_COLOR}"
    exit 1
fi
if [ -z "${INPUT_PROJECT_ID}" ]; then
    echo -e "${ERROR_COLOR}Process could not be completed. You have not set your project ID.${RESET_COLOR}"
    exit 1
fi
if [ -z "${INPUT_APP_ID}" ]; then
    echo -e "${ERROR_COLOR}Process could not be completed. You have not set your application ID.${RESET_COLOR}"
    exit 1
fi

# Inform the user which account they are using
echo -e "Signing into account: ${INFO_COLOR}$INPUT_EMAIL${RESET_COLOR}"

# Pass the email and password to Jexia's config file allowing us to skip the interactive inputs
mkdir ~/.jexia/
printf "email: $INPUT_EMAIL\npassword: $INPUT_PASSWORD" >>~/.jexia/config.yml

# Create the initial command as a string, this allows us to add flags later and then execute separately
COMMAND=$(echo "jexia app deploy --project $INPUT_PROJECT_ID --app $INPUT_APP_ID --format shell")

# If the user has set the `wait` input to true we add the `--wait` flag to the command
if [ "$INPUT_WAIT" = true ]; then
    # Display a warning as a user has a limited amount of minutes and minutes cost money. This should only be used when necessary
    echo -e "\e[33mWarning: '--wait' flag added. Jexia can take around 7 minutes to deploy. This will wait for the whole duration.${RESET_COLOR}"
    COMMAND="${COMMAND} --wait"
fi

# If the user has passed an API Key value (ie var length is greater than 0) we add the flag and value
if [ ! -z "${INPUT_API_KEY}" ]; then
    COMMAND="${COMMAND} --api-key ${INPUT_API_KEY}"
fi

# If the user has passed an API Secret value (ie var length is greater than 0) we add the flag and value
if [ ! -z "${INPUT_API_SECRET}" ]; then
    COMMAND="${COMMAND} --api-secret ${INPUT_API_SECRET}"
fi

# Output the to the user we are deploying and inform them what command we a using, if they have `debug: true`
# Note: Outputting secrets is not recommended by GitHub even though these are automatically handled and replaced with `***`
if [ "$INPUT_DEBUG" = true ]; then
    # Display the exact command used
    echo -e "Deploying with: ${DARK_COLOR}${COMMAND}${RESET_COLOR}"
else
    # Display a general message
    echo -e "Deploying to Jexia"
fi

# Run the command and send the response to OUTPUT
OUTPUT=$(eval " ${COMMAND}" 2>&1)

# Get values from Jexia CLIs deploy command by searching for them in the string
STATUS=$(echo "${OUTPUT}" | grep -oP '(?<=status=").*?(?=")')
ERROR_INFO=$(echo "${OUTPUT}" | grep -oP '(?<=info=").*?(?=")')

# Check if the status value is returned, if not search the output for know phrases related to errors
# This process allows us to better handle when an exit code 0 and exit code 1 are used by searching the
# error for a string if the output is not returned in the desired shell format.
if [ -z "${STATUS}" ]; then

    # We use a case command to match substrings within the output, we use this to return 'better' errors.
    case "${OUTPUT}" in
    *"already in progress"*)
        # Emulate a known error returned from the deploy command when a deploy is in progress
        STATUS="Error"
        ERROR_INFO="a deployment is already running"
        ;;
    *"internal server error"*)
        # Emulate a known error returned from the deploy command when there is an unknown internal server error
        STATUS="Error"
        ERROR_INFO="internal server error"
        ;;
    *"no matching policy"*)
        # Emulate a known error returned from the deploy command when the project ID is not found
        STATUS="Error"
        ERROR_INFO="incorrect Jexia project ID"
        serious_error
        ;;
    *"incorrect email or password"*)
        # Emulate a known error returned from the deploy command when authentication fails
        STATUS="Error"
        ERROR_INFO="unable to authenticate, incorrect email or password provided"
        serious_error
        ;;
    esac

    # If the user has turned debugging on, we will append the whole command response to the end of ERROR_INFO
    if [ "$INPUT_DEBUG" = true ]; then
        # Display the exact command used
        ERROR_INFO="${ERROR_INFO} ${DARK_COLOR}(${OUTPUT})${RESET_COLOR}"
    fi
fi

# Case statement to output the correct message and exit with the correct code
case "${STATUS}" in
"Success")
    echo -e "${SUCCESS_COLOR}Deployed successfully${RESET_COLOR}"
    ;;

"In progress")
    echo -e "${SUCCESS_COLOR}Starting deployment.${RESET_COLOR} Not waiting for completion"
    ;;

"Error")
    echo -e "${ERROR_COLOR}Deploy failed, ${ERROR_INFO}${RESET_COLOR}"

    # This will be useful if they expect to trigger this event frequently where Jexia may not have completed a previous deployment
    # If it is a serious error, such as the users credentials are incorrect, we will ignore the silent error request.
    if [ "$INPUT_SILENT_FAIL" = true ] && [ "$SERIOUS_ERROR" = false ]; then
        echo -e "${ERROR_COLOR}Failed silently, exit code 0${RESET_COLOR}"
    else
        # This will be interpreted by GitHub as a fail
        exit 1
    fi
    ;;

*)
    echo -e "${ERROR_COLOR}Deploy failed. Unknown internal error.${RESET_COLOR}"
    # As this is an unexpected error, we will ignore the silent fail
    exit 1
    ;;
esac

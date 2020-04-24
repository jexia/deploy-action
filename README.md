# Jexia's GitHub Deploy Action

Automatically request Jexia to deploy your [App Hosting](https://docs.jexia.com/apphost/) application.

## Notable Features

- Ability to set API Key and API Secret
- Ability to wait until the project has been deployed
- Ability to allow this action to fail silently

## GitHub Action Inputs

### User Email

```yaml
with:
  email: value
```

(**Required**)
([String](#string))
This is the account email used for authentication. The project you are using should be linked to this account.

### User Password

```yaml
with:
  password: value
```

(**Required**)
([GitHub Secret](#github-secret))
This is the password used to authenticate the request. **This should be a GitHub Secret**, see [here](#github-secret) for a guide.

### Jexia Project ID

```yaml
with:
  project_id: value
```

(**Required**)
([string](#string))
The Jexia project ID, this can be found on the project's settings page within the Jexia dashboard.

### Jexia Application ID

```yaml
with:
  app_id: value
```

(**Required**)
([String](#string))
The Jexia Application ID, this can be found on the project's "Deploy Application" page within the Jexia dashboard. You need to look for your URL, such as `61faf315-cf25-4b87-8f27-ec73b1a7e328.jexia.app`. The ID for this particular URL is `61faf315-cf25-4b87-8f27-ec73b1a7e328` and follows the pattern: `<app_id>.jexia.app`.

### API Key

```yaml
with:
  api_key: value
```

([String](#string))
This is an API Key previously created within the Jexia dashboard, it will be passed to the application when deploying as `process.env.API_KEY`.

### API Secret

```yaml
with:
  api_secret: value
```

([GitHub Secret](#github-secret))
This is an API Secret previously created within the Jexia dashboard, it will be passed to the application when deploying as `process.env.API_SECRET`. **This should be a GitHub Secret**, see [here](#github-secret) for a guide.

### Wait for the deployment status

```yaml
with:
  #   default: false
  wait: value
```

([Boolean](#boolean))
This adds the flag `--wait` and will cause the command to run until Jexia has returned a value based on whether the deployment was successful or failed. This is **not recommended** and should only be used when **absolutely necessary** as it could cause the GitHub Action to run for around 7 minutes, which will have a large impact on your _GitHub Action Minutes_ and could result in a high monetary cost.

### Fail Silently

```yaml
with:
  #   default: false
  silent_fail: value
```

([Boolean](#boolean))
This allows the action to always exit on an exit code `0`. This should only be used if you expect to trigger this event within ~10 minute intervals and don't want the whole action to fail when Jexia returns an error such as when the application is already in the process of deploying.

### Debug

```yaml
with:
  #   default: false
  debug: value
```

([Boolean](#boolean))
This will output values useful for debugging, such as the exact command used with the Jexia CLI.

**Please note:** This will knowingly output the `api_secret` value to the console, however, GitHub should automatically remove this as it is a known secret.

## Input Types

A few pieces to describe what input each value expects.

### GitHub Secret

As said by GitHub, "_Encrypted secrets allow you to store sensitive information, such as access tokens, in your repository._". Please see [GitHub's Official Guide](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) regarding correctly creating and storing encrypted secrets for GitHub Actions.

### String

A string could be anything, when using **YAML**, it does not need to be encased in quotes.

### Boolean

This should be either `true` or `false`.

## Usage Examples

An example of a workflow for deploying on a release.

```yml
# .github/workflows/jexia-deploy.yml

name: Deploy to Jexia
# This workflow is triggered when a release is created for repository.
on:
  release:
    types: # When a release is created
      - created

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: jexia/deploy-action@v1
        with:
          email: someone@example.com
          password: ${{ secrets.JEXIA_USER_PASSWORD }}
          project_id: 450d7735-fb9f-4f15-b6e4-e628f2109019
          app_id: 8a5cb709-c495-4b84-950e-9b72d9d3928e
          api_key: api_key
          api_secret: ${{ secrets.JEXIA_API_SECRET }}
```

## Contributions

Any contributions are helpful, please make a pull-request. If you would like to discuses a new feature, please create an issue first.

# Google Cloud Run Starter

## Project Overview

This repository provides a template for a Python-based web application designed for deployment on Google Cloud Run. It includes a basic application structure and sets up a Continuous Integration/Continuous Deployment (CI/CD) pipeline using Google Cloud Build and Google Cloud Deploy. This allows for automated building, testing, and deployment of your application.

## Directory Structure

This project is organized as follows:

*   `main.py`: An example Python web application (e.g., using Flask or FastAPI).
*   `Dockerfile`: Defines the Docker container for packaging the application.
*   `requirements.txt`: Lists the Python dependencies for the application.
*   `cloudbuild.yaml`: Configuration file for Cloud Build, defining the CI pipeline steps.
*   `cicd/`: This directory contains configurations for Cloud Deploy and Skaffold.
    *   `clouddeploy.yaml`: Defines the delivery pipeline, including stages like development (dev) and production (prod).
    *   `skaffold.yaml`: Skaffold configuration used by Cloud Build and Cloud Deploy for building, deploying, and verifying the application.
    *   `gcp-cloud-run-starter-dev.yaml`: Cloud Run service definition for the development environment.
    *   `gcp-cloud-run-starter-prod.yaml`: Cloud Run service definition for the production environment.
    *   `build-trigger.yaml`: Configuration for the Cloud Build trigger, often linked to repository events like pushes to the main branch.
*   `README.md`: This file, providing an overview and instructions for the project.
*   `.gitignore`: Specifies intentionally untracked files that Git should ignore (e.g., `__pycache__/`, `.env`).
*   `LICENSE`: Contains the license information for this project.
*   `sample-variables.sh`: A sample shell script to help users set up necessary environment variables for interacting with Google Cloud.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Initial Project Setup](#initial-project-setup)
  - [Configure Environment Variables](#configure-environment-variables)
  - [Create GCP Project](#create-gcp-project)
  - [Get Project Number](#get-project-number)
  - [Set Default Project](#set-default-project)
  - [Link Billing Account](#link-billing-account)
- [Local Development](#local-development)
- [Enable Required APIs](#enable-required-apis)
  - [Compute & Storage APIs](#compute--storage-apis)
  - [CI/CD APIs](#cicd-apis)
  - [Verify Services Enabled](#verify-services-enabled)
- [Configure Service Accounts and Permissions](#configure-service-accounts-and-permissions)
  - [Cloud Build Setup](#cloud-build-setup)
  - [Cloud Build Permissions](#cloud-build-permissions)
- [Setup Artifact Registry](#setup-artifact-registry)
  - [Create Artifact Registry Repository](#create-artifact-registry-repository)
- [Configure CI/CD with Cloud Build and Cloud Deploy](#configure-cicd-with-cloud-build-and-cloud-deploy)
  - [Bind Permissions](#bind-permissions)
  - [Create GitHub Connection](#create-github-connection)
  - [Create Repository - Link to GitHub Repo](#create-repository---link-to-github-repo)
  - [Create a Build Trigger from GitHub](#create-a-build-trigger-from-github)
  - [Create Cloud Deploy Pipeline and Targets](#create-cloud-deploy-pipeline-and-targets)
- [CI/CD Pipeline Overview](#cicd-pipeline-overview)
- [Deploying and Testing the Application](#deploying-and-testing-the-application)
- [Troubleshooting](#troubleshooting)
- [Customizing the Template](#customizing-the-template)

## Prerequisites
* You have a Google Cloud Organization
  * You have permissions to create projects and resources
* You have a Billing Account Setup
* You have an initial GitHub Repo 

## Initial Project Setup

### Configure Environment Variables
This project uses a `sample-variables.sh` script to manage essential configuration values. Copy this file to `variables.sh` (which is in `.gitignore`) and update it with your specific details. Do not commit `variables.sh` with your secrets.

Source the script in your shell environment before running `gcloud` commands:
```bash
source variables.sh
```

Below is a detailed explanation of each variable found in `sample-variables.sh`:

*   `PROJECT_ID`: Your unique Google Cloud Project ID. Choose a descriptive name (e.g., `my-app-dev`). This will be used when creating your GCP project.
*   `PROJECT_NUMBER`: Your Google Cloud Project Number. This is automatically assigned when you create the project. You will need to update this variable in `variables.sh` after running the project creation step.
*   `BILLING_ACCOUNT_ID`: Your Google Cloud Billing Account ID. You can find this in the GCP Console under 'Billing' > 'Billing accounts'. It's required to link your project to a billing account.
*   `APP`: The name of your application (e.g., `gcp-cloud-run-starter`). This is used for tagging resources and naming conventions.
*   `FOLDER_ID`: (Optional) The ID of the GCP Folder where you want to create the project. If you use GCP Folders to organize projects, specify its ID here. Otherwise, it can be left blank or the variable removed.
*   `PORT`: The port your application will listen on inside the container (e.g., `8080`). Cloud Run will route external traffic to this port.
*   `REGION`: The default Google Cloud region for deploying resources like Cloud Run services and Artifact Registry repositories (e.g., `"us-central1"`).
*   `TAG`: The tag for your Docker image in Artifact Registry (e.g., `"$REGION-docker.pkg.dev/$PROJECT_ID/docker-repository/$APP"` if using a region-specific Artifact Registry).
*   `REPO_NAME`: The name of your GitHub repository (e.g., `my-cloud-run-app`). This should match the repository you are using with Cloud Build.
*   `CONNECTION_NAME`: The name for the Cloud Build GitHub connection you will create in GCP (e.g., `my-github-connection`). This connection links GCP to your GitHub repositories.
*   `INSTALLATION_ID`: The installation ID of the GitHub App used by Cloud Build for the connection. This is usually handled during the connection setup in the GCP console. (Note: The `sample-variables.sh` uses `INSTALL_ID`; `INSTALLATION_ID` is the term more often seen in documentation for 2nd gen connections and used here for clarity).
*   `BUILD_TRIGGER_NAME`: A descriptive name for your Cloud Build trigger (e.g., `gcp-cloud-run-starter-build-trigger`).
*   `REPO_URI`: The HTTPS URI of your GitHub repository (e.g., `https://github.com/YOUR_ORG/YOUR_REPO.git`).
*   `REPO_OWNER`: The owner of the GitHub repository (your GitHub username or organization name).
*   `BRANCH_PATTERN`: The branch pattern that triggers builds (e.g., `"^main$"` for builds on the main branch).
*   `BUILD_CONFIG_FILE`: Path to your Cloud Build configuration file within your repository (e.g., `cloudbuild.yaml`).
*   `SERVICE_ACCOUNT`: The email address of the service account Cloud Build will use to execute builds and deploy resources. You can set this to the default Cloud Build SA (e.g., `"$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"`) or a custom service account you create.

**Important:** Ensure all values, especially those with placeholder text like `REPLACE_...` or `SET_AFTER_CREATING_PROJECT`, are updated with your actual information in your `variables.sh` file.

### Create GCP Project
Labels are like Tags in other clouds; this is helpful for billing, FinOps, etc.
```
gcloud projects create $PROJECT_ID --name="My Cloud Run Application" --folder=$FOLDER_ID --labels=environment=development,name=$PROJECT_ID,cost-center=my-org,owner=miles,type=prototype --set-as-default
```
#### Project Creation Reference
For more details on project creation, see the official documentation:
https://cloud.google.com/sdk/gcloud/reference/projects/create

*(Command structure: `gcloud projects create [PROJECT_ID] [--no-enable-cloud-apis] [--folder=FOLDER_ID] [--labels=[KEY=VALUE,…]] [--name=NAME] [--organization=ORGANIZATION_ID] [--set-as-default] [--tags=[KEY=VALUE,…]] [GCLOUD_WIDE_FLAG …]`)*

### Get Project Number
After creating the project, retrieve its unique project number.
```
gcloud projects describe $PROJECT_ID
```
Note: After running this command, update the `PROJECT_NUMBER` in your `variables.sh` file with the value from the `projectNumber` field in the output.

### Set Default Project 
Set the current project for all subsequent `gcloud` commands:
```
gcloud config set project $PROJECT_ID
```

### Link Billing Account
Associate your project with a billing account:
```
gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
```

## Local Development

This template includes a sample Python application in `main.py`.

Python dependencies are listed in `requirements.txt`. You can install them using pip:
```bash
pip install -r requirements.txt
```

To run the application locally for development or testing, you can typically execute:
```bash
python main.py
```

**Note:** Ensure you have Python installed and have installed the dependencies from `requirements.txt`. The application by default might run on port 8080, as configured in the `Dockerfile` and Cloud Run services. You may need to set environment variables (e.g., `PORT`) locally if the application expects them.

## Enable Required APIs
Google Cloud services are backed by APIs that need to be enabled for your project.

### Compute & Storage APIs
Enable APIs for core compute and storage services. The example below includes Cloud Run, BigQuery, Firestore, and Pub/Sub. Adjust the list based on your application's needs.
```
gcloud services enable run.googleapis.com \
    bigquery.googleapis.com \
    firestore.googleapis.com \
    pubsub.googleapis.com 
```
To find other available Google APIs:
```
gcloud services list --available --filter="name:googleapis.com"
```

### CI/CD APIs
Enable APIs necessary for the CI/CD pipeline, including Cloud Build, Cloud Deploy, Artifact Registry, Secret Manager (if used), and IAM.
```
gcloud services enable cloudbuild.googleapis.com \
    clouddeploy.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    iam.googleapis.com
```

### Verify Services Enabled 
List enabled services to confirm:
```
gcloud services list 
```

## Configure Service Accounts and Permissions

### Cloud Build Setup
Cloud Build uses an Identity and Access Management (IAM) service account to execute builds on your behalf. You have two main options for the service account specified by the `SERVICE_ACCOUNT` variable in `variables.sh`:

1.  **Default Cloud Build Service Account:**
    *   GCP automatically creates a service account for Cloud Build in your project with the email format: `$PROJECT_NUMBER@cloudbuild.gserviceaccount.com`.
    *   **Pros:** Simpler setup as the account is pre-created.
    *   **Cons:** By default, this service account has broad permissions (Project Editor role) within the project, which might be more permissive than necessary. For enhanced security, it's recommended to reduce its permissions or use a custom service account.
    *   To use it, set `export SERVICE_ACCOUNT=$PROJECT_NUMBER@cloudbuild.gserviceaccount.com` in `variables.sh` (after `PROJECT_NUMBER` is known).

2.  **Custom Service Account:**
    *   You can create a dedicated service account with granular permissions tailored to your CI/CD pipeline's needs.
    *   **Pros:** Follows the principle of least privilege, enhancing security by only granting necessary permissions.
    *   **Cons:** Requires manual creation and management of the service account and its permissions.
    *   Example creation:
        ```bash
        gcloud iam service-accounts create continuous-build-delivery \
          --description="Service Account for CI CD in $PROJECT_ID" \
          --display-name="CI CD Service Account"
        # Then set in variables.sh:
        # export SERVICE_ACCOUNT=continuous-build-delivery@$PROJECT_ID.iam.gserviceaccount.com
        ```

To list service accounts in your project:
```
gcloud iam service-accounts list
```
This guide's permission grants will apply to the service account specified in your `SERVICE_ACCOUNT` variable.

### Cloud Build Permissions
The service account that Cloud Build uses to execute builds (`$SERVICE_ACCOUNT` from your `variables.sh`) requires specific IAM roles to perform its tasks. This is true whether you use the default Cloud Build service account or a custom one (though the default SA often comes with broader permissions like Project Editor initially). For a secure, least-privilege setup, ensure it has at least the following:

```bash
# Essential for Cloud Build to execute build steps.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/cloudbuild.builds.builder"

# Required for Cloud Build to write build logs to Cloud Logging.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/logging.logWriter"

# Required for Cloud Build to push container images to Artifact Registry.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/artifactregistry.writer"

# Required for Cloud Build to create new releases in Google Cloud Deploy.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/clouddeploy.releaser"

# (Optional) If your build steps need to access secrets stored in Secret Manager.
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#    --member="serviceAccount:$SERVICE_ACCOUNT" \
#    --role="roles/secretmanager.secretAccessor"

# (Optional) If your Cloud Build steps need to act as another service account (e.g., for specific gcloud commands not related to Cloud Deploy).
# This is generally not needed for the core functionality of this template's CI/CD pipeline.
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#    --member="serviceAccount:$SERVICE_ACCOUNT" \
#    --role="roles/iam.serviceAccountUser" # This would typically be granted on the SA it needs to impersonate, or on the project for broader impersonation.
```
Ensure these commands are run after `$PROJECT_ID` and `$SERVICE_ACCOUNT` are correctly set in your environment. It's crucial to understand that this service account does *not* directly deploy to Cloud Run in this pipeline; it delegates that to Cloud Deploy.

### Cloud Deploy Execution Environment Permissions
Google Cloud Deploy executes deployments in an execution environment that uses a service account. By default, this is the Compute Engine default service account (`[PROJECT_NUMBER]-compute@developer.gserviceaccount.com`). This execution service account requires the following permissions to deploy to Cloud Run:

*   **`roles/clouddeploy.jobRunner`**: Allows the service account to perform operations for Cloud Deploy.
*   **`roles/run.developer`**: Allows deploying and managing Cloud Run services (creating new revisions, updating traffic, etc.).
*   **`roles/iam.serviceAccountUser`**: Required if your Cloud Run service is configured to run as a specific runtime service account. This permission allows the Cloud Deploy execution SA to act as (impersonate) the Cloud Run service's runtime SA. Grant this role to the Cloud Deploy execution SA on the Cloud Run runtime SA.
    ```bash
    # Example: Grant Cloud Deploy's execution SA (default Compute SA) permission to act as a specific Cloud Run runtime SA
    # export CLOUD_RUN_RUNTIME_SA="my-app-runtime-sa@$PROJECT_ID.iam.gserviceaccount.com"
    # export CLOUD_DEPLOY_EXEC_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
    # gcloud iam service-accounts add-iam-policy-binding $CLOUD_RUN_RUNTIME_SA \
    #   --member="serviceAccount:$CLOUD_DEPLOY_EXEC_SA" \
    #   --role="roles/iam.serviceAccountUser" \
    #   --project=$PROJECT_ID
    ```
*   **`roles/artifactregistry.reader`**: (If using private images) Allows the execution environment to pull images from Artifact Registry for deployment to Cloud Run.

You can grant these roles to the default Compute Engine SA or, for stricter control, configure your Cloud Deploy targets to use a custom service account with these specific roles.

## Setup Artifact Registry

### Create Artifact Registry Repository 
Create a repository in Artifact Registry to store your Docker container images.
```bash
# Set REPOSITORY in variables.sh if not already defined, e.g.:
# export REPOSITORY="docker-repository" 
# The REGION variable from variables.sh will be used for the location.

gcloud artifacts repositories create $REPOSITORY \
    --location=$REGION \
    --repository-format="docker" \
    --description="Docker repository for $APP"
```

## Configure CI/CD with Cloud Build and Cloud Deploy

### Bind Permissions
This section addresses permissions that might be needed for the *Google-managed Cloud Build service agent* (format: `service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com`) if it needs to access resources like secrets in Secret Manager, particularly for scenarios like 1st generation Cloud Build triggers or manually managed API tokens.

**For the 2nd generation Cloud Build GitHub App connection described in the subsequent steps, these specific secret access permissions for the Google-managed Cloud Build service agent are generally not required for basic repository access**, as authentication is handled by the GitHub App installation.

However, if your build process *itself* (running under `$SERVICE_ACCOUNT`) needs to access secrets you've stored in Secret Manager (e.g., API keys for third-party services), then `$SERVICE_ACCOUNT` (not the Google-managed service agent) would need the `roles/secretmanager.secretAccessor` role for those specific secrets. You would grant this like other permissions:
```bash
# Example: Granting your build's SA access to a specific secret
# gcloud secrets add-iam-policy-binding YOUR_SECRET_NAME \
#   --member="serviceAccount:$SERVICE_ACCOUNT" \
#   --role="roles/secretmanager.secretAccessor" \
#   --project=$PROJECT_ID
```
The original reference link for context on service agent permissions with GitHub is: https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github

### Create GitHub Connection
This step connects your Google Cloud project to your GitHub account or organization, allowing Cloud Build to access your repositories. You'll typically do this through the GCP Console (Cloud Build > Settings > GitHub Connections), which guides you through installing the Google Cloud Build GitHub App on your desired repositories. The `CONNECTION_NAME` variable in `variables.sh` should match the name you give this connection in GCP.

Reference: https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen

### Create Repository - Link to GitHub Repo
Once the connection is established, link your specific GitHub repository to Cloud Build.
```bash
gcloud builds repositories create $REPO_NAME \
    --remote-uri=$REPO_URI \
    --connection=$CONNECTION_NAME \
    --region=$REGION
```

### Create a Build Trigger from GitHub
Import the build trigger definition from the `cicd/build-trigger.yaml` file. This trigger will automatically start a Cloud Build pipeline when changes are pushed to the specified branch in your linked GitHub repository.
```bash
gcloud alpha builds triggers import --region=$REGION \
  --source=cicd/build-trigger.yaml \
  --project=$PROJECT_ID
```
Ensure your `cicd/build-trigger.yaml` is configured to use your `$REPO_NAME` and `$BRANCH_PATTERN`.

### Create Cloud Deploy Pipeline and Targets
Apply the Cloud Deploy configuration to create a delivery pipeline and targets (e.g., dev, prod). This pipeline orchestrates the deployment of your application to Cloud Run across different environments.
```bash
gcloud deploy apply --file=cicd/clouddeploy.yaml --region=$REGION --project=$PROJECT_ID
```
Reference: https://cloud.google.com/deploy/docs/deploy-app-run

## CI/CD Pipeline Overview

This project implements an automated CI/CD pipeline using Google Cloud Build and Google Cloud Deploy to build, test, and deploy your application to Cloud Run. Here's a step-by-step overview of the flow:

1.  **Trigger:**
    *   The pipeline is automatically initiated by a push to the `main` branch (or any pattern defined in `cicd/build-trigger.yaml`) in your connected GitHub repository.

2.  **Cloud Build Execution (`cloudbuild.yaml`):**
    *   Upon triggering, Cloud Build executes the steps defined in `cloudbuild.yaml`:
        *   **(Future Step):** Unit tests and linting checks will be performed to ensure code quality before proceeding with the build. (This will be implemented in subsequent tasks).
        *   **Build Docker Image:** The application is packaged into a Docker image using the `Dockerfile`.
        *   **Tag Image:** The built Docker image is tagged with the commit SHA (for traceability) and `latest`.
        *   **Push to Artifact Registry:** The tagged image is pushed to your Google Artifact Registry repository (configured in `variables.sh` and used by `cloudbuild.yaml`).

3.  **Cloud Deploy Release Creation (`cicd/clouddeploy.yaml`):**
    *   After the image is successfully built and pushed, Cloud Build creates a new release in Google Cloud Deploy.
    *   This release references the specific Docker image version from Artifact Registry that was just built.
    *   The delivery pipeline (`cicd/clouddeploy.yaml`) is configured for a serial progression, targeting the `dev` environment first.

4.  **Deployment to `dev` Environment:**
    *   Cloud Deploy automatically initiates the deployment of this new release to the `dev` target.
    *   The application is rolled out to the Cloud Run service defined for the development environment (see `cicd/gcp-cloud-run-starter-dev.yaml` and `cicd/skaffold.yaml` for rendering).
    *   **Verification:** After deployment, Skaffold performs verification tests (`skaffold.yaml`) to ensure the `dev` deployment is healthy. (This verification step will be enhanced in a later task).

5.  **Promotion to `prod` Environment:**
    *   **Manual Promotion:** Following a successful deployment and verification in the `dev` environment, promoting the release to the `prod` environment is a manual step. This can be done via the Google Cloud Console or using `gcloud deploy releases promote` command, allowing for a final review gate before production.
    *   **Canary Deployment:** When promoted, Cloud Deploy deploys the application to the `prod` Cloud Run service (defined in `cicd/gcp-cloud-run-starter-prod.yaml` and rendered via `cicd/skaffold.yaml`).
    *   The deployment to `prod` uses a canary strategy as configured in `cicd/clouddeploy.yaml`. Initially, a percentage of traffic (e.g., 25%) is routed to the new version.
    *   **Verification & Rollout:** Skaffold verification (`skaffold.yaml`) runs against the canary deployment. If successful, Cloud Deploy automatically manages the gradual rollout to 100% traffic. If verification fails, it can automatically roll back.

## Deploying and Testing the Application

### Test Out Cloud Run From Proxy
After a successful deployment to a Cloud Run environment (e.g., `gcp-cloud-run-starter-dev`), you can test it.

List your Cloud Run services:
```bash
gcloud beta run services list --project=$PROJECT_ID --region=$REGION
```
Proxy to your service (replace `gcp-cloud-run-starter-dev` with your service name if different):
```bash
gcloud beta run services proxy gcp-cloud-run-starter-dev \
    --project=$PROJECT_ID \
    --region=$REGION \
    --port=$PORT 
```
This will make the service available at `http://localhost:$PORT`.

## Troubleshooting

This section provides guidance for common issues you might encounter.

*   **Permission Errors during `gcloud` commands:**
    *   **Symptom:** `PERMISSION_DENIED` errors when running `gcloud` commands.
    *   **Solution:** Ensure the logged-in user (`gcloud auth list`) or the service account being used has the necessary IAM roles (e.g., Project Owner, Editor, or specific roles mentioned in the setup like `roles/cloudbuild.builds.builder`, `roles/run.admin`, etc.). Review the "Cloud Build Permissions" and other relevant permission sections in this README. Double-check that the `$PROJECT_ID` and `$SERVICE_ACCOUNT` variables are correctly set and exported in your shell.

*   **Cloud Build Fails:**
    *   **Symptom:** Build fails in the Cloud Build console/history.
    *   **Solution:** Carefully examine the build logs in the Cloud Build history for specific error messages. Common issues include:
        *   Syntax errors in `cloudbuild.yaml`.
        *   Failing unit tests or linters (once implemented).
        *   Errors during Docker image construction (`Dockerfile` issues).
        *   Problems fetching dependencies (e.g., from `requirements.txt`).
        *   Incorrect image tagging or push permissions to Artifact Registry.

*   **Deployment Fails in Cloud Deploy:**
    *   **Symptom:** A release promotion fails, or a rollout gets stuck or fails.
    *   **Solution:**
        *   Navigate to the Cloud Deploy UI in the Google Cloud Console to examine the release details and rollout logs for your delivery pipeline.
        *   Check Skaffold logs, which are often part of the Cloud Deploy logs for rendering and deployment steps.
        *   Inspect the Cloud Run service logs for the target environment (`dev` or `prod`) for application-level errors during startup or health checks.
        *   Ensure the Cloud Build service account (`$SERVICE_ACCOUNT`) has permissions to deploy to Cloud Run (e.g., `roles/run.admin`) and to act as the Cloud Run service's runtime service account (`roles/iam.serviceAccountUser` on the runtime SA).

*   **Application Not Working on Cloud Run:**
    *   **Symptom:** The Cloud Run service deploys successfully, but the application returns HTTP 5xx errors, "Container failed to start," or doesn't respond as expected.
    *   **Solution:**
        *   Check the Cloud Run service logs in the Google Cloud Console. Look for application startup errors, crashes, or specific request handling errors.
        *   Verify that any necessary environment variables are correctly defined in the service YAML configuration files (`cicd/gcp-cloud-run-starter-dev.yaml`, `cicd/gcp-cloud-run-starter-prod.yaml`) and are being correctly interpreted by your application.
        *   Ensure your application is listening on the port specified by the `PORT` environment variable (Cloud Run sets this automatically, typically 8080 if not overridden in your Dockerfile or service config).
        *   Test your application locally using `python main.py` or by building and running the Docker container locally to isolate issues.

*   **`variables.sh` Issues:**
    *   **Symptom:** `gcloud` or other script commands fail due to unset, incorrect, or misspelled environment variables (e.g., "project '' not found").
    *   **Solution:**
        *   Ensure you have correctly sourced the `variables.sh` script in your current terminal session: `source variables.sh`.
        *   Verify that you have copied `sample-variables.sh` to `variables.sh` and replaced all placeholder values (like `REPLACE_BILLING_ACCOUNT_ID`, `REPLACE_FOLDER_ID`, `SET_AFTER_CREATING_PROJECT`) with your actual project-specific details.
        *   Use `echo $VARIABLE_NAME` to check the current value of any suspect variable.

## Customizing the Template

This template provides a starting point. Here’s how you can customize it for your specific needs:

*   **Application Code:**
    *   Modify `main.py` to implement your own application logic, web framework (e.g., Flask, FastAPI), and endpoints.
    *   Update `requirements.txt` with your project's Python dependencies. Run `pip freeze > requirements.txt` to capture them after installing new packages.

*   **Dockerfile:**
    *   Adjust `Dockerfile` if your application requires different base images (e.g., a specific Python version, a different OS).
    *   Change build steps, add system dependencies, or modify runtime commands (e.g., `CMD` instruction for Gunicorn or Uvicorn).

*   **Cloud Build Pipeline (`cloudbuild.yaml`):**
    *   Edit `cloudbuild.yaml` to add or change build steps. This could include:
        *   Adding linters (e.g., Flake8, Pylint).
        *   Integrating different testing frameworks (e.g., PyTest, Unittest).
        *   Adding security scanning steps for your container images.
        *   Including database migration steps.

*   **Service Configuration (`cicd/*-dev.yaml`, `cicd/*-prod.yaml`):**
    *   Update `cicd/gcp-cloud-run-starter-dev.yaml` and `cicd/gcp-cloud-run-starter-prod.yaml` to change Cloud Run service settings such as:
        *   Environment variables specific to each environment.
        *   CPU/memory allocation.
        *   Scaling parameters (min/max instances, concurrency).
        *   Container port (ensure it matches what your application and Dockerfile expose).
        *   VPC connectors or other networking settings.
        *   **Runtime Service Account:** The Cloud Run service itself runs with an identity (service account). By default, this is the Compute Engine default service account. If your application needs to access other Google Cloud services (e.g., Cloud SQL, Pub/Sub, Spanner), this runtime service account must have the appropriate IAM permissions for those services. Consider creating a dedicated, least-privilege service account for your application's runtime identity and assign it only the necessary roles.

*   **Deployment Strategy (`cicd/clouddeploy.yaml`):**
    *   Modify `cicd/clouddeploy.yaml` to alter the deployment pipeline. You might:
        *   Add more stages (e.g., staging, QA).
        *   Change canary percentages or implement multi-step canary deployments.
        *   Switch to a different deployment strategy if your needs change (though Cloud Deploy primarily focuses on standard and canary for Cloud Run).
        *   Adjust verification settings or manual promotion requirements.

*   **Skaffold Configuration (`cicd/skaffold.yaml`):**
    *   Update `cicd/skaffold.yaml` if you:
        *   Change the names of your Cloud Run services in the `*-dev.yaml` or `*-prod.yaml` files.
        *   Modify how services are deployed or how manifests are generated.
        *   Want to enhance or change the verification steps (e.g., add specific health check endpoints or test scripts).

*   **Project/Service Names:**
    *   If you are using this template for a new project with a different name than `gcp-cloud-run-starter`, you will need to perform a search and replace across multiple files for `gcp-cloud-run-starter` and update other placeholder values like `PROJECT_ID` in Skaffold, Cloud Deploy, and service YAMLs.
    *   Key files to check include: `sample-variables.sh` (and your `variables.sh`), `cloudbuild.yaml`, `cicd/clouddeploy.yaml`, `cicd/skaffold.yaml`, `cicd/gcp-cloud-run-starter-dev.yaml`, `cicd/gcp-cloud-run-starter-prod.yaml`, and `cicd/build-trigger.yaml`.
    *   (Future Note: A "Parameterizing Project-Specific Values" section, once added, will provide more detailed guidance on this.)

## Parameterizing for Your Own Project

This template uses placeholder names (like `gcp-cloud-run-starter` for the application/service name and references to a placeholder Project ID) throughout its configuration files. When you adapt this template for your own project, you'll need to update these values to match your specific project and application names.

Here's a list of key files and the types of values that typically need to be changed:

*   **`variables.sh` (and your copy from `sample-variables.sh`):**
    *   This is the primary place to define your core project and application names.
    *   `PROJECT_ID`: Your globally unique Google Cloud Project ID.
    *   `APP`: The name for your application (e.g., `my-web-app`). This is used to derive names for services, images, etc. The template default is `gcp-cloud-run-starter`.
    *   `TAG`: The image tag in Artifact Registry, typically constructed as `"$REGION-docker.pkg.dev/$PROJECT_ID/your-artifact-repo/$APP"`. Ensure the repository name part matches your Artifact Registry setup.
    *   `REPO_NAME`: Your GitHub repository name.
    *   `CONNECTION_NAME`: The name of your Cloud Build GitHub connection.
    *   `BUILD_TRIGGER_NAME`: The desired name for your Cloud Build trigger.
    *   `REPO_URI`: The full HTTPS URI of your GitHub repository.
    *   `REPO_OWNER`: Your GitHub organization or username.
    *   *Note: `PROJECT_NUMBER` is automatically derived after project creation and should be updated in `variables.sh`.*

*   **`cloudbuild.yaml`:**
    *   `substitutions._ARTIFACT_REPOSITORY`: The default is `docker-repository`. Change this if you use a different Artifact Registry repository name.
    *   `substitutions._IMAGE_NAME`: The default is `gcp-cloud-run-starter`. This **must** be updated to match the `APP` name you set in `variables.sh`.
    *   Review for any hardcoded project IDs or region names if they exist, though these should ideally use substitutions (like `$PROJECT_ID`, `$_REGION`).

*   **`cicd/build-trigger.yaml`:**
    *   `name`: The name of the build trigger (e.g., `my-web-app-trigger`).
    *   `repositoryEventConfig.repository`: This is a resource path like `projects/YOUR_PROJECT_ID/locations/YOUR_REGION/connections/YOUR_CONNECTION_NAME/repositories/YOUR_REPO_NAME`. Ensure `YOUR_PROJECT_ID`, `YOUR_REGION`, `YOUR_CONNECTION_NAME`, and `YOUR_REPO_NAME` match your setup.
    *   `serviceAccount`: This is a resource path like `projects/YOUR_PROJECT_ID/serviceAccounts/YOUR_SERVICE_ACCOUNT_EMAIL`. Ensure it points to the correct service account.

*   **`cicd/clouddeploy.yaml`:**
    *   `metadata.name` for `DeliveryPipeline` (e.g., `my-web-app-pipeline` instead of `gcp-cloud-run-starter-pipeline`).
    *   `metadata.name` for `Target` resources (e.g., `dev-my-web-app`, `prod-my-web-app`).
    *   `run.location` for `Target` resources: Ensure this points to your project and region, e.g., `projects/YOUR_PROJECT_ID/locations/YOUR_REGION`. (The template uses `gcp-cloud-run-starter` as a placeholder Project ID here).

*   **`cicd/gcp-cloud-run-starter-dev.yaml` (and `gcp-cloud-run-starter-prod.yaml`):**
    *   **Rename these files** to reflect your `APP` name (e.g., `my-web-app-dev.yaml`, `my-web-app-prod.yaml`).
    *   `metadata.name`: The Cloud Run service name (e.g., `my-web-app-dev` instead of `gcp-cloud-run-starter-dev`).
    *   `spec.template.spec.containers[0].image`: The image name. Skaffold typically handles substituting this based on its configuration and the build output. Ensure it aligns with your `_IMAGE_NAME` from `cloudbuild.yaml` and `APP` name.

*   **`cicd/skaffold.yaml`:**
    *   `metadata.name`: Skaffold configuration name (e.g., `deploy-my-web-app`).
    *   `profiles[*].manifests.rawYaml[*]`: Update the filenames if you renamed your service YAML files (e.g., `my-web-app-dev.yaml`).
    *   `profiles[*].verify[*].container.args`: The `gcloud run services describe` command within the verification script uses service names (e.g., `gcp-cloud-run-starter-dev`). These must be updated to your actual Cloud Run service names. The script also uses `$PROJECT_ID`; ensure this environment variable is available and correct in the Skaffold execution context or replace it with the literal project ID if necessary.

*   **`README.md` (this file):**
    *   Review any example commands, descriptions, or variable settings throughout this README. If you've forked this repository, update these examples to reflect your chosen application name and project details to avoid confusion for your users.

**General Advice:**

*   After updating `variables.sh` with your primary `APP` name and `PROJECT_ID`, perform a global search across all project files for the template's default name (e.g., `gcp-cloud-run-starter`) and the placeholder project ID used in some files (often `gcp-cloud-run-starter` itself if used as a project ID placeholder in files like `clouddeploy.yaml`). This will help you catch most instances that need updating.
*   Pay close attention to resource names, which often combine your `APP` name with environment suffixes (e.g., `my-web-app-dev`, `my-web-app-prod`).

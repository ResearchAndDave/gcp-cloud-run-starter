# Google Cloud Run Starter
Template for using gcloud CLI to create a project and continuous delivery pipeline.


## Prerequisites
* You have a Google Cloud Organization
  * You have permissions to create projects and resources
* You have a Billing Account Setup
* You have an initial GitHub Repo 

## Starting GCP Setup

Create a variables.sh to set variables

```
export PROJECT_ID=gcp-cloud-run-starter
export PROJECT_NUMBER=SET_AFTER_CREATING_PROJECT
export BILLING_ACCOUNT_ID=REPLACE_BILLING_ACCOUNT_ID
export APP=gcp-cloud-run-starter
export FOLDER_ID=REPLACE_FOLDER_ID
export PORT=8080
export REGION="us-central1"
#export REGION="us-east4"
export TAG="gcr.io/$PROJECT_ID/$APP"
export REPO_NAME=REPLACE

export CONNECTION_NAME=YOUR_CONNECTION_NAME
export INSTALLATION_ID=INSTALL_ID
export BUILD_TRIGGER_NAME=gcp-cloud-run-starter-build-trigger
export REPO_URI=REPO_URI_HERE
export REPO_OWNER=ORG_OR_USER
export BRANCH_PATTERN="^main$" 
export BUILD_CONFIG_FILE=cloudbuild.yaml
# OR Create your own Service Account
export SERVICE_ACCOUNT=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

```

## Create Project
Labels are like Tags in other clouds, this is helpful for billing, finops, etc.
```
gcloud projects create $PROJECT_ID --name="GCP Starter Project" --folder=$FOLDER_ID --labels=environment=development,name=$PROJECT_ID,cost-center=my-org,owner=miles,type=prototype --set-as-default
```

### Get Project Number
Note you will need to update the variables.sh to set the PROJECT_NUMBER or run the comman sepe
```
gcloud projects describe $PROJECT_ID 

```
### Project Creation Reference
gcloud projects create [PROJECT_ID] [--no-enable-cloud-apis] [--folder=FOLDER_ID] [--labels=[KEY=VALUE,…]] [--name=NAME] [--organization=ORGANIZATION_ID] [--set-as-default] [--tags=[KEY=VALUE,…]] [GCLOUD_WIDE_FLAG …]

#### Reference For Creating Projects
https://cloud.google.com/sdk/gcloud/reference/projects/create

### Set Default Project (all later commands will use it) 
```
gcloud config set project $PROJECT_ID
```

## Add and Enable Billing Account
```
gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
```

## Enable APIS

### Compute & Storage
Example list of APIs to enable
- Cloud Run
- Pub/Sub
- Firestore
- Big Query

```
gcloud services enable run.googleapis.com \
    bigquery.googleapis.com \
    firestore.googleapis.com \
    pubsub.googleapis.com 
```
### Find googleapis
Lists Google APIs 
```
gcloud services list --available --filter="name:googleapis.com"
```

### CI CD
- Cloud Build
- Cloud Deploy
- Artifact Registry
- Secrets Manager
- IAM APIs

```
gcloud services enable cloudbuild.googleapis.com \
    clouddeploy.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    iam.googleapis.com
```

### Verify Services Enabled 
```
gcloud services list 
```

### Cloud Build Setup
Either use the default Cloud Build Service Account or create your own

#### Default Cloud Build Service Account
Set SERVICE_ACCOUNT
```
export SERVICE_ACCOUNT=[PROJECT_NUMBER]@cloudbuild.gserviceaccount.com

```
#### Create Service Account for Cloud Builds
Reference https://cloud.google.com/build/docs/cloud-build-service-account

```
gcloud iam service-accounts create continuous-build-delivery \
  --description="Service Account for CI CD" \
  --display-name="CI CD Service Account"
```

### List Service Accounts
```
gcloud iam service-accounts list
```

### Cloud Build Permissions

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/cloudbuild.builds.builder

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/cloudbuild.serviceAgent"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/logging.logWriter"

```

### Create Artifact Registry Repository 
```
# Set in variables.sh
export REPOSITORY="docker-repository"
export REGION=us-central1

gcloud artifacts repositories create $REPOSITORY --location $REGION --repository-format "docker"
```

#TODO Is this needed
### Bind Permissions 
https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github
```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com \
    --role=roles/secretmanager.admin

  CLOUD_BUILD_SERVICE_AGENT="service-${PN}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  gcloud secrets add-iam-policy-binding GITHUB_TOKEN_READ \
    --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"    
```

### Create GitHub Connection

Use a Bot GitHub Account and Create a Connection

Reference: https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen


### Create Repository - Link to GitHub Repo
```
gcloud builds repositories create $REPO_NAME \
    --remote-uri=$REPO_URI \
    --connection=$CONNECTION_NAME --region=$REGION
```

### Create a Build Trigger from GitHub
```
gcloud alpha builds triggers import --region $REGION \
  --source cicd/build-trigger.yaml \
  --project $PROJECT_ID
```

### Create Cloud Deploy Pipeline and Targets
```
gcloud deploy apply --file=cicd/clouddeploy.yaml --region=$REGION
```

<!-- ### Give Access to Pipeline 
```
gcloud deploy delivery-pipelines set-iam-policy $PIPELINE_NAME policy.yaml --region=$REGION
``` -->
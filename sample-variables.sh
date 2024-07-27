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

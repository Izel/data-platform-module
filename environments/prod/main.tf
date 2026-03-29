#
# Modules definition
#

# 1.All other modules require these APIs to be active
module "apis" {
  source = "../../modules/apis"

  project_id    = var.project_id
  required_apis = var.required_apis
}

# 1.1 GCP requires time to propagate the APIs enabeling. 
resource "time_sleep" "wait_for_apis" {
  create_duration = "360s" # Waits for 6 minutes for the APIs provisioning
  depends_on      = [module.apis]
}

# 2. IAM 
module "iam" {
  source = "../../modules/iam"

  project_id  = var.project_id
  environment = var.environment
  depends_on  = [time_sleep.wait_for_apis]
}

# 3. Networking
module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  subnet_cidr = var.subnet_cidr
  depends_on  = [time_sleep.wait_for_apis]
}

# 4. Security (KMS + Secret Manager)
module "security" {
  source = "../../modules/security"

  project_id          = var.project_id
  environment         = var.environment
  region              = var.region
  key_rotation_period = var.key_rotation_period
  depends_on          = [time_sleep.wait_for_apis]
}

# 4. Storage 
module "storage" {
  source = "../../modules/storage"

  project_id     = var.project_id
  environment    = var.environment
  region         = var.region
  gcs_kms_key_id = module.security.gcs_kms_key_id

  depends_on = [module.security]
}

# 5. BigQuery 
module "bigquery" {
  source = "../../modules/bigquery"

  project_id             = var.project_id
  environment            = var.environment
  region                 = var.region
  bigquery_kms_key_id    = module.security.bigquery_kms_key_id
  data_pipeline_sa_email = module.iam.data_pipeline_sa_email
  bq_analyst_sa_email    = module.iam.bq_analyst_sa_email

  depends_on = [module.security, module.iam]
}

# 6. Monitoring 
module "monitoring" {
  source = "../../modules/monitoring"

  project_id               = var.project_id
  environment              = var.environment
  log_dataset_id           = module.bigquery.analytics_dataset_id
  notification_channel_ids = var.notification_channel_ids

  depends_on = [module.bigquery]
}

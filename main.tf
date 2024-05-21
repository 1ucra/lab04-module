module "s3" {
  source = "./modules/aws-s3"
  s3_name = var.s3_name
}

module "vpc" {
  source = "./modules/aws-vpc"

  vpc_name         = var.vpc_name
  vpc_cidr         = var.vpc_cidr
  igw_name         = var.igw_name
  public_cird1     = var.public_cird1
  public_subnet1   = var.public_subnet1
  public_cidr2     = var.public_cidr2
  public_subnet2   = var.public_subnet2
  private_cidr1    = var.private_cidr1
  private_subnet1  = var.private_subnet1
  private_cidr2    = var.private_cidr2
  private_subnet2  = var.private_subnet2
  db_cird1         = var.db_cird1
  db_subnet1       = var.db_subnet1
  db_cird2         = var.db_cird2
  db_subnet2       = var.db_subnet2
  eip_name1        = var.eip_name1
  eip_name2        = var.eip_name2
  ngw_name1        = var.ngw_name1
  ngw_name2        = var.ngw_name2
  public_routeTable_name   = var.public_routeTable_name
  private_routeTable_name1 = var.private_routeTable_name1
  private_routeTable_name2 = var.private_routeTable_name2
  db_routeTable_name1      = var.db_routeTable_name1
  db_routeTable_name2      = var.db_routeTable_name2
}

module "security-group" {
  source = "./modules/aws-sg"

  vpc_name    = var.vpc_name
  web_alb_securityGroup_name = var.web_alb_securityGroup_name
  app_alb_securityGroup_name = var.app_alb_securityGroup_name
  webTier_securityGroup_name = var.webTier_securityGroup_name
  appTier_securityGroup_name = var.appTier_securityGroup_name
  dbTier_securityGroup_name  = var.dbTier_securityGroup_name
  redis_securityGroup_name = var.redis_securityGroup_name
  bastion_securityGroup_name = var.bastion_securityGroup_name

  depends_on = [module.vpc]

}

module "rds" {
  source = "./modules/aws-rds"

  db_securityGroup_name              = var.db_securityGroup_name
  db_subnet_name1 = var.db_subnet1
  db_subnet_name2 = var.db_subnet2
  dbTier_securityGroup_name           = var.dbTier_securityGroup_name
  rds_username         = var.rds_username
  rds_pwd              = var.rds_pwd
  db_name              = var.db_name
  rds_name             = var.rds_name
  db_securityGroup_id             = module.security-group.database_securityGroup_id
  db_user_id = var.db_user_id
  db_user_pwd = var.db_user_pwd
  depends_on = [module.security-group]

}

module "alb" {
  source = "./modules/aws-alb"

  public_subnet_name1  = var.public_subnet1
  public_subnet_name2  = var.public_subnet2
  private_subnet_name1 = var.private_subnet1
  private_subnet_name2 = var.private_subnet2
  web_alb_securityGroup_name      = var.web_alb_securityGroup_name
  web_alb_securityGroup_id        = module.security-group.web_alb_securityGroup_id
  app_alb_securityGroup_name      = var.app_alb_securityGroup_name
  app_alb_securityGroup_id        = module.security-group.app_alb_securityGroup_id
  web_alb_name         = var.web_alb_name
  app_alb_name         = var.app_alb_name
  web_tg_name          = var.web_tg_name
  app_tg_name          = var.app_tg_name
  vpc_name             = var.vpc_name
  header_name = var.header_name
  header_value = var.header_value

  depends_on = [module.security-group]
}

module "db-cache" {
  source = "./modules/aws-elasticache"
  
  db_subnet1 = var.db_subnet1
  db_subnet2 = var.db_subnet2
  redis_securityGroup_id = module.security-group.redis_securityGroup_id
  depends_on = [module.security-group]
}

module "iam" {
  source = "./modules/aws-iam"

  iam_role              = var.iam_role
  iam-policy            = var.IAM-POLICY
  instance_profile_name = var.instance_profile_name
  
}

module "ami" {
  source ="./modules/aws-ami"

  instance_profile_name = var.instance_profile_name
  vpc_name    = var.vpc_name
  db_subnet1 = var.db_subnet1
  app_alb_dns_name      = module.alb.app_alb_dns_name
  bastion_securityGroup_id = module.security-group.bastion_securityGroup_id

  depends_on = [ module.security-group, module.iam ]
}

module "autoscaling" {
  source = "./modules/aws-autoscaling"
  
  ami-id = module.ami.my-ami-id
  ami_name              = var.AMI-NAME
  instance_profile_name = var.instance_profile_name
  webTier_securityGroup_name           = var.webTier_securityGroup_name
  appTier_securityGroup_name           = var.appTier_securityGroup_name
  web-securityGroup-id             = module.security-group.web-tier-sg-id
  app-securityGroup-id             = module.security-group.app-tier-sg-id
  private_subnet_name1  = var.private_subnet1
  private_subnet_name2  = var.private_subnet2
  web_asg_name          = var.web_asg_name
  app_asg_name          = var.app_asg_name
  web-targetGroup-arn            = module.alb.web_tg_arn
  app-targetGroup-arn            = module.alb.app_tg_arn
  app_alb_dns_name      = module.alb.app_alb_dns_name
  depends_on            = [module.ami]
}

module "acm-route53-cloudfront-waf" {
  source = "./modules/aws-acm-route53-cloudfront-waf"

  domain_name     = var.domain_name
  cloudfront_name = var.cloudfront_name
  alb_dns_name    = module.alb.web_alb_dns_name
  web_acl_name    = var.web_acl_name
  header_name = var.header_name
  header_value = var.header_value

  providers = {
    aws = aws.us-east-1
  }

  depends_on = [module.autoscaling]
}
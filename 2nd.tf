/*# VPC
resource "aws_vpc" "vpc0" {
  cidr_block = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames = true
  tags = { Name = "vpc0" }
}

# Subnet
resource "aws_subnet" "pubSn0" {
  vpc_id            = aws_vpc.vpc0.id
  cidr_block        = "10.0.0.0/24"
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc0.ipv6_cidr_block, 8, 0)
  availability_zone = "ap-northeast-1a"
  tags = { Name = "pubSn0" }
}

resource "aws_subnet" "pubSn1" {
  vpc_id            = aws_vpc.vpc0.id
  cidr_block        = "10.0.1.0/24"
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc0.ipv6_cidr_block, 8, 1)
  availability_zone = "ap-northeast-1c"
  tags = { Name = "pubSn1" }
}

resource "aws_subnet" "priSn0" {
  vpc_id            = aws_vpc.vpc0.id
  cidr_block        = "10.0.2.0/24"
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc0.ipv6_cidr_block, 8, 2)
  availability_zone = "ap-northeast-1a"
  tags = { Name = "priSn0" }
}

resource "aws_subnet" "priSn1" {
  vpc_id            = aws_vpc.vpc0.id
  cidr_block        = "10.0.3.0/24"
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc0.ipv6_cidr_block, 8, 3)
  availability_zone = "ap-northeast-1c"
  tags = { Name = "priSn1" }
}

# Internet Gateway
resource "aws_internet_gateway" "ig0" {
  vpc_id = aws_vpc.vpc0.id
  tags = { Name = "ig0" }
}

# EIP
resource "aws_eip" "eip0" {
  vpc = true
  tags = { Name = "eip0" }
}

resource "aws_eip" "eip1" {
  vpc = true
  tags = { Name = "eip1"}
}

# NAT Gateway
resource "aws_nat_gateway" "ng0" {
  allocation_id = aws_eip.eip0.id
  subnet_id     = aws_subnet.pubSn0.id
  tags = { Name = "ng0" }
}

resource "aws_nat_gateway" "ng1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.pubSn1.id
  tags = { Name = "ng1" }
}

# Egress Only Internet Gateway
resource "aws_egress_only_internet_gateway" "eoig0" {
  vpc_id = aws_vpc.vpc0.id
  tags = { Name = "eoig0" }
}

# Ruote Table
resource "aws_route_table" "pubRt0" {
  vpc_id = aws_vpc.vpc0.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig0.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.ig0.id
  }

  tags = { Name = "pubRt0" }
}

resource "aws_route_table" "priRt0" {
  vpc_id = aws_vpc.vpc0.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ng0.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_egress_only_internet_gateway.eoig0.id
  }

  tags = { Name = "priRt0" }
}

resource "aws_route_table" "priRt1" {
  vpc_id = aws_vpc.vpc0.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ng1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_egress_only_internet_gateway.eoig0.id
  }

  tags = { Name = "priRt1" }
}

# Ruote Table Association
resource "aws_route_table_association" "pubRt0a" {
  route_table_id = aws_route_table.pubRt0.id
  subnet_id      = aws_subnet.pubSn0.id
}

resource "aws_route_table_association" "pubRt0b" {
  route_table_id = aws_route_table.pubRt0.id
  subnet_id      = aws_subnet.pubSn1.id 
}

resource "aws_route_table_association" "priRt0a" {
  route_table_id = aws_route_table.priRt0.id
  subnet_id      = aws_subnet.priSn0.id 
}

resource "aws_route_table_association" "priRt1a" {
  route_table_id = aws_route_table.priRt1.id
  subnet_id      = aws_subnet.priSn1.id 
}

resource "aws_vpc_endpoint" "vpcEnd0" {
    vpc_id = aws_vpc.vpc0.id
    vpc_endpoint_type     = "Gateway"
    service_name          = "com.amazonaws.ap-northeast-1.s3"
    tags                  = { "Name" = "s3g" }
}

resource "aws_vpc_endpoint_route_table_association" "vpcEnd0a" {
  route_table_id  = aws_route_table.priRt0.id
  vpc_endpoint_id = aws_vpc_endpoint.vpcEnd0.id
}

resource "aws_vpc_endpoint_route_table_association" "vpcEnd0b" {
  route_table_id  = aws_route_table.priRt1.id
  vpc_endpoint_id = aws_vpc_endpoint.vpcEnd0.id
}

# Security Group
resource "aws_security_group" "pubSg0" {
  name        = "pubSg0"
  vpc_id      = aws_vpc.vpc0.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmpv6"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "pubSg0" }
}

resource "aws_security_group" "priSg0" {
  name        = "priSg0"
  vpc_id      = aws_vpc.vpc0.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.pubSg0.id]
    #cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "priSg0" }
}

resource "aws_security_group" "redisSg0" {
    name        = "redisSg0"
    vpc_id      = aws_vpc.vpc0.id

    ingress {
      from_port        = 6379
      to_port          = 6379
      security_groups  = [aws_security_group.priSg0.id]
      protocol         = "tcp"
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = { Name = "redisSg0" }
}

resource "aws_security_group" "rdsSg0" {
    name        = "rdsSg0"
    vpc_id      = aws_vpc.vpc0.id

    ingress {
      from_port        = 5432
      to_port          = 5432
      security_groups  = [aws_security_group.priSg0.id]
      protocol         = "tcp"
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = { Name = "rdsSg0" }
}

# IAM Role
resource "aws_iam_role" "iamRole0" {
    name                  = "myEcsTaskExecutionRole"
    assume_role_policy    = jsonencode(
        {
          "Version": "2012-10-17",
          "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                  "Service": "ecs-tasks.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
          ]
        }
    )
    
    managed_policy_arns   = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    ]

    #managed_policy_arns   = [
    #    aws_iam_policy.policy_one.arn,
    #]
}

resource "aws_iam_role" "iamRole1" {
    name                  = "myEcsCodeDeployRole"
    assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "codedeploy.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    managed_policy_arns   = [
        "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS",
    ]
}

resource "aws_iam_role" "iamRole2" {
    name                  = "myRdsMonitoringRole"
    assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "monitoring.rds.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    managed_policy_arns   = [
        "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole",
    ]
}*/

/*# Redis Subnet Group
resource "aws_elasticache_subnet_group" "redisSng0" {
  name       = "redissng0"
  subnet_ids = [aws_subnet.priSn0.id, aws_subnet.priSn1.id]
}

resource "aws_elasticache_replication_group" "redisClu0" {
    replication_group_id          = "redisClu0"
    replication_group_description = " "
    node_type                     = "cache.t2.micro"
    number_cache_clusters         = 2
    multi_az_enabled              = true
    automatic_failover_enabled    = true
    subnet_group_name        = aws_elasticache_subnet_group.redisSng0.name
    availability_zones            = ["ap-northeast-1a", "ap-northeast-1c"]
    security_group_ids            = [aws_security_group.redisSg0.id]
    at_rest_encryption_enabled    = true
    transit_encryption_enabled    = true
    auto_minor_version_upgrade    = true
}*/
/*
# RDS Subnet Group
resource "aws_db_subnet_group" "rdsSng0" {
  name       = "rdssng0"
  subnet_ids = [aws_subnet.priSn0.id, aws_subnet.priSn1.id]
}

# Choose Test db or Production db and uncomment and run
# DB Instance for Test.
resource "aws_db_instance" "rds0" {
    engine                                = "postgres"
    engine_version                        = "12.5"
    identifier                            = "${var.dbName}ins"
    name                                  = var.dbName
    username                              = var.dbUserName
    password                              = var.dbPassword
    instance_class                        = "db.t2.micro"
    storage_type                          = "gp2"
    allocated_storage                     = 20
    #iops                                  = 0
    max_allocated_storage                 = 1000
    multi_az                              = false # If true, comment out the az below
    availability_zone                     = "ap-northeast-1a" 
    db_subnet_group_name                  = aws_db_subnet_group.rdsSng0.name
    publicly_accessible                   = true
    vpc_security_group_ids                = [aws_security_group.rdsSg0.id]
    #port                                  = 5432
    #iam_database_authentication_enabled   = false
    backup_retention_period               = 7
    #backup_window                         = "17:17-17:47"
    copy_tags_to_snapshot                 = true
    #storage_encrypted                     = false
    performance_insights_enabled          = true
    #performance_insights_retention_period = 7
    #performance_insights_kms_key_id       = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    monitoring_interval                   = 60
    monitoring_role_arn                   = aws_iam_role.iamRole2.arn
    enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
    #auto_minor_version_upgrade            = true
    #maintenance_window                    = "wed:16:47-wed:17:17"
    #delete_automated_backups              = true
    deletion_protection                   = false
    skip_final_snapshot                   = true # might be false in production
    #final_snapshot_identifier             = "${var.dbName}snap"
}*/

/*
# DB Instance for Production.
resource "aws_db_instance" "rds0" {
    engine                                = "postgres"
    engine_version                        = "12.5"
    identifier                            = "${var.dbName}ins"
    name                                  = var.dbName
    username                              = var.dbUserName
    password                              = var.dbPassword
    instance_class                        = "db.m6g.large"
    storage_type                          = "gp2"
    allocated_storage                     = 20
    #iops                                  = 0
    max_allocated_storage                 = 1000
    multi_az                              = true # If false, uncomment the az below
    #availability_zone                     = "ap-northeast-1a"
    db_subnet_group_name                  = aws_db_subnet_group.rdsSng0.name
    publicly_accessible                   = true
    vpc_security_group_ids                = [aws_security_group.rdsSg0.id]
    #port                                  = 5432
    #iam_database_authentication_enabled   = false
    backup_retention_period               = 7
    #backup_window                         = "17:54-18:24"
    copy_tags_to_snapshot                 = true
    #storage_encrypted                     = false
    performance_insights_enabled          = true
    #performance_insights_retention_period = 7
    #performance_insights_kms_key_id       = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    monitoring_interval                   = 60
    monitoring_role_arn                   = aws_iam_role.iamRole2.arn
    enabled_cloudwatch_logs_exports       = ["postgresql","upgrade"]
    #auto_minor_version_upgrade            = true
    #maintenance_window                    = "sat:13:23-sat:13:53"
    #delete_automated_backups              = true
    deletion_protection                   = true
    skip_final_snapshot                   = false
    final_snapshot_identifier             = "${var.dbName}snap"
}
*/

########## Just uncomment and run above ##########

























########## Don't uncomment and run below ##########

/* Multi-AZ
resource "aws_rds_cluster" "rdsClu0" {
    arn                                 = "arn:aws:rds:ap-northeast-1:446381700699:cluster:mydbclu"
    availability_zones                  = [
        "ap-northeast-1a",
        "ap-northeast-1c",
        "ap-northeast-1d",
    ]
    backtrack_window                    = 0
    backup_retention_period             = 7
    cluster_identifier                  = "mydbclu"
    cluster_members                     = [
        "mydbclu-instance-1",
        "mydbclu-instance-1-ap-northeast-1a",
    ]
    cluster_resource_id                 = "cluster-OF7A3HKN3JXLISIUHS6OJNXLUQ"
    copy_tags_to_snapshot               = true
    database_name                       = "mydb"
    db_cluster_parameter_group_name     = "default.aurora-postgresql12"
    db_subnet_group_name                = "rdsSng0"
    deletion_protection                 = true
    enable_http_endpoint                = false
    enabled_cloudwatch_logs_exports     = [
        "postgresql",
    ]
    endpoint                            = "mydbclu.cluster-cxaqeifmotha.ap-northeast-1.rds.amazonaws.com"
    engine                              = "aurora-postgresql"
    engine_mode                         = "provisioned"
    engine_version                      = "12.4"
    hosted_zone_id                      = "Z24O6O9L7SGTNB"
    iam_database_authentication_enabled = false
    iam_roles                           = []
    id                                  = "mydbclu"
    kms_key_id                          = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    master_username                     = "myuser"
    port                                = 5432
    preferred_backup_window             = "14:45-15:15"
    preferred_maintenance_window        = "wed:18:54-wed:19:24"
    reader_endpoint                     = "mydbclu.cluster-ro-cxaqeifmotha.ap-northeast-1.rds.amazonaws.com"
    skip_final_snapshot                 = true
    storage_encrypted                   = true
    tags                                = {}
    tags_all                            = {}
    vpc_security_group_ids              = [
        "sg-0325465bfb9d2be95",
    ]

    timeouts {}
}

resource "aws_rds_cluster_instance" "rdsCluIns0" {
    arn                             = "arn:aws:rds:ap-northeast-1:446381700699:db:mydbclu-instance-1"
    auto_minor_version_upgrade      = true
    availability_zone               = "ap-northeast-1c"
    ca_cert_identifier              = "rds-ca-2019"
    cluster_identifier              = "mydbclu"
    copy_tags_to_snapshot           = false
    db_parameter_group_name         = "default.aurora-postgresql12"
    db_subnet_group_name            = "rdsSng0"
    dbi_resource_id                 = "db-E2PZ7HBL7AV2QJ55Y3ENBDRQPE"
    endpoint                        = "mydbclu-instance-1.cxaqeifmotha.ap-northeast-1.rds.amazonaws.com"
    engine                          = "aurora-postgresql"
    engine_version                  = "12.4"
    id                              = "mydbclu-instance-1"
    identifier                      = "mydbclu-instance-1"
    instance_class                  = "db.t3.medium"
    kms_key_id                      = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    monitoring_interval             = 60
    monitoring_role_arn             = "arn:aws:iam::446381700699:role/myRdsMonitoringRole"
    performance_insights_enabled    = true
    performance_insights_kms_key_id = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    port                            = 5432
    preferred_backup_window         = "14:45-15:15"
    preferred_maintenance_window    = "wed:20:07-wed:20:37"
    promotion_tier                  = 1
    publicly_accessible             = true
    storage_encrypted               = true
    tags                            = {}
    tags_all                        = {}
    writer                          = true

    timeouts {}
}

resource "aws_rds_cluster_instance" "rdsCluIns1" {
    arn                             = "arn:aws:rds:ap-northeast-1:446381700699:db:mydbclu-instance-1-ap-northeast-1a"
    auto_minor_version_upgrade      = true
    availability_zone               = "ap-northeast-1a"
    ca_cert_identifier              = "rds-ca-2019"
    cluster_identifier              = "mydbclu"
    copy_tags_to_snapshot           = false
    db_parameter_group_name         = "default.aurora-postgresql12"
    db_subnet_group_name            = "rdsSng0"
    dbi_resource_id                 = "db-R2DIBW6YHLGS7JU53ZR2QTQF6E"
    endpoint                        = "mydbclu-instance-1-ap-northeast-1a.cxaqeifmotha.ap-northeast-1.rds.amazonaws.com"
    engine                          = "aurora-postgresql"
    engine_version                  = "12.4"
    id                              = "mydbclu-instance-1-ap-northeast-1a"
    identifier                      = "mydbclu-instance-1-ap-northeast-1a"
    instance_class                  = "db.t3.medium"
    kms_key_id                      = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    monitoring_interval             = 60
    monitoring_role_arn             = "arn:aws:iam::446381700699:role/myRdsMonitoringRole"
    performance_insights_enabled    = true
    performance_insights_kms_key_id = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    port                            = 5432
    preferred_backup_window         = "14:45-15:15"
    preferred_maintenance_window    = "thu:16:52-thu:17:22"
    promotion_tier                  = 1
    publicly_accessible             = true
    storage_encrypted               = true
    tags                            = {}
    tags_all                        = {}
    writer                          = false

    timeouts {}
}

/* Non Multi-AZ
resource "aws_rds_cluster" "rdsClu0" {
    availability_zones                  = [
        "ap-northeast-1a",
        "ap-northeast-1c",
        "ap-northeast-1d",
    ]
    backtrack_window                    = 0
    backup_retention_period             = 7
    cluster_identifier                  = "mydbclu"
    cluster_members                     = [
        "mydbclu-instance-1",
    ]
    cluster_resource_id                 = "cluster-TPR6LI2NHPMT5PTANLDQF7GG6Q"
    copy_tags_to_snapshot               = true
    database_name                       = "mydb"
    db_cluster_parameter_group_name     = "default.aurora-postgresql12"
    db_subnet_group_name                = "rdsSng0"
    deletion_protection                 = false
    enable_http_endpoint                = false
    enabled_cloudwatch_logs_exports     = [
        "postgresql",
    ]
    endpoint                            = "mydbclu.cluster-cxaqeifmotha.ap-northeast-1.rds.amazonaws.com"
    engine                              = "aurora-postgresql"
    engine_mode                         = "provisioned"
    engine_version                      = "12.4"
    hosted_zone_id                      = "Z24O6O9L7SGTNB"
    iam_database_authentication_enabled = false
    iam_roles                           = []
    id                                  = "mydbclu"
    kms_key_id                          = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    master_username                     = "myuser"
    #port                                = 5432
    preferred_backup_window             = "18:37-19:07"
    preferred_maintenance_window        = "tue:13:33-tue:14:03"
    reader_endpoint                     = "mydbclu.cluster-ro-cxaqeifmotha.ap-northeast-1.rds.amazonaws.com"
    skip_final_snapshot                 = true
    storage_encrypted                   = true
    vpc_security_group_ids              = [
        "sg-0a602c9abdbc1bb6b",
    ]
}

resource "aws_rds_cluster_instance" "rdsCluIns0" {
    engine                          = "aurora-postgresql"
    engine_version                  = "12.4"
    cluster_identifier              = "mydbclu"
    instance_class                  = "db.t3.medium"
    availability_zone               = "ap-northeast-1a"
    db_subnet_group_name            = aws_db_subnet_group.rdsSng0.name
    publicly_accessible             = true
    #port                            = 5432
    #preferred_backup_window         = "18:37-19:07"
    copy_tags_to_snapshot           = false
    storage_encrypted               = true
    performance_insights_enabled    = true
    #performance_insights_kms_key_id = "arn:aws:kms:ap-northeast-1:446381700699:key/d6a2e7f9-9b54-4c98-ba65-4446a74d6f72"
    monitoring_interval             = 60
    monitoring_role_arn             = aws_iam_role.iamRole2.arn
    auto_minor_version_upgrade      = true
    #preferred_maintenance_window    = "fri:17:24-fri:17:54"
    
    db_parameter_group_name         = "default.aurora-postgresql12"
        
    promotion_tier                  = 1
    writer                          = true
}*/


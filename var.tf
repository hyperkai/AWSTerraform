variable accessKey { sensitive = true } # Access Key
variable secretKey { sensitive = true } # Secret Key
variable "domain" { sensitive = true }  # Naked Domain (Without subdomain) 
variable "subdomain" { sensitive = true } # UnNaked Domain (With subdomain)
variable "receiverMail" { sensitive = true } # Mail Address for receive mails
variable "s3bucket" { sensitive = true } # S3 Bucket name
variable "keyPair" { sensitive = true }  # Key Pair name
variable "webImg" { sensitive = true } # Web Server Image name
variable "appImg" { sensitive = true } # Application Server Image name

# Postgresql Database
variable "dbName" { sensitive = true } # Database name 
variable "dbUserName" { sensitive = true } # Database user name
variable "dbPassword" { sensitive = true } # Database password
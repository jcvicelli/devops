# Sixpack

A terraform script to install sixpack AB test

## Usage:

Initialize terraform:

```
terraform init -backend-config=“access_key=<your-aws-key>” -backend-config=“secret_key=<your-aws-secret>”
```

To view changes on the stack:

```
terraform plan -var-file=vars.tfvars
```

To create the stack:

```
terraform apply -var-file=vars.tfvars
```

To destroy the stack:

```
terraform destroy -var-file=vars.tfvars
```

## Using Sixpack service

```
curl 'http://sixpack.com:5000/participate\?experiment\=new-header\&alternatives\=red\&alternatives\=blue\&client_id\=\123-456'
```

```
https://sixpack.com/experiments.json
```

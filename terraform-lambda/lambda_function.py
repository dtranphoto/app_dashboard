import os
import subprocess
import tempfile
import json
import boto3

def lambda_handler(event, context):
    s3_bucket = "monitor-frontend-site"
    s3_prefix = "terraform/"
    local_path = "terraform"

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            os.chdir(tmpdir)
            print(f"📁 Temp dir: {tmpdir}")

            # Download S3 contents using boto3
            print("📥 Downloading from S3 using boto3...")
            s3 = boto3.client("s3")
            paginator = s3.get_paginator("list_objects_v2")
            for page in paginator.paginate(Bucket=s3_bucket, Prefix=s3_prefix):
                for obj in page.get("Contents", []):
                    s3_key = obj["Key"]
                    rel_path = os.path.relpath(s3_key, s3_prefix)
                    if rel_path == ".":
                        continue  # skip the directory root
                    local_file = os.path.join(local_path, rel_path)
                    os.makedirs(os.path.dirname(local_file), exist_ok=True)
                    print(f"⬇️ {s3_key} → {local_file}")
                    s3.download_file(s3_bucket, s3_key, local_file)

            os.chdir(local_path)
            print(f"📂 Entered terraform directory: {os.getcwd()}")

            print("🔧 terraform init...")
            init_output = subprocess.run(["terraform", "init", "-input=false"], capture_output=True, text=True)
            print(init_output.stdout)

            print("📄 terraform plan...")
            plan_output = subprocess.run(["terraform", "plan", "-input=false"], capture_output=True, text=True)
            print(plan_output.stdout)

            return {
                "statusCode": 200,
                "body": json.dumps({
                    "init_output": init_output.stdout,
                    "plan_output": plan_output.stdout
                })
            }

    except subprocess.CalledProcessError as e:
        print("❌ Terraform error")
        print(f"Command: {e.cmd}")
        print(f"Stderr: {e.stderr}")
        return {
            "statusCode": 500,
            "body": f"Terraform failed: {e.stderr}"
        }

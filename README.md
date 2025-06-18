# 🚦 Service Health Dashboard

A dashboard that monitors service health across companies (e.g. Nintendo, T-Mobile, Tesla). Built with Flask, Ansible, Docker, and ECS. Includes Prometheus, Alertmanager, and Grafana for full observability.

---

## 🔧 Features

- ⚙️ Auto-generated dashboards using Jinja2 templates + Ansible
- 🐳 Dockerized mock API, frontend UI, and monitoring stack
- 📊 Real-time Grafana dashboards with Prometheus metrics
- 🔄 Auto-refreshing health data with realistic mock values
- 🧰 Company theming with SVG logos and color configs
- 🚀 CI/CD deployment to AWS ECS via GitHub Actions

---

## 🗂️ Project Structure

.
├── app/
│ ├── backend/ # Flask mock API for dynamic health data
│ └── frontend/ # Dashboard HTML renderer and static site
│ ├── templates/ # Jinja2 HTML template
│ ├── branding_configs/ # Company branding .yml files
│ ├── services/ # Mock services data (.json)
│ ├── assets_svg/ # Raw SVG logos
│ ├── assets/ # Resized PNG logos for rendered dashboards
│ └── output/ # Final rendered static dashboards
├── Dockerfile.frontend
├── Dockerfile.mock_api
├── docker-compose.yml
├── generate.sh # CLI script to generate themed dashboards
├── render_site.yml # Ansible playbook for HTML rendering
├── terraform/ # ECS infrastructure definitions
└── .github/workflows/ci.yml # GitHub Actions for CI/CD


---

## 🚀 Quick Start

### 1. Generate a company dashboard

```bash
cd app/frontend
./generate.sh nintendo

This will:

Create services/services_nintendo.json

Create branding_configs/branding_config_nintendo.yml

Convert the logo from assets_svg/nintendo.svg → assets/nintendo.png

Render static HTML to output/sites/nintendo/

🔁 Repeat with other companies: ./generate.sh t-mobile, etc.

2. Run locally with Docker Compose
bash
Copy
Edit
docker-compose up --build
Access:

Frontend UI: http://localhost:5000

Mock API: http://localhost:5001/services.json?company=nintendo

3. Deploy to AWS via GitHub Actions
Make sure these secrets are set in your GitHub repo:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

On every push to main, CI/CD will:

Build Docker images for frontend + monitoring stack

Push to AWS ECR

Trigger ECS deployments for:

dashboard-service
prometheus-service
grafana-service
alertmanager-service

🏗️ Infrastructure
Provisioned using Terraform:

ECS Cluster
ECR Repositories
Task Definitions
IAM Roles
Private Subnets (lookup via VPC tag)

To deploy:

bash
Copy
Edit
cd terraform
terraform init
terraform apply

🧠 Technologies
Python + Flask
Jinja2 + Ansible
Docker + ECS Fargate
Prometheus + Grafana + Alertmanager
GitHub Actions CI/CD
Terraform (infra as code)


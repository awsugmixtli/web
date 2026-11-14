# AWS User Group Mixtli — Sitio Web

Repositorio oficial de [awsugmixtli.com](https://awsugmixtli.com) — comunidad de Amazon Web Services en Cholula, Puebla, México.

## Arquitectura

```
GitHub Actions
  ├── build         → Hugo genera, minifica y aplica fingerprint/SRI a CSS/JS → dist/
  ├── deploy-site   → dist/ → S3 + invalidación CloudFront
  └── deploy-lambda → actualiza mixtli-sponsor-form (solo si cambió lambda/index.py)

AWS
  ├── CloudFront  (CDN global, HTTPS, HTTP/3, headers de seguridad vía CF Functions)
  ├── S3          (origen privado, acceso solo vía OAC)
  ├── Lambda      mixtli-sponsor-form  (formulario de patrocinio → SES)
  ├── SES         (envío de correos verificado en dominio)
  └── ACM + Route 53
```

## Stack

| Capa | Tecnología |
|------|-----------|
| Sitio | [Hugo](https://gohugo.io) (extended) — plantillas Go, sin framework de JS |
| Build | Hugo Pipes: `resources.Get` + `js.Build` (esbuild) + `resources.Fingerprint`/SRI |
| Infra | Terraform ≥ 1.7 · AWS provider ~> 6.48 |
| CI/CD | GitHub Actions con OIDC (sin claves de larga duración) |
| CDN | CloudFront · HTTP/3 · TLS 1.3 |
| Email | AWS SES |

---

## Setup inicial (una sola vez)

### 1. Prerequisitos

- AWS CLI configurado con permisos de administrador
- Terraform ≥ 1.7
- [Hugo](https://gohugo.io) extended ≥ 0.162 (solo para compilar/previsualizar en local; CI lo instala automáticamente)

### 2. Aprovisionar infraestructura

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores reales
terraform init
terraform apply
```

Anota los outputs — los necesitarás en el paso siguiente:

```bash
terraform output deploy_role_arn
terraform output cloudfront_distribution_id
terraform output s3_bucket_name
```

### 3. Configurar variables en GitHub Actions

En **Settings → Secrets and variables → Actions → Variables** del repositorio, crea:

| Variable | Valor |
|----------|-------|
| `AWS_DEPLOY_ROLE_ARN` | ARN del output `deploy_role_arn` |
| `CLOUDFRONT_DISTRIBUTION_ID` | ID del output `cloudfront_distribution_id` |
| `S3_BUCKET` | `awsugmixtli.com` |

### 4. Primer deploy

Haz push a `main` y el pipeline correrá automáticamente.

---

## Pipeline (GitHub Actions)

El workflow `.github/workflows/deploy.yml` corre en cada push a `main`, diariamente vía cron (06:00 UTC, para que los eventos pasen de "próximo" a "pasado" sin necesidad de un push) y bajo demanda (`workflow_dispatch`). Tiene tres jobs:

```
push a main / cron diario / workflow_dispatch
  │
  ├─► build          (siempre corre, no necesita credenciales AWS)
  │     hugo --minify --buildFuture --cleanDestinationDir
  │       ← genera dist/, minifica CSS/JS (js.Build vía esbuild), fingerprint + SRI
  │     sube dist/ como artefacto
  │
  ├─► deploy-site    (después de build)
  │     descarga el artefacto dist/
  │     make sync BUCKET=...       ← sube a S3 con Cache-Control por tipo de archivo
  │     make invalidate DISTRIBUTION_ID=...  ← borra caché de CloudFront
  │
  └─► deploy-lambda  (en paralelo con build, solo si cambió lambda/index.py)
        zip + aws lambda update-function-code → mixtli-sponsor-form
```

**Autenticación:** OIDC — GitHub obtiene credenciales AWS temporales sin necesidad de `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` almacenados como secretos.

---

## Desarrollo local

```bash
# Levantar el servidor de desarrollo de Hugo (con drafts y eventos futuros)
hugo server --buildDrafts --buildFuture

# Deploy completo local (build → sync → invalidate; BUCKET/DISTRIBUTION_ID
# se leen automáticamente de `terraform output` si no se pasan explícitos)
make all

# O por pasos
make build
make sync        BUCKET=awsugmixtli.com
make invalidate  DISTRIBUTION_ID=<id>
```

No hay `npm install` ni `node_modules`: todo el build (Hugo templates, minificación de CSS/JS, fingerprinting, SRI) corre a través de Hugo Pipes, sin dependencias externas de Node.

---

## Estructura del proyecto

```
.
├── hugo.toml                Configuración del sitio (idioma, taxonomías, output formats)
├── content/
│   ├── _index.md            Página principal
│   ├── eventos/              Un directorio por evento (page bundle: index.md + imágenes)
│   ├── recursos/             Artículos/recursos
│   ├── patrocinar/           Página de patrocinio
│   └── certification-challenge/
├── layouts/
│   ├── _default/            baseof.html, single.html, list.html, taxonomy.html, llms.txt, ...
│   ├── partials/             head, nav, footer, schema-*.html (JSON-LD), image.html, gallery.html, speakers.html, youtube-*.html, ...
│   ├── eventos/, recursos/, patrocinar/   Plantillas específicas de sección
│   └── sitemap.xml
├── assets/
│   ├── css/                 style.css, sponsor.css, challenge.css (procesados por Hugo Pipes)
│   └── js/                  main.js, sponsor.js (procesados con js.Build/esbuild)
├── static/                  Archivos servidos tal cual (favicons, fuentes, robots.txt, security.txt, ...)
├── data/                    social.yaml, sponsors.yaml
├── archetypes/              Plantillas para `hugo new`
├── lambda/
│   └── index.py             Handler del formulario de patrocinio (mixtli-sponsor-form)
├── terraform/                Infraestructura AWS completa
├── Makefile                  Comandos de build y deploy
└── .github/workflows/deploy.yml
```

`dist/` es el `publishDir` de Hugo (configurado en `hugo.toml`) — se genera en cada build y no se versiona.

---

## Lambda

### `mixtli-sponsor-form`

Recibe POST desde `/api/sponsor` (CloudFront lo proxea). Valida el header `x-origin-secret` para rechazar llamadas directas a la Function URL. Envía el formulario por SES.

---

## Licencia

MIT — ver [LICENSE](LICENSE).

AWS y los logos relacionados son marcas registradas de Amazon.com, Inc. Este es un grupo de usuarios independiente.

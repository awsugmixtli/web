# AWS User Group Mixtli — Sitio Web

Repositorio oficial de [awsugmixtli.com](https://awsugmixtli.com) — comunidad de Amazon Web Services en Cholula, Puebla, México.

## Arquitectura

```
GitHub Actions
  ├── build      → minifica CSS/JS, inyecta hashes SRI → dist/
  ├── deploy-site → dist/ → S3 + invalidación CloudFront
  └── deploy-lambda → actualiza Lambdas (solo si cambiaron)

AWS
  ├── CloudFront  (CDN global, HTTPS, HTTP/3, headers de seguridad vía CF Function)
  ├── S3          (origen privado, acceso solo vía OAC)
  ├── Lambda      mixtli-sponsor-form  (formulario de patrocinio → SES)
  ├── Lambda      mixtli-ics-sync      (sincroniza iCal de Meetup → S3 JSON)
  ├── SES         (envío de correos verificado en dominio)
  └── ACM + Route 53
```

## Stack

| Capa | Tecnología |
|------|-----------|
| Frontend | HTML, CSS, JS — sin frameworks |
| Build | Node.js 24 · `lightningcss` · `terser` |
| Infra | Terraform ≥ 1.7 · AWS provider ~> 5.0 |
| CI/CD | GitHub Actions con OIDC (sin claves de larga duración) |
| CDN | CloudFront · HTTP/3 · TLS 1.3 |
| Email | AWS SES |

---

## Setup inicial (una sola vez)

### 1. Prerequisitos

- AWS CLI configurado con permisos de administrador
- Terraform ≥ 1.7
- Node.js ≥ 22

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

El workflow `.github/workflows/deploy.yml` tiene tres jobs:

```
push a main
  │
  ├─► build          (siempre corre)
  │     npm install
  │     node scripts/build.js   ← minifica, inyecta SRI, genera dist/
  │     sube dist/ como artefacto
  │
  ├─► deploy-site    (después de build)
  │     descarga dist/
  │     make sync     ← sube a S3 con Cache-Control por tipo de archivo
  │     make invalidate ← borra caché de CloudFront
  │
  └─► deploy-lambda  (en paralelo con build, solo si cambiaron .py)
        lambda/index.py   → mixtli-sponsor-form
        lambda/ics_sync.py → mixtli-ics-sync
```

**Autenticación:** OIDC — GitHub obtiene credenciales AWS temporales sin necesidad de `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` almacenados como secretos.

---

## Desarrollo local

```bash
# Instalar dependencias de build
npm install

# Compilar (genera dist/)
node scripts/build.js

# Deploy completo local
make all BUCKET=awsugmixtli.com DISTRIBUTION_ID=<id>

# O por pasos
make build
make sync        BUCKET=awsugmixtli.com
make invalidate  DISTRIBUTION_ID=<id>
```

> **Nota:** La primera vez que corras `npm install` localmente se generará `package-lock.json`. Haz commit de ese archivo para que CI use `npm ci` en lugar de `npm install`.

---

## Estructura del proyecto

```
.
├── index.html              Página principal
├── sponsor.html            Formulario de patrocinio
├── robots.txt
├── sitemap.xml
├── llms.txt                Descripción para agentes de IA
├── .well-known/
│   └── security.txt        Contacto de seguridad (RFC 9116)
├── assets/
│   ├── style.css           Estilos principales (fuente: sin minificar)
│   ├── sponsor.css
│   ├── main.js
│   ├── sponsor.js
│   ├── *.woff2             Fuentes Ember (Amazon brand)
│   └── ...                 Imágenes, íconos, favicons
├── events/
│   └── next.json           Escrito por Lambda mixtli-ics-sync (no editar)
├── lambda/
│   ├── index.py            Handler del formulario de patrocinio
│   └── ics_sync.py         Sincronizador iCal → JSON
├── scripts/
│   └── build.js            Script de build (minificación + SRI)
├── terraform/              Infraestructura AWS completa
├── Makefile                Comandos de build y deploy
└── package.json            Dependencias de build (lightningcss, terser)
```

---

## Lambdas

### `mixtli-sponsor-form`

Recibe POST desde `/api/sponsor` (CloudFront lo proxea). Valida el header `x-origin-secret` para rechazar llamadas directas a la Function URL. Envía el formulario por SES.

### `mixtli-ics-sync`

Se ejecuta todos los lunes a las 06:00 UTC vía EventBridge. Descarga el feed iCal de Meetup, extrae el próximo evento y escribe `events/next.json` en S3.

---

## Licencia

MIT — ver [LICENSE](LICENSE).

AWS y los logos relacionados son marcas registradas de Amazon.com, Inc. Este es un grupo de usuarios independiente.

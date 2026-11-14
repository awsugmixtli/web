---
# ─────────────────────────────────────────────────────────────
# NUEVO ARTÍCULO — AWS UG Mixtli
# Uso: hugo new recursos/<slug>/index.md
# ─────────────────────────────────────────────────────────────

# Título H1 de la página. Apunta a la consulta principal que
# quieres rankear: "Cómo hacer X en AWS", "Guía de Y para Z".
title: "{{ replace .File.ContentBaseName "-" " " | title }}"

# Fecha de publicación (se usa para ordenar en /recursos/).
date: {{ .Date | time.Format "2006-01-02" }}

# Actualiza este campo cada vez que hagas cambios sustanciales.
# Aparece en la página como "Actualizado: …".
lastmod: {{ .Date | time.Format "2006-01-02" }}

slug: "{{ .File.ContentBaseName }}"

# Descripción para Google (meta description) y para la tarjeta
# en /recursos/. Sé específico: qué aprende el lector y por qué
# importa. Ideal 140–160 caracteres.
description: >
  

# Palabras clave secundarias para el <head>. Incluye variantes
# de la consulta principal, el servicio AWS específico y el
# contexto geográfico si aplica ("AWS México", "Puebla").
keywords:
  - ""
  - "AWS México"

# Taxonomías — generan páginas /tags/X/ y /topics/Y/ automáticamente.
# tags: términos específicos (IAM, Lambda, DynamoDB…)
# topics: categorías amplias — elige de la lista del sitio:
#   Arquitectura Cloud | DevOps & CI/CD | Serverless | Seguridad en AWS
#   Machine Learning | FinOps & Cost Optimization | Bases de datos
#   Contenedores & Kubernetes | Analytics & Big Data | Networking & CDN
tags:
  - ""
topics:
  - ""

author: "AWS UG Mixtli"

# Ruta a imagen Open Graph específica del artículo (relativa a
# static/). Déjalo vacío para usar la imagen global del sitio.
og_image: ""

# Mantén draft: true mientras escribes. Cambia a false para publicar.
draft: true

sitemap:
  priority: 0.8
---

<!-- ============================================================
     GUÍA DE ESCRITURA — borra esta sección antes de publicar
     ============================================================

ESTRUCTURA RECOMENDADA:
  - Párrafo de apertura: define el problema y por qué importa (sin H2)
  - ## Sección 1 — concepto o contexto
  - ## Sección 2 — implementación / cómo hacerlo
  - ## Sección 3 — errores comunes o trade-offs
  - ## Recursos adicionales — links a docs AWS y eventos relacionados

LONGITUD: mínimo 600 palabras. Google favorece contenido que cubre
el tema con suficiente profundidad. No rellenes — cada párrafo debe
aportar valor concreto.

LINKS INTERNOS: enlaza a eventos relacionados con la sintaxis:
  [Evento: Título del evento](/eventos/slug-del-evento/)
Esto mejora el SEO interno y da contexto al lector.

CÓDIGO: usa bloques de código con el lenguaje correcto:
  ```bash
  aws iam list-roles --query 'Roles[].RoleName'
  ```
  ```json
  { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "*" }
  ```

============================================================ -->

Párrafo introductorio — define el problema que resuelve este artículo
y por qué le importa al lector. No uses H2 aquí; entra directo al punto.

## Primera sección

Contenido...

## Segunda sección

Contenido...

## Recursos adicionales

- [Documentación AWS](https://docs.aws.amazon.com/)
- [Evento relacionado: Título](/eventos/slug/)

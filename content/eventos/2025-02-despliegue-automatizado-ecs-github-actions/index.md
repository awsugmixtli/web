---
title: "Despliegue Automatizado: AWS ECS y GitHub Actions"
date: 2025-02-20T18:30:00-06:00
slug: "despliegue-automatizado-ecs-github-actions"
description: >
  Cómo construir un pipeline de CI/CD completo con GitHub Actions y Amazon ECS. Desde el commit hasta producción: construcción de imagen Docker, push a ECR, despliegue en ECS Fargate y rollback automático. Demostración práctica con una aplicación real y las mejores prácticas de seguridad en el pipeline.
keywords: ["CI/CD AWS", "GitHub Actions ECS", "Amazon ECS Fargate", "DevOps AWS Puebla", "pipeline deployment"]
venue: "Workósfera Coworking"
locality: "Cholula"
meetup_url: "https://www.meetup.com/awsugmixtli/"
youtube_url: ""
og_image: ""
speakers:
  - name: "AWS UG Mixtli"
    role: "Comunidad AWS Cholula"
tags: ["DevOps", "CI/CD", "ECS", "GitHub Actions", "Docker"]
topics: ["DevOps & CI/CD", "Contenedores & Kubernetes"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

Los pipelines de CI/CD son la columna vertebral de los equipos de ingeniería modernos. En este meetup, exploramos cómo integrar GitHub Actions con Amazon ECS para lograr despliegues automatizados, seguros y reproducibles — desde que un desarrollador hace push de código hasta que la nueva versión está corriendo en producción.

La demostración cubrió el flujo completo: configuración del repositorio en GitHub, construcción de la imagen Docker y push a Amazon ECR, definición de la task definition en ECS, y el despliegue controlado en ECS Fargate con sustitución de servicios. Se prestó atención especial a los secretos y credenciales: cómo usar IAM Roles para GitHub Actions con OIDC (sin access keys hardcodeadas), y cómo proteger las variables de entorno con AWS Secrets Manager.

También se revisaron estrategias de despliegue: rolling update, blue/green con CodeDeploy, y cómo configurar alarmas de CloudWatch para rollback automático cuando una nueva versión falla sus health checks.

## Puntos clave

- Configuración de IAM OIDC para GitHub Actions (sin access keys)
- Amazon ECR: repositorio privado de imágenes Docker
- ECS Fargate vs EC2 Launch Type: cuándo usar cada uno
- Blue/Green deployment con CodeDeploy
- Rollback automático con CloudWatch Alarms
- Gestión de secretos con AWS Secrets Manager

## Recursos

- [GitHub Actions para AWS](https://github.com/aws-actions)
- [Documentación Amazon ECS](https://docs.aws.amazon.com/ecs/)
- [OIDC con GitHub Actions y AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

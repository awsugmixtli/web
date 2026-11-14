---
title: "Implementando DevSecOps para Entornos de Nube"
date: 2025-07-10T18:30:00-06:00
slug: "devsecops-entornos-nube"
description: >
  Cómo integrar seguridad en cada etapa del ciclo de vida de desarrollo en AWS. Desde escaneo de código estático hasta detección de amenazas en tiempo de ejecución: AWS Security Hub, GuardDuty, Inspector, CodeGuru Security y políticas de IAM con mínimo privilegio. Una guía práctica para llevar DevSecOps de teoría a producción.
keywords: ["DevSecOps AWS", "seguridad AWS pipeline", "GuardDuty", "AWS Security Hub", "seguridad cloud México"]
venue: "Workósfera Coworking"
locality: "Cholula"
meetup_url: "https://www.meetup.com/awsugmixtli/"
youtube_url: ""
og_image: ""
speakers:
  - name: "AWS UG Mixtli"
    role: "Comunidad AWS Cholula"
tags: ["DevSecOps", "Seguridad", "GuardDuty", "IAM", "DevOps"]
topics: ["Seguridad en AWS", "DevOps & CI/CD"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

DevSecOps no es un producto ni una herramienta — es una cultura que integra la seguridad en cada fase del ciclo de vida del software. En entornos cloud, esto significa que las vulnerabilidades deben detectarse en el código antes del commit, en las imágenes de contenedor antes del despliegue, y en la infraestructura en tiempo de ejecución.

La sesión presentó una arquitectura de seguridad por capas para AWS: escaneo de dependencias con Dependabot y Amazon CodeGuru Security en el pipeline de CI/CD, análisis de imágenes Docker con Amazon ECR Image Scanning, evaluación de postura de seguridad con AWS Security Hub, y detección de amenazas en tiempo real con GuardDuty.

Se discutieron casos concretos: cómo GuardDuty detecta credenciales IAM comprometidas, cómo Inspector identifica vulnerabilidades en instancias EC2 y contenedores, y cómo estructurar políticas de IAM con mínimo privilegio para limitar el blast radius de un incidente.

## Puntos clave

- Shift-left security: escaneo en cada etapa del pipeline
- Amazon GuardDuty: detección de amenazas basada en ML
- AWS Security Hub: vista unificada de postura de seguridad
- Amazon Inspector: vulnerabilidades en EC2, Lambda y contenedores
- IAM con mínimo privilegio: Access Analyzer y políticas granulares
- Respuesta a incidentes con AWS CloudTrail y Security Hub

## Recursos

- [AWS Security Hub](https://aws.amazon.com/security-hub/)
- [Amazon GuardDuty](https://aws.amazon.com/guardduty/)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)
- [OWASP Top 10 en AWS](https://owasp.org/www-project-top-ten/)

---
title: "Acelerando el Desarrollo: Aplicaciones Web con AWS Amplify"
date: 2025-08-14T18:30:00-06:00
slug: "aplicaciones-web-aws-amplify"
description: >
  AWS Amplify permite a equipos frontend y full-stack desplegar aplicaciones web completas en AWS sin gestionar infraestructura compleja. Exploración de Amplify Gen 2: autenticación con Cognito, APIs GraphQL y REST, almacenamiento con S3, y despliegue continuo desde GitHub. Demo en vivo con una aplicación React completa.
keywords: ["AWS Amplify", "Amplify Gen 2", "desarrollo web AWS", "React AWS", "full-stack AWS Puebla"]
venue: "Workósfera Coworking"
locality: "Cholula"
meetup_url: "https://www.meetup.com/awsugmixtli/"
youtube_url: ""
og_image: ""
speakers:
  - name: "AWS UG Mixtli"
    role: "Comunidad AWS Cholula"
tags: ["Amplify", "Frontend", "React", "Serverless", "Full-Stack"]
topics: ["Serverless", "DevOps & CI/CD"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

AWS Amplify Gen 2 representa una evolución importante: en lugar de una CLI con magia implícita, ahora la infraestructura se define en TypeScript con el mismo lenguaje que usan los desarrolladores frontend. El resultado es un flujo de desarrollo más predecible, mejor integración con IDEs, y una experiencia de CI/CD que funciona desde el primer commit.

En este meetup se hizo una demostración completa: desde `npm create amplify@latest` hasta una aplicación React en producción con autenticación (Cognito), base de datos (DynamoDB via AppSync), almacenamiento de archivos (S3) y funciones serverless (Lambda). Todo con despliegue automático desde GitHub en minutos.

Se comparó Amplify con alternativas: cuándo Amplify tiene sentido vs. construir la infraestructura manualmente con CDK o Terraform. La respuesta depende del equipo, la velocidad requerida y cuánto control se necesita sobre cada componente.

## Puntos clave

- AWS Amplify Gen 2: arquitectura y diferencias con Gen 1
- Autenticación con Amazon Cognito: user pools, identity pools y MFA
- APIs con AppSync (GraphQL) y API Gateway (REST)
- Almacenamiento con S3 y acceso granular por usuario
- CI/CD automático: branch previews y despliegue en producción
- Cuándo usar Amplify vs. CDK vs. Terraform

## Recursos

- [AWS Amplify — documentación oficial](https://docs.amplify.aws/)
- [Amplify Gen 2 — guía de inicio](https://docs.amplify.aws/react/start/)
- [AWS Amplify Discord](https://discord.gg/amplify)

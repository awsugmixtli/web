---
title: "Guía de Supervivencia para IAM: Cómo No Ponerle Admin a Todo"
date: 2026-03-27T18:30:00-06:00
slug: "guia-supervivencia-iam"
description: >
  Charla práctica sobre políticas IAM, roles y el principio de mínimo privilegio en AWS. Los errores de seguridad más costosos en producción pasan por IAM mal configurado. Aprende a estructurar políticas granulares, auditar permisos con IAM Access Analyzer, y eliminar el hábito de usar AdministratorAccess para todo.
keywords: ["IAM AWS", "seguridad IAM", "mínimo privilegio AWS", "IAM Access Analyzer", "seguridad AWS Puebla"]
venue: "Workósfera Coworking"
locality: "Cholula"
meetup_url: "https://www.meetup.com/awsugmixtli/events/313433227/"
youtube_url: ""
og_image: ""
speakers:
  - name: "AWS UG Mixtli"
    role: "Comunidad AWS Cholula"
tags: ["IAM", "Seguridad", "Mínimo Privilegio", "Fundamentos"]
topics: ["Seguridad en AWS"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

"Ponle Admin y ya" es la frase más peligrosa en un equipo de ingeniería cloud. IAM (Identity and Access Management) es el sistema nervioso de la seguridad en AWS — y también el lugar donde ocurren los incidentes más costosos: credenciales comprometidas con permisos excesivos, roles con wildcards en acciones y recursos, y usuarios con acceso programático que nunca rotan sus keys.

Esta charla es una guía práctica para salir del caos de IAM sin entrar en parálisis por análisis. Cubrimos los conceptos fundamentales que todo ingeniero que trabaja con AWS debe dominar: policies vs. roles vs. groups, cuándo usar roles de instancia vs. roles de servicio, y cómo el principio de mínimo privilegio se implementa de manera pragmática sin bloquear el trabajo del equipo.

IAM Access Analyzer es la herramienta más subutilizada de la consola de AWS — y una de las más valiosas para identificar permisos excesivos, recursos públicos involuntarios y rutas de escalación de privilegios.

## Puntos clave

- Por qué `AdministratorAccess` es un riesgo aunque "confíes en tu equipo"
- Anatomía de una política IAM: Effect, Action, Resource, Condition
- Roles de servicio vs. roles de instancia vs. IAM Users
- IAM Access Analyzer: encontrar y cerrar accesos innecesarios
- Service Control Policies (SCPs) en AWS Organizations
- Rotación de credenciales y AWS Secrets Manager

## Recursos

- [IAM Best Practices — AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)
- [AWS Policy Simulator](https://policysim.aws.amazon.com/)
- [Regístrate en Meetup](https://www.meetup.com/awsugmixtli/events/313433227/)

---
title: "Guía de Supervivencia para IAM: Cómo No Ponerle Admin a Todo"
date: 2026-03-27T18:30:00-06:00
slug: "guia-supervivencia-iam"
description: >
  Sabemos que estás aquí porque en algún momento de tu carrera dijiste: "Le pongo Admin y ya veo después". Spoiler alert: nunca viste después ⚠️
keywords: ["IAM AWS", "seguridad IAM", "mínimo privilegio AWS", "IAM Access Analyzer", "seguridad AWS Puebla"]
venue: "Workósfera Coworking"
locality: "Puebla"
meetup_url: "https://www.meetup.com/awsugmixtli/events/313433227/"
youtube_url: ""
og_image: "banner.png"
speakers:
  - name: "Mario Meza"
    role: "Engineering Manager @ Caylent"
    photo: "mario-meza.jpg"
    bio: ""
    linkedin: "https://www.linkedin.com/in/mario-meza-c/"
tags: ["IAM", "Seguridad", "Mínimo Privilegio", "Fundamentos"]
topics: ["Seguridad en AWS"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

Sabemos que estás aquí porque en algún momento de tu carrera dijiste: *"Le pongo Admin y ya veo después"*.

**Spoiler alert: nunca viste después ⚠️**

En esta charla de supervivencia en la selva de AWS IAM, aprenderemos juntos a:

* Reconocer los síntomas de la "adminitis aguda" (cuando todo tiene AdministratorAccess porque "no tengo tiempo")
* Desintoxicarte del Action: [""] y Resource: [""] (es difícil, pero se puede)
* Usar el principio de menor privilegio sin que tus developers te lancen su laptop
* Entender qué permisos necesita REALMENTE tu Lambda (pista: no es DeleteAllThings)
* Roles de IAM: cómo delegar sin repartir llaves maestras como si fueran dulces
* Policy Simulator: tu nuevo mejor amigo para no romper producción a las 3 AM

Incluye casos reales de terror, mejores prácticas que sí funcionan, y un espacio seguro para confesar tus pecados de IAM.

* Requisitos: Haber usado Administrator al menos una vez en tu vida y sentirte ligeramente culpable por ello.
* Promesa: Saldrás sabiendo cómo hacer IAM correctamente... o al menos menos incorrectamente .


## Puntos clave

- Por qué `AdministratorAccess` es un riesgo aunque "confíes en tu equipo"
- Anatomía de una política IAM: Effect, Action, Resource, Condition
- IAM Access Analyzer: encontrar y cerrar accesos innecesarios
- Service Control Policies (SCPs) en AWS Organizations

## Recursos

- [IAM Best Practices — AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)
- [AWS Policy Simulator](https://policysim.aws.amazon.com/)
- [Regístrate en Meetup](https://www.meetup.com/awsugmixtli/events/313433227/)

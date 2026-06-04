---
title: "Modern Serverless Architectures y Lambda Managed Instances"
date: 2026-01-22T18:30:00-06:00
slug: "serverless-moderno-lambda-managed-instances"
description: >
  Las arquitecturas serverless modernas van mucho más allá de una función Lambda aislada. En este meetup exploramos composición de servicios, el nuevo modelo de Lambda Managed Instances para cargas de trabajo con estado, Step Functions para orquestación, y cómo construir sistemas serverless resilientes y observables en producción.
keywords: ["Lambda Managed Instances", "serverless moderno AWS", "Step Functions", "arquitectura serverless 2026"]
venue: "Workósfera Coworking"
locality: "Cholula"
meetup_url: "https://www.meetup.com/awsugmixtli/"
youtube_url: ""
og_image: ""
speakers:
  - name: "AWS UG Mixtli"
    role: "Comunidad AWS Cholula"
tags: ["Serverless", "Lambda", "Step Functions", "Arquitectura"]
topics: ["Serverless", "Arquitectura Cloud"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

La madurez del ecosistema serverless en 2026 se refleja en patrones más sofisticados: ya no hablamos de funciones Lambda aisladas sino de sistemas completos compuestos de servicios administrados, integrados con Step Functions para orquestación, EventBridge para comunicación basada en eventos, y el nuevo modelo de Lambda Managed Instances para cargas de trabajo que requieren estado o inicialización costosa.

Lambda Managed Instances representa una evolución importante: permite que Lambda mantenga instancias "calientes" con inicialización realizada, eliminando el cold start para aplicaciones que cargan modelos de ML, conexiones a bases de datos o configuración extensa. Es una respuesta directa a los casos de uso de IA generativa que habían empujado a muchos equipos de vuelta hacia ECS.

La sesión exploró cómo combinar estos bloques: cuándo Step Functions (Express vs. Standard), cómo diseñar el modelo de eventos para sistemas loosely coupled, y las estrategias de observabilidad para sistemas distribuidos serverless.

## Puntos clave

- Lambda Managed Instances: modelo de ejecución y casos de uso
- Step Functions Express Workflows para alta frecuencia
- EventBridge Pipes y Scheduler para integración sin código
- Patrones de resiliencia: retries, dead-letter queues y circuit breakers
- Observabilidad: Lambda Powertools, X-Ray y CloudWatch Logs Insights
- Costos avanzados: right-sizing de memoria y ARM (Graviton)

## Recursos

- [AWS Lambda Managed Instances](https://docs.aws.amazon.com/lambda/latest/dg/configuration-managed-instances.html)
- [AWS Step Functions](https://aws.amazon.com/step-functions/)
- [AWS Lambda Powertools](https://docs.powertools.aws.dev/lambda/python/)

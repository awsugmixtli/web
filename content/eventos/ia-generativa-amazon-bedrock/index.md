---
title: "IA Generativa con Amazon Bedrock"
date: 2025-09-11T18:30:00-06:00
slug: "ia-generativa-amazon-bedrock"
description: >
  Deep dive en Amazon Bedrock: cómo construir aplicaciones de IA generativa en producción con modelos de Anthropic Claude, Meta Llama y Amazon Titan. Patrones de arquitectura para RAG (Retrieval Augmented Generation), Agents, guardrails de seguridad y evaluación de modelos. Demo en vivo con una aplicación real.
keywords: ["Amazon Bedrock", "IA generativa AWS", "Claude AWS", "RAG AWS", "LLM producción México"]
venue: "Workósfera Coworking"
locality: "Cholula"
meetup_url: "https://www.meetup.com/awsugmixtli/"
youtube_url: ""
og_image: ""
speakers:
  - name: "AWS UG Mixtli"
    role: "Comunidad AWS Cholula"
tags: ["Bedrock", "IA Generativa", "Claude", "RAG", "Machine Learning"]
topics: ["Machine Learning"]
gallery: []
draft: false
sitemap:
  priority: 0.8
---

## Sobre la charla

Amazon Bedrock se estableció en 2025 como la plataforma de referencia para construir aplicaciones de IA generativa en AWS. Su propuesta: acceso unificado a los mejores modelos fundacionales del mercado — Anthropic Claude, Meta Llama, Mistral, Cohere, Amazon Titan — con la seguridad, privacidad y controles de una plataforma empresarial.

El meetup ofreció un deep dive técnico: desde la API de Bedrock para inferencia básica hasta patrones avanzados como Retrieval Augmented Generation (RAG) con Knowledge Bases, Agents para orquestar flujos multi-paso, y Guardrails para control de contenido y seguridad.

Se demostró cómo construir un asistente de preguntas y respuestas sobre documentación interna: ingesta de PDFs en S3 → vectorización con Bedrock Embeddings → almacenamiento en OpenSearch Serverless → recuperación semántica → respuesta con Claude. Todo en AWS, sin infraestructura de ML que mantener.

## Puntos clave

- Amazon Bedrock: modelos disponibles y diferencias clave
- Bedrock Knowledge Bases: RAG sin infraestructura propia
- Bedrock Agents: flujos multi-paso con herramientas externas
- Guardrails: filtrado de contenido, PII y temas sensibles
- Evaluación de modelos: cómo medir calidad de respuestas
- Costos: tokens, on-demand vs. provisionado

## Recursos

- [Amazon Bedrock — documentación](https://docs.aws.amazon.com/bedrock/)
- [Bedrock User Guide: Knowledge Bases](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)
- [Anthropic Claude en AWS](https://aws.amazon.com/bedrock/claude/)

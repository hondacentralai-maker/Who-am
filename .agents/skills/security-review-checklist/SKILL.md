---
name: security-review-checklist
description: Review application design and code for security risks using proportionate OWASP ASVS and WSTG guidance. Use for authentication, authorization, personal data, APIs, uploads, payments, admin areas, deployment, or security reviews.
---

# Security Review Checklist

Use this checklist proportionately to the application's risk. Consult current official OWASP references rather than assuming this short checklist replaces them.

## Review sequence
1. Map assets, trust boundaries, user roles, sensitive data, external services, and abuse cases.
2. Authentication: secure password/session handling, MFA where risk warrants it, reset flows, rate limits, session rotation and logout.
3. Authorization: enforce server-side access checks for every protected operation and record; test cross-user and cross-role access.
4. Input/output: validate on the server, parameterize database queries, encode output, defend against XSS/CSRF/SSRF/injection as applicable.
5. Data: minimize collection, encrypt transport, restrict logs, define retention/deletion, avoid exposing secrets or personal data.
6. Files and uploads: type/size limits, content validation, safe storage, malware controls where appropriate, no executable public uploads.
7. APIs and integrations: authentication, authorization, rate limiting, timeouts, retries, webhook signature validation, least-privilege tokens.
8. Dependencies and configuration: review known vulnerabilities, lock dependencies, remove debug endpoints, secure CORS and headers, separate environments.
9. Operations: audit security-relevant events without logging secrets, define backup/restore, incident response and monitoring proportionate to risk.
10. Tests: add negative tests for unauthenticated access, privilege escalation, invalid input, abuse limits, and tenant/user isolation.

## Report format
For each finding record: severity, affected location, realistic impact, evidence, remediation, and verification test. Separate confirmed vulnerabilities from risks requiring further investigation. Do not claim compliance certification based on this checklist.

## Official references
- OWASP ASVS: https://github.com/OWASP/ASVS
- OWASP Web Security Testing Guide: https://github.com/OWASP/wstg

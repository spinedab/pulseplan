# Security Policy

## Supported Versions

| Version   | Supported          | Notes                              |
|-----------|--------------------|------------------------------------|
| 1.0.1+2   | ✅ Active          | Current production release         |
| < 1.0.0   | ❌ Not supported   | Development / pre-release builds   |

## Scope & Threat Model

**PulsePlan is a personal planning tool only.**

It is **explicitly designed** to help individuals organize their own authorized listening routines. It does **not**:

- Store or transmit any credentials, passwords, or tokens
- Automate logins or sessions on third-party platforms
- Simulate user behavior to manipulate streaming services
- Perform any network requests except user-initiated opening of Tidal.com via the system browser
- Access, read, or modify any external application data

All data remains **strictly local** on the user's device using SharedPreferences.

## Reporting a Vulnerability

If you discover a security issue in PulsePlan (for example, an unintended data exposure, injection vector, or flaw in the local persistence layer), please report it responsibly:

1. **Do not** create public GitHub issues for security reports.
2. Contact the maintainers privately (or open a private security advisory if hosted on GitHub).
3. Include as much detail as possible (steps to reproduce, affected versions, potential impact).

We commit to responding to security reports within 14 days.

## Responsible Use Reminder

Users of this software are expected to:
- Only use it for personal, authorized activities
- Comply with the Terms of Service of any music streaming platforms they use
- Understand that this tool provides **planning assistance only**, not automation or circumvention capabilities

Any use outside the declared safe personal scope is considered outside the intended purpose of this software.

---

**Last updated:** 2026-05 (v1.0.1+2)
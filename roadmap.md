# OpenSocial Ecosystem Development Roadmap

**Version:** 1.0  
**Last Updated:** November 4, 2025  
**Author:** Rob Zaar (rjzaar)

---

## Table of Contents

### [Executive Summary](#executive-summary)

### [1. Repository Ecosystem Overview](#1-repository-ecosystem-overview)
- [1.1 System Architecture](#11-system-architecture)
- [1.2 Repository Relationships](#12-repository-relationships)
- [1.3 Data Flow](#13-data-flow)

### [2. commons_template - Foundation Layer](#2-commons_template---foundation-layer)
- [2.1 Purpose and Functionality](#21-purpose-and-functionality)
- [2.2 Current Status](#22-current-status)
- [2.3 Outstanding Tasks](#23-outstanding-tasks)

### [3. workflow_assignment - Feature Module Layer](#3-workflow_assignment---feature-module-layer)
- [3.1 Purpose and Functionality](#31-purpose-and-functionality)
- [3.2 Architecture](#32-architecture)
- [3.3 Current Status](#33-current-status)
- [3.4 Outstanding Tasks](#34-outstanding-tasks)

### [4. commons_install - Automation Layer](#4-commons_install---automation-layer)
- [4.1 Purpose and Functionality](#41-purpose-and-functionality)
- [4.2 Installation Scripts](#42-installation-scripts)
- [4.3 Current Status](#43-current-status)
- [4.4 Outstanding Tasks](#44-outstanding-tasks)

### [5. opensocial-moodle-sso-integration - Integration Layer](#5-opensocial-moodle-sso-integration---integration-layer)
- [5.1 Purpose and Functionality](#51-purpose-and-functionality)
- [5.2 Architecture](#52-architecture)
- [5.3 Current Status](#53-current-status)
- [5.4 Outstanding Tasks](#54-outstanding-tasks)

### [6. Development Phases](#6-development-phases)
- [6.1 Phase 1: Stabilization (1-2 months)](#61-phase-1-stabilization-1-2-months)
- [6.2 Phase 2: Feature Enhancement (2-3 months)](#62-phase-2-feature-enhancement-2-3-months)
- [6.3 Phase 3: Production Hardening (2-3 months)](#63-phase-3-production-hardening-2-3-months)
- [6.4 Phase 4: Advanced Features (3-4 months)](#64-phase-4-advanced-features-3-4-months)

### [7. Complexity & Skills Matrix](#7-complexity--skills-matrix)
- [7.1 By Repository](#71-by-repository)
- [7.2 By Task Type](#72-by-task-type)

### [8. Immediate Action Items](#8-immediate-action-items)

### [9. Long-Term Vision](#9-long-term-vision)

### [10. Resource Requirements](#10-resource-requirements)

### [11. Success Metrics](#11-success-metrics)

### [Appendix A: Technology Stack](#appendix-a-technology-stack)

### [Appendix B: Glossary](#appendix-b-glossary)

---

## Executive Summary

This roadmap outlines the development strategy for an interconnected ecosystem of repositories designed to build, deploy, and manage OpenSocial-based community platforms with advanced workflow management and Learning Management System (LMS) integration capabilities.

**The ecosystem consists of four primary repositories:**

1. **commons_template** - Foundation layer providing base installation template
2. **workflow_assignment** - Feature module for flexible workflow management
3. **commons_install** - Automation layer with installation scripts
4. **opensocial-moodle-sso-integration** - Full integration with Moodle LMS via OAuth2 SSO

**Current State:** The core infrastructure is functional with basic features implemented. The system can successfully install OpenSocial with custom workflow capabilities and basic Moodle integration.

**Target State:** A production-ready, fully-integrated platform with comprehensive workflow management, bidirectional badge synchronization, enhanced security, and enterprise-grade deployment capabilities.

**Timeline:** 10-12 months across four development phases  
**Estimated Effort:** 800-1200 developer hours  
**Priority Focus:** Stabilization, badge synchronization, security hardening

[Back to Top](#table-of-contents)

---

## 1. Repository Ecosystem Overview

### 1.1 System Architecture

The repository ecosystem forms an integrated development stack for building and deploying OpenSocial-based community platforms.

```
┌─────────────────────────────────────────────────────────┐
│                    End User Experience                   │
│  (Community Platform with Workflows & LMS Integration)  │
└───────────────────────┬─────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────┐
│              opensocial-moodle-sso-integration          │
│                   (Integration Layer)                    │
│  • OAuth2 SSO between OpenSocial ↔ Moodle              │
│  • Badge Synchronization                                 │
│  • Unified Installation                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
┌───────▼─────────┐            ┌────────▼────────┐
│  commons_install│            │  commons_template│
│ (Automation)    │            │   (Foundation)   │
│  • cinstall.sh  │◄───────────│  • Composer      │
│  • moodle_*.sh  │            │  • Open Social   │
└───────┬─────────┘            └────────┬─────────┘
        │                               │
        │                    ┌──────────▼──────────┐
        └────────────────────►workflow_assignment  │
                             │   (Feature Module)  │
                             │  • Workflow Lists   │
                             │  • Assignments      │
                             └─────────────────────┘
```

### 1.2 Repository Relationships

| Repository | Type | Role | Dependencies |
|------------|------|------|--------------|
| **commons_template** | Composer Project | Base template for OpenSocial installations | Open Social core, workflow_assignment |
| **workflow_assignment** | Drupal Module | Adds workflow management to content | Drupal core, dynamic_entity_reference, twig_tweak |
| **commons_install** | Bash Scripts | Automates installation process | commons_template, DDEV |
| **opensocial-moodle-sso** | Integration Project | Connects OpenSocial with Moodle | commons_install, Moodle, OAuth2 libraries |

### 1.3 Data Flow

**Installation Flow:**
```
User runs script → commons_install/cinstall.sh
    ↓
Downloads commons_template via Composer
    ↓
Installs Open Social + workflow_assignment
    ↓
Configures DDEV environment
    ↓
Ready-to-use OpenSocial site
```

**Integration Flow:**
```
User runs → opensocial_moodle_sso_complete.sh
    ↓
Installs OpenSocial (via cinstall.sh logic)
    ↓
Installs Moodle (via moodle_install.sh logic)
    ↓
Configures OAuth2 (OpenSocial = IdP, Moodle = Client)
    ↓
Sets up badge sync (partially implemented)
    ↓
Integrated platform ready
```

[Back to Top](#table-of-contents)

---

## 2. commons_template - Foundation Layer

**Repository:** `rjzaar/commons_template`  
**Type:** Composer Project Template  
**Current Version:** dev-master

### 2.1 Purpose and Functionality

Provides Composer-based installer for Open Social distribution. Acts as the starting point for all new OpenSocial installations.

**Key Capabilities:**
- Structured project template following Drupal best practices
- Automatically pulls Open Social distribution (~12.4.13)
- Includes workflow_assignment module as core dependency
- Manages patches for PHP 8.2 compatibility

### 2.2 Current Status

**✅ Completed:**
- Basic Composer project structure
- Integration with workflow_assignment module
- PHP 8.2 compatibility patch
- Available on Packagist

**❌ Known Issues:**
- No automated testing pipeline
- Limited customization documentation
- Version constraints may be too restrictive

### 2.3 Outstanding Tasks

#### Task 1: Update Open Social Version Management
- **Difficulty:** ⭐ Easy
- **Time:** 2-4 hours
- **Skills:** Composer, Semantic Versioning
- **Description:** Make version constraints more flexible to allow minor updates while maintaining compatibility

#### Task 2: Enhanced Patch Management
- **Difficulty:** ⭐⭐ Medium
- **Time:** 4-8 hours
- **Skills:** Composer, Drupal patching, Git
- **Description:** Add Ultimate Cron Drush 12 patch and document all patches with issue references

#### Task 3: Add Environment Detection
- **Difficulty:** ⭐⭐ Medium
- **Time:** 6-10 hours
- **Skills:** Composer, PHP, Environment Management
- **Description:** Differentiate between dev/staging/production installs with appropriate dependencies

#### Task 4: Documentation Enhancement
- **Difficulty:** ⭐ Easy
- **Time:** 4-6 hours
- **Skills:** Technical Writing, Markdown
- **Description:** Create comprehensive README, architecture diagrams, and troubleshooting guides

[Back to Top](#table-of-contents)

---

## 3. workflow_assignment - Feature Module Layer

**Repository:** `rjzaar/workflow_assignment`  
**Type:** Drupal 10/11 Custom Module  
**Current Version:** 1.0.0

### 3.1 Purpose and Functionality

Comprehensive workflow management system for Open Social with user/group/location assignments.

**Core Features:**
- Named workflows with descriptions
- Assign users, groups, or taxonomy terms
- Resource location tagging (Google Drive, SharePoint, etc.)
- Quick edit functionality
- Dedicated workflow tab on content
- Color-coded visual display

### 3.2 Architecture

```
WorkflowList (Config Entity)
├── id, label, description
├── assigned_users (User references)
├── assigned_groups (Group references)
└── resource_tags (Taxonomy terms)

field_workflow_list
└── Entity reference field on content types
```

### 3.3 Current Status

**✅ Completed:**
- Core entity structure
- Admin UI with proper routes
- Quick Edit functionality
- Workflow tab on content
- Color-coded display
- Permissions system

**❌ Known Issues:**
- No workflow state machine
- No audit trail/history
- Limited bulk operations
- Performance not optimized

### 3.4 Outstanding Tasks

#### Task 1: Advanced Features Integration
- **Difficulty:** ⭐⭐⭐⭐ Hard
- **Time:** 40-60 hours
- **Skills:** Drupal Entity API, State Machine patterns, PHP OOP
- **Description:** Implement workflow states, transitions, audit trail, and notifications

#### Task 2: Performance Optimization
- **Difficulty:** ⭐⭐ Medium
- **Time:** 15-25 hours
- **Skills:** Drupal caching, MySQL optimization
- **Description:** Add caching strategy, optimize queries, implement lazy loading

#### Task 3: UI/UX Enhancements
- **Difficulty:** ⭐⭐ Medium
- **Time:** 20-30 hours
- **Skills:** Drupal Forms API, JavaScript, AJAX
- **Description:** Ajax-powered assignment, drag-and-drop ordering, bulk operations tool

#### Task 4: Testing & Documentation
- **Difficulty:** ⭐⭐ Medium
- **Time:** 25-35 hours
- **Skills:** PHPUnit, Behat, Technical Writing
- **Description:** Comprehensive test suite, API docs, user guides, video tutorials

#### Task 5: Integration Improvements
- **Difficulty:** ⭐⭐ Easy-Medium
- **Time:** 15-20 hours
- **Skills:** Drupal Hooks, REST API
- **Description:** Activity stream integration, export/import, REST API endpoints

[Back to Top](#table-of-contents)

---

## 4. commons_install - Automation Layer

**Repository:** `rjzaar/commons_install`  
**Type:** Bash Installation Scripts  
**Primary Script:** `cinstall.sh` (17 steps)

### 4.1 Purpose and Functionality

Sophisticated automation for installing and configuring OpenSocial and Moodle environments.

**Core Capabilities:**
- Automated DDEV environment setup
- OpenSocial installation via commons_template
- Workflow assignment configuration
- GitHub token support for Composer
- Resumable installation with state tracking

### 4.2 Installation Scripts

**cinstall.sh:** 17-step OpenSocial installation (~12-20 minutes)  
**moodle_install.sh:** Standalone Moodle installation (~15-25 minutes)

### 4.3 Current Status

**✅ Completed:**
- Full DDEV-based installation
- GitHub token support
- Workflow integration
- Ultimate Cron fixes
- Error handling

**❌ Known Issues:**
- Monolithic structure
- Limited configuration options
- No rollback capability
- DDEV-only (no native Docker Compose)

### 4.4 Outstanding Tasks

#### Task 1: Script Modularity
- **Difficulty:** ⭐⭐ Medium
- **Time:** 20-30 hours
- **Skills:** Bash scripting, Software architecture
- **Description:** Break monolithic script into function libraries and configuration files

#### Task 2: Enhanced Error Recovery
- **Difficulty:** ⭐⭐ Medium
- **Time:** 15-25 hours
- **Skills:** Bash error handling, Logging
- **Description:** Automatic rollback, detailed logging, recovery mode

#### Task 3: Multi-Environment Support
- **Difficulty:** ⭐⭐⭐ Medium
- **Time:** 30-40 hours
- **Skills:** Docker, Docker Compose, Kubernetes basics
- **Description:** Support for Docker Compose, Platform.sh, Kubernetes deployments

#### Task 4: Interactive Mode
- **Difficulty:** ⭐⭐ Easy-Medium
- **Time:** 10-15 hours
- **Skills:** Bash scripting, UI/UX
- **Description:** Wizard-style installation, validation, progress indicators

#### Task 5: CI/CD Integration
- **Difficulty:** ⭐⭐⭐ Medium
- **Time:** 15-25 hours
- **Skills:** GitHub Actions, Docker, Testing
- **Description:** Automated testing pipeline, shellcheck, security scanning

[Back to Top](#table-of-contents)

---

## 5. opensocial-moodle-sso-integration - Integration Layer

**Repository:** `rjzaar/opensocial-moodle-sso-integration`  
**Type:** Full-Stack Integration Project

### 5.1 Purpose and Functionality

Comprehensive solution for connecting OpenSocial with Moodle using OAuth2 SSO and badge synchronization.

**Key Capabilities:**
- Single Sign-On (SSO) via OAuth2
- Automatic user account creation
- Badge synchronization (partial)
- Unified installation script

### 5.2 Architecture

```
OpenSocial (Drupal) → OAuth2 Provider (IdP)
  ├── opensocial_oauth_provider module
  ├── Simple OAuth module
  └── Public/private key pair
       ↓
    OAuth2 Authentication Flow
       ↓
Moodle LMS → OAuth2 Client
  ├── auth_opensocial plugin
  ├── OAuth2 service configuration
  └── Badge synchronization hooks
```

### 5.3 Current Status

**✅ Completed:**
- Combined installation script
- OAuth2 provider module
- Moodle authentication plugin
- Basic documentation
- GitHub token support

**❌ Known Issues:**
- YAML parser doesn't handle inline comments
- Badge sync not fully implemented
- No token refresh mechanism
- Limited monitoring capabilities

### 5.4 Outstanding Tasks

#### Task 1: Badge Synchronization Implementation
- **Difficulty:** ⭐⭐⭐⭐ Hard
- **Time:** 40-60 hours
- **Skills:** Drupal/Moodle APIs, OAuth2, Webhooks
- **Description:** Complete bidirectional badge sync with webhook infrastructure

#### Task 2: Enhanced Security
- **Difficulty:** ⭐⭐⭐ Medium
- **Time:** 20-30 hours
- **Skills:** OAuth2 security, Encryption
- **Description:** Token refresh, key rotation, rate limiting, PKCE support

#### Task 3: User Profile Synchronization
- **Difficulty:** ⭐⭐ Medium
- **Time:** 15-20 hours
- **Skills:** API integration, Data mapping
- **Description:** Sync user profiles beyond basic fields with conflict resolution

#### Task 4: Monitoring & Debugging
- **Difficulty:** ⭐⭐ Medium
- **Time:** 12-18 hours
- **Skills:** Logging, Debugging, Monitoring tools
- **Description:** OAuth transaction logging, admin dashboard, health check endpoints

#### Task 5: Production Readiness
- **Difficulty:** ⭐⭐⭐⭐ Hard
- **Time:** 40-60 hours
- **Skills:** DevOps, Security, Performance
- **Description:** HA configuration, load balancing, backups, security hardening

#### Task 6: Installation Script Improvements
- **Difficulty:** ⭐⭐ Medium
- **Time:** 10-15 hours
- **Skills:** Bash, YAML, Configuration Management
- **Description:** Fix YAML parser, add validation, support multiple environments

#### Task 7: Testing Suite
- **Difficulty:** ⭐⭐⭐⭐ Hard
- **Time:** 30-40 hours
- **Skills:** Testing, Behat, PHPUnit
- **Description:** Unit tests, integration tests, end-to-end tests for SSO and badge sync

[Back to Top](#table-of-contents)

---

## 6. Development Phases

### 6.1 Phase 1: Stabilization (1-2 months)

**Priority: HIGH**  
**Estimated Hours:** 150-200

**Focus Areas:**
1. Fix critical issues (Ultimate Cron patch, YAML parser)
2. Documentation sprint (README files, architecture diagrams)
3. Testing foundation (PHPUnit setup, basic integration tests)
4. CI/CD pipeline setup

**Deliverables:**
- All critical bugs fixed
- Comprehensive documentation for each repo
- Basic test coverage (>50%)
- Automated testing pipeline

**Skills Required:** Drupal, Bash, Technical Writing, PHPUnit, GitHub Actions

### 6.2 Phase 2: Feature Enhancement (2-3 months)

**Priority: MEDIUM**  
**Estimated Hours:** 250-350

**Focus Areas:**
1. Workflow states implementation
2. Badge synchronization (Moodle → OpenSocial)
3. Installation improvements (modularity, interactive mode)
4. Performance optimization

**Deliverables:**
- Working workflow state machine
- Complete badge sync (one direction)
- Modular installation scripts
- Performance benchmarks

**Skills Required:** Drupal State API, Moodle Badges API, OAuth2, Bash scripting

### 6.3 Phase 3: Production Hardening (2-3 months)

**Priority: MEDIUM-HIGH**  
**Estimated Hours:** 200-300

**Focus Areas:**
1. Security audit and enhancements
2. Performance optimization
3. Scalability improvements
4. Comprehensive monitoring

**Deliverables:**
- Security audit report
- Performance optimization complete
- HA configuration documented
- Monitoring dashboards operational

**Skills Required:** Security Engineering, Performance Tuning, DevOps

### 6.4 Phase 4: Advanced Features (3-4 months)

**Priority: LOW-MEDIUM**  
**Estimated Hours:** 200-350

**Focus Areas:**
1. API development (RESTful/GraphQL)
2. Advanced integrations (Calendar, Document Management)
3. Mobile support considerations
4. Analytics integration

**Deliverables:**
- Public API with documentation
- Integration plugins for major platforms
- Mobile-optimized interfaces
- Analytics dashboard

**Skills Required:** REST/GraphQL, API Design, Mobile Development, Integration Architecture

[Back to Top](#table-of-contents)

---

## 7. Complexity & Skills Matrix

### 7.1 By Repository

| Repository | Complexity | Primary Skills | Est. Dev Hours |
|------------|-----------|----------------|----------------|
| **commons_template** | ⭐⭐ Easy | Composer, JSON | 15-25 |
| **workflow_assignment** | ⭐⭐⭐⭐ Hard | Drupal 10/11, Entity API, OOP | 150-220 |
| **commons_install** | ⭐⭐⭐ Medium | Bash, DDEV, System admin | 100-150 |
| **opensocial-moodle-sso** | ⭐⭐⭐⭐⭐ Very Hard | OAuth2, Drupal, Moodle, APIs | 200-300 |

### 7.2 By Task Type

| Task Type | Difficulty | Time Range | Critical Skills |
|-----------|-----------|------------|-----------------|
| **Bug Fixes** | Easy-Medium | Hours-Days | Debugging, framework knowledge |
| **Documentation** | Easy | Days-Week | Technical writing |
| **UI Enhancement** | Medium | 1-2 weeks | JavaScript, CSS, Forms API |
| **API Development** | Medium-Hard | 2-4 weeks | REST/GraphQL, Authentication |
| **Security Hardening** | Hard | 2-4 weeks | Security practices, OAuth2 |
| **Badge Sync** | Hard | 4-8 weeks | Both Drupal & Moodle APIs |
| **Production Deploy** | Hard | 4-6 weeks | DevOps, Docker, Kubernetes |

[Back to Top](#table-of-contents)

---

## 8. Immediate Action Items

**Next 2 Weeks - High Priority:**

1. ✅ **Add Ultimate Cron patch to commons_template** (COMPLETED)
   
2. **Fix YAML parser in opensocial-moodle-sso-integration**
   - Remove inline comments from config.yml
   - Add config validation function
   - Test with clean config file
   - **Effort:** 2-4 hours
   
3. **Create unified README architecture**
   - Add repository relationship diagram
   - Document installation order
   - Link all repos together
   - **Effort:** 4-6 hours

4. **Set up GitHub Actions**
   - Basic linting for all repos
   - Automated testing where possible
   - Dependency vulnerability scanning
   - **Effort:** 8-12 hours

5. **Version tagging**
   - Tag stable releases for each repo
   - Create CHANGELOG files
   - Document breaking changes
   - **Effort:** 2-3 hours

[Back to Top](#table-of-contents)

---

## 9. Long-Term Vision

Your repository ecosystem represents a comprehensive solution for:

- **Community Management:** OpenSocial platform with custom workflows
- **Learning Management:** Integrated Moodle LMS
- **Automated Deployment:** One-click installation scripts
- **Enterprise Features:** SSO, badge synchronization, workflow tracking

**Target Markets:**
- Corporate training portals
- Educational institutions
- Non-profit organizations
- Government community platforms

**Success Criteria:**
1. Production-ready badge synchronization (bidirectional)
2. Security audit passed with zero critical issues
3. Documentation comprehensive enough for third-party adoption
4. Installation time < 15 minutes for basic setup
5. 99.9% uptime for production deployments
6. Active community of contributors

**5-Year Goals:**
- 100+ production installations
- Active developer community
- Marketplace for workflow templates
- SaaS hosting option
- Mobile native apps
- AI-powered workflow suggestions

[Back to Top](#table-of-contents)

---

## 10. Resource Requirements

### Development Team

**Immediate Needs (Phase 1):**
- 1 Senior Drupal Developer (30-40 hrs/week)
- 1 DevOps Engineer (10-15 hrs/week)
- 1 Technical Writer (10-15 hrs/week)

**Growth Phase (Phase 2-3):**
- 2 Senior Drupal Developers
- 1 Full Stack Developer (Moodle + Drupal)
- 1 Security Engineer (consultant basis)
- 1 DevOps Engineer (20-30 hrs/week)
- 1 QA Engineer (20-30 hrs/week)

### Infrastructure

**Development:**
- GitHub organization with CI/CD minutes
- Development servers for testing
- Code quality tools (SonarQube, etc.)

**Production:**
- Multiple environment hosting (dev, staging, prod)
- CDN for asset delivery
- Monitoring services (Datadog, New Relic)
- Backup infrastructure

### Budget Estimate

**Phase 1 (Months 1-2):** $20,000 - $30,000  
**Phase 2 (Months 3-5):** $40,000 - $60,000  
**Phase 3 (Months 6-8):** $35,000 - $50,000  
**Phase 4 (Months 9-12):** $30,000 - $45,000

**Total 12-Month Budget:** $125,000 - $185,000

[Back to Top](#table-of-contents)

---

## 11. Success Metrics

### Technical Metrics

- **Code Coverage:** >80% for all custom modules
- **Performance:** Page load < 2 seconds for 95th percentile
- **Uptime:** 99.9% availability for production
- **Security:** Zero critical vulnerabilities
- **Installation Time:** < 15 minutes for basic setup

### Adoption Metrics

- **Installations:** 50+ in first year, 200+ in second year
- **GitHub Stars:** 100+ across all repos
- **Documentation Views:** 1,000+ monthly
- **Community Contributors:** 10+ active contributors
- **Forum Activity:** 50+ active users

### Quality Metrics

- **Bug Report Response Time:** < 24 hours
- **Feature Request Processing:** Review within 1 week
- **Documentation Completeness:** 100% coverage of features
- **Test Pass Rate:** 100% for release branches
- **Code Review Turnaround:** < 48 hours

[Back to Top](#table-of-contents)

---

## Appendix A: Technology Stack

### Core Technologies

**Backend:**
- PHP 8.1-8.2
- Drupal 10/11
- Moodle 4.0+
- MySQL 8.0 / PostgreSQL 13+
- Redis (caching)
- Apache Solr (search)

**Frontend:**
- JavaScript (ES6+)
- jQuery (Drupal standard)
- Bootstrap (OpenSocial theme)
- Twig (templating)

**Development:**
- DDEV (local environment)
- Docker & Docker Compose
- Git & GitHub
- Composer (PHP dependencies)
- npm (JS dependencies)

**Testing:**
- PHPUnit (unit tests)
- Behat (BDD tests)
- PHPStan (static analysis)
- PHP CodeSniffer (code standards)

**CI/CD:**
- GitHub Actions
- ShellCheck (bash linting)
- Trivy (security scanning)

**Infrastructure:**
- Nginx / Apache
- Platform.sh (cloud option)
- Kubernetes (enterprise option)
- Cloudflare (CDN)

[Back to Top](#table-of-contents)

---

## Appendix B: Glossary

**AJAX:** Asynchronous JavaScript and XML - technique for updating parts of a web page without reload

**Badge:** Digital recognition of achievement, can be synced between OpenSocial and Moodle

**Behat:** Behavior-Driven Development testing framework for PHP

**CI/CD:** Continuous Integration/Continuous Deployment - automated testing and deployment pipeline

**Config Entity:** Drupal entity type for configuration (exportable, translatable)

**Content Entity:** Drupal entity type for content (fieldable, revisable)

**DDEV:** Docker-based local development environment tool

**Entity Reference:** Drupal field type that creates relationships between entities

**IdP:** Identity Provider - system that authenticates users (OpenSocial in this architecture)

**LMS:** Learning Management System (Moodle)

**OAuth2:** Industry-standard protocol for authorization

**Open Social:** Drupal distribution for building community platforms

**PKCE:** Proof Key for Code Exchange - OAuth2 security extension

**SSO:** Single Sign-On - log in once, access multiple applications

**Webhook:** HTTP callback for event notifications between systems

**Workflow:** Process for managing content through defined states

[Back to Top](#table-of-contents)

---

**End of Roadmap**

For questions or contributions, please open an issue in the relevant repository or contact rjzaar@gmail.com.

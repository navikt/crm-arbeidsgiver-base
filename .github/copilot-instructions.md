# CRM Arbeidsgiver Base - Copilot Instructions

## Project Overview
This is a **Norwegian CRM system for employers** built on **Salesforce DX**, managed by NAV (Norwegian Labour and Welfare Administration). The system handles employer relationships, temporary layoffs, activities, agreements, and integrations with external Norwegian systems.

## Architecture & Organization

### Core Structure
- **`force-app/`** - Main Salesforce metadata organized in 3 layers:
  - **`components/`** - Reusable Lightning Web Components (LWCs) and supporting classes
  - **`functionality/`** - Business domain logic (activities, agreements, integrations)
  - **`main/`** - Standard Salesforce metadata (objects, fields, flows, etc.)

### Naming Conventions
- **TAG_** prefix for all custom Apex classes, triggers, and components
- **Norwegian business terminology** throughout (e.g., `Arbeidsgiver` = Employer, `Permitteringer` = Layoffs)
- Components organized by business domain, not technical layers

## Key Dependencies & Integrations

### External Packages (defined in sfdx-project.json)
- `crm-platform-base` - Core platform functionality
- `crm-platform-access-control` - Permission management
- `crm-shared-timeline` - Activity timeline components
- `crm-platform-reporting` - Analytics and Amplitude integration

### External System Integrations
- **Arbeidsplassen.no** - Norwegian job portal integration (`arbeidsplassen/` components)
- **Arena** - Legacy NAV system for activities and measures
- **Azure AD** - Authentication and token management
- **Amplitude** - User behavior analytics (extensive implementation)

## Development Patterns

### Salesforce DX Workflow
```bash
# Create scratch org (macOS)
npm run mac:build

# Standard development cycle
sfdx force:source:push    # Deploy local changes
sfdx force:source:pull    # Retrieve org changes  
sfdx force:org:open      # Open scratch org
```

### Testing Strategy
- **Jest for LWC testing** - Configured with custom mocks (`jest.config.js`)
- **Apex test classes** - Follow `*Test.cls` naming convention
- **Accessibility testing** - Integration with @sa11y/jest
- **PMD code analysis** - Custom ruleset in `ruleset.xml`

### Component Architecture
- **Controller-Helper pattern** - Apex classes split between web-facing controllers and business logic helpers
- **Platform Events** - `EmployerActivityEvent__e` for cross-system communication
- **Custom Metadata Types** - Extensive use for configuration (badges, activity mappings)

## Business Domain Knowledge

### Key Objects & Relationships
- **Account** - Employers (companies) with Norwegian-specific fields (`INT_OrganizationalStructure__c`, `TAG_NavUnit__c`)
- **Contact** - Company contacts with employment status tracking
- **CustomOpportunity__c** - Job opportunities and inclusion measures
- **Contract__c** - Partnership agreements between NAV and employers
- **TemporaryLayoff__c** - Temporary layoff registrations (Norwegian: Permitteringer)

### Activity Management
- Tasks and Events with extensive custom fields for IA (Inclusive Workplace) tracking
- Custom activity types mapped via `Activity_Account_Map__mdt` metadata
- Platform events trigger external system notifications for activity changes

### Permission Model
- Custom sharing rules via `ApexSharingRules` framework
- Region-based access control through NAV organizational units
- Role-based component visibility in FlexiPages

## Amplitude Analytics Integration

### Implementation Pattern
```javascript
import { publishToAmplitude } from 'c/amplitude';

// Track user interactions
publishToAmplitude(this.appName, { type: 'Badge Click - Muligheter' });
```

### Key Components
- **amplitudeBackground** - Utility bar component for initialization
- **amplitudeUtilityApp** - Stores current app name in localStorage
- Event tracking across all major UI interactions (badges, forms, navigation)

## Common Patterns

### Badge System
- Dynamic badge generation based on related records (`AccountBadgesController`)
- Consistent styling and behavior across components
- Integrated analytics tracking for all badge interactions

### Data Import/Export
- **dummy-data/** directory with SFDX tree export/import commands
- Structured approach to test data with relationship preservation
- Plan-based data loading for complex object hierarchies

### Error Handling & Logging
```apex
private static final LoggerUtility LOGGER = new LoggerUtility();
// Consistent logging pattern across all controllers
```

## Development Guidelines

### Code Quality
- Strict PMD rules enforced (`ruleset.xml`)
- Prettier formatting for all file types
- Husky pre-commit hooks for code quality
- Comprehensive test coverage requirements

### Localization
- Norwegian as primary language with English fallbacks
- Custom labels for user-facing text
- Translation files exclude English (`*-en_US` in .gitignore)

### Performance Considerations
- SOQL optimization patterns in selector classes
- Bulk processing for data operations
- Careful use of platform events to avoid governor limits

## Quick Reference Commands

```bash
# Linting and testing
npm run lint                 # Lint all code
npm test                    # Run all tests
npm run prettier            # Format code

# Data management  
cd dummy-data && ./queries.sh  # Export test data
sfdx force:data:tree:import    # Import test data

# Package management
sfdx force:package:install     # Install dependencies
```

This system requires understanding of Norwegian business processes, Salesforce platform capabilities, and integration patterns with Norwegian government systems.


## Preferred Technologies

This project uses Salesforce technologies. Prioritize the following:
- Apex (Salesforce's backend language)
- Lightning Web Components (LWC) for frontend
- SOQL for data queries
- Salesforce DX project structure
- Metadata and configuration files (`.xml`, `object-meta.xml`, etc.)

## Apex Development Guidelines

- Use `@AuraEnabled(cacheable=true)` for read-only methods exposed to LWC.
- Use the `without sharing` keyword only when absolutely necessary.
- Prefer bulk-safe and asynchronous patterns (e.g., `Queueable`, `Future`, `Batchable`) for data processing.
- Guard against nulls and uncommitted DMLs inside loops.
- Always check for field-level security (FLS) and CRUD access if relevant.
- Follow Apex design patterns like Service Layer, Selector, and Unit of Work when structuring code.

## Lightning Web Components (LWC)

- Use `@wire` decorators when possible for reactivity.
- Handle `recordId` when building components for Lightning Record Pages.
- Use `import { ShowToastEvent }` from `'lightning/platformShowToastEvent'` for user notifications.
- Minimize imperative Apex calls unless needed for control or performance.
- Organize components clearly with separate folders for test components, utilities, and shared services.

## Security and Performance

- Avoid hardcoding record type IDs, field API names, or URLs.
- Use Custom Metadata Types or Custom Settings for configurable behavior.
- Use selective SOQL queries with indexed fields or filters on `Id`, `CreatedDate`, or `LastModifiedDate` where appropriate.
- Avoid nested loops and unbounded queries.

## Code Style

- Use meaningful class and method names. E.g., `BadgeService.getBadgesForUser()` is preferred over `Utils.getData()`.
- Inline comments only when needed to explain complex logic.
- Include `@testSetup` methods in test classes when initializing common data.
- Keep unit test methods small and focused.

## General Preferences

- Use dependency injection and separation of concerns when building services.
- Keep Apex classes under 200–300 lines when possible.
- Group related Apex classes in logical folders (e.g., `classes/services`, `classes/triggers`, `classes/selectors`).
- Treat test coverage as a design tool – cover edge cases and governor limit conditions.

## Don’t Suggest

- Visualforce (unless explicitly stated)
- Aura components (deprecated in favor of LWC)
- Unbulkified trigger logic
- Deprecated APIs or synchronous callouts unless required

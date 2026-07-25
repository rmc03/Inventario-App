# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios android

## Users

Single shop owner (admin) who manages the business, and several employees (dependientes) who process sales and manage inventory day-to-day. Used in a motorcycle parts and accessories retail shop.

## Product Purpose

Complete management system for a motorcycle parts/accessories retail shop: inventory tracking, daily sales processing, cash register (cuadres), and employee shift management. Exists to replace manual/paper-based tracking for small shops with unreliable internet.

## Positioning

Offline-first inventory and sales system designed for small shops with unreliable internet connectivity. Works without connection using local SQLite storage and syncs to Supabase when online.

## Operating Context

- Daily workflow: employees open shifts, process sales, and close cash register at end of day
- Owner/manager monitors inventory levels, reviews sales, and manages product catalog
- Environment: small retail shop with potentially unstable internet connection
- Spanish-speaking users in Latin America (based on currency formatting and language)

## Capabilities and Constraints

- **Core capabilities:** Product CRUD, stock tracking, daily sales, cash register (cuadres), shift management, role-based access (admin/dependiente)
- **Technical constraints:** Must use Supabase as backend; offline sync with SQLite is critical; Spanish-only (no i18n beyond Spanish)
- **Roles:** Admin (full access) and Dependiente (limited to sales, inventory view, and own shift)
- **Offline:** App must function without internet; syncs when connection is restored

## Brand Commitments

No specific brand identity established yet. "Inventario App" is a working placeholder. Brand development is an open decision.

## Evidence on Hand

- Working Flutter mobile app with all core features implemented
- Demo product images in assets/images/ (placeholder only; real images from Supabase)
- Splash screen and basic theming (light/dark mode)

## Product Principles

1. Offline reliability: app must work without internet; data integrity is non-negotiable
2. Role clarity: admin and employee experiences are distinct and appropriate
3. Operational efficiency: minimize steps for daily workflows (sales, shifts, cash register)
4. Small shop reality: designed for limited resources, unstable connectivity, and non-technical users

## Accessibility & Inclusion

Accessibility settings implemented (text size, bold text). No specific screen reader requirements established beyond current implementation.

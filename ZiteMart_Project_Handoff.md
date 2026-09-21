# ZiteMart POS — Project Handoff Document

Last updated: 2026-09-21
Purpose: Context for continuing work in a new chat session.

---

## 1. What this project is

A point-of-sale system for retail shops, developed by Nelson. Two deployment
editions:

1. **Offline/Desktop edition** — Flutter Windows app + Node backend + local
   MySQL, all on the client's standalone laptop. No internet required.
2. **Cloud edition** (planned) — same Flutter web app + Node backend +
   cloud MySQL, hosted. Multi-device access. Mobile monitoring app planned.

The client for the first deployment is **Auxano Concept Limited**, Nigeria.
The client has the desktop edition running on their laptop as of 2026-09-21.

---

## 2. Two codebases on the dev machine

- **`~/Desktop/pos_system`** — the **desktop edition**. Flutter Windows app.
  Source of truth for future desktop builds. Do not modify this unless
  shipping a desktop update.
- **`~/Desktop/ZiteWeb_POS`** — the **web edition**. Flutter web app. This is
  where active work happens now.
- **`~/pos_server`** — the Node backend for both editions. Same `server.js`.
  It talks to the remote dev DB (172.125.0.200) when running from the dev
  machine.

The desktop and web projects have separate `pubspec.yaml` package names:
- Desktop: `pos_system`
- Web: `zite_web_pos`

---

## 3. Stack

- **Frontend:** Flutter 3.44.x (stable channel)
- **Backend:** Node.js, Express, mysql2
- **Database:** MySQL 8
- **Auth:** JWT (8-hour expiry), bcrypt password hashing
- **Dev environment:** Windows, VS Code, Git Bash

---

## 4. Repository / folder layout (web edition)
ZiteWeb_POS/
├── lib/
│ ├── main.dart
│ ├── models/
│ ├── screens/
│ ├── services/
│ └── utils/
│ └── permissions.dart ← RBAC permission checks
├── assets/
├── web/
├── pubspec.yaml ← name: zite_web_pos
└── build/web/ ← output of flutter build web --release

pos_server/
├── server.js ← ~3100 lines, all routes
├── .env ← DB credentials, port, JWT secret
├── node_modules/
├── uploads/
│ └── logos/ ← company logo files
├── license_private.pem ← NEVER ship
├── license_public.pem
├── make_license.js
├── verify_license.js
└── package.json

text

---

## 5. What's been built and works

### Core POS
- Login/logout (JWT)
- Product management (SKU auto-generation, image upload, markup pricing)
- Categories, units, customers, vendors, purchase orders, receive stock
- Sales (cash, card, transfer, credit, layaway)
- Sales returns
- Stock movements, bincard
- Cash book, bank book, expenses, credit sales
- Layaway management
- Receipts (POS thermal layout + A4 invoice), print via browser
- Reports: sales, stock, cash book, stock movements, bincard
- Excel and PDF export (desktop and web)
- Dashboard with charts

### Markup / pricing
- Three-level markup resolution: product override → category → company global
- `products.markup_percent`, `categories.markup_percent`,
  `company.default_markup_percent`
- `products.markup_is_manual` flag
- Selling price auto-computed from cost + effective markup when not manual
- `POST /api/products/recalculate-prices` bulk endpoint

### SKU auto-generation
- `GET /api/products/next-sku?category_id=X&name=Y`
- Format: `<CATEGORY_PREFIX>-<PRODUCT_INITIALS>-<SEQUENCE>`
  e.g. `AUD-OJ-001`
- Category prefix = first 3 letters of category name
- Product initials = first letter of each word in product name
- Sequence is per prefix, 3 digits

### Discount system with PIN approval
- Manager generates PINs (`discount_pins` table)
- PINs are 6-digit, single-use, tied to a max discount
- Cashier enters PIN at checkout, discount applied, PIN consumed
- PIN report screen for audit
- PINs grant percent or amount discounts
- Sale discount stored on `sales` table: `discount_type`, `discount_value`,
  `discount_amount`, `discount_pin_id`
- Receipt shows discount line

### RBAC (roles and permissions)
- Tables: `roles`, `permissions`, `role_permissions`
- `users.role_id` links to a role
- Three built-in roles: admin (27 perms), manager (21), cashier (4)
- Custom roles can be created
- `Permissions` class in Flutter reads a permission set loaded at login
- `GET /api/my-permissions` returns the current user's permission codes
- Roles admin screen: create/edit/delete roles, edit permission grid
- Admin role is protected; manager and cashier are editable

### VAT
- `company.vat_enabled` master switch
- `company.vat_rate`
- Products and categories have `is_vat_exempt` flags
- Resolution: if global off → no VAT. Else if product exempt → no VAT.
  Else → apply rate.
- Current client has VAT off

### Licensing
- RSA-signed license files, verified against an embedded public key
- `license_service.dart` reads `license.key` next to the executable
- Soft lock with expired screen and vendor contact info
- **Currently disabled** in `main.dart` and **skipped entirely on web**
- Private key must never leave the dev machine

---

## 6. Known state on the client's laptop (desktop edition)

- Backend runs via NSSM as a Windows service named `POSServer`
- Service config: AppDirectory = `C:\pos_server`
- Startup directory matters — dotenv reads `.env` from there
- Client's `.env` points to `localhost` MySQL (`admin` user, laptop-local password)
- Flutter app installed at `C:\ZiteMart\`
- License file at `C:\ZiteMart\license.key` (currently the dev key, expires 2030)
- Client has taken the laptop as of 2026-09-21

---

## 7. Web edition — what works and what doesn't

### Works
- Login, dashboard, POS, cart, checkout
- Product/category/customer/vendor/unit management
- Sales, returns, stock, cash book, bank book, expenses
- Discount PINs, RBAC
- Receipts (open in browser window, printable)
- Excel export (all reports)
- PDF export (all reports, using MultiPage for long lists)
- Backup download (SQL file)

### Known gaps on web
- **Database restore** — not available in web UI. Must be done server-side
  via `mysql -u admin -p pos_system < backup.sql`. Deliberate.
- **Product image upload** — untested on web; may break
- **Company logo upload** — untested on web; may break
- **License check** — disabled entirely on web

### Filesystem-related: on web, `path_provider`, `dart:io`, and file writes
don't work. Any screen using them needs an HTML blob download approach
(see `export_service_web.dart` for the pattern).

---

## 8. Backend API surface (high level)

Auth:
- POST /api/login
- GET /api/test
- GET /api/my-permissions

Products:
- GET /api/products
- GET /api/products/:id
- GET /api/products/next-sku
- POST /api/products
- PUT /api/products/:id
- PATCH /api/products/:id/stock
- POST /api/products/recalculate-prices
- GET /api/products/:id/bincard
- DELETE /api/products/:id

Categories:
- GET, POST, PUT /api/categories[/:id]

Sales:
- POST /api/sales  (accepts discountType, discountValue, discountPin)
- GET /api/sales
- GET /api/sales/:id
- GET /api/sales/invoice/:invoiceNumber

Discount PINs:
- POST /api/discount-pins/generate
- POST /api/discount-pins/validate
- GET /api/discount-pins

Roles/Permissions:
- GET /api/roles
- GET /api/roles/:id
- POST /api/roles
- PUT /api/roles/:id
- DELETE /api/roles/:id
- PUT /api/roles/:id/permissions
- GET /api/permissions
- GET /api/my-permissions

Company:
- GET /api/company
- POST /api/company
- PUT /api/company
- POST /api/company/logo

Backup:
- GET /api/backup/export
- POST /api/backup/import (stub)
- POST /api/backup/restore (stub)

Plus routes for users, customers, vendors, units, purchase orders,
vendor payments, invoices, stock movements, cash book, bank book,
expenses, sales returns, credit sales, notifications, banks, bank accounts,
credit payments, layaway.

---

## 9. Deployment status

### Desktop edition
- **Deployed.** Running on client's laptop.
- To rebuild: `flutter build windows --release` in `pos_system`
- To update: copy `build/windows/x64/runner/Release/*` to `C:\ZiteMart\`
  and `server.js` to `C:\pos_server\`, then `net stop POSServer && net start POSServer`

### Web edition
- **Not deployed.** Currently only runs on the dev machine.
- `flutter build web --release` produces `build/web/`
- To serve: `server.js` needs `app.use(express.static('web'))` added,
  and `build/web/*` copied into `pos_server/web/`
- Deployment target not yet chosen (Render, Railway, etc.)

---

## 10. Next planned work

### Immediate
- Test product image upload and company logo upload on web
- Decide cloud deployment approach

### Medium term
- Deploy cloud edition: backend on Render (or similar), MySQL in cloud,
  web app served by the backend
- Handle file uploads (move to S3/R2 or persistent disk on cloud)

### Larger feature: mobile monitoring app
- **Purpose:** oversight only, not a transaction terminal
- Owner/manager logs into a mobile app to see live state: dashboard,
  current sales, pending approvals
- Real-time approval flow replaces discount PINs in the cloud edition:
  cashier requests approval → manager gets notification on phone →
  taps Approve/Reject → POS updates within seconds
- Requires WebSockets (or SSE) in the backend, an approvals table,
  and a new small Flutter mobile app
- Estimated ~2 weeks of focused work for the full feature

---

## 11. Key design decisions already made

- **Multi-tenancy:** not decided. Likely one cloud deployment per client
  initially, with possible multi-tenancy later.
- **Cloud provider:** leaning Render (already used for other projects).
- **Mobile app:** separate Flutter project, oversight-only.
- **Approval model:** replaces PIN system in cloud edition. PINs remain
  in the offline edition.
- **VAT:** global switch with per-product and per-category exemption.
- **Markup:** three-level resolution with manual override flag.
- **Permissions:** database-driven RBAC, not hardcoded.
- **Receipts:** browser-based print (`window.print()` on web,
  `Process.run('start', ...)` on desktop).

---

## 12. Environment / credentials (do not paste into chat)

On the dev machine:
- `~/pos_server/.env` — DB_HOST=172.125.0.200 (remote dev DB)
- `~/pos_server/license_private.pem` — RSA private key. Back it up.
- MySQL admin password for the remote dev DB — known to Nelson.

On the client's laptop:
- `C:\pos_server\.env` — DB_HOST=localhost
- Local MySQL admin user: `admin`, password set on the laptop
- JWT secret in `.env`

Never share the private key, JWT secrets, or DB passwords.

---

## 13. Contact / ownership

Developer: Nelson (nelsongarri@gmail.com)
Vendor contact for licenses: zitemart@chowexpress.co, +234 705 661 1743

---

## 14. How to resume work in a new chat

Opening prompt suggestion:

> I'm continuing work on a POS project called ZiteMart. Two editions exist:
> a desktop Flutter app (deployed to a client's laptop) and a web Flutter
> app (in development). Backend is Node + MySQL. I have a handoff document
> at [path] describing the state. I'd like to work on [specific next task].

Then paste the doc's relevant section, or the whole doc if the session is
short.

When asking about a specific screen, paste that screen's current file.
Don't assume I remember it from a previous session.

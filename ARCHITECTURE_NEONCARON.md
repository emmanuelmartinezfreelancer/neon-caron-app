# Neon Caron — Architecture Overview

This document describes the **high-level architecture** of Neon Caron for external developers and automated agents. It is the main reference for understanding how the app is structured and how its parts interact, without exposing internal implementation details.

---

## For AI Agents & Tooling

- **Stack:** iOS app (UIKit + Storyboard). Backend: AWS (Cognito, Lambda, API Gateway, Aurora, S3). Local: Core Data, UserDefaults.
- **Source of truth for technical details:** `TECHNICAL_CONTRACT.md` in the project root. Use it for phases, file paths, and implementation decisions. This file is overview-only.
- **App flow:** Home (collection list) → AR experience (image tracking + video overlay). Login and “Create Collection” lead to auth/login flow. User collections (when implemented) follow the same AR flow with dynamic image trackers.
- **Key folders:** `Neon Caron/Controllers/`, `Common/` (e.g. `PaintingCollections.swift`), `Models/`, `Views/`, and (when present) `Services/`, `Repositories/`, `CoreData/`.

---

## 1. What the App Does

**Neon Caron** is an iOS app that combines **static art collections** with **AR (augmented reality)**. Users can:

- Browse **curated collections** of artworks (e.g. Classical, Disney, MonaLisa).
- Open a collection and use the device camera to point at **reference images** (e.g. posters, prints). The app recognizes these images and plays **video overlays** in AR.
- (Planned) Sign in, create **personal collections**, and use the same AR experience with their own selection of paintings from the existing catalog.

So the app has two main modes: **browse static collections** and (future) **browse and use user-owned collections**, both leading to the same AR viewing experience.

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (UIKit)                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Home      │  │   Login     │  │   AR View (ViewController)│  │
│  │   (list)    │──│   (auth)    │  │   Image tracking + video  │  │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┬─────────────┘  │
│         │                │                       │                │
│         └────────────────┼───────────────────────┘                │
│                          │                                        │
│  ┌───────────────────────▼───────────────────────┐                │
│  │  Data & logic: PaintingCollections, (future:  │                │
│  │  Auth, API, Core Data, Repositories)           │                │
│  └───────────────────────┬───────────────────────┘                │
└──────────────────────────┼────────────────────────────────────────┘
                           │ HTTPS (when backend is used)
┌──────────────────────────▼────────────────────────────────────────┐
│  Cloud (AWS)                                                       │
│  API Gateway → Lambda → Aurora (DB)  |  Cognito  |  S3 (optional)  │
└───────────────────────────────────────────────────────────────────┘
```

- **Client:** Single iOS app; UI is UIKit with Storyboards.
- **Data on device:** Static catalog lives in code (`PaintingCollections`); user data and sync are planned via Core Data and optional UserDefaults.
- **Cloud (planned/partial):** Auth with AWS Cognito; business logic and persistence via API Gateway, Lambda, and Aurora; optional S3 for assets.

---

## 3. Main Technical Layers

| Layer | Role | Examples |
|-------|------|----------|
| **UI** | Screens and user interaction | `HomeViewController`, `LoginViewController`, `ViewController` (AR), Storyboards |
| **Data / catalog** | Static collection definitions and video URLs | `PaintingCollections.swift`, `Category` |
| **Services (existing)** | Download, caching, playback helpers | `SDDownloadManager`, `CachingPlayerItem` |
| **Services (planned)** | Auth, API, sync, analytics | Cognito, `APIService`, `SyncManager`, etc. |
| **Persistence (planned)** | Local storage and sync | Core Data, repositories abstracting local + API |

The app is **not** built with SwiftUI; it uses **UIKit + Storyboard** consistently. External contributors should follow that choice.

---

## 4. Core Concepts

### 4.1 Collections and categories

- **Categories** are the top-level groups shown on the home screen (e.g. Classical, Disney). Each has a name, image, and internal key.
- **Collections** (in code) are key-value maps: **painting key → video URL**. The same key is used for the **AR image tracker** name so that when the camera sees the image, the correct video is played.
- **Static collections** are defined in `PaintingCollections`: one dictionary per collection, plus a unified list `categoryNames` used by the home table view.

### 4.2 AR flow

- User selects a **category** on Home → app passes the **collection name** (e.g. `"classical"`) to the AR `ViewController`.
- AR uses **ARKit image tracking**: reference images are loaded from the app’s asset catalog (group name = collection name).
- When a reference image is detected, its **name** is matched to a key in the active collection’s dictionary to get the **video URL**. Video is streamed or played from cache and displayed on the AR node.

So: **collection name** → **reference image set** + **painting key → video URL** map. No custom backend is required for the current static AR experience.

### 4.3 User collections (planned)

- Users will be able to create **personal collections** whose “paintings” are **references** to the existing static catalog (e.g. painting key + source collection).
- AR will load **multiple** reference image groups (one per source collection) and only play video when the detected image belongs to the user’s collection. Video URLs still come from the existing catalog (e.g. `PaintingCollections` or same CDN), so the current design does not require S3 or uploads for user collections.

---

## 5. Project Layout (Overview)

```
Neon Caron/
├── AppDelegate.swift                 # App lifecycle, audio session
├── Controllers/
│   ├── HomeViewController.swift     # Home screen: greeting, “Create Collection”, collection list
│   ├── LoginViewController.swift    # Login / sign-up (to be wired to Cognito)
│   └── ViewController.swift         # AR scene: image tracking + video playback
├── Common/
│   ├── PaintingCollections.swift    # Static catalog: categories + collection → painting key → video URL
│   ├── CachingPlayerItem.swift      # Video playback helper
│   ├── UserDefaultWrapper.swift     # Simple persistence
│   └── SDDownloadManager/           # File download and cache
├── Models/
│   └── CodableHelper.swift          # Serialization helpers
├── Views/
│   └── HomeTableCell.swift          # Home table cell
└── Resources/
    ├── Base.lproj/Main.storyboard   # UI flow and layout
    └── Assets.xcassets/             # Images, AR reference image groups (per collection)
```

Planned (see `TECHNICAL_CONTRACT.md`): `Services/` (e.g. `AuthManager`, `CognitoService`, `APIService`), `Repositories/`, `CoreData/`, and additional view controllers for creating/editing user collections and selecting paintings.

---

## 6. Data and Backend (Planned)

- **Auth:** AWS Cognito (e.g. Google Sign-In, email/password). Tokens stored securely on device; API calls use them for authorization.
- **API:** REST via API Gateway and Lambda. Main resources: users, collections, paintings (user-owned). CRUD for collections and paintings.
- **Database:** Relational (Aurora); main entities: users, collections, paintings (with foreign keys). Sync and offline behavior are intended to go through a repository layer and optional sync manager.
- **Assets:** Video URLs today point to existing CDN (e.g. neoncaron.com). S3 is optional (e.g. for future custom assets); user collections in the current design use existing static catalog URLs.

---

## 7. User Flows (Summary)

1. **Open app** → Home shows “Hello, stranger” (or “Hello, [name]” when logged in) and the list of static categories; “Create Collection +” is visible.
2. **Tap a category** → AR view opens with that collection’s image trackers and videos.
3. **Tap “Create Collection +”** → If not logged in, user is sent to Login; after auth, flow for creating/editing user collections (planned).
4. **In AR** → User points camera at a reference image; app recognizes it and plays the corresponding video overlay.

---

## 8. For External Developers

- **Onboarding:** Read this file first, then `TECHNICAL_CONTRACT.md` for phases, file names, and acceptance criteria. Do not rely on this overview for low-level or phase-specific details.
- **Stack:** Stay with **UIKit + Storyboard**; backend and data design assume **AWS** (Cognito, Lambda, API Gateway, Aurora, optional S3). Local persistence is **Core Data** (+ UserDefaults where appropriate).
- **Adding a new static collection:** Add a new dictionary and category in `PaintingCollections`, create the matching AR reference image group in Assets, and ensure collection name and asset group name align.
- **Changing AR behavior:** See `ViewController` and the contract’s “FASE 6” for how user collections will plug into the same image-tracking and video-mapping flow.
- **Deep technical or phase-specific decisions:** Refer to `TECHNICAL_CONTRACT.md`; this document intentionally stays at an overview level for external use.

---

*Last updated: 2026-02-23. For internal technical details and phase checklist, see `TECHNICAL_CONTRACT.md`.*

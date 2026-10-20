# My Recipe Book

A beautiful, personal recipe manager built for iPad (and iPhone) that feels like your favorite physical cookbook — but smarter, searchable, and always with you.

**Core Vision**  
Centralize every recipe you own: magazine clippings, handwritten notes, web recipes, and digital files — all in one private, offline-first app with excellent typography and kitchen-friendly design.

### Key Features (MVP)
- **Add recipes** any way you like:
  - Manual entry
  - Photo of magazine clipping or handwritten note → on-device OCR (Apple Vision)
  - Paste text or basic web URL import
- Clean, large, book-like **Recipe View** optimized for iPad landscape
- Scalable servings with automatic ingredient adjustment
- Measurement conversion (metric ↔ US/imperial)
- Nutrition & calorie calculation per recipe
- Grocery lists generated from recipes
- Cook Mode (distraction-free, check-off ingredients & steps)
- Powerful search + custom tags/folders
- Favorites, ratings, notes, and original clipping photos preserved
- Fully offline, private, and local-first

### Tech Stack
- **SwiftUI** (native Apple, best iPad experience)
- **SwiftData** (modern local database)
- **Vision Framework** (on-device OCR)
- **AWS Amplify** (future optional sync — free tier)
- Dark/Light mode + excellent typography for kitchen use

### Platform Priority
1. iPadOS (optimized for landscape widescreen — like an open cookbook)
2. iPhone (adaptive)
3. Android (future)

### Project Structure

```bash
MyRecipeBook/
├── MyRecipeBook/              # Main SwiftUI App + Entry point
├── MyRecipeBook.xcodeproj     # Xcode project file
├── MyRecipeBook/Models/       # SwiftData models (Recipe, Ingredient, etc.)
├── MyRecipeBook/Views/        # All SwiftUI screens and components
├── MyRecipeBook/Services/     # Business logic (OCR, recipe scaling, export, etc.)
├── MyRecipeBook/Resources/    # Assets, colors, fonts, preview images
├── MyRecipeBook/Extensions/   # Swift extensions & helpers
├── MyRecipeBook/Utilities/    # Reusable utilities
└── README.md
```

### Roadmap

The product ships offline-first and stays free for everything that runs on-device.
Cloud-powered features arrive later as an optional premium tier.

- **Phase 1 (MVP — offline)**: Recipe CRUD + OCR import (Apple Vision) + manual entry + beautiful iPad-optimized views
- **Phase 2 (offline, complete the cookbook)**: Cook Mode, serving scaling, measurement conversion (metric ↔ US/imperial), nutrition/calorie calculation, grocery lists, search/filters, tags, favorites & ratings
- **Phase 3 (premium, cloud-powered)**: AWS sync across devices, social & video recipe import from **public** Instagram / TikTok / YouTube / Pinterest / web, web scraper, export, meal planner

Everything in Phases 1 and 2 runs fully on-device and is free. Phase 3 features
rely on a backend (fetching, transcription, AI extraction, sync) and form the
paid tier. See the tiering model below.

### Free vs Premium (planned)

| Capability | Free (offline-first) | Premium (cloud-powered) |
|---|---|---|
| Manual entry | Unlimited | Unlimited |
| OCR import (clippings / handwriting) | Unlimited (on-device) | Unlimited |
| Serving scaling, measurement conversion, nutrition, grocery lists | Yes | Yes |
| Social / video grabs (public content only) | 3 total (taste) | Unlimited |
| Cloud sync across devices | — | Yes |
| Meal planner | — | Yes |

**Privacy First** — Your recipes never leave your devices unless you choose a cloud feature. The free tier is 100% offline. Social/video import only ever touches **public** content.

---

**Built with ❤️ using Kiro**  
Let’s make this the recipe app you actually use every week.

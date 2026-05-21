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
- **Phase 1 (MVP)**: Recipe CRUD + OCR import + beautiful iPad-optimized views
- **Phase 2**: Cook Mode, scaling, search/filters, tags
- **Phase 3**: AWS sync, web scraper, export, meal planner

**Privacy First** — Your recipes never leave your devices unless you choose to sync.

---

**Built with ❤️ using Grok**  
Let’s make this the recipe app you actually use every week.

# PraxisEn UI Implementation - Step by Step Instructions

## 🎨 Design Overview
- **Theme:** Açık krem rengi, sade, modern, iç açıcı
- **Main Feature:** Swipeable flashcard sistemi (sağ/sol kaydır)
- **Card Front:** Kelime + Unsplash fotoğrafı
- **Card Back:** Türkçe çeviri + Max 3 örnek cümle

---

## 📋 Implementation Steps

### ✅ Step 1: Unsplash API Setup
**What to do:**
- Unsplash Developer hesabı aç (https://unsplash.com/developers)
- Yeni uygulama oluştur → Access Key al
- Access Key'i projeye ekle

**Files to create:**
- `Config.swift` - API key için

**User Action Required:**
- [ ] Unsplash Access Key aldın mı?
- [ ] Config dosyası oluşturuldu mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 2: Unsplash Service
**What to do:**
- Unsplash API'den foto çeken service yaz
- Cache mekanizması ekle
- Async/await yapısı kullan

**Files to create:**
- `Services/UnsplashService.swift`
- `Services/ImageCache.swift`

**What it does:**
- Kelimeye göre related foto getirir
- Cache'te varsa oradan döner
- Network error handling

**User Action Required:**
- [ ] Service implementasyonu tamam mı?
- [ ] Test edildi mi?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 3: Theme & Colors
**What to do:**
- Açık krem rengi tema tanımla
- Color extension oluştur
- Typography scale belirle

**Files to create:**
- `Theme/AppTheme.swift`
- `Theme/Colors+Extensions.swift`

**Colors to define:**
- Primary: Açık krem (#FFF8E7)
- Secondary: Koyu krem (#E8DCC4)
- Text: Koyu gri (#2C2C2C)
- Accent: Soft orange/brown

**User Action Required:**
- [ ] Renkler beğendin mi?
- [ ] Typography uygun mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 4: Flashcard View Model
**What to do:**
- Rastgele kelime getiren ViewModel
- Swipe gesture logic
- Card flip logic

**Files to create:**
- `ViewModels/FlashcardViewModel.swift`

**Features:**
- Random kelime seçimi
- Önceki/sonraki kelime
- Flip state management
- Örnek cümle fetch (max 3)

**User Action Required:**
- [ ] ViewModel logic çalışıyor mu?
- [ ] Random kelime geliyor mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 5: Flashcard UI - Front Side
**What to do:**
- Kart ön yüzü: Kelime + foto
- Clean, minimal tasarım
- Image loading state

**Files to create:**
- `Views/Flashcard/FlashcardFrontView.swift`

**Layout:**
```
┌────────────────────┐
│                    │
│   [Unsplash Foto]  │
│                    │
│                    │
│    "abandon"       │ ← Kelime (centered, bold)
│                    │
└────────────────────┘
```

**User Action Required:**
- [ ] Tasarım beğendin mi?
- [ ] Foto yükleniyor mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 6: Flashcard UI - Back Side
**What to do:**
- Kart arka yüzü: Çeviri + örnek cümleler
- Scrollable (örnek cümleler için)

**Files to create:**
- `Views/Flashcard/FlashcardBackView.swift`

**Layout:**
```
┌────────────────────┐
│                    │
│  "abandon"         │
│  ─────────         │
│  terk etmek        │ ← Türkçe
│                    │
│  📝 Examples:       │
│                    │
│  1. "She decided   │
│     to abandon..." │
│                    │
│  2. "Don't abandon │
│     hope..."       │
│                    │
└────────────────────┘
```

**User Action Required:**
- [ ] Arka yüz düzeni iyi mi?
- [ ] Örnek cümleler görünüyor mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 7: Card Flip Animation
**What to do:**
- 3D flip animasyonu ekle
- Tap to flip
- Smooth transition

**Files to modify:**
- `Views/Flashcard/FlashcardView.swift`

**Animation:**
- `.rotation3DEffect` kullan
- 0.6 saniye duration
- Spring animation

**User Action Required:**
- [ ] Animasyon akıcı mı?
- [ ] Flip çalışıyor mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 8: Swipe Gesture 
**What to do:**
- Sağ/sol swipe gesture
- Card stack effect
- Yeni kart getir

**Files to modify:**
- `Views/Flashcard/FlashcardView.swift`
- `ViewModels/FlashcardViewModel.swift`

**Gesture:**
- `.gesture(DragGesture())`
- Threshold: 100 points
- Sağ swipe → Sonraki kelime
- Sol swipe → Önceki kelime

**User Action Required:**
- [ ] Swipe çalışıyor mu?
- [ ] Yeni kart geliyor mu?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 9: Main Screen Assembly
**What to do:**
- Ana ekranı oluştur
- Flashcard view'ı merkeze yerleştir
- Background tema rengini uygula

**Files to modify:**
- `ContentView.swift`

**Layout:**
```
┌─────────────────────┐
│  🎯 PraxisEn        │ ← Minimal header
│                     │
│   [Flashcard]       │ ← Center
│                     │
│                     │
│   Swipe hint        │ ← Alt bilgi
└─────────────────────┘
```

**User Action Required:**
- [ ] Ana ekran tamam mı?
- [ ] Tema rengi uygulandı mı?

**⚠️ STOP - Get user confirmation before proceeding**

---

### ✅ Step 10: Polish & Testing
**What to do:**
- Loading states ekle
- Error handling
- Edge cases test et

**Tasks:**
- [ ] Foto yüklenirken placeholder
- [ ] Network error durumu
- [ ] Kelime biterse ne olur?
- [ ] Cache temizleme

**User Action Required:**
- [ ] Tüm durumlar test edildi mi?
- [ ] App stabil mi?

**⚠️ STOP - Get user confirmation before proceeding**

---

## 📁 Final File Structure

```
PraxisEn/
├── Models/
│   ├── VocabularyWord.swift ✅
│   └── SentencePair.swift ✅
├── ViewModels/
│   └── FlashcardViewModel.swift 🆕
├── Views/
│   ├── Flashcard/
│   │   ├── FlashcardView.swift 🆕
│   │   ├── FlashcardFrontView.swift 🆕
│   │   └── FlashcardBackView.swift 🆕
│   └── ContentView.swift ✅ (modify)
├── Services/
│   ├── UnsplashService.swift 🆕
│   └── ImageCache.swift 🆕
├── Theme/
│   ├── AppTheme.swift 🆕
│   └── Colors+Extensions.swift 🆕
├── Helpers/
│   ├── DatabaseManager.swift ✅
│   └── Config.swift 🆕
└── Data/
    ├── vocabulary.db ✅
    └── sentences.db ✅
```

---

## 🎯 Success Criteria

Each step is complete when:
1. ✅ Code compiles without errors
2. ✅ Feature works as expected
3. ✅ User has tested and approved
4. ✅ User explicitly says "continue" or "next step"

---

## ⚡ Quick Reference

**Unsplash API:**
- Endpoint: `https://api.unsplash.com/search/photos`
- Query param: `query=<word>`
- Header: `Authorization: Client-ID <YOUR_ACCESS_KEY>`

**SwiftUI Components Needed:**
- `DragGesture()` - Swipe
- `.rotation3DEffect()` - Flip
- `AsyncImage` - Photo loading
- `@StateObject` - ViewModel
- `.task {}` - Async operations

**Database Queries:**
- Random word: Already in `DatabaseManager`
- Search sentences: Already implemented
- Max 3 results: Use `.prefix(3)`

---

## 🚨 Important Rules

1. **NEVER proceed without user confirmation**
2. **Keep each step focused and small**
3. **Test before moving to next step**
4. **User must explicitly approve each step**
5. **If user requests changes, modify current step**

---

**Ready to start? Say "Step 1" to begin!** 🚀

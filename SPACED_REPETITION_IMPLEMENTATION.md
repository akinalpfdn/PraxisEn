# Spaced Repetition Implementation Guide

## Proje Özeti
PraxisEn: SwiftUI + SwiftData flashcard uygulaması. 3000 İngilizce kelime + Türkçe çeviri.
Mevcut özellikler: Swipe left/right (navigation), tap to flip, photo loading (Unsplash), example sentences.

## Hedef
Basit spaced repetition sistemi ekle: Öğrenilen kelimeleri takip et, akıllı kelime seçimi, progress bar, stats ekranı.

---

## Kullanıcı Gereksinimleri

### Öğrenme Mekanizması
1. **Öğrendim İşareti**: Kartın ARKA yüzünden yukarı kaydırma (swipe up)
2. **Öğrenilen Kelimeler**: `isKnown=true` ile işaretle, bir daha gösterme (ayrı liste olacak)
3. **Kelime Dengesi**:
   - 0-50 kelime review'da → %70 yeni, %30 tekrar
   - 50-100 kelime review'da → %30 yeni, %70 tekrar
   - 100+ kelime review'da → %0 yeni, %100 tekrar
4. **Zorluk**: YOK. Basit: ya biliyor ya bilmiyor
5. **Progress**: Öğrenilen kelime sayısı (örn: 45/3000)

### UI Gereksinimleri
1. **Progress Bar**: Ana ekran altında, yeşil bar, +1 animasyon
2. **Stats Menu**: Sağ üst profile icon → dropdown menu → Stats / Learned Words / Settings
3. **Navigation**: NavigationStack ile back button

---

## MEVCUT YAPI (DOKUNMA!)

### Models
- **VocabularyWord.swift**: SwiftData model
  - Mevcut fields: `word`, `level`, `turkishTranslation`, `definition`, `isLearned`, `reviewCount`, `lastReviewedDate`
  - Mevcut methods: `markAsReviewed()`, `toggleLearned()`, `resetProgress()`

### ViewModels
- **FlashcardViewModel.swift**: @ObservableObject
  - `currentWord`, `isFlipped`, `wordHistory`, `currentIndex`
  - `loadRandomWord()` → TÜM kelimeleri fetch, random seç
  - `nextWord()`, `previousWord()`, `toggleFlip()`
  - Preview words + photos

### Views
- **ContentView.swift**: Ana view
  - FlashcardContentView içinde SwipeableCardStack
  - Header (profile icon sağ üstte)
  - Hint view (swipe/tap hints)

- **SwipeableCardStack.swift**: Swipe gesture handler
  - Left/right swipe: `onSwipeLeft()`, `onSwipeRight()`
  - Tap: `onTap()`
  - Mevcut gesture: Sadece horizontal

- **FlashcardView.swift**: Flip container (front/back)
- **FlashcardFrontView.swift**: Ön yüz (word + photo)
- **FlashcardBackView.swift**: Arka yüz (translation, definition, examples, synonyms, antonyms, collocations)

### Services
- **UnsplashService**: Photo loading + cache
- **DatabaseManager**: SQLite for sentences

---

## STEP-BY-STEP IMPLEMENTATION

### Step 1: VocabularyWord Model'i Genişlet ✅
**Dosya**: `PraxisEn/Models/VocabularyWord.swift`

**ÖNEMLİ**: Mevcut fields KALACAK! Sadece YENİ ekle.

**Eklenecek Fields**:
```swift
var isKnown: Bool = false         // Kullanıcı "öğrendim" dedi mi?
var nextReviewDate: Date?         // Bir sonraki tekrar tarihi
var repetitions: Int = 0          // Kaç kere tekrar edildi
```

**Eklenecek Computed Property**:
```swift
var isDueForReview: Bool {
    guard let reviewDate = nextReviewDate else { return true }
    return reviewDate <= Date()
}
```

**Eklenecek Methods**:
```swift
func scheduleNextReview() {
    // Interval tablosu: [1, 3, 7, 14, 30] gün
    let intervals = [1, 3, 7, 14, 30]
    let dayInterval = repetitions < intervals.count
        ? intervals[repetitions]
        : 30

    nextReviewDate = Calendar.current.date(
        byAdding: .day,
        value: dayInterval,
        to: Date()
    )
    repetitions += 1
}

func markAsKnown() {
    isKnown = true
    nextReviewDate = nil
}

func resetKnownStatus() {
    isKnown = false
    repetitions = 0
    nextReviewDate = Date()
}
```

**Test**: Uygulamayı çalıştır, SwiftData migration çalıştı mı? Crash yok mu?

**İlerleme Kaydı**: `SPACED_REPETITION_IMPLEMENTATION.md` içinde Step 1'in başına `✅` ekle.

---

### Step 2: SpacedRepetitionManager Oluştur
**Dosya**: `PraxisEn/Helpers/SpacedRepetitionManager.swift` **(YENİ DOSYA)**

**Amaç**: Kelime seçim algoritması (FlashcardViewModel buradan çağıracak)

**Tam Kod**:
```swift
import Foundation
import SwiftData

@MainActor
class SpacedRepetitionManager {

    /// Bir sonraki kelimeyi seç
    static func selectNextWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        let stats = await getReviewStats(from: context)
        let shouldShowNew = shouldSelectNewWord(stats: stats)

        if shouldShowNew {
            return await selectNewWord(from: context, excluding: recentWords)
        } else {
            return await selectReviewWord(from: context, excluding: recentWords)
        }
    }

    /// Stats hesapla
    static func getReviewStats(from context: ModelContext) async -> ReviewStats {
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = (try? context.fetch(descriptor)) ?? []

        let known = allWords.filter { $0.isKnown }.count
        let inReview = allWords.filter { !$0.isKnown && $0.repetitions > 0 }.count
        let dueForReview = allWords.filter { !$0.isKnown && $0.isDueForReview }.count

        return ReviewStats(
            totalWords: allWords.count,
            knownWords: known,
            wordsInReview: inReview,
            wordsDueForReview: dueForReview
        )
    }

    /// Yeni mi yoksa tekrar mı gösterelim?
    private static func shouldSelectNewWord(stats: ReviewStats) -> Bool {
        let inReview = stats.wordsInReview

        if inReview < 50 {
            return Double.random(in: 0...1) < 0.7  // %70 yeni
        } else if inReview < 100 {
            return Double.random(in: 0...1) < 0.3  // %30 yeni
        } else {
            return false  // %0 yeni (sadece tekrar)
        }
    }

    /// Yeni kelime seç
    private static func selectNewWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions == 0
            }
        )
        descriptor.fetchLimit = 100

        let newWords = (try? context.fetch(descriptor)) ?? []
        let recentIDs = Set(recentWords.map { $0.word })
        let available = newWords.filter { !recentIDs.contains($0.word) }

        return available.randomElement()
    }

    /// Tekrar edilmesi gereken kelime seç
    private static func selectReviewWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions > 0
            },
            sortBy: [SortDescriptor(\.nextReviewDate)]
        )
        descriptor.fetchLimit = 50

        let reviewWords = (try? context.fetch(descriptor)) ?? []
        let recentIDs = Set(recentWords.map { $0.word })
        let available = reviewWords.filter { !recentIDs.contains($0.word) }

        // Vadesi geçmiş olanları önceliklendir
        let overdue = available.filter { $0.isDueForReview }
        return overdue.first ?? available.randomElement()
    }
}

struct ReviewStats {
    let totalWords: Int
    let knownWords: Int
    let wordsInReview: Int
    let wordsDueForReview: Int
}
```

**Test**: Compile ediyor mu? Import hataları yok mu?

**İlerleme Kaydı**: Step 2'ye `✅` ekle.

---

### Step 3: FlashcardViewModel'i Güncelle
**Dosya**: `PraxisEn/ViewModels/FlashcardViewModel.swift`

**ÖNEMLİ**: Mevcut functionality KALACAK! Sadece eklemeler yapacağız.

**Eklenecek Properties** (var `@Published` olanların yanına):
```swift
@Published var knownWordsCount: Int = 0
@Published var totalWordsCount: Int = 3000
@Published var showProgressAnimation: Bool = false
```

**YENİ Method Ekle** (`loadRandomWord()` üstüne veya altına):
```swift
/// Spaced repetition ile bir sonraki kelimeyi yükle
func loadNextWord() async {
    guard let word = await SpacedRepetitionManager.selectNextWord(
        from: modelContext,
        excluding: Array(wordHistory.suffix(10))
    ) else {
        // Fallback: eski random yöntemi
        await loadRandomWord()
        return
    }

    currentWord = word
    addToHistory(word)

    isFlipped = false
    await loadPhotoForCurrentWord()
    await loadExamplesForCurrentWord()
    await updatePreviews()
    await updateKnownWordsCount()
}
```

**Ekle** (`markAsReviewed()` gibi methodların yanına):
```swift
/// Kelimeyi "öğrendim" olarak işaretle
func markCurrentWordAsKnown() async {
    guard let word = currentWord else { return }

    word.markAsKnown()
    try? modelContext.save()

    await updateKnownWordsCount()

    // +1 animasyonu göster
    showProgressAnimation = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    showProgressAnimation = false

    // Yeni kelime yükle
    await loadNextWord()
}

/// Öğrenilen kelime sayısını güncelle
func updateKnownWordsCount() async {
    let descriptor = FetchDescriptor<VocabularyWord>(
        predicate: #Predicate { $0.isKnown }
    )
    let knownWords = (try? modelContext.fetch(descriptor)) ?? []
    knownWordsCount = knownWords.count
}
```

**GÜNCELLE** (mevcut `nextWord()` methodunu):
```swift
func nextWord() async {
    // Mevcut kelimeyi review için zamanla
    if let word = currentWord, !word.isKnown {
        word.scheduleNextReview()
        try? modelContext.save()
    }

    // MEVCUT KOD KALACAK (aşağıdaki kısım değişmeyecek)
    if currentIndex < wordHistory.count - 1 {
        currentIndex += 1
        currentWord = wordHistory[currentIndex]
    } else {
        if let preview = nextWordPreview {
            currentWord = preview
            addToHistory(preview)
        } else {
            await loadNextWord()  // YENİ: loadRandomWord yerine loadNextWord
            return
        }
    }

    currentPhoto = nextWordPreviewPhoto
    isFlipped = false
    await loadPhotoForCurrentWord()
    await loadExamplesForCurrentWord()
    await updatePreviews()
}
```

**GÜNCELLE** (`previousWord()` da aynı şekilde):
```swift
func previousWord() async {
    // Mevcut kelimeyi review için zamanla
    if let word = currentWord, !word.isKnown {
        word.scheduleNextReview()
        try? modelContext.save()
    }

    // MEVCUT KOD AYNEN KALACAK...
}
```

**GÜNCELLE** (ContentView'de ilk yükleme - `task` modifier içinde):
```swift
.task {
    let vm = FlashcardViewModel(modelContext: modelContext)
    viewModel = vm

    await vm.loadNextWord()  // DEĞİŞTİ: loadRandomWord yerine loadNextWord
    await vm.updateKnownWordsCount()  // YENİ: progress sayacını başlat
}
```

**Test**: Kelime seçimi çalışıyor mu? Progress count doğru mu?

**İlerleme Kaydı**: Step 3'e `✅` ekle.

---

### Step 4: Swipe Up Gesture Ekle
**Dosya**: `PraxisEn/Views/Flashcard/SwipeableCardStack.swift`

**Eklenecek Properties**:
```swift
@State private var verticalOffset: CGFloat = 0
private let swipeUpThreshold: CGFloat = -100
```

**Eklenecek Callback** (mevcut callback'lerin yanına):
```swift
let onSwipeUp: () -> Void
```

**GÜNCELLE** (mevcut `DragGesture` içindeki `.onChanged`):
```swift
.onChanged { value in
    let horizontalAmount = value.translation.width
    let verticalAmount = value.translation.height

    // Vertical swipe (sadece arka yüzde ve yukarı)
    if verticalAmount < 0 && currentCard.isFlipped && abs(verticalAmount) > abs(horizontalAmount) {
        verticalOffset = verticalAmount
        isDragging = true
    }
    // Horizontal swipe (mevcut kod)
    else if abs(horizontalAmount) > abs(verticalAmount) {
        offset = horizontalAmount
        isDragging = true
    }
}
```

**GÜNCELLE** (mevcut `DragGesture` içindeki `.onEnded`):
```swift
.onEnded { value in
    let horizontalAmount = value.translation.width
    let verticalAmount = value.translation.height

    // Swipe up (arka yüzden yukarı)
    if verticalAmount < swipeUpThreshold && currentCard.isFlipped {
        withAnimation(.easeOut(duration: 0.3)) {
            verticalOffset = -1000
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipeUp()
            verticalOffset = 0
        }
        return
    }

    // MEVCUT HORIZONTAL SWIPE KODU AYNEN KALACAK
    if abs(horizontalAmount) > abs(verticalAmount) {
        if abs(horizontalAmount) > swipeThreshold {
            // ... mevcut kod ...
        }
    }

    // Reset offsets
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        offset = 0
        verticalOffset = 0
    }
    isDragging = false
}
```

**GÜNCELLE** (card offset):
```swift
FlashcardView(...)
    .offset(x: offset, y: verticalOffset)  // DEĞİŞTİ: y eklendi
    .rotationEffect(...)
```

**Test**: Arka yüzden yukarı swipe çalışıyor mu? Ön yüzden yukarı swipe engelleniyor mu?

**İlerleme Kaydı**: Step 4'e `✅` ekle.

---

### Step 5: ProgressBarView Oluştur
**Dosya**: `PraxisEn/Views/Components/ProgressBarView.swift` **(YENİ DOSYA)**

**Tam Kod**:
```swift
import SwiftUI

struct ProgressBarView: View {
    let current: Int
    let total: Int
    let showAnimation: Bool

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress text
            HStack {
                Text("Words Learned")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(current)/\(total)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.success)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.gray.opacity(0.2))

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.success, .success.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)

                    // +1 Animation
                    if showAnimation {
                        Text("+1")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.success)
                            .offset(
                                x: geometry.size.width * progress - 20,
                                y: -30
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
    }
}
```

**Dosya**: `PraxisEn/ContentView.swift` **GÜNCELLE**

**Ekle** (flashcard ve hint view arasına):
```swift
Spacer()

// Progress bar (YENİ)
ProgressBarView(
    current: viewModel.knownWordsCount,
    total: viewModel.totalWordsCount,
    showAnimation: viewModel.showProgressAnimation
)
.padding(.horizontal, AppSpacing.lg)

// Bottom hint
hintView
```

**Test**: Progress bar görünüyor mu? +1 animasyon test et (manuel trigger).

**İlerleme Kaydı**: Step 5'e `✅` ekle.

---

### Step 6: Profile Icon Dropdown Menu
**Dosya**: `PraxisEn/ContentView.swift`

**Ekle** (FlashcardContentView içine, en üstte):
```swift
@State private var showMenuDropdown = false
```

**GÜNCELLE** (mevcut profile icon):
```swift
Image(systemName: "person.circle.fill")
    .font(.system(size: 32))
    .foregroundColor(.accentOrange)
    .onTapGesture {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showMenuDropdown.toggle()
        }
    }
```

**Ekle** (headerView'in `.overlay` modifier'ı olarak - döndüğü HStack'in dışında):
```swift
private var headerView: some View {
    HStack {
        // ... mevcut kod ...
    }
    .overlay(alignment: .topTrailing) {
        if showMenuDropdown {
            VStack(spacing: 0) {
                MenuButton(icon: "chart.bar.fill", title: "Stats") {
                    showMenuDropdown = false
                    // TODO: Navigate
                }

                Divider()

                MenuButton(icon: "checkmark.circle.fill", title: "Learned Words") {
                    showMenuDropdown = false
                    // TODO: Navigate
                }

                Divider()

                MenuButton(icon: "gearshape.fill", title: "Settings") {
                    showMenuDropdown = false
                    // TODO: Navigate
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 10)
            .padding(.top, 50)
            .padding(.trailing, 10)
            .transition(.scale.combined(with: .opacity))
            .zIndex(100)
        }
    }
}
```

**Ekle** (ContentView sonuna, helper view):
```swift
struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentOrange)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 200)
    }
}
```

**Test**: Menu açılıyor/kapanıyor mu? Animasyon smooth mu?

**İlerleme Kaydı**: Step 6'ya `✅` ekle.

---

### Step 7: StatsView Oluştur
**Dosya**: `PraxisEn/Views/Stats/StatsView.swift` **(YENİ DOSYA, YENİ KLASÖR)**

Önce klasör oluştur: `PraxisEn/Views/Stats/`

**Tam Kod**:
```swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: ReviewStats?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let stats = stats {
                    StatCard(
                        title: "Words Learned",
                        value: "\(stats.knownWords)",
                        icon: "checkmark.circle.fill",
                        color: .success
                    )

                    StatCard(
                        title: "In Review",
                        value: "\(stats.wordsInReview)",
                        icon: "arrow.clockwise.circle.fill",
                        color: .accentOrange
                    )

                    StatCard(
                        title: "Due Today",
                        value: "\(stats.wordsDueForReview)",
                        icon: "clock.fill",
                        color: .info
                    )

                    StatCard(
                        title: "Total Words",
                        value: "\(stats.totalWords)",
                        icon: "book.fill",
                        color: .textSecondary
                    )
                } else {
                    ProgressView("Loading stats...")
                }
            }
            .padding()
        }
        .background(Color.creamBackground.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            stats = await SpacedRepetitionManager.getReviewStats(from: modelContext)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
```

**Test**: View compile ediyor mu?

**İlerleme Kaydı**: Step 7'ye `✅` ekle.

---

### Step 8: LearnedWordsView Oluştur
**Dosya**: `PraxisEn/Views/Stats/LearnedWordsView.swift` **(YENİ DOSYA)**

**Tam Kod**:
```swift
import SwiftUI
import SwiftData

struct LearnedWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<VocabularyWord> { $0.isKnown },
        sort: \VocabularyWord.word
    ) private var learnedWords: [VocabularyWord]

    @State private var searchText = ""

    var filteredWords: [VocabularyWord] {
        if searchText.isEmpty {
            return learnedWords
        }
        return learnedWords.filter {
            $0.word.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if learnedWords.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredWords, id: \.word) { word in
                        WordRow(word: word) {
                            resetWord(word)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search learned words")
            }
        }
        .background(Color.creamBackground.ignoresSafeArea())
        .navigationTitle("Learned Words")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)

            Text("No learned words yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.textSecondary)

            Text("Swipe up on a card to mark it as learned")
                .font(.system(size: 14))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func resetWord(_ word: VocabularyWord) {
        word.resetKnownStatus()
        try? modelContext.save()
    }
}

struct WordRow: View {
    let word: VocabularyWord
    let onReset: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.word.capitalized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(word.turkishTranslation)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.accentOrange)
                    .padding(8)
                    .background(Circle().fill(Color.accentOrange.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

**Test**: Compile ediyor mu?

**İlerleme Kaydı**: Step 8'e `✅` ekle.

---

### Step 9: NavigationStack Ekle
**Dosya**: `PraxisEn/ContentView.swift`

**Ekle** (ContentView içine, en üstte):
```swift
enum NavigationDestination: Hashable {
    case stats
    case learnedWords
    case settings
}

@State private var navigationPath: [NavigationDestination] = []
```

**GÜNCELLE** (ContentView body - tüm içeriği NavigationStack'e sar):
```swift
var body: some View {
    NavigationStack(path: $navigationPath) {
        ZStack {
            Color.creamBackground.ignoresSafeArea()

            if let viewModel = viewModel {
                FlashcardContentView(
                    viewModel: viewModel,
                    navigationPath: $navigationPath  // YENİ: binding geç
                )
            } else {
                ProgressView("Initializing...")
                    .font(AppTypography.bodyText)
                    .foregroundColor(.textSecondary)
            }
        }
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .stats:
                StatsView()
            case .learnedWords:
                LearnedWordsView()
            case .settings:
                Text("Settings - Coming Soon")
                    .navigationTitle("Settings")
            }
        }
    }
    .task {
        // ... mevcut kod ...
    }
}
```

**GÜNCELLE** (FlashcardContentView signature):
```swift
struct FlashcardContentView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @Binding var navigationPath: [NavigationDestination]  // YENİ

    // ... mevcut kod ...
}
```

**GÜNCELLE** (MenuButton action'ları):
```swift
MenuButton(icon: "chart.bar.fill", title: "Stats") {
    showMenuDropdown = false
    navigationPath.append(.stats)
}

MenuButton(icon: "checkmark.circle.fill", title: "Learned Words") {
    showMenuDropdown = false
    navigationPath.append(.learnedWords)
}

MenuButton(icon: "gearshape.fill", title: "Settings") {
    showMenuDropdown = false
    navigationPath.append(.settings)
}
```

**Test**: Navigation çalışıyor mu? Geri butonu var mı? Stats/LearnedWords açılıyor mu?

**İlerleme Kaydı**: Step 9'a `✅` ekle.

---

### Step 10: Swipe Up'ı Bağla
**Dosya**: `PraxisEn/ContentView.swift`

**GÜNCELLE** (SwipeableCardStack çağrısı):
```swift
SwipeableCardStack(
    currentCard: ...,
    nextCard: ...,
    previousCard: ...,
    onSwipeLeft: {
        Task {
            await viewModel.nextWord()
        }
    },
    onSwipeRight: {
        Task {
            await viewModel.previousWord()
        }
    },
    onTap: {
        viewModel.toggleFlip()
    },
    onSwipeUp: {  // YENİ
        Task {
            await viewModel.markCurrentWordAsKnown()
        }
    }
)
```

**Test**: Arka yüzden yukarı swipe → progress artar, yeni kelime gelir, +1 animasyon görünür.

**İlerleme Kaydı**: Step 10'a `✅` ekle.

---

### Step 11: Test & Polish

**Test Senaryoları**:
1. ✅ İlk açılış: progress 0/3000
2. ✅ Yeni kelime gösteriliyor
3. ✅ Arka yüze flip et → yukarı swipe → progress artar
4. ✅ +1 animasyon görünüyor
5. ✅ Learned Words listesinde kelime var
6. ✅ Stats doğru sayıları gösteriyor
7. ✅ 50 kelime öğrendikten sonra denge değişiyor mu?
8. ✅ Reset butonu çalışıyor mu?
9. ✅ Ön yüzden yukarı swipe engelleniyor

**Polish**:
- Haptic feedback (yukarı swipe'ta)
- Loading states
- Error handling

**İlerleme Kaydı**: Step 11'e `✅` ekle.

---

## SON KONTROL LİSTESİ

Tamamlandı mı?
- [ ] Step 1: VocabularyWord genişletildi
- [ ] Step 2: SpacedRepetitionManager oluşturuldu
- [ ] Step 3: FlashcardViewModel güncellendi
- [ ] Step 4: Swipe up gesture eklendi
- [ ] Step 5: ProgressBarView oluşturuldu
- [ ] Step 6: Dropdown menu eklendi
- [ ] Step 7: StatsView oluşturuldu
- [ ] Step 8: LearnedWordsView oluşturuldu
- [ ] Step 9: NavigationStack eklendi
- [ ] Step 10: Swipe up bağlandı
- [ ] Step 11: Test edildi

---

## HATIRLATMA

**HER ADIM SONRASI**:
1. Build et, hataları gider
2. Test et
3. SPACED_REPETITION_IMPLEMENTATION.md'de ilgili step'e `✅` ekle
4. Kullanıcıdan onay al
5. Bir sonraki step'e geç

**ASLA**:
- Mevcut kodu silme
- Birden fazla step'i aynı anda yapma
- Kullanıcı onayı olmadan devam etme

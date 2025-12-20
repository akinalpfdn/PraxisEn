# PraxisEn iOS App (Swift)

> **Master English Vocabulary with the Oxford 3000™ & Spaced Repetition.**
> *No Ads. No Distractions. Just Learning.*

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat&logo=swift)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-lightgrey.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Live-blue.svg?style=flat)]()

## 📖 Overview

**PraxisEn** is a minimalist, offline-first iOS application written in Swift that helps Turkish speakers master the most important 3,000 English words (Oxford 3000™).

This Swift implementation features a modern iOS architecture using SwiftUI, SwiftData, and a hybrid database approach to deliver a seamless language learning experience with scientific Spaced Repetition System (SRS) algorithms.

## ✨ Key Features

- **📚 Oxford 3000™ Vocabulary**: Covers A1 to B2 levels with curated vocabulary
- **🧠 Spaced Repetition System (SRS)**: Smart algorithms schedule reviews at optimal intervals
- **⚡️ Offline-First**: 100% functional without internet connection
- **🇹🇷 Contextual Learning**: 700,000+ Turkish-English sentence pairs from Tatoeba corpus
- **🎨 Modern SwiftUI Interface**: Clean, gesture-based design with swipe navigation
- **🔊 Audio Support**: Text-to-speech pronunciation for all vocabulary words
- **📱 Subscription Model**: Freemium model with premium features
- **🎯 Gamification Free**: Focus on pure learning without distractions

## 🛠 Technical Architecture

### iOS-Specific Implementation

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (Core Data) + SQLite hybrid approach
- **Target Platform**: iOS 17.0+
- **Development Environment**: Xcode 15.0+

### Hybrid Database Architecture

To handle **3,000+ words** and **700,000+ sentences** efficiently on mobile devices:

1. **SwiftData (Vocabulary)**:
   - Stores 3,354 vocabulary entries with user progress
   - Reactive UI bindings with SwiftUI
   - Handles user state (learning progress, reviews)

2. **SQLite (Sentences)**:
   - Pre-bundled SQLite database (~153 MB) for sentence corpus
   - FTS5 (Full-Text Search) optimized for instant (<50ms) queries
   - Low memory footprint (~10-20 MB)

### Key Components

```
PraxisEn/
├── Models/
│   ├── VocabularyWord.swift          # SwiftData model for vocabulary
│   ├── SentencePair.swift            # Sentence pair structure
│   └── UserSettings.swift            # User preferences and progress
├── ViewModels/
│   ├── FlashcardViewModel.swift      # Main learning logic
│   └── LearnedFlashcardViewModel.swift
├── Views/
│   ├── Flashcard/                    # Flashcard UI components
│   ├── Stats/                        # Progress tracking views
│   ├── Settings/                     # App configuration
│   └── Premium/                      # Subscription features
├── Services/
│   ├── AudioManager.swift            # Text-to-speech
│   ├── ImageService.swift            # Image handling
│   ├── SubscriptionManager.swift     # In-app purchases
│   └── ODRManager.swift              # On-demand resources
├── Helpers/
│   ├── DatabaseManager.swift         # Database operations
│   ├── SpacedRepetitionManager.swift # SRS algorithm
│   └── Config.swift                  # App configuration
└── Theme/
    ├── AppTheme.swift                # UI theme definitions
    └── Colors+Extensions.swift       # Color schemes
```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ target
- Swift 5.9+
- CocoaPods (if using external dependencies)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/akinalpfdn/PraxisEn.git
   cd PraxisEn/PraxisEnSwift
   ```

2. **Open in Xcode**
   ```bash
   open PraxisEn.xcodeproj
   ```

3. **Set up API Keys**
   - Create `APIKeys.swift` in the project root
   - Add your API keys for text-to-speech and image generation services

4. **Add Database Files**
   - The app requires `vocabulary.db` and `sentences.db`
   - If not present, generate them using the Python scripts (see DATABASE_SETUP_README.md)
   - Add database files to the Xcode project bundle

5. **Build and Run**
   - Select your target simulator or device
   - Press `Cmd + R` to build and run

## 📱 App Architecture

### SwiftUI Navigation

```swift
enum NavigationDestination: Hashable {
    case stats
    case learnedWords
    case settings
    case learnedFlashcard(wordID: String, allLearnedWordIDs: [String])
}
```

### Core Components

#### FlashcardViewModel
- Manages flashcard presentation logic
- Handles word selection and progression
- Integrates with spaced repetition system
- Manages audio and image loading

#### DatabaseManager
- Hybrid database operations
- SwiftData integration
- SQLite sentence queries
- Database migration and setup

#### SubscriptionManager
- Freemium model implementation
- Feature access control
- Purchase validation

## 🎯 User Features

### Flashcard Learning
- **Swipe Gestures**: Left/Right for navigation, Up to mark as known
- **Tap to Flip**: Reveal translation and definition
- **Audio Pronunciation**: Text-to-speech for all words
- **Visual Learning**: AI-generated images for vocabulary
- **Context Examples**: Real-world Turkish-English sentences

### Progress Tracking
- **Learning Statistics**: Words learned, review streaks
- **CEFR Level Progress**: A1, A2, B1, B2 completion tracking
- **Spaced Repetition**: Smart review scheduling based on performance

### Premium Features
- **Unlimited Learning**: Access to all 3,000+ words
- **B2 Level Content**: Advanced vocabulary unlocked
- **Background Audio**: Practice while multitasking
- **Offline Mode**: Complete offline functionality

## 🗲 Database Integration

### SwiftData Model

```swift
@Model
final class VocabularyWord {
    @Attribute(.unique) var word: String
    var level: String                    // A1, A2, B1, B2
    var turkishTranslation: String
    var isLearned: Bool
    var reviewCount: Int
    var repetitions: Int                 // SRS counter
    var isKnown: Bool                   // Mastered words
    // ... additional properties
}
```

### SQLite Queries for Sentences

```swift
// Search for contextual examples
let sentences = try await DatabaseManager.shared.searchSentences(
    containing: "merhaba",
    limit: 50
)
```

## 🧠 Spaced Repetition Implementation

The app uses a modified SuperMemo-2 algorithm:

```swift
class SpacedRepetitionManager {
    func calculateNextReview(for word: VocabularyWord, quality: Int) -> Date {
        // Implementation of SRS algorithm
        // Returns optimal review date based on performance
    }
}
```

## 📦 Dependencies

### iOS Frameworks
- `SwiftUI` - Modern UI framework
- `SwiftData` - Data persistence
- `StoreKit` - In-app purchases
- `AVFoundation` - Audio playback
- `SQLite3` - Direct database access

### External Services
- Text-to-Speech API (for pronunciation)
- Image Generation API (for vocabulary visuals)
- StoreKit (for subscription management)

## 🔧 Configuration

### App Settings (Config.swift)
```swift
struct Config {
    static let apiKey = "YOUR_API_KEY"
    static let maxDailyFreeWords = 20
    static let subscriptionTiers = [...]
}
```

### User Preferences
- Daily learning goals
- Audio settings
- Theme preferences
- Learning mode (review vs. new words)

## 📊 Performance Optimizations

### Memory Management
- Lazy loading of images and audio
- Efficient SQLite queries with indexing
- SwiftData relationship optimization

### UI Performance
- SwiftUI view modifiers optimization
- Image caching with `AsyncImage`
- Smooth animations and transitions

### Network Optimization
- On-Demand Resources (ODR) for large assets
- Progressive content loading
- Offline-first architecture

## 🧪 Testing

### Unit Tests
- ViewModel logic testing
- Database operations
- SRS algorithm validation

### UI Tests
- User flow automation
- Gesture recognition
- Subscription flow testing

## 🗺 Development Roadmap

### Current Features ✅
- Core flashcard functionality
- Spaced repetition system
- Audio pronunciation
- Subscription model
- Offline support

### Planned Features 🚧
- Widget support
- Apple Watch companion app
- Advanced analytics
- Social learning features
- Custom vocabulary lists

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

**Akın Alp Fidan**
📧 feedback@praxisen.com
GitHub: [@akinalpfdn](https://github.com/akinalpfdn)

---

*Built with ❤️ for language learners using modern iOS technologies.*
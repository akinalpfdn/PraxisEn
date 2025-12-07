# PraxisEn

> **Master English Vocabulary with the Oxford 3000™ & Spaced Repetition.**  
> *No Ads. No Distractions. Just Learning.*

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat&logo=swift)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-lightgrey.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Live-blue.svg?style=flat)]()

## 📖 Overview

**PraxisEn** is a minimalist, offline-first iOS application designed to help Turkish speakers master the most important 3,000 English words (Oxford 3000™). 

Unlike other language apps that clutter the experience with gamification and ads, PraxisEn focuses purely on **efficiency** and **retention**. By combining a curated vocabulary list with a scientific **Spaced Repetition System (SRS)** and real-world sentence examples from the Tatoeba corpus, it ensures you learn the words that matter most, and remember them forever.

## ✨ Key Features

- **📚 Oxford 3000™ Vocabulary**: Covers A1 to B2 levels, representing the most frequent and useful words in English.
- **🧠 Spaced Repetition System (SRS)**: Smart algorithms schedule reviews at the optimal time to combat the forgetting curve.
- **⚡️ Offline-First**: 100% functional without an internet connection.
- **🇹🇷 Contextual Learning**: Over **700,000+** Turkish-English sentence pairs to see words in real-life context.
- **🎨 Minimalist Design**: A clean, gesture-based interface (Swipe Left/Right) designed for focus.
- **🔊 Rich Metadata**: Includes definitions, synonyms, antonyms, collocations, and pronunciation (coming soon).

## 📱 Screenshots

| Home Screen | Flashcard | Stats |
|:-----------:|:---------:|:------------:|
| <img src="Media/Simulator Screenshot - iPhone 17 Pro - 2025-12-07 at 17.31.26.png" width="250" /> | <img src="Media/Simulator Screenshot - iPhone 17 Pro - 2025-12-07 at 17.31.36.png" width="250" /> | <img src="Media/Simulator Screenshot - iPhone 17 Pro - 2025-12-07 at 17.31.48.png" width="250" /> |
 

## 🛠 Technical Architecture

PraxisEn is built with modern iOS technologies and a unique hybrid database architecture to ensure performance and scalability.

### The Hybrid Database Approach
To handle **3,000+ words** and **700,000+ sentences** efficiently on a mobile device, we utilize a dual-database strategy:

1.  **SwiftData (Vocabulary)**: 
    -   Used for the core 3,354 vocabulary entries.
    -   Handles user state (learning progress, reviews) and UI bindings.
    -   Ensures reactive UI updates and seamless integration with SwiftUI.

2.  **SQLite (Sentences)**:
    -   A raw, pre-bundled SQLite database (~153 MB) stores the massive sentence corpus.
    -   Optimized with **FTS5 (Full-Text Search)** for instant (<50ms) context queries.
    -   Keeps the app's memory footprint low (~10-20 MB) by avoiding loading all data into memory.

### Tech Stack
-   **Language**: Swift 5.9
-   **UI Framework**: SwiftUI
-   **Data Persistence**: SwiftData & SQLite (Direct Access)
-   **Data Processing**: Python (Pandas, pdfplumber) for parsing and generating databases.

## 🚀 Getting Started

### Prerequisites
-   Xcode 15.0+
-   iOS 17.0+
-   Python 3.9+ (only if you need to regenerate data)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/akinalpfdn/PraxisEn.git
    cd PraxisEn
    ```

2.  **Prepare the Databases**
    The app requires `vocabulary.db` and `sentences.db`. If they are not present in the `PraxisEn/Resources` folder (due to gitignore), you can generate them:
    ```bash
    # Install dependencies
    pip install pandas pdfplumber

    # Run the generation script
    python generate_sqlite_databases.py
    ```
    *This will create the `.db` files which you should then add to the Xcode project.*

3.  **Open in Xcode**
    ```bash
    open PraxisEn.xcodeproj
    ```

4.  **Build and Run**
    Select your target simulator or device and hit `Cmd + R`.

## 🗺 Roadmap

- [x] **Phase 1: Foundation**
    - [x] PDF Parsing & Data Extraction
    - [x] Hybrid Database Architecture Implementation
    - [x] Basic UI & Navigation
- [x] **Phase 2: Core Learning**
    - [x] Spaced Repetition Algorithm (SuperMemo-2 or similar)
    - [x] Statistics Dashboard
    - [x] Daily Word Notifications
- [x] **Phase 3: Polish & Polish**
    - [x] Audio Pronunciations (TTS)
    - [x] Image generation for vocabulary
    - [x] Widget Support

## 🤝 Contributing

Contributions are welcome! If you have ideas for improvements or bug fixes, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

**Akın Alp Fidan**  
📧 feedback@praxisen.com  
GitHub: [@akinalpfdn](https://github.com/akinalpfdn)

---
*Built with ❤️ for language learners.*

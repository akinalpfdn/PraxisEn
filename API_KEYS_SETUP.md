# 🔒 API Keys Setup Guide

## Güvenlik Notu
⚠️ **Bu repo public olduğu için API key'leri asla commit etme!**

API key'ler `Secrets.plist` dosyasında tutulur ve `.gitignore`'a eklenmiştir.

---

## 📝 Kurulum Adımları

### 1. Unsplash API Key Al

1. [Unsplash Developers](https://unsplash.com/developers) sitesine git
2. Hesap oluştur veya giriş yap
3. "New Application" oluştur
4. Access Key'i kopyala

### 2. Secrets.plist Dosyasını Güncelle

Proje içinde `Secrets.plist` dosyası var:
```
PraxisEn/PraxisEn/Secrets.plist
```

Bu dosyayı aç ve API key'ini yapıştır:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UnsplashAccessKey</key>
    <string>BURAYA_SENIN_API_KEYIN</string>
</dict>
</plist>
```

### 3. Xcode'a Ekle

1. `Secrets.plist` dosyasını Xcode projesine ekle
2. **ÖNEMLİ:** "Copy items if needed" ✓ seçili olsun
3. Target'a eklenmiş olsun ✓

### 4. Test Et

Uygulamayı çalıştır. Console'da şunu görmemelisin:
```
⚠️ Warning: Could not load 'UnsplashAccessKey' from Secrets.plist
```

Eğer görüyorsan:
- Secrets.plist dosyası Bundle'a eklendi mi?
- API key doğru yapıştırıldı mı?

---

## 📁 Dosya Yapısı

```
PraxisEn/
├── .gitignore                    # Secrets.plist ignore edilir
├── API_KEYS_SETUP.md            # Bu dosya
└── PraxisEn/
    ├── Helpers/
    │   └── Config.swift          # Secrets.plist'ten okur
    └── Secrets.plist            # API keys (GIT'E GİTMEZ!)
```

---

## 🔍 Nasıl Çalışır?

**Config.swift:**
```swift
static var unsplashAccessKey: String {
    return loadSecret(key: "UnsplashAccessKey")
}
```

Bu kod `Secrets.plist` dosyasından API key'i okur.

---

## ⚠️ Güvenlik Kontrol Listesi

- [x] `.gitignore` dosyası oluşturuldu
- [x] `Secrets.plist` `.gitignore`'a eklendi
- [ ] `Secrets.plist` dosyasına API key eklendi
- [ ] `git status` ile kontrol edildi (Secrets.plist görünmemeli)
- [ ] Uygulama test edildi

---

## 🚨 Eğer Yanlışlıkla Commit Ettiysen

API key'i yanlışlıkla commit ettiysen:

1. **Hemen Unsplash'ta key'i iptal et**
2. Yeni bir key oluştur
3. Git history'den sil:
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch Secrets.plist" \
  --prune-empty --tag-name-filter cat -- --all

git push origin --force --all
```

---

## 💡 Best Practices

✅ **YAP:**
- API key'leri .plist dosyasında tut
- .gitignore'a ekle
- Ekip için setup guide yaz

❌ **YAPMA:**
- API key'leri code'a hard-code etme
- Public repo'da secret commit etme
- API key'leri screenshot'ta paylaşma

---

**Sorular için:** README.md'ye bak veya issue aç!

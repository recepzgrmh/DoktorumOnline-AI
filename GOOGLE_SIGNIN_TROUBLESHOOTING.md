# Google Sign-In Sorun Giderme Rehberi

## Yapılan Düzeltmeler

### 1. Kod İyileştirmeleri

- ✅ Detaylı hata yönetimi eklendi
- ✅ Debug log'ları eklendi
- ✅ Google Sign-In konfigürasyonu iyileştirildi
- ✅ AndroidManifest.xml'e intent-filter eklendi

### 2. Firebase Console Kontrolleri

#### Authentication > Sign-in method

1. **Google'ı etkinleştirin:**
   - Firebase Console > Authentication > Sign-in method
   - Google'ı etkinleştirin
   - Web SDK configuration'da client ID'yi kontrol edin

#### Project Settings > General

1. **SHA-1 sertifika parmak izlerini kontrol edin:**
   - Debug SHA-1: `24099334a55568f8583cb0313e06ae32e74714a4`
   - Release SHA-1: `c1d970948a07ab9f278f3bdc4b4ebdc840f57f94`

#### Google Cloud Console

1. **OAuth 2.0 client ID'leri kontrol edin:**
   - Android: `325913484637-fbvot6mbudvs9okvko4dnianv0te85vm.apps.googleusercontent.com`
   - Web: `325913484637-80fha91qrunaiafu8ld2jidennuvovhg.apps.googleusercontent.com`

### 3. Test Adımları

1. **Uygulamayı yeniden build edin:**

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Debug log'larını kontrol edin:**

   - Console'da "🔍 Google Sign-In başlatılıyor..." mesajını görmelisiniz
   - Her adımda ilerleme log'ları görünmelidir

3. **Hata mesajlarını not edin:**
   - Hangi adımda hata alıyorsunuz?
   - Firebase Auth Exception kodu nedir?

### 4. Yaygın Hatalar ve Çözümleri

#### "operation-not-allowed"

- **Çözüm:** Firebase Console'da Google Sign-In'i etkinleştirin

#### "invalid-credential"

- **Çözüm:** SHA-1 sertifika parmak izini kontrol edin

#### "account-exists-with-different-credential"

- **Çözüm:** Aynı e-posta ile farklı yöntemle kayıt varsa, kullanıcıyı bilgilendirin

#### "network-request-failed"

- **Çözüm:** İnternet bağlantısını kontrol edin

### 5. Ek Kontroller

1. **Package name uyumluluğu:**

   - `build.gradle.kts`: `com.zgr.doktorumOnline`
   - `google-services.json`: `com.zgr.doktorumOnline` ✅

2. **Google Play Services:**

   - Test cihazında Google Play Services güncel olmalı

3. **Emulator vs Physical Device:**
   - Physical device'da test edin (emulator'da sorun olabilir)

### 6. Debug Komutları

```bash
# SHA-1 sertifika parmak izini almak için:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release için:
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

## Hala Sorun Yaşıyorsanız

1. **Tam hata mesajını paylaşın**
2. **Debug log'larını kontrol edin**
3. **Firebase Console'da Authentication > Users bölümünü kontrol edin**
4. **Google Cloud Console'da OAuth consent screen'i kontrol edin**

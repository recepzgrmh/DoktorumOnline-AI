# DoktorumOnline AI

**DoktorumOnline AI** – Flutter ile geliştirilmiş, Firestore + Firebase Auth altyapısını kullanan mobil bir sağlık asistanı uygulamasıdır.

---

## 📦 Uygulama Paketi (APK)

[En son APK’yı indir](https://github.com/recepzgrmh/DoktorumOnline-AI/releases/tag/v0.0.1-beta)

---

## 📋 Uygulamanın Amacı ve Özellikleri

- **Semptom Girişi:**  
  Boy, Cinsiyet, Yaş, Kilo, Kan Grubu, Şikayet, Şikayet Süresi, Mevcut İlaçlar ve Kronik Rahatsızlıklar adım adım girerek hızlıca sağlık verilerinizi paylaşırsınız.  
  _Burada kullanıcıdan boy, yaş, kilo ve şikayet kısımlarını zorunlu olarak doldurması isteniliyor._
- **Yapay Zeka Sohbeti:**  
  AI yönlendirmeli sorularla (adım adım form doldurma yerine doğal sohbet akışı) semptomlarınızı derinlemesine toplar. Hastalığınız (Şikayetiniz) ile ilgili detaylı sorular sorar.
- **Anında Analiz:**  
  Girdiğiniz bilgiler doğrultusunda yapay zeka tarafından oluşturulmuş kişiye özel sağlık önerilerini ve detaylı analiz raporunu görürsünüz.
- **Geçmiş Şikayetler:**  
  Tek bir dokunuşla önceki şikayet ve analiz geçmişinize ulaşarak önceki değerlendirmeleri tekrar inceleyebilirsiniz.

![Uygulamaya Ait Ekranlar](Frame_5.png)

---

## 🏗️ Teknoloji ve Mimarisi

1. **Flutter**  
   Tüm ekranları tek bir kod tabanında, hem iOS hem Android için responsive olarak yazdım.
2. **Firebase Authentication**  
   E-posta / şifre ve Google oturum açma destekli kimlik doğrulama; kullanıcı verilerini güvenle saklıyor.
3. **Cloud Firestore**
   - Kullanıcı profili ve şikayet kayıtları, NoSQL doküman yapısında tutuluyor.
   - `StreamBuilder` widget’ı ile “canlı” veri akışı sağlanıyor: yeni kayıt eklenir eklenmez UI güncelleniyor.
   - Yapay zeka sohbet ekranında da mesaj atılır atılmaz hem UI hem de Firestore veritabanı eş zamanlı güncelleniyor.

---

## 🗂️ Firestore Veri Modeli (Güncel)

```mermaid
classDiagram
    %% ------- Users koleksiyonu -------
    class User {
        +string displayName
        +string email
        +timestamp verifiedAt
        --
        +string activeProfileId
        --
        %% Legacy alanlar %%
        +number boy
        +number yas
        +number kilo
        +string cinsiyet
        +string kan_grubu
        +string kronik_rahatsizlik
    }

    %% ------- Gömülü profiles dizisi -------
    class Profile {
        +string id
        +string name
        +number height
        +number age
        +number weight
        +string gender
        +string bloodType
        +string chronicIllness
        +bool   isActive
        +timestamp createdAt
        +timestamp updatedAt
    }

    %% ------- Alt koleksiyonlar -------
    class Complaint {
        +string sikayet
        +string sure
        +string ilac
        +timestamp createdAt
        +timestamp lastAnalyzed
    }

    class Message {
        +string text
        +string senderId
        +timestamp sentAt
    }

    class Analysis {
        +string fileName
        +map    analysis
        +timestamp createdAt
    }

    %% ------- İlişkiler -------
    User "1" --o "array" Profile : profiles
    User "1" --o "0..n"  Complaint : complaints
    User "1" --o "0..n"  Analysis  : analyses
    Complaint "1" --o "0..n" Message : messages
```

---

## 🔁 Uygulama Akış Diyagramı

```mermaid
flowchart TD
  subgraph LAUNCH_&_AUTH["1  Launch & Authentication"]
    A["Uygulama Çalışır<br/>(main.dart)"] --> B{Auth Durumu?}
    B -->|Loading| C["Loading…"]
    B -->|Error| D["Opening Screen"]
    B -->|Kullanıcı Yok| D
    B -->|Giriş Var| E{Mail Doğrulandı mı?}
    E -->|Evet| F["ProfilesScreen"]
    E -->|Hayır| G["VerifyAccount"]
  end

  D --> H{Opening Seçimi}
  H --> I["Sign In"]
  H --> J["Sign Up"]

  subgraph SIGN_IN_FLOW["2  Sign-In Flow"]
    I --> K["Firebase signIn()"]
    K -->|Success| B
    I --> L["ResetPassword"]
  end

  subgraph SIGN_UP_FLOW["3  Sign-Up Flow"]
    J --> M["Kullanıcı Oluştur"]
    M --> N["sendEmailVerification()"]
    N --> G
  end

  subgraph VERIFY_FLOW["4  Verify Flow"]
    G -->|Mail Onaylandı| F
  end

  subgraph DRAWER["5  Drawer Navigation"]
    F --> O["Drawer Menu"]
    O --> P["HomeScreen (Şikayet)"]
    O --> Q["OldChatScreen"]
    O --> R["PdfAnalysisScreen"]
    O --> S["ProfilesScreen"]
    O --> T["Sign Out"]
    T --> D
  end

  subgraph COMPLAINT["6  Complaint Flow"]
    P --> U{Profil Var mı?}
    U -->|Evet| V["Mini Complaint Form"]
    U -->|Hayır| W["Full Complaint Form"]
    V --> X["Validate + Save"]
    W --> X
    X --> Y["AI Soruları Oluştur"]
    Y --> Z["OverviewScreen"]
  end

  subgraph QNA["7  AI Q&A Loop"]
    Z --> AA["AI follow-up"]
    AA --> BB["Kullanıcı Cevabı"]
    BB --> AA
    AA --> CC["Son Analiz"]
  end

  subgraph HISTORY["8  Analysis History"]
    Q --> DD["Şikayet Kartları"]
    DD --> EE["ChatHistoryDetail"]
  end

  subgraph PDF["9  PDF Analysis"]
    R --> FF["PDF Seç"]
    FF --> GG["Text Çıkar"]
    GG --> HH["Chunk + AI Analizi"]
    HH --> II["Kaydet + Sonucu Göster"]
  end
```

---

## 🎓 Öğrenme Süreci ve Karşılaşılan Zorluklar

- **Asenkron Veri Akışı:**  
  Firestore’dan `snapshots` alıp widget’lara aktarmakta zorlandım; StackOverflow ve resmi dokümantasyon örnekleriyle `StreamBuilder` widget’ını kullanmayı biraz öğrendim.
- **Firestore Veritabanı Düzenlemeleri:**  
  AI sohbet mesajlarını eski şikayetler kısmında göstermek için veritabanı yapısını baştan düzenledim.
- **Yapay Zeka Entegrasyonu:**  
  Chat akışındaki doğal dil sorularını dinamik olarak hazırlamak için OpenAI API’si kullandım; örnek prompt’ları ChatGPT’den oluşturarak hızla test ettim.
- **Yeni Paket Kullanımı:**  
  Dash Chat 2 paketini entegre ederek sohbet ekranı geliştirmesini hızlandırdım; “Amerika’yı yeniden keşfetmeme gerek kalmadı” 😊

---

## 📚 Yardım Alınan Kaynaklar

- **StackOverflow:** Firestore query sorunları, `StreamBuilder` pattern’leri, widget prop kullanımları
- **YouTube:** Firebase Auth, Firestore veri ekleme, `StreamBuilder` ve Dash Chat 2 kılavuzları
- **Yapay Zeka Araçları:** ChatGPT prompt optimizasyonu, örnek diyalog akışları, UI tasarım desteği
- **Resmi Dokümantasyon:** Flutter & Firebase eklentileri, Firebase Console ayarları, OpenAI servisleri

---

## 🎯 Sonuç

Bu proje ile birlikte Flutter’da daha fazla deneyim kazandım ve ilk kez kullandığım widget’lar hakkında bilgi sahibi oldum. Kullanıcı ve Yapay Zeka arasında gerçek zamanlı etkileşimi nasıl kuracağımı öğrendim. Ayrıca Firebase, Firestore ve OpenAI API’si ile çalışarak bu teknolojileri gelecek projelerde nasıl kullanacağımı pekiştirmiş oldum.

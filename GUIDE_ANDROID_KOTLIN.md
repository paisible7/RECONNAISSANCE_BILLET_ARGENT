# Guide de Migration : Application Android Native (Kotlin + Jetpack Compose)

Ce guide détaille les étapes pour créer une nouvelle application Android et y intégrer le code Kotlin généré pour **Ni nghapi**.

## 1. Création du Projet Android

1.  Ouvrez **Android Studio**.
2.  Cliquez sur **New Project**.
3.  Sélectionnez **Empty Activity** (avec l'icône Jetpack Compose).
4.  Configurez le projet :
    *   **Name** : `Ni nghapi`
    *   **Package name** : `com.ningapi`
    *   **Save location** : Choisissez votre dossier.
    *   **Language** : `Kotlin`
    *   **Minimum SDK** : `API 26` (Android 8.0) ou supérieur.
    *   **Build Configuration Language** : `Kotlin DSL (build.gradle.kts)` est recommandé.
5.  Cliquez sur **Finish**.

## 2. Configuration des Dépendances (`build.gradle.kts`)

Ouvrez le fichier `app/build.gradle.kts` et ajoutez les dépendances suivantes dans le bloc `dependencies`.

Ceci est nécessaire pour la navigation, TensorFlow Lite (reconnaissance de billets), ML Kit (détection de visages) et les icônes étendues.

```kotlin
dependencies {
    // ... dépendances existantes (core-ktx, lifecycle, etc.)

    // Jetpack Compose BOM (Bill of Materials) - Gardez la version existante
    // implementation(platform("androidx.compose:compose-bom:2023.08.00")) // Exemple

    // Navigation Compose
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Icons Extended (pour Icons.Default.CameraAlt, etc.)
    implementation("androidx.compose.material:material-icons-extended:1.6.3")

    // TensorFlow Lite (Reconnaissance de billets)
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
    implementation("org.tensorflow:tensorflow-lite-metadata:0.4.4")

    // Google ML Kit (Détection de visage)
    implementation("com.google.mlkit:face-detection:16.1.6")

    // Coroutines (si pas déjà présent)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Pour l'accès aux fichiers (ex: FileProvider) - souvent inclus, mais à vérifier si besoin spécifique
}
```

Assurez-vous également d'ajouter l'option suivante dans le bloc `android` pour éviter que les fichiers `.tflite` ne soient compressés (ce qui empêcherait leur chargement direct) :

```kotlin
android {
    // ...
    aaptOptions {
        noCompress("tflite")
    }
}
```

Cliquez sur **Sync Now** en haut à droite.

## 3. Configuration du Manifeste (`AndroidManifest.xml`)

Ouvrez `app/src/main/AndroidManifest.xml`. Ajoutez les permissions nécessaires et la configuration du `FileProvider` pour la caméra.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Permissions Caméra -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />

    <application
        ... >
        
        <!-- Activité Principale -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Ningapi">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Configuration FileProvider (pour enregistrer la photo prise) -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

    </application>
</manifest>
```

## 4. Création des ressources

#### 4.1 File Paths (`file_paths.xml`)
Créez le fichier `app/src/main/res/xml/file_paths.xml` (créez le dossier `xml` s'il n'existe pas) :

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-cache-path name="my_images" path="/" />
    <external-path name="external_files" path="." />
</paths>
```

#### 4.2 Modèle TensorFlow Lite
1.  Créez le dossier `app/src/main/assets/models`.
2.  Copiez votre fichier `model.tflite` existant (du projet Flutter) dans ce dossier.
    *   Source : `ningapi/assets/models/model.tflite`
    *   Destination : `app/src/main/assets/models/model.tflite`

## 5. Intégration du Code Kotlin

Copiez les dossiers et fichiers générés dans le dossier du source code Java/Kotlin (`app/src/main/java/com/ningapi/`).

Structure finale attendue :

```text
com.ningapi
├── MainActivity.kt          <-- Point d'entrée
├── models
│   └── CurrencyResult.kt    <-- Modèle de données
├── services
│   ├── CurrencyRecognitionService.kt
│   ├── FaceDetectionService.kt
│   └── TtsService.kt
└── ui
    ├── AppNavigation.kt     <-- Configuration de la navigation
    ├── screens
    │   ├── HomeScreen.kt
    │   ├── ResultsScreen.kt
    │   └── ScanningScreen.kt
    └── theme
        └── AppColors.kt     <-- Palette de couleurs
```

### Contenu des fichiers

Utilisez le contenu que j'ai généré dans le dossier `KOTLIN` de votre espace de travail actuel. Voici un rappel de quel fichier va où :

1.  **`MainActivity.kt`** : Remplace le fichier généré par défaut.
2.  **`ui/theme/AppColors.kt`** : Définit les couleurs.
3.  **`models/CurrencyResult.kt`** : La classe de données.
4.  **`services/*.kt`** : Les 3 services (TTS, ML Kit, TFLite).
5.  **`ui/AppNavigation.kt`** : Le `NavHost`.
6.  **`ui/screens/*.kt`** : Les 3 écrans (Home, Scanning, Results).

## 6. Vérifications Finales

1.  **Imports** : Assurez-vous que la première ligne de chaque fichier correspond bien à votre `package name`. Si vous avez gardé `com.ningapi`, tout devrait fonctionner directement.
2.  **Theme** : Dans `MainActivity.kt`, assurez-vous que `NingapiTheme` enveloppe bien l'application. Vous pouvez ajuster le fichier `ui/theme/Theme.kt` généré par Android Studio pour utiliser vos `AppColors` si vous voulez une intégration plus profonde, mais le code fourni force déjà les couleurs.

## 7. Lancer l'application

1.  Connectez votre appareil Android ou lancez un émulateur.
2.  Appuyez sur **Run** (flèche verte).
3.  L'application devrait se lancer, demander la permission caméra, et fonctionner comme la version Flutter.

---

### Note sur les modèles TensorFlow

Le code `CurrencyRecognitionService.kt` suppose que les inputs du modèle sont normalisés entre `[-1, 1]` (MobileNetV2 standard). Si votre modèle utilise une autre normalisation (ex: `[0, 255]`), ajustez la méthode `preprocessImage` dans ce fichier.

De même, la liste des labels est codée en dur dans le service (`private val labels = listOf(...)`). Assurez-vous qu'elle correspond exactement à l'ordre de sortie de votre modèle TFLite.

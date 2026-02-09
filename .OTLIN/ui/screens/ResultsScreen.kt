package com.ningapi.ui.screens

import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircleOutline
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Swipe
import androidx.compose.material.icons.filled.TouchApp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import androidx.navigation.NavController
import com.ningapi.models.CurrencyResult
import com.ningapi.services.TtsService
import com.ningapi.ui.theme.AppColors
import kotlinx.coroutines.delay
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun ResultsScreen(
    navController: NavController,
    imageFile: File,
    currencyResult: CurrencyResult
) {
    val context = LocalContext.current
    val ttsService = remember { TtsService.getInstance(context) }
    
    var isProcessing by remember { mutableStateOf(false) }

    // TTS Announcement
    LaunchedEffect(Unit) {
        delay(300)
        ttsService.speak(currencyResult.speakableResult)
        delay(2000)
        ttsService.speak("Appuyez pour repeter. Balayez pour scanner un autre billet.")
    }

    // Camera Logic for "Scan Again"
    var currentPhotoPath by remember { mutableStateOf<String?>(null) }
    
    fun createImageFile(): File? {
        val timeStamp: String = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir: File? = context.externalCacheDir
        return try {
            File.createTempFile("JPEG_${timeStamp}_", ".jpg", storageDir).apply {
                currentPhotoPath = absolutePath
            }
        } catch (ex: IOException) {
            null
        }
    }

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        isProcessing = false
        if (success && currentPhotoPath != null) {
            navController.navigate("scanning/${currentPhotoPath}") {
                popUpTo("results") { inclusive = true }
            }
        } else {
             ttsService.speakAsync("Scan annule. Balayez pour reessayer.")
        }
    }

    fun scanAgain() {
        if (isProcessing) return
        isProcessing = true
        ttsService.speakAsync("Ouverture de la camera")
        
        val photoFile = createImageFile()
        if (photoFile != null) {
             val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                photoFile
            )
            cameraLauncher.launch(uri)
        } else {
            isProcessing = false
            Toast.makeText(context, "Erreur création fichier", Toast.LENGTH_SHORT).show()
        }
    }

    BackHandler {
        navController.popBackStack("home", inclusive = false)
    }

    val resultText = if (currencyResult.isUnknown) "Inconnu" else currencyResult.denomination
    val resultSubtext = if (currencyResult.isUnknown) "Non reconnu" else if (currencyResult.currency == "USD") "Dollars" else "Francs Congolais"
    val color = if (currencyResult.isUnknown) Color(0xFFFF9800) else AppColors.Accent // Orange or Accent

    Scaffold(
        containerColor = AppColors.BackgroundLight
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragEnd = { scanAgain() },
                        onDrag = { _, _ -> } 
                    )
                }
                .pointerInput(Unit) {
                     detectTapGestures(
                         onTap = { ttsService.speakAsync(currencyResult.speakableResult) }
                     )
                }
        ) {
            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                 Spacer(modifier = Modifier.weight(1f))

                // Icon
                Icon(
                    imageVector = if (currencyResult.isUnknown) Icons.Default.HelpOutline else Icons.Default.CheckCircleOutline,
                    contentDescription = null,
                    modifier = Modifier.size(120.dp),
                    tint = color
                )

                Spacer(modifier = Modifier.height(40.dp))

                // Result Text
                Text(
                    text = resultText,
                    style = MaterialTheme.typography.displayLarge.copy(
                        fontWeight = FontWeight.Bold,
                        color = AppColors.TextDark,
                        fontSize = 80.sp
                    ),
                    textAlign = TextAlign.Center,
                    maxLines = 1
                )

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = resultSubtext,
                    style = MaterialTheme.typography.headlineMedium.copy(
                         color = AppColors.Secondary,
                         fontWeight = FontWeight.SemiBold,
                         fontSize = 30.sp
                    ),
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.weight(1f))

                // Bottom Hint
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(AppColors.BackgroundCard)
                        .padding(30.dp)
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                        Icon(Icons.Default.TouchApp, contentDescription = null, modifier = Modifier.size(40.dp), tint = AppColors.TextGray.copy(alpha = 0.5f))
                        Spacer(modifier = Modifier.height(10.dp))
                        Text("Appuyer pour Répéter", style = TextStyle(fontSize = 20.sp, color = AppColors.TextGray))
                        
                        Spacer(modifier = Modifier.height(20.dp))
                        
                        Icon(Icons.Default.Swipe, contentDescription = null, modifier = Modifier.size(40.dp), tint = AppColors.TextGray.copy(alpha = 0.5f))
                        Spacer(modifier = Modifier.height(10.dp))
                        Text("Balayer pour Scanner", style = TextStyle(fontSize = 20.sp, color = AppColors.TextGray))
                    }
                }
            }

            if (isProcessing) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = AppColors.Accent)
                }
            }
        }
    }
}

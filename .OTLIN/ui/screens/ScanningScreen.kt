package com.ningapi.ui.screens

import android.graphics.BitmapFactory
import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.ningapi.services.CurrencyRecognitionService
import com.ningapi.services.FaceDetectionService
import com.ningapi.services.TtsService
import com.ningapi.ui.theme.AppColors
import kotlinx.coroutines.delay
import java.io.File

@Composable
fun ScanningScreen(
    navController: NavController,
    imageFile: File
) {
    val context = LocalContext.current
    val ttsService = remember { TtsService.getInstance(context) }
    
    var isProcessing by remember { mutableStateOf(false) } 
    
    // Animation
    val infiniteTransition = rememberInfiniteTransition(label = "scan")
    val scanLinePosition by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "scanLine"
    )

    LaunchedEffect(imageFile) {
        if (isProcessing) return@LaunchedEffect
        isProcessing = true
        
        ttsService.speakAsync("Analyse en cours")
        
        try {
            // 1. Face Detection
            val hasFace = FaceDetectionService.getInstance().hasFace(context, imageFile)
            
            if (hasFace) {
                delay(500)
                ttsService.speak("Attention. Ceci n'est pas un billet, c'est un visage. Veuillez scanner un billet.")
                delay(2000)
                navController.popBackStack() 
                return@LaunchedEffect
            }
            
            // 2. Currency Recognition
            val result = CurrencyRecognitionService.getInstance(context).recognizeCurrency(imageFile)
            
            delay(500)
            ttsService.stop()
            
            navController.currentBackStackEntry?.savedStateHandle?.set("result", result)
            navController.currentBackStackEntry?.savedStateHandle?.set("imagePath", imageFile.absolutePath)
            
            navController.navigate("results")
            
        } catch (e: Exception) {
            e.printStackTrace()
            ttsService.speak("Erreur lors de l'analyse. Veuillez reessayer.")
            delay(2000)
            navController.popBackStack()
        } finally {
            isProcessing = false
        }
    }

    Scaffold(
        containerColor = AppColors.BackgroundLight
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))

            // Image container
            Box(
                modifier = Modifier
                    .size(width = 320.dp, height = 420.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .border(3.dp, AppColors.Accent, RoundedCornerShape(24.dp))
            ) {
                val bitmap = remember(imageFile) { BitmapFactory.decodeFile(imageFile.absolutePath) }
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                }

                Box(modifier = Modifier.fillMaxSize().background(Color.White.copy(alpha = 0.1f)))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .align(Alignment.TopCenter)
                        .offset(y = (420.dp * scanLinePosition))
                        .background(
                             brush = Brush.horizontalGradient(
                                 colors = listOf(
                                     Color.Transparent,
                                     AppColors.Accent,
                                     AppColors.AccentLight,
                                     AppColors.Accent,
                                     Color.Transparent
                                 )
                             )
                        )
                )
            }
            
            Spacer(modifier = Modifier.height(50.dp))

            Card(
                colors = CardDefaults.cardColors(containerColor = AppColors.BackgroundCard),
                elevation = CardDefaults.cardElevation(defaultElevation = 5.dp),
                shape = RoundedCornerShape(20.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, AppColors.BorderColor)
            ) {
                Column(
                    modifier = Modifier.padding(28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier
                            .size(55.dp)
                            .background(AppColors.Accent, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.Search, contentDescription = null, tint = AppColors.TextLight)
                    }
                    
                    Spacer(modifier = Modifier.height(20.dp))
                    
                    Text(
                        text = "Analyse...",
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Bold,
                            color = AppColors.TextDark
                        )
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Veuillez patienter",
                        style = MaterialTheme.typography.bodyLarge.copy(color = AppColors.TextGray)
                    )
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    LinearProgressIndicator(
                        modifier = Modifier.fillMaxWidth().height(5.dp).clip(RoundedCornerShape(4.dp)),
                        color = AppColors.Accent,
                        trackColor = AppColors.BorderColor
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            TextButton(onClick = { navController.popBackStack() }) {
                Text(
                    text = "Annuler",
                    style = MaterialTheme.typography.bodyLarge.copy(color = AppColors.TextGray)
                )
            }
            
            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}

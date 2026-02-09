package com.ningapi.ui.screens

import android.Manifest
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.core.content.FileProvider
import androidx.navigation.NavController
import com.ningapi.services.TtsService
import com.ningapi.ui.theme.AppColors
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun HomeScreen(
    navController: NavController,
    autoStart: Boolean = false
) {
    val context = LocalContext.current
    val ttsService = remember { TtsService.getInstance(context) }
    
    // Camera Logic
    var currentPhotoPath by remember { mutableStateOf<String?>(null) }
    var photoUri by remember { mutableStateOf<Uri?>(null) }

    fun createImageFile(): File? {
        val timeStamp: String = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir: File? = context.externalCacheDir
        return try {
            File.createTempFile(
                "JPEG_${timeStamp}_", 
                ".jpg", 
                storageDir
            ).apply {
                currentPhotoPath = absolutePath
            }
        } catch (ex: IOException) {
            null
        }
    }

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success && currentPhotoPath != null) {
            // Navigate to scanning screen passing the path
            // Note: need to encode path if it contains special chars, but typically temp path is safe
            navController.navigate("scanning/${currentPhotoPath}")
        } else {
             ttsService.speakAsync("Aucune photo prise.")
        }
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            val photoFile = createImageFile()
            if (photoFile != null) {
                val uri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    photoFile
                )
                photoUri = uri
                ttsService.speakAsync("Ouverture de la camera")
                cameraLauncher.launch(uri)
            } else {
                Toast.makeText(context, "Erreur création fichier", Toast.LENGTH_SHORT).show()
            }
        } else {
            ttsService.speakAsync("Permission camera refusée.")
        }
    }

    fun startScan() {
        permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    LaunchedEffect(Unit) {
        if (autoStart) {
            startScan()
        } else {
            ttsService.speakAsync("Bienvenue sur Ni nghapi. Touchez l'ecran n'importe ou pour scanner un billet.")
        }
    }
    
    // Animation
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Scaffold(
        containerColor = AppColors.BackgroundLight
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .clickable { startScan() }
                .semantics { contentDescription = "Scanner un billet. Appuyez deux fois pour ouvrir la caméra" },
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // Huge Icon with Pulse
                Box(
                    modifier = Modifier
                        .size(200.dp)
                        .scale(scale)
                        .shadow(elevation = 10.dp, shape = CircleShape, spotColor = AppColors.Accent)
                        .background(color = AppColors.Accent, shape = CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.CameraAlt,
                        contentDescription = null,
                        modifier = Modifier.size(100.dp),
                        tint = AppColors.TextLight
                    )
                }

                Spacer(modifier = Modifier.height(60.dp))

                // Huge Text
                Text(
                    text = "APPUYER\nPOUR SCANNER",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.displayMedium.copy(
                        fontWeight = FontWeight.Black,
                        color = AppColors.TextDark,
                        letterSpacing = 2.sp,
                        lineHeight = 50.sp
                    )
                )

                Spacer(modifier = Modifier.height(40.dp))

                // Hint Text
                Text(
                    text = "Touchez n'importe où",
                    style = MaterialTheme.typography.titleLarge.copy(
                        color = AppColors.TextGray,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }
    }
}

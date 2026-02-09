package com.ningapi

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.ningapi.ui.theme.AppColors
import com.ningapi.ui.AppNavigation

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            NingapiTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    AppNavigation()
                }
            }
        }
    }
}

@Composable
fun NingapiTheme(content: @Composable () -> Unit) {
    val colorScheme = lightColorScheme(
        primary = AppColors.Primary,
        onPrimary = AppColors.TextLight,
        background = AppColors.BackgroundLight,
        surface = AppColors.BackgroundLight,
        // Add other colors mapping if needed
    )

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}

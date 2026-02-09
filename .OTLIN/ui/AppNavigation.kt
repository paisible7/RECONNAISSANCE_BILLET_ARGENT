package com.ningapi.ui

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.ningapi.ui.screens.HomeScreen
import com.ningapi.ui.screens.ResultsScreen
import com.ningapi.ui.screens.ScanningScreen
import com.ningapi.models.CurrencyResult
import java.io.File

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(navController = navController)
        }
        
        composable(
            route = "scanning/{imagePath}",
            arguments = listOf(navArgument("imagePath") { type = NavType.StringType })
        ) { backStackEntry ->
            val imagePath = backStackEntry.arguments?.getString("imagePath")
            if (imagePath != null) {
                ScanningScreen(navController = navController, imageFile = File(imagePath))
            }
        }

        composable("results") {
            val result = navController.previousBackStackEntry?.savedStateHandle?.get<CurrencyResult>("result")
            val imagePath = navController.previousBackStackEntry?.savedStateHandle?.get<String>("imagePath")
            
            if (result != null && imagePath != null) {
                 ResultsScreen(
                     navController = navController, 
                     imageFile = File(imagePath),
                     currencyResult = result
                 )
            }
        }
    }
}

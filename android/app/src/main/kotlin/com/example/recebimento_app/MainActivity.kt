package com.example.recebimento_app
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen // Importe isso
import android.os.Bundle // Importe isso
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Isso remove a splash nativa antes de carregar o Flutter
        installSplashScreen() 
        super.onCreate(savedInstanceState)
    }
}
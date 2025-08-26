class UPlayerValues:UScriptGameInstanceSubsystem
{
	// Values player can't change but we can tweak. EG ui animation speed 
    UPROPERTY(BlueprintReadWrite)
    float MainMenuFadeTime = 1.0f;

	// Settings
    UPROPERTY(BlueprintReadWrite)
    float MouseSensitivity = 1.0f;

    UPROPERTY(BlueprintReadWrite)
    float Volume = 1.0f;

	UPROPERTY(BlueprintReadWrite)
	float FOV = 100;

	UPROPERTY(BlueprintReadWrite)
	float MaxFOV = 120;

    UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        LoadSettingsFromFile();
    }

    UFUNCTION()
    void SaveSettingsToFile()
    {
        FString File = f"{FPaths::ConvertRelativePathToFull(FPaths::ProjectDir())}GameSettings.ini";
		FString VolumeString = f"Volume={Volume}\n";
		FString SensitivityString = f"Sensitivity={MouseSensitivity}\n";
		FString FOVString = f"FOV={FOV}\n";
        FString SettingsString = VolumeString + SensitivityString + FOVString;
		FFileHelper::SaveStringToFile(SettingsString, File);
		// FFileHelper::SaveStringToFile(SensitivityString, File, WriteFlags = uint(EFileWrite::Append));
    }

    UFUNCTION(BlueprintCallable)
    void LoadSettingsFromFile()
    {
        FString File = f"{FPaths::ConvertRelativePathToFull(FPaths::ProjectDir())}GameSettings.ini";
        FString StringFromFile;
        if(FFileHelper::LoadFileToString(StringFromFile, File))
        {
            TArray<FString> UnlimitedString;
            TArray<FString> Delimiters;
            Delimiters.Add("=");
            Delimiters.Add("\n");
            StringFromFile.ParseIntoArray(UnlimitedString, Delimiters);
            Volume = String::Conv_StringToDouble(UnlimitedString[1]);
            MouseSensitivity = String::Conv_StringToDouble(UnlimitedString[3]);
			FOV = String::Conv_StringToDouble(UnlimitedString[5]);
			MaxFOV = FOV + 20;
        }
    }
}
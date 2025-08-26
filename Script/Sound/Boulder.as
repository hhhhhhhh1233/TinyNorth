class ABoulder:AActor
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UAudioComponent CrashSound;

	UPROPERTY(DefaultComponent)
	UAudioComponent MoveSound;

	// Can only play sound once
	bool bHasPlayed = false;
	float MaxAudioSpeed = 500;

	default CrashSound.AutoActivate = false;
	default MoveSound.AutoActivate = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"BeginOverlap");
	}

	UFUNCTION()
	void BeginOverlap(AActor OverlappedActor, AActor Other)
	{
		if(!bHasPlayed && Other.ActorHasTag(n"SoundTrigger"))
		{
			bHasPlayed = true;
			CrashSound.Play();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//This makes the sound react if the player changes the volume while the sound is playing
		MoveSound.VolumeMultiplier = (Velocity.Size()/MaxAudioSpeed);
	}
}
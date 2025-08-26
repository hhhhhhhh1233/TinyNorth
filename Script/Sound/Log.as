class ALog:AActor
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UAudioComponent EndSound;
	default EndSound.AutoActivate = false;
	UPROPERTY(DefaultComponent)
	UAudioComponent StartSound;
	default StartSound.AutoActivate = false;
	// Can only play sound once
	bool bHasPlayedStart = false;
	bool bHasPlayedEnd = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"BeginOverlap");
	}

	UFUNCTION()
	void BeginOverlap(AActor OverlappedActor, AActor Other)
	{
		if(!bHasPlayedStart && Other.ActorHasTag(n"StartSoundTrigger"))
		{
			bHasPlayedStart = true;
			StartSound.Play();
		}
		if(!bHasPlayedEnd && Other.ActorHasTag(n"EndSoundTrigger"))
		{
			bHasPlayedEnd = true;
			EndSound.Play();
		}
	}
}
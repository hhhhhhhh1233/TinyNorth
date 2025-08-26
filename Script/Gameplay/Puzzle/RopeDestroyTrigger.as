class ARopeDestroyTrigger:AActor
{
	UPROPERTY(DefaultComponent, RootComponent = true)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;
	
	UPROPERTY(EditAnywhere)
	TArray<ARope> RopesToSleep;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"ActorOverlap");
		
	}
	UFUNCTION()
	void ActorOverlap(AActor Overlapped, AActor Other)
	{
		for(auto Rope:RopesToSleep)
		{
			if(Rope != nullptr)
				Rope.DestroyActor();
		}
	}
}
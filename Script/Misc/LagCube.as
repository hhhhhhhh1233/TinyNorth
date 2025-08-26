class ALagCube : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	default bAsyncPhysicsTickEnabled = true;
	default Mesh.SimulatePhysics = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetLifeSpan(0.1);
	}

	UFUNCTION(BlueprintOverride)
	void AsyncPhysicsTick(float DeltaSeconds, float SimSeconds)
	{
		Mesh.AddForce(FVector::UpVector);
	}
};
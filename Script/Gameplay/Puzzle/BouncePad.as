class ABouncePad:AActor
{
    UPROPERTY(DefaultComponent)
    UGeometryCacheComponent Geometry;
    UPROPERTY(DefaultComponent, Attach = Geometry)
    UStaticMeshComponent CollisionMesh;
    UPROPERTY(DefaultComponent, Attach = Geometry)
    UAudioComponent Audio;
    
    UPROPERTY(EditInstanceOnly)
    bool bFixedExitVelocity = false;
	UPROPERTY(EditInstanceOnly)
    float BounceFactor = 1.2f;
    UPROPERTY(EditInstanceOnly)
    float MaxExitVelocity = 650;
    UPROPERTY(EditInstanceOnly)
    bool bKeepLateralVelocity = false;
	bool bIsOnCoolDown = false;
	const float CoolDown = 0.1f;

    UFUNCTION(BlueprintOverride)
    void Hit(UPrimitiveComponent MyComp, AActor Other, UPrimitiveComponent OtherComp, bool bSelfMoved,
             FVector HitLocation, FVector HitNormal, FVector NormalImpulse, FHitResult Hit)
    {
		if(bIsOnCoolDown)
		{
			return;
		}
        if(Other.IsA(AAlien))
        {
            AAlien Alien = Cast<AAlien>(Other);
			FVector Vel = Alien.CharacterMovement.Velocity; // Where this code is being run, the collision has already been handled. So to get proper velocity for bounce, get the last frame velocity.
            FVector VelLast = Alien.CharacterMovement.GetLastUpdateVelocity();

			FVector VelocityToAdd;
            // Print(f"{VelocityToAdd.Size()}");
            if(bFixedExitVelocity)
			{
            	VelocityToAdd = -HitNormal * MaxExitVelocity * BounceFactor;
			}
			else 
            {
            	VelocityToAdd = -HitNormal * VelLast.Size() * BounceFactor;
                if(VelocityToAdd.Size() > MaxExitVelocity)
				{
					VelocityToAdd = VelocityToAdd * (MaxExitVelocity/VelocityToAdd.Size());
				}
            }
            // Print(f"{VelocityToAdd.Size()}");
            if(bKeepLateralVelocity)
            {
                Alien.CharacterMovement.AddImpulse(VelocityToAdd, true);
				// Print(f"{MyComp.Name}");
            }
            else
            {
                Alien.CharacterMovement.AddImpulse(-Vel /*Counteract the velocity after the collision was handled and then add bounce*/ + VelocityToAdd, true);
                // Alien.CharacterMovement.AddImpulse(-HitNormal * Vel.Size() * Alien.CharacterMovement.Mass);
            }
			bIsOnCoolDown=true;
			System::SetTimer(this, n"ResetCoolDown", CoolDown, false);
			PlayGeometryAnimation();
			Audio.Play();
        }
    }
	UFUNCTION()
	void ResetCoolDown()
	{
		// Print("Reset");
		bIsOnCoolDown=false;
	}
	UFUNCTION(BlueprintEvent)
	void PlayGeometryAnimation(){}
}
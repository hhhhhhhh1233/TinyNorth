class UGrappleComponent : UActorComponent
{
    AAlien Alien;

    bool bAttachedSpeed;
    bool bAttachedRope;
    AActor GrappledObject;
    
    USceneComponent AttachedPoint;
    UMeshComponent AttachedMesh;
	const int MaxOldRopes = 5;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	bool bReadyToShoot = true;

	UPROPERTY()
	float MaxRopeLength = 1200;
	float CurrentRopeLength;

	UPROPERTY()
	float ReelSpeed = 0.7;

    UPROPERTY()
    float SpeedGrapplePower = 1000;

    bool bSpeedGrappleEnabled = false;
    bool bRopeGrappleEnabled = false;
    
	ARope Rope;

	UPROPERTY()
	TSubclassOf<AGrappleHook> HookClass;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem GrappleHitEffect;

    ShootRopeGrappleEvent ShootRopeGrappleEvent;
    ReelInEvent ReelInEvent;
    ReelOutEvent ReelOutEvent;
	DetachRopeEvent DetachRopeEvent;

	
	float DefaultAirControl;
	float DefaultAirControlBoostMultiplier;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AttachedPoint = USceneComponent::Create(Owner);    
		Rope = SpawnActor(ARope);
		Rope.bIsPlayerGrappleRope = true;
		Rope.EndObjectAttachPosition = AttachedPoint;
		// Rope.bDebugDrawSpheres = false;
        Alien = Cast<AAlien>(GetOwner());
        ShootRopeGrappleEvent.AddUFunction(UTutorialManager::Get().ShootRopeGrappleTutorial, FName("Trigger"));
        ReelInEvent.AddUFunction(UTutorialManager::Get().ReelInTutorial, FName("Trigger"));
        ReelOutEvent.AddUFunction(UTutorialManager::Get().ReelOutTutorial, FName("Trigger"));
        DetachRopeEvent.AddUFunction(UTutorialManager::Get().DetachRopeTutorial, FName("Trigger"));
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(bAttachedRope)
        {
            // FVector Direction = (AttachedPoint.WorldLocation - Alien.GetActorLocation());
            // Direction.Normalize();

			// float CurrentDistance = AttachedPoint.WorldLocation.Distance(Alien.ActorLocation);
			// bool bIsTaut = CurrentDistance > CurrentRopeLength;
			// float Overshoot = CurrentDistance - CurrentRopeLength;

			// if (bIsTaut)
			// {
			// 	Alien.CharacterMovement.AddForce(Direction * 300000 * (Overshoot * 0.005));

			// 	if(AttachedMesh != nullptr && AttachedMesh.IsSimulatingPhysics())
			// 	{
			// 		AttachedMesh.AddForceAtLocation(Direction * -300000 * (Overshoot * 0.005), AttachedPoint.WorldLocation);
			// 	}
			// }

			// float Tension = CurrentDistance/Math::Max(CurrentRopeLength, 1);

            // System::DrawDebugSphere(AttachedPoint.WorldLocation, 10.0f);
            // System::DrawDebugLine(Alien.Camera.WorldLocation + Alien.GetActorRightVector() * 20 + FVector(0, 0, -10), AttachedPoint.WorldLocation, FLinearColor(Tension, 1 - Tension, 0, 1));

			// Print(f"Current Rope Length: {CurrentRopeLength:.2f}/{MaxRopeLength}", 0);
        }

        if(bAttachedSpeed)
        {
            FVector Direction = (AttachedPoint.WorldLocation-Alien.GetActorLocation());
            Direction.Normalize();
            FVector Velocity = Alien.Velocity;
            Velocity.Normalize();
            
            // Add more force if the playeaar has velocity away from the grapple point
            float RelativeVelocity = Math::Max(-Velocity.DotProduct(Direction), 0); 
            Print(f"{RelativeVelocity}", 0);
            Alien.CharacterMovement.AddForce(Direction*SpeedGrapplePower + Direction*RelativeVelocity*SpeedGrapplePower*5);
            if(AttachedMesh != nullptr)
            {
                // AttachedMesh.AddForce(Direction*-SpeedGrapplePower);
				AttachedMesh.AddForceAtLocation(FVector::ZeroVector, AttachedPoint.WorldLocation);
            }
            System::DrawDebugSphere(AttachedPoint.WorldLocation, 10.0f);
            System::DrawDebugLine(Alien.Camera.WorldLocation+Alien.GetActorRightVector()*20+FVector(0,0,-10), AttachedPoint.WorldLocation, FLinearColor(0,1,0,1));
        }
    }

	void ResetRope()
	{
		Rope.RemoveLink();
		Rope.ParticleDistance = Rope.DefaultParticleDistance;
		Alien.GrappleHookMesh.SetHiddenInGame(false);
		if (GrappleHook != nullptr)
			GrappleHook.DestroyActor();
		bAttachedRope = false;
		bReadyToShoot = true;
		Rope.ParticleDistance = Rope.DefaultParticleDistance;
		Rope.GravityConstant = Rope.DefaultGravityConstant;
		Rope.AirDragConstant = Rope.DefaultAirDragConstant;
		Rope.FrictionConstant = Rope.DefaultFrictionConstant;
	}


	AGrappleHook GrappleHook = nullptr;

    void ShootRope()
    {
        if(!bRopeGrappleEnabled || !bReadyToShoot || bAttachedRope || Rope.bDetachedReeling)
            return;

		Alien.bRecoiling = true;
		FHitResult Hit;
        TArray<AActor> IgnoreList;
		if (System::LineTraceSingle(Alien.Camera.WorldLocation, Alien.Camera.WorldLocation + Alien.Camera.ForwardVector * MaxRopeLength, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Hit, true))
		{
			FVector Forward = Hit.Location - Alien.RopeAttachPoint.WorldLocation;
			Forward.Normalize();

			GrappleHook = SpawnActor(HookClass, Alien.RopeAttachPoint.WorldLocation, FRotator::MakeFromX(Forward));
		}
		else
		{
			GrappleHook = SpawnActor(HookClass, Alien.RopeAttachPoint.WorldLocation, Alien.Camera.WorldRotation);
		}

		GrappleHook.PlayerAlien = Alien;
		GrappleHook.PlayerGrapple = this;
		Alien.GrappleHookMesh.SetHiddenInGame(true);

		Alien.GrappleGunSound.Sound = Alien.GrappleShootSound;
		Alien.GrappleGunSound.Play();
		Alien.GrappleGunReelFast.Sound = Alien.GrappleReelOutFast;
		Alien.GrappleGunReelFast.Play();
		bReadyToShoot = false;
    }

	void Release()
	{
		if (bAttachedRope)
		{
			Alien.CharacterMovement.AirControl = DefaultAirControl;
			Alien.CharacterMovement.AirControlBoostMultiplier = DefaultAirControlBoostMultiplier;
			if(GrappleHook != nullptr)
			{
				GrappleHook.Release();
			}
		}

		Rope.DetachEndPoint();
		// Rope.CutRope(1);
		bAttachedRope = false;
		GrappledObject = nullptr;
		// Remove link is handled 
		// Rope.RemoveLink();
	}
	void Detach()
	{
		if (!Rope.bIsPlayerGrappleRope || Rope.bDetachedReeling || !bAttachedRope)
			return;
		Rope.CutRope(1);
		Alien.GrappleGunSound.Sound = Alien.GrappleRelease;
		Alien.GrappleGunSound.Play();
		DetachRopeEvent.Broadcast();

		Alien.CharacterMovement.AirControl = DefaultAirControl;
		Alien.CharacterMovement.AirControlBoostMultiplier = DefaultAirControlBoostMultiplier;
		if(GrappleHook != nullptr)
		{
			GrappleHook.Release();
		}
	

		// Rope.DetachEndPoint();
		bAttachedRope = false;
		GrappledObject = nullptr;
		// Remove link is handled 
		// Rope.RemoveLink();
	}

	void Reel()
	{
		CurrentRopeLength -= ReelSpeed * World.GetDeltaSeconds();
		CurrentRopeLength = Math::Max(CurrentRopeLength, 0);
		Rope.Reel(-ReelSpeed);
		ReelInEvent.Broadcast();
	}

	void Slack()
	{
		CurrentRopeLength += ReelSpeed * World.GetDeltaSeconds();
		CurrentRopeLength = Math::Min(CurrentRopeLength, MaxRopeLength);
		Rope.Reel(ReelSpeed);
		ReelOutEvent.Broadcast();
	}
}

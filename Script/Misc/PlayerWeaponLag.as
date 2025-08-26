class UPlayerWeaponLag : UPrimitiveComponent
{
	float DefaultLagSpeed = 0.2;
	float LagSpeed = DefaultLagSpeed;
	float SpedUpLagSpeed = 0.7;

	// FVector LastActorLocation = FVector::ZeroVector;
	FVector LastActorLocation;
	AAlien Alien;

	UPROPERTY()
	float WeaponNearLimit = 12;

	UPROPERTY()
	float RangeLimit = 4;

	// HOW MUCH MOVEMENT CHANGED OVER THE FRAME
	FVector MovementDelta = FVector::ZeroVector;

	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Alien = Cast<AAlien>(Owner);
		LastActorLocation = Alien.ActorLocation;

		// So that the gun mesh can lag behind desired location
		Alien.GrappleGunMesh.bAbsoluteLocation = true;
		Alien.GrappleGunMesh.WorldLocation = Alien.GrappleGunTargetPosition.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// I hate this cause it is such a band-aid fix but for some reason when I set the GrappleGunMesh to be absolutelocation in beginplay instead of as a default
		// it makes the GrappleGunMesh get a WorldLocation at the origin when the player moves or looks around, but only the first time they do that.
		// It's incomprehensible to me but this check for if it's at the origin and then just setting it the player resolves the issue at least.
		// The reason I want to set absolutelocation in begin play instead of a default is so that the gun in the editor moves around with the target so you can see where it will end up
		if (Alien.GrappleGunMesh.WorldLocation == FVector::ZeroVector)
		{
			Alien.GrappleGunMesh.WorldLocation = Alien.GrappleGunTargetPosition.WorldLocation;
		}

		MovementDelta = Owner.ActorLocation - LastActorLocation;
		LastActorLocation = Owner.ActorLocation;

		// UPDATE THE WORLD POSITION OF THE GUN BASED ON HOW THE PLAYER MOVED SINCE LAST FRAME; THEN LERP IT TO THE TARGET
		Alien.GrappleGunMesh.WorldLocation += MovementDelta;
		Alien.GrappleGunMesh.WorldLocation = Math::Lerp(Alien.GrappleGunMesh.WorldLocation, Alien.GrappleGunTargetPosition.WorldLocation, LagSpeed);

		float DistanceToMove = WeaponNearLimit - (Alien.GrappleGunMesh.WorldLocation - Alien.Camera.WorldLocation).ProjectOnTo(Alien.Camera.ForwardVector).Size();
		if (DistanceToMove > 0)
		{
			Alien.GrappleGunMesh.WorldLocation += Alien.Camera.ForwardVector * DistanceToMove;
		}

		if (Alien.GrappleGunMesh.WorldLocation.Distance(Alien.GrappleGunTargetPosition.WorldLocation) > RangeLimit)
		{
			FVector Direction = Alien.GrappleGunMesh.WorldLocation - Alien.GrappleGunTargetPosition.WorldLocation;
			Direction.Normalize();
			Alien.GrappleGunMesh.WorldLocation = Alien.GrappleGunTargetPosition.WorldLocation + Direction * RangeLimit;
		}

		// Update Position of rope attach point based on camera FOV and other info
		FMinimalViewInfo ViewInfo;
		Alien.Camera.GetCameraView(Gameplay::GetWorldDeltaSeconds(), ViewInfo);
		Alien.RopeAttachPoint.WorldLocation = Gameplay::TransformWorldToFirstPerson(ViewInfo, Alien.GrappleGunMuzzlePoint.WorldLocation, true);
	}
}

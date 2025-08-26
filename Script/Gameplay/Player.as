class AAlien : ACharacter
{
	JumpEvent JumpEvent;
	VaultEvent VaultEvent;
	CrouchEvent CrouchEvent;

	UPROPERTY(DefaultComponent)
	UEnhancedInputComponent EnhancedInputComponent;

	UPROPERTY(DefaultComponent)
	UHudInterface HudInterface;
	UPROPERTY(DefaultComponent)
	UGrappleComponent Grapple;

	UPROPERTY()
	UHUDUserWidget HudWidget;

	// Sound

	UPROPERTY(DefaultComponent, Category = "Sound")
	UAudioComponent RopeTensionSound;
	default RopeTensionSound.SetAutoActivate(true);

	UPROPERTY(DefaultComponent, Category = "Sound")
	UAudioComponent GrappleGunSound;
	default GrappleGunSound.SetAutoActivate(false);
	default GrappleGunSound.bCanPlayMultipleInstances=true;
	
	UPROPERTY(DefaultComponent, Category = "Sound")
	UAudioComponent GrappleGunReel;
	default GrappleGunReel.SetAutoActivate(false);
	default GrappleGunReel.bCanPlayMultipleInstances=true;
	
	UPROPERTY(DefaultComponent, Category = "Sound")
	UAudioComponent GrappleGunReelFast;
	default GrappleGunReelFast.SetAutoActivate(false);
	default GrappleGunReelFast.bCanPlayMultipleInstances=true;

	UPROPERTY(DefaultComponent, Category = "Sound")
	UAudioComponent AlienSound;
	default AlienSound.SetAutoActivate(false);
	default AlienSound.bCanPlayMultipleInstances=true;

	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleShootSound;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleHitSuccess;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleHitFail;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue RopeBreak;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleReelInSlow;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleReelInFast;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleReelOutSlow;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleReelOutFast;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue GrappleRelease;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue StepSoundMossWalk;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue StepSoundMossSprint;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue StepSoundMossCrouch;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue HardLandingMoss;
	UPROPERTY(EditAnywhere, Category = "Sound")
	USoundCue JumpSound;
	
	
	UPROPERTY()
	UStaticMesh GrappleRopeMesh;

	UPROPERTY(DefaultComponent)
	UPlayerWeaponLag WeaponLag;

	// Fall damage variables
	bool bFellLastFrame = false;
	bool bFallDamageCameraActive = false;
	FVector LastFallSpeed = FVector::ZeroVector;
	FRotator CurrentFallDamageCameraEffect = FRotator::ZeroRotator;
	FVector CurrentFallDamageCameraOffset = FVector::ZeroVector;
	float FallDamageTime = 0.0f;
	float MinFallDamageSpeed = 300.0f;
	float MaxFallDamageSpeed = 1500.0f;
	float MaxFallDamageTime = 0.8;
	float MinFallDamageTime = 0.4f;
	float MinFallDamageAngle = 1.0f;
	float MaxFallDamageAngle = 10.0f;
	float CurrentFallDamageTime = 0.0f;
	float FallDamageSeverity = 0.0f;
	

	// Vault Variables
	bool bIsVaulting = false;
	UPROPERTY(Category = "Vault")
	float MinObstacleVaultHeight = 40.0f;

	UPROPERTY(Category = "Vault")
	float MaxObstacleVaultHeight = 140.0f;

	UPROPERTY(Category = "Vault")
	const float MinVaultTime = 0.4f;
	
	UPROPERTY(Category = "Vault")
	const float MaxVaultTime = 0.8f;
	
	// When the camera switches from rotating like you are heaving yourself up to moving forwards
	UPROPERTY(EditAnywhere, Category ="Vault")
	float SwitchTime = 0.7f;
	UPROPERTY(EditAnywhere, Category ="Vault")
	float VaultCameraRoll = 4.0f;
	UPROPERTY(EditAnywhere, Category ="Vault")
	float VaultCameraPitch = 6.0f;
	FRotator CurrentVaultCameraEffect = FRotator::ZeroRotator;

	UPROPERTY(Category = "Vault")
	// Radians
	float MaxVaultFloorAngle = 0.5f;

	FVector VaultDirection;

	FVector VaultStartLookDirection;

	UPROPERTY(Category = "Interact")
	float InteractDistance = 150.0f;

	UPROPERTY(DefaultComponent)
	USceneComponent CameraAttachPoint;

	FVector DefaultCameraPos = FVector(0.0f, 0.0f, 15.0f);
	default CameraAttachPoint.RelativeLocation = DefaultCameraPos;

	UPROPERTY(DefaultComponent, Attach = CameraAttachPoint)
	USceneComponent GrappleGunTargetPosition;

	UPROPERTY(DefaultComponent, Attach = GrappleGunTargetPosition)
	UStaticMeshComponent GrappleGunMesh;


	// default GrappleGunMesh.bAbsoluteLocation = true;

	UPROPERTY(DefaultComponent, Attach = GrappleGunMesh)
	UStaticMeshComponent GrappleHookMesh;

	default GrappleGunMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default GrappleGunMesh.SetHiddenInGame(true);
	default GrappleHookMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default GrappleHookMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = CameraAttachPoint)
	UCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = GrappleGunMesh)
	USceneComponent GrappleGunMuzzlePoint;

	UPROPERTY(DefaultComponent)
	USceneComponent RopeAttachPoint;

	// Where to vault to
	FVector VaultPoint;
	FVector VaultStartPoint;
	// Scale on how close to max vault height, and set camera effects and vault time from that.
	float VaultSeverity;
	float CurrentVaultTime = 0;

	UPROPERTY(EditAnywhere)
	float ViewBobProgress = 0.0f;
	UPROPERTY(EditAnywhere)
	float ViewBobFrequency = 1.2f;
	UPROPERTY(EditAnywhere)
	float ViewBobPitch = 0.13f;
	UPROPERTY(EditAnywhere)
	float ViewBobRoll = 0.15f;
	UPROPERTY(EditAnywhere)
	float ViewBobYaw = 0.08f;
	FRotator CurrentViewBobCameraEffect = FRotator::ZeroRotator;

	// Moved these values to the player values subsystem instead
	// UPROPERTY(EditAnywhere)
	// float DefaultFOV = 100;
	// UPROPERTY(EditAnywhere)
	// float MaxFOV = 120;
	float CurrentFOVEffect = 0;

	// Checkpoint and death values
	ACheckpoint CurrentCheckpoint;
	float DeathTime = 2;

	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction MoveAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction LookAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction JumpAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction ShootRopeAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction ShootSpeedGrappleAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction ReleaseAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction ReelAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction SlackAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction CrouchAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction SprintAction;
	UPROPERTY(BlueprintReadOnly, Category=Input, meta=(AllowPrivateAccess = "true"))
	UInputAction InteractAction;

	bool bCanReel = false;

	float CrouchGroundFriction = 20;
	float DefaultGroundFriction;
	UPROPERTY(EditAnywhere)
	float DefaultMass = 2;
	UPROPERTY(EditAnywhere)
	float CrouchMass = DefaultMass*2;
	UPROPERTY(EditAnywhere)
	float GrappleAirControl = 0.10;
	UPROPERTY(EditAnywhere)
	float DefaultAirControl = 0.085;

	float CrouchWalkSpeed = 200;
	float SprintWalkSpeed = 500;
	float DefaultWalkSpeed;
	float TargetWalkSpeed;

	bool bIsDead = false;

	bool bReeling = false;
	bool bSlacking = false;

	// Gun Recoil Values
	bool bRecovering = false;
	bool bRecoiling = false;

	FRotator DefaultGunRotation;
	FRotator GunRecoilRotation;

	float RecoilSpeed = 0.5;
	float RecoverSpeed = 0.2;

	float RecoilAngle = 40;

	bool bCrouching = false;
	bool bWantsToStopCrouching = false;

	// Crouching
	float StandingCapsuleHeight = 88; // This value is fetched from the player blueprint
	float CrouchingCapsuleHeight = 44; // This value is set to just be half of the above value
	float CrouchProgress = 0;
	UPROPERTY(EditAnywhere)
	float CrouchSpeed = 3.8f;

	// Sprinting
	bool bSprinting = false;
	float SprintSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnhancedInputComponent.BindAction(MoveAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"Move"));
		EnhancedInputComponent.BindAction(LookAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"Look"));
		EnhancedInputComponent.BindAction(JumpAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"AlienJump"));
		EnhancedInputComponent.BindAction(ShootRopeAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"ShootRope"));
		EnhancedInputComponent.BindAction(ShootRopeAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"ShootRope"));
		EnhancedInputComponent.BindAction(ReleaseAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"Release"));
		EnhancedInputComponent.BindAction(ReelAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"StartReelInput"));
		EnhancedInputComponent.BindAction(ReelAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"StopReelInput"));
		EnhancedInputComponent.BindAction(SlackAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"StartSlackInput"));
		EnhancedInputComponent.BindAction(SlackAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"StopSlackInput"));
		EnhancedInputComponent.BindAction(InteractAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"Interact"));

		// START AND COMPLETE GET CALLED ONCE
		EnhancedInputComponent.BindAction(CrouchAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"AlienCrouch"));
		EnhancedInputComponent.BindAction(CrouchAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"AlienCrouch"));
		
		EnhancedInputComponent.BindAction(SprintAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"AlienSprint"));
		EnhancedInputComponent.BindAction(SprintAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"AlienSprint"));

		JumpEvent.AddUFunction(UTutorialManager::Get().JumpTutorial, FName("Trigger"));
		VaultEvent.AddUFunction(UTutorialManager::Get().VaultTutorial, FName("Trigger"));
		CrouchEvent.AddUFunction(UTutorialManager::Get().DigInHeelsTutorial, FName("Trigger"));
		CrouchEvent.AddUFunction(UTutorialManager::Get().CrouchTutorial, FName("Trigger"));

		DefaultGroundFriction = CharacterMovement.GroundFriction;
		DefaultWalkSpeed = CharacterMovement.MaxWalkSpeed;

		DefaultGunRotation = GrappleGunMesh.RelativeRotation;
		GunRecoilRotation = GrappleGunMesh.RelativeRotation + FRotator(0, 0, RecoilAngle);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Vaulting
		//----------------------------------------------------------------------------------------------------------------
		if(bIsVaulting)
		{
			VaultUpdate(DeltaSeconds);
		}
		//----------------------------------------------------------------------------------------------------------------
		// Sound volume update
		float Volume = UPlayerValues::Get().Volume;
		if(Grapple.Rope.NodePositions.Num()==0 || Grapple.Rope.bDetachedReeling)
		{
			RopeTensionSound.VolumeMultiplier = 0;
		}
		else
		{
			float Tension = Grapple.Rope.GetTotalTension();
			Tension = (Tension-1)/(Grapple.Rope.TensionLimit-1);
			RopeTensionSound.VolumeMultiplier = Volume * Tension;
			// Print(f"{Volume * Tension}");
		}
		// GrappleGunSound.VolumeMultiplier = Volume;

		//----------------------------------------------------------------------------------------------------------------
		// Camera effects
		ApplyViewBobbingCameraEffect(DeltaSeconds);
		ApplyFallDamageCameraEffect(DeltaSeconds);
		
		// Add upp the camera effects and apply them
		Camera.SetRelativeRotation(CurrentVaultCameraEffect + CurrentViewBobCameraEffect + CurrentFallDamageCameraEffect);
		CameraAttachPoint.SetRelativeLocation(DefaultCameraPos + CurrentFallDamageCameraOffset);
		
		float TargetFOVEffect = Math::Clamp((GetVelocity().Size()/Math::Sqrt(DefaultWalkSpeed**2+CharacterMovement.JumpZVelocity**2))-1, 0, 1);
		if(bSprinting && LastMovementInputVector.Size() != 0)
		{
			TargetFOVEffect = Math::Clamp(TargetFOVEffect + 0.4, 0, 1);
		}
		CurrentFOVEffect = Math::Lerp(CurrentFOVEffect, TargetFOVEffect, 3*DeltaSeconds);
		// CurrentFOVEffect = Math::Lerp(CurrentFOVEffect, Math::Clamp((GetVelocity().Size()/(DefaultWalkSpeed))-1, 0,1), 3*DeltaSeconds);
		Camera.SetFieldOfView(Math::Lerp(UPlayerValues::Get().FOV, UPlayerValues::Get().MaxFOV, CurrentFOVEffect));

		// Gun recoiling section (Probably should be replaced by an animation at some point)
		if (bRecoiling)
		{
			GrappleGunMesh.RelativeRotation = Math::LerpShortestPath(GrappleGunMesh.RelativeRotation, GunRecoilRotation, RecoilSpeed);
			if (GrappleGunMesh.RelativeRotation.AngularDistance(GunRecoilRotation) < 1)
			{
				GrappleGunMesh.RelativeRotation = GunRecoilRotation;
				bRecoiling = false;
				bRecovering = true;
			}
		}

		if (bRecovering)
		{
			GrappleGunMesh.RelativeRotation = Math::LerpShortestPath(GrappleGunMesh.RelativeRotation, DefaultGunRotation, RecoverSpeed);
			if (GrappleGunMesh.RelativeRotation.AngularDistance(DefaultGunRotation) < 1)
			{
				GrappleGunMesh.RelativeRotation = DefaultGunRotation;
				bRecovering = false;
			}
		}

		if(bReeling)
		{
			Reel();
		}
		else if(bSlacking)
		{
			Slack();
		}

		// Print(f"{bReeling=}", 0);
		// Print(f"{bSlacking=}", 0);

		float SmoothCrouchProgress;
		if(CharacterMovement.IsMovingOnGround())
		{
			if(bFellLastFrame)
			{
				if(Math::Abs(LastFallSpeed.Z) > MinFallDamageSpeed)
				{
					FallDamageSeverity = Math::Min((-LastFallSpeed.Z-MinFallDamageSpeed)/(MaxFallDamageSpeed-MinFallDamageSpeed), 1.0f);
					FallDamageTime = Math::Lerp(MinFallDamageTime, MaxFallDamageTime, FallDamageSeverity);
					CurrentFallDamageTime = 0;
					bFallDamageCameraActive = true;
					WeaponLag.LagSpeed = WeaponLag.SpedUpLagSpeed;
					AlienSound.Sound = StepSoundMossWalk;
				}
				else
				{
					AlienSound.Sound = StepSoundMossWalk;
				}
		
				AlienSound.Play();
				// Print(f"{-LastFallSpeed.Z-MinFallDamageSpeed}");
				// Print(f"{MinFallDamageSpeed=}");
				// Print(f"{MaxFallDamageSpeed=}");
				// Print(f"{(-LastFallSpeed.Z-MinFallDamageSpeed)/(MaxFallDamageSpeed-MinFallDamageSpeed)}");

			}
			bFellLastFrame = false;
		}
		else
		{
			LastFallSpeed = CharacterMovement.LastUpdateVelocity;
			bFellLastFrame = true;
			bCrouching = false;
		}

		if (bWantsToStopCrouching)
		{
			TArray<AActor> ToIgnore;
			FHitResult Hit;
			if (!System::CapsuleTraceSingle(CapsuleComponent.WorldLocation + FVector(0, 0, CrouchingCapsuleHeight), CapsuleComponent.WorldLocation + FVector(0, 0, CrouchingCapsuleHeight), CapsuleComponent.CapsuleRadius, StandingCapsuleHeight, ETraceTypeQuery::Visibility, false, ToIgnore, EDrawDebugTrace::None, Hit, true))
			{
				bCrouching = false;
				bWantsToStopCrouching = false;
			}
		}

		if(bCrouching)
		{
			TargetWalkSpeed = CrouchWalkSpeed;
			CrouchProgress = Math::Clamp(CrouchProgress + DeltaSeconds * CrouchSpeed, 0, 1);
			SmoothCrouchProgress = 0.5 + (0.5 * Math::Cos((PI*CrouchProgress)-PI));
		}
		else if(bSprinting)
		{
			TargetWalkSpeed = SprintWalkSpeed;
			CrouchProgress = Math::Clamp(CrouchProgress - DeltaSeconds * CrouchSpeed, 0, 1);
			SmoothCrouchProgress = 0.5 + (0.5 * Math::Cos((PI*CrouchProgress)-PI));
		}
		else
		{
			TargetWalkSpeed = DefaultWalkSpeed;
			CrouchProgress = Math::Clamp(CrouchProgress - DeltaSeconds * CrouchSpeed, 0, 1);
			SmoothCrouchProgress = 0.5 + (0.5 * Math::Cos((PI*CrouchProgress)-PI));
		}

		if(Grapple.bAttachedRope || Grapple.bAttachedSpeed)
		{
			CharacterMovement.AirControl = GrappleAirControl;
		}
		else
		{
			CharacterMovement.AirControl = DefaultAirControl;
		}

		CharacterMovement.Mass = Math::Lerp(DefaultMass, CrouchMass, CrouchProgress);
		// Print(f"{CharacterMovement.MaxWalkSpeed=}");
		CharacterMovement.MaxWalkSpeed = Math::Lerp(CharacterMovement.MaxWalkSpeed, TargetWalkSpeed, 0.1);
		// CapsuleComponent.SetWorldScale3D(FVector(1, 1, Math::Lerp(StandingCapsuleHeight, CrouchingCapsuleHeight, SmoothCrouchProgress)));
		CapsuleComponent.SetCapsuleHalfHeight(Math::Lerp(StandingCapsuleHeight, CrouchingCapsuleHeight, SmoothCrouchProgress));
	}
	
	UFUNCTION()
	void Move(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;

		AddMovementInput(GetActorForwardVector()*FVector(1,1,0), Value.Axis2D.Y);
		AddMovementInput(GetActorRightVector()*FVector(1,1,0), Value.Axis2D.X);
	}
	
	UFUNCTION()
	void Look(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		// AddControllerPitchInput(-Value.Axis2D.Y);
		CameraAttachPoint.SetRelativeRotation(FRotator(Math::Clamp(CameraAttachPoint.GetRelativeRotation().Pitch+(Value.Axis2D.Y*UPlayerValues::Get().MouseSensitivity),-90,90), 0, 0));
		AddControllerYawInput(Value.Axis2D.X*UPlayerValues::Get().MouseSensitivity);
	}

	UFUNCTION()
	void AlienJump(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;

		if(!bIsVaulting && !CheckAndInitiateVault() && !bCrouching && CharacterMovement.IsMovingOnGround())
		{
			TArray<AActor> IgnoreList;
			FHitResult Res;     
			FVector StartPoint = GetActorLocation() + FVector(0, 0, -90);
			FVector EndPoint = GetActorLocation() + FVector(0, 0, -120);
			if(System::LineTraceSingle(StartPoint, EndPoint, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Res, true))
			{
				if(bFellLastFrame && Res.Actor.IsA(ABouncePad))
				{
					return;
				}
			}
			AlienSound.Sound = JumpSound;
			AlienSound.Play();
			Jump();
			JumpEvent.Broadcast();
		}
	}

	// IT MIGHT BE WEIRD THAT THE PLAYER IS RESPONSIBLE FOR THE BCANREEL VARIABLE, MAYBE MOVE THAT INTO GRAPPLE
	UFUNCTION()
	void ShootRope(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;

		if (Value.Axis1D != 0)
		{
			if (!Grapple.bAttachedRope)
				bCanReel = false;
			Grapple.ShootRope();
		}
		else
		{
			bCanReel = true;
		}
	}
	
	UFUNCTION()
	void Release(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;
		
		Grapple.Detach();
	}

	UFUNCTION()
	void StartReelInput(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if(bIsDead || Grapple.Rope.NodePositions.Num() == 0 || Grapple.Rope.bDetachedReeling || bReeling)
			return;

		bReeling = true;
		bSlacking = false;

		GrappleGunReel.Sound = GrappleReelInSlow;
		GrappleGunReel.Play();
	}
	
	UFUNCTION()
	void StopReelInput(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		StopReel();
	}

	void StopReel()
	{
		bReeling = false;
		if(!bSlacking)
		{
			GrappleGunReel.Stop();
		}
	}

	void Reel()
	{
		if (bIsDead)
		{
			StopReel();
			return;
		}
		
		Grapple.Reel();
	}

	UFUNCTION()
	void StartSlackInput(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if(bIsDead || Grapple.Rope.NodePositions.Num() == 0 || Grapple.Rope.bDetachedReeling || bSlacking)
			return;

		bSlacking = true;
		bReeling = false;

		GrappleGunReel.Sound = GrappleReelOutSlow;
		GrappleGunReel.Play();
	}

	UFUNCTION()
	void StopSlackInput(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		StopSlack();
	}

	void StopSlack()
	{
		bSlacking = false;
		if(!bReeling)
		{
			GrappleGunReel.Stop();
		}
	}

	void Slack()
	{
		if (bIsDead)
		{
			StopSlack();
			return;
		}

		Grapple.Slack();
	}

	UFUNCTION()
	void AlienCrouch(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;

		if (Value.Axis1D != 0 && CharacterMovement.IsMovingOnGround())
		{
			bCrouching = true;
			bSprinting = false;
			CrouchEvent.Broadcast();
		}
		else
		{
			bWantsToStopCrouching = true;
		}
	}

	UFUNCTION()
	void AlienSprint(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;

		if (Value.Axis1D != 0 && CharacterMovement.IsMovingOnGround())
		{
			bSprinting = true;
			bCrouching = false;
		}
		else
		{
			bSprinting = false;
		}
	}

	
	bool CheckAndInitiateVault()
    {
		if (bIsDead)
			return false;

		// Check if there is an object in front of the player, then check in the oposite direction of the normal of the
		// hit object. This is so the player vaults up on the object in the direction of th object and not just straight forward
		if(bIsVaulting)
			return false;

		if(GetLastMovementInputVector().DotProduct(GetActorForwardVector())<0.5f)
			return false;

		

        TArray<AActor> IgnoreList;
        FHitResult Res;     
		FVector StartPoint = GetActorLocation() + FVector(0, 0, -90 + MinObstacleVaultHeight);
		FVector EndPoint = GetActorLocation() + GetActorForwardVector()*50 + FVector(0, 0, -90 + MinObstacleVaultHeight);
        if(!System::LineTraceSingle(StartPoint, EndPoint, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Res, true))
		{
			return false;
		}
		VaultDirection = -Res.ImpactNormal;
		VaultDirection.Z = 0.0f;
		VaultDirection.Normalize();
		VaultStartLookDirection = GetActorForwardVector();
		
		// Check if there Is a level place ahead beneath max vault level to vault up to

        // As of now, both actor origin and unchanged eye level is at the height of 90 units.
        // Minimal and maximal obstacle height along with other vault variables need to be easily changed and accessed.
 		StartPoint = GetActorLocation() + VaultDirection*50 + FVector(0, 0, -90 + MaxObstacleVaultHeight);
        EndPoint = GetActorLocation() + VaultDirection*50 + FVector(0, 0, -90 + MinObstacleVaultHeight);
        
        if(System::LineTraceSingle(StartPoint, EndPoint, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Res, true))
        {
            // Radians
            float Angle = Math::Acos(FVector::UpVector.DotProduct(Res.ImpactNormal)/(Res.Normal.Size()));
            
            if(Angle>MaxVaultFloorAngle)
            {
                return false;
            }

			// Capsule check
            {
                TArray<EObjectTypeQuery> ObjectTypes;
                TArray<AActor> IgnoreListCapsule;
                IgnoreListCapsule.Add(this);
                TArray<AActor> OutListCapsule;
                UClass ClassFilter;
                // Check a bit from the ground
                float Padding = 10;
                FVector Point = Res.ImpactPoint+FVector::UpVector*CapsuleComponent.CapsuleHalfHeight + FVector::UpVector*Padding;
                // System::DrawDebugCapsule(Point, CapsuleComponent.CapsuleHalfHeight, CapsuleComponent.CapsuleRadius, GetActorRotation(), FLinearColor::Green, 5);
                if(System::CapsuleOverlapActors(Point, CapsuleComponent.CapsuleRadius, CapsuleComponent.CapsuleHalfHeight, ObjectTypes, ClassFilter, IgnoreListCapsule, OutListCapsule))
                {
					for (auto OverlappedActor : OutListCapsule)
					{
						if (OverlappedActor.IsA(ACheckpoint))
							continue;
						return false;
					}
                }
            }
			
            bIsVaulting = true;
            CurrentVaultTime = 0;
    
            VaultSeverity = 1-(Res.Distance/(MaxObstacleVaultHeight - MinObstacleVaultHeight));
            VaultPoint = Res.ImpactPoint+FVector(0, 0, 90);
            VaultStartPoint = GetActorLocation();
            // Print(f"Vault scale:  {VaultScale}");
            // Print(f"Angle:  {Angle}");
            CharacterMovement.MovementMode=EMovementMode::MOVE_None;
            VaultEvent.Broadcast();
			CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            return true;
        }
        return false;
    }

	void VaultUpdate(float DeltaSeconds)
    {
        CurrentVaultTime += DeltaSeconds;
        float VaultTime = MinVaultTime+(VaultSeverity*(MaxVaultTime-MinVaultTime));
        // Print(f"Vault Time:  {CurrentVaultTime/VaultTime}, {VaultTime}");
        if(CurrentVaultTime >= VaultTime)
        {
			CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
            bIsVaulting=false;
            CharacterMovement.MovementMode=EMovementMode::MOVE_Walking;
			
			// Reset just in case
			CurrentVaultCameraEffect = FRotator(0.0f, 0.0f, 0.0f);
        }

		float StageOneProgress = (CurrentVaultTime/VaultTime)*(1/SwitchTime);
		float StageTwoProgress = (1/(1-SwitchTime))*((CurrentVaultTime/VaultTime)-SwitchTime);

		// Essentially split the vault movement to moving straight up and then moving forwards. Also handle camera effects differently depending on this, tilting the camera down and to the side when moving up, and oposite when you got you legs over the edge.
		if(CurrentVaultTime/VaultTime <= SwitchTime)
		{
        	SetActorLocation(Math::Lerp(VaultStartPoint, VaultStartPoint+((VaultPoint-VaultStartPoint)*FVector(0,0,1)), (0.5 + (0.5 * Math::Cos((PI*StageOneProgress)-PI)))));
			CurrentVaultCameraEffect = FRotator(CurrentVaultCameraEffect.Pitch, CurrentVaultCameraEffect.Yaw, VaultSeverity * -VaultCameraRoll * (0.5 + (0.5 * Math::Cos((PI*StageOneProgress)-PI))));
			// Pitch is handled differently because of the need the let the player keep some control and thus not just set the picth
			CurrentVaultCameraEffect = FRotator(CurrentVaultCameraEffect.Pitch - VaultCameraPitch * VaultSeverity * DeltaSeconds*(1/SwitchTime), CurrentVaultCameraEffect.Yaw, CurrentVaultCameraEffect.Roll);						
		}
		else
		{
        	SetActorLocation(Math::Lerp(VaultStartPoint + ((VaultPoint - VaultStartPoint)*FVector(0,0,1)), VaultStartPoint+((VaultPoint-VaultStartPoint)*FVector(0,0,1))+((VaultPoint-VaultStartPoint)*FVector(1,1,0)), (0.5 + (0.5 * Math::Cos((PI*StageTwoProgress)-PI)))));
			CurrentVaultCameraEffect = FRotator(CurrentVaultCameraEffect.Pitch, CurrentVaultCameraEffect.Yaw, VaultSeverity * -VaultCameraRoll * (1-(0.5 + (0.5 * Math::Cos((PI*StageTwoProgress)-PI)))));
			// Pitch is handled differently because of the need the let the player keep some control and thus not just set the picth
			CurrentVaultCameraEffect = FRotator(CurrentVaultCameraEffect.Pitch + VaultCameraPitch * VaultSeverity * DeltaSeconds*(1/(1-SwitchTime)), CurrentVaultCameraEffect.Yaw, CurrentVaultCameraEffect.Roll);
		}
		
	}
	void PlayStepSound()
	{
		if(bSprinting)
		{
			AlienSound.Sound = StepSoundMossSprint;
		}
		else
		if(bCrouching)
		{
			AlienSound.Sound = StepSoundMossCrouch;
		}
		else
		{
			AlienSound.Sound = StepSoundMossWalk;
		}
		AlienSound.Play();
	}
	void ApplyViewBobbingCameraEffect(float DeltaSeconds)
	{	
		
		if(GetVelocity().Size() != 0 && CharacterMovement.IsMovingOnGround())
		{
			if(ViewBobProgress<0.5f)
			{
				ViewBobProgress += DeltaSeconds*ViewBobFrequency*(GetVelocity().Size()/DefaultWalkSpeed);
				if(ViewBobProgress >= 0.5f)
				{
					PlayStepSound();
				}
			}
			else
			{
				ViewBobProgress += DeltaSeconds*ViewBobFrequency*(GetVelocity().Size()/DefaultWalkSpeed);
				if(ViewBobProgress >= 1.0f)
				{
					ViewBobProgress = 0;
					PlayStepSound();
				}
			}
		}
		else
		{
			ViewBobProgress = Math::Lerp(ViewBobProgress, 0.0f, 0.05);
		}
		
		CurrentViewBobCameraEffect.Pitch = Math::Sin(2 * ViewBobProgress * 2 * PI) * ViewBobPitch;
		CurrentViewBobCameraEffect.Roll = Math::Sin(1 * ViewBobProgress * 2 * PI) * ViewBobRoll;
		CurrentViewBobCameraEffect.Yaw = Math::Sin(1 * ViewBobProgress * 2* PI) * ViewBobYaw;
		// Print(f"{CharacterMovement.MaxWalkSpeed}");
		// Print(f"{ViewBobProgress}")
	}

	void ApplyFallDamageCameraEffect(float DeltaSeconds)
	{	
		if(bFallDamageCameraActive)
		{
			CurrentFallDamageTime += DeltaSeconds;
			if(CurrentFallDamageTime > FallDamageTime)
			{
				bFallDamageCameraActive = false;
				return;
			}
			float Progress = CurrentFallDamageTime/FallDamageTime;
			CurrentFallDamageCameraEffect.Pitch = (-Math::Sin(PI*Progress)) * FallDamageSeverity * Math::Lerp(MinFallDamageAngle, MaxFallDamageAngle, FallDamageSeverity);
			CurrentFallDamageCameraEffect.Roll = (Math::Cos(PI*Progress )** 2-1) * FallDamageSeverity * Math::Lerp(MinFallDamageAngle, MaxFallDamageAngle, FallDamageSeverity) * 0.5f;
			// float CameraOffsetEffect = -(Math::Sin(PI*Progress)**2) * Severity * Math::Lerp(MinFallDamageAngle, MaxFallDamageAngle, Severity);
			CurrentFallDamageCameraOffset = FVector(0, 0, (Math::Cos(PI*Progress * 2)-1) * FallDamageSeverity * Math::Lerp(5, 20, FallDamageSeverity));
			// Print(f"{Severity}");
		}
		else
		{
			CurrentFallDamageCameraEffect = FRotator::ZeroRotator;
			CurrentFallDamageTime = 0;
			WeaponLag.LagSpeed = WeaponLag.DefaultLagSpeed;

		}
	}
	

	UInteractComponent CheckInteract()
	{
		TArray<AActor> IgnoreList;
		FHitResult Res;     
		
		FVector StartPoint = Camera.WorldLocation;
		FVector EndPoint = Camera.WorldLocation+Camera.ForwardVector*InteractDistance;
		
		if(System::LineTraceSingle(StartPoint, EndPoint, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Res, true))
		{
			UInteractComponent InteractComponent = Res.Actor.GetComponent(UInteractComponent);
			if(InteractComponent!=nullptr)
			{
				return InteractComponent;
			}
		}
		return nullptr;
	}

	UFUNCTION()
	void Interact(const FInputActionValue Value, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		if (bIsDead)
			return;

		TArray<AActor> IgnoreList;
		FHitResult Res;     
		
		FVector StartPoint = Camera.WorldLocation;
		FVector EndPoint = Camera.WorldLocation+Camera.ForwardVector*InteractDistance;
		
		if(System::LineTraceSingle(StartPoint, EndPoint, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Res, true))
		{
			UInteractComponent InteractComponent = Res.Actor.GetComponent(UInteractComponent);
			if(InteractComponent!=nullptr)
			{
				InteractComponent.Interact();
				return;
			}
		}
		return;
	}
	UFUNCTION()
	void ActivateGrapple()
	{
		Grapple.bRopeGrappleEnabled = true;
		GrappleGunMesh.SetHiddenInGame(false);
		GrappleHookMesh.SetHiddenInGame(false);
	}

	void Kill()
	{
		bIsDead = true;
		PlayDeathHudEffect(DeathTime);
		System::SetTimer(this, n"Respawn", DeathTime, false);
	}

	UFUNCTION()
	void Respawn()
	{
		if (CurrentCheckpoint != nullptr)
		{
			SetActorLocation(CurrentCheckpoint.PlayerRespawnPosition.WorldLocation);
			Controller.SetControlRotation(CurrentCheckpoint.PlayerRespawnPosition.WorldRotation);
			CurrentCheckpoint.Reset.ResetPuzzles();
		}
		else
		{
			AActor PlayerStart = Gameplay::GameMode.K2_FindPlayerStart(Controller);
			SetActorLocation(PlayerStart.ActorLocation);
			Controller.SetControlRotation(PlayerStart.ActorRotation);
		}
		CameraAttachPoint.WorldRotation = FRotator(0, CameraAttachPoint.WorldRotation.Yaw, CameraAttachPoint.WorldRotation.Roll);
		CharacterMovement.StopMovementImmediately();
		bIsDead = false;
		bSprinting = false;
		bCrouching = false;
		if(Grapple.bRopeGrappleEnabled)
		{
			Grapple.ResetRope();
		}
	}

	UFUNCTION(BlueprintEvent)
	void PlayDeathHudEffect(float FadeTime) {}
}
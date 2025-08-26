class UTutorial
{
    FString Tip;
    // Is set to active when it is first in the list
    bool bActive = false;
    // Set to true when complete,
    bool bFinished = false;

    UFUNCTION()
    void Trigger()
    {
        // Override this function to set bFinished at the appropriate time, for example increment and check a value if the player needs to do something more than once.
    }

    UFUNCTION()
    void Activate()
    {
        // Override this function to set all values to starting position so that tutorial can be run again if needed.
        bActive = true;
        bFinished = false;

		Cast<AAlien>(Gameplay::GetPlayerCharacter(0)).HudWidget.NewTutorial();
    }
}

class UJumpTutorial : UTutorial
{
    default Tip = f"Press SPACE to jump";
    
    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UVaultTutorial : UTutorial
{   
    default Tip = f"Press SPACE to vault when close to a ledge";
    
    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UPickupRopeGrappleTutorial : UTutorial
{   
    default Tip = f"Find your grapple gun";

    void Activate() override
    {
        Super::Activate();
        AAlien Alien = Cast<AAlien>(Gameplay::GetPlayerPawn(0));
        if(Alien != nullptr)
        {
            // Has already aquired the grapple gun
            if(Alien.Grapple.bRopeGrappleEnabled)
            {
                bFinished=true;
            }
        }
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UShootRopeGrappleTutorial : UTutorial
{   
    default Tip = f"Shoot the grapple on the boulder";

    void Activate() override
    {
        Super::Activate();
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UReelInTutorial : UTutorial
{   
    default Tip = f"Hold left mouse button to reel the rope in";

    void Activate() override
    {
        Super::Activate();
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UReelOutTutorial : UTutorial
{   
    default Tip = f"Hold right mouse button to reel the rope out";

    void Activate() override
    {
        Super::Activate();
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UDigInHeelsTutorial : UTutorial
{   
    default Tip = f"Hold CTRL to dig in your heels and pull down the boulder";

    void Activate() override
    {
        Super::Activate();
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UCrouchTutorial : UTutorial
{   
    default Tip = f"Hold CTRL to crouch";

    void Activate() override
    {
        Super::Activate();
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UDetachRopeTutorial : UTutorial
{   
    default Tip = f"Press R to detach the rope";

    void Activate() override
    {
        Super::Activate();
    }

    void Trigger() override
    {
        Super::Trigger();
        if(bActive)
        {
            bFinished = true;
        }
    }
}

class UTutorialManager : UScriptWorldSubsystem
{
    TArray<UTutorial> Tutorials;

    // Declare tutorials here
    UJumpTutorial JumpTutorial;
    UVaultTutorial VaultTutorial;
    UPickupRopeGrappleTutorial PickupRopeGrappleTutorial;
    UShootRopeGrappleTutorial ShootRopeGrappleTutorial;
    UDigInHeelsTutorial DigInHeelsTutorial;
	UCrouchTutorial CrouchTutorial;
    UReelInTutorial ReelInTutorial;
    UReelOutTutorial ReelOutTutorial;
	UDetachRopeTutorial DetachRopeTutorial;

	UPROPERTY()
	bool bNewTutorial = false;
	
	UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        // Construct the tutorial object and add it to the list when and where its needed
        JumpTutorial = UJumpTutorial();
		CrouchTutorial = UCrouchTutorial();
        VaultTutorial = UVaultTutorial();
        PickupRopeGrappleTutorial = UPickupRopeGrappleTutorial();
        ShootRopeGrappleTutorial = UShootRopeGrappleTutorial();
        ReelInTutorial = UReelInTutorial();
        ReelOutTutorial = UReelOutTutorial();
        DigInHeelsTutorial = UDigInHeelsTutorial();
		DetachRopeTutorial = UDetachRopeTutorial();

        // System::SetTimer(this, n"AddTutorials", 5, false);
    }

	UFUNCTION()
	void AddVaultTutorial()
	{
        Tutorials.Add(VaultTutorial);
		ActivateFirst();
	}

	UFUNCTION()
	void AddTutorials()
	{

        Tutorials.Add(JumpTutorial);
		Tutorials.Add(CrouchTutorial);
        Tutorials.Add(PickupRopeGrappleTutorial);
        Tutorials.Add(ShootRopeGrappleTutorial);
        Tutorials.Add(DigInHeelsTutorial);
        Tutorials.Add(ReelInTutorial);
        Tutorials.Add(ReelOutTutorial);
        Tutorials.Add(DetachRopeTutorial);

		ActivateFirst();
        // System::SetTimer(this, n"ActivateFirst", 3, false);
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        CheckCompleted();
    }

    bool CheckCompleted()
    {
        if(Tutorials.Num() > 0)
        {
            if(Tutorials[0].bFinished)
            {
                Tutorials.RemoveAt(0);
				// ActivateFirst();
                System::SetTimer(this, n"ActivateFirst", 1.5, false);
				// Cast<AAlien>(Gameplay::GetPlayerCharacter(0)).HudWidget.HideTutorial();
                return true;
            }
        }
        return false;
    }

	UFUNCTION()
    void ActivateFirst()
    {

        if(Tutorials.Num() > 0)
        {
            Tutorials[0].Activate();
        }
    }

	UFUNCTION()
	void ResetNewTutorial()
	{
		bNewTutorial = false;
	}
}


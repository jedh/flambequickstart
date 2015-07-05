package quickstart;

import flambe.Entity;
import flambe.sound.Sound;
import flambe.System;
import flambe.asset.AssetPack;
import flambe.asset.Manifest;
import flambe.display.FillSprite;
import flambe.display.ImageSprite;
import format.abc.Data.IName;

import flambe.display.Font;
import flambe.display.TextSprite;
import flambe.input.PointerEvent;
import flambe.util.SignalConnection;
import haxe.Timer;

class Main
{
    // Constants
	private static inline var GAME_TIME:Int = 10;
	
	// Assets
	private static var assetPack:AssetPack;
	private static var gameFont:Font;	
	
	// Screens
	private static var menuScreen:Entity;
	private static var gameScreen:Entity;
	private static var gameOverScreen:Entity;
	
	// Game Data
	private static var time:Int;
	private static var score:Int;
	private static var planeSignalConnection:SignalConnection;
	
	// Game Screen Content
	private static var levelTimer:Timer;
	private static var planeSprite:ImageSprite;
	private static var scoreText:TextSprite;
	private static var timeText:TextSprite;
	private static var tapSound:Sound;
	
	// Game Over Screen Content
	private static var gameOverScoreText:TextSprite;
	private static var playAgainButtonText:TextSprite;
	
	private static function main ()
    {     	
		// Wind up all platform-specific stuff
        System.init();

        // Load up the compiled pack in the assets directory named "bootstrap"
        var manifest = Manifest.fromAssets("bootstrap");
        var loader = System.loadAssetPack(manifest);
        loader.get(onSuccess);
    }

    private static function onSuccess (pack :AssetPack)
    {		
		assetPack = pack;
		gameFont = new Font(assetPack, "bebasNeue48");
	   
		// Add a basic background that will be present on all screens.
		var gameBG = new FillSprite(0x033E6B, System.stage.width, System.stage.height);
		System.root.addChild(new Entity().add(gameBG));			
	   
		// Create the game screens.
		CreateGameScreen();
		CreateGameOverScreen();
	   
		// Show the first screen.
		ShowGameScreen();
    }
	
	private static function CreateGameScreen():Void
	{
		gameScreen = new Entity();
		
		// Plane stuff.
		var plane = new Entity();
		planeSprite = new ImageSprite(assetPack.getTexture("plane"));
		planeSprite.centerAnchor();
		planeSprite.x._ = System.stage.width * .5;
		planeSprite.y._ = System.stage.height * .5;
		plane.add(planeSprite);
		gameScreen.addChild(plane);
		
		// Game score UI stuff.
		var scoreSection = new Entity();
		var scoreBG = new FillSprite(0xFF9200, System.stage.width, 50);
		scoreSection.add(scoreBG);
		
		scoreText = new TextSprite(gameFont, "Score: 0000");
		scoreText.x._ = 12;
		scoreSection.addChild(new Entity().add(scoreText));
		
		gameScreen.addChild(scoreSection);
		
		// Timer UI stuff.
		var timeSection = new Entity();
		var timeBG = new FillSprite(0x0B61A4, System.stage.width, 50);
		timeBG.y._ = System.stage.height - timeBG.height._;
		timeSection.add(timeBG);
		
		timeText = new TextSprite(gameFont, "Time:");
		timeText.x._ = 12;
		timeSection.addChild(new Entity().add(timeText));
		
		gameScreen.addChild(timeSection);
		
		// Load the tap sound here so we don't have to retrieve it from the asset packs every time.
		tapSound = assetPack.getSound("tap");
	}
	
	private static function CreateGameOverScreen():Void
	{				
		// Create the basic entity that will contain our game over screen elements.
		gameOverScreen = new Entity();
		
		// Create a ui section for displaying the "Game Over" header.
		var headerSection = new Entity();
		var headerBG = new FillSprite(0xFF9200, System.stage.width, 50);
		headerBG.y._ = System.stage.height * .5 - (headerBG.height._ * .5);
		headerSection.add(headerBG);
		
		var gameOverText = new TextSprite(gameFont, "GAME OVER G");
		gameOverText.centerAnchor();
		gameOverText.x._ = System.stage.width * .5;
		gameOverText.y._ += gameOverText.getNaturalHeight() * .5;
		headerSection.addChild(new Entity().add(gameOverText));
		
		gameOverScreen.addChild(headerSection);
		
		// Create a UI section for displaying the game score.
		var scoreSection = new Entity();
		var scoreBG = new FillSprite(0x0B61A4, System.stage.width, 50);
		scoreBG.y._ = System.stage.height * .5 + (scoreBG.height._ * .5);
		scoreSection.add(scoreBG);
		
		gameOverScoreText = new TextSprite(gameFont, "SCORE: 000000");
		gameOverScoreText.align = TextAlign.Center;
		gameOverScoreText.centerAnchor();
		gameOverScoreText.x._ = (System.stage.width * .5) + (gameOverScoreText.getNaturalWidth() * .5);
		gameOverScoreText.y._ += gameOverScoreText.getNaturalHeight() * .5;
		scoreSection.addChild(new Entity().add(gameOverScoreText));
		
		gameOverScreen.addChild(scoreSection);
		
		// Create a text sprite that will be our "PLAY AGAIN" button.
		playAgainButtonText = new TextSprite(gameFont, "PLAY AGAIN");
		playAgainButtonText.centerAnchor();
		playAgainButtonText.x._ = System.stage.width * .5;
		playAgainButtonText.y._ = scoreBG.y._ + (playAgainButtonText.getNaturalHeight() * 2);
		gameOverScreen.addChild(new Entity().add(playAgainButtonText));							
	}
	
	private static function ShowGameScreen():Void
	{
		// Reset game before showing it.
		time = GAME_TIME;
		score = 0;
		
		timeText.text = "Time: " + time;
		scoreText.text = "Score: " + score;
		
		planeSprite.scaleX._ = 1;
		planeSprite.scaleY._ = 1;
		
		// Remove the game over screen and add the game screen.
		// Note that if the game over screen hasn't been added yet, nothing bad will happen.
		System.root.removeChild(gameOverScreen);
		System.root.addChild(gameScreen);
		
		// Create and start the game timer.
		levelTimer = new Timer(1000);
		levelTimer.run = OnTimer;
		
		// Listen for the pointerUp signal on the plane sprite, store a reference to its signal connection so that it can be cleaned up.
		planeSignalConnection = planeSprite.pointerUp.connect(OnClickPlane);
	}
	
	private static function ShowGameOverScreen():Void 
	{
		// Remove the game screen and add the game screen.
		// Note that if the game screen hasn't been added yet, nothing bad will happen.
		System.root.removeChild(gameScreen);
		System.root.addChild(gameOverScreen);
		
		// Set the score text.
		gameOverScoreText.text = "Score: " + score;
		
		// Listen for the pointerUp signal on the play again button using the once function.
		// Adding .once() to the end of the connect function will guarantee it disposes itself after being called once.
		playAgainButtonText.pointerUp.connect(OnPlayAgain).once();
	}
	
	private static function OnTimer():Void 
	{
		// Decrease the time remaining.
		time--;
		// If we have less than 0 seconds remaining.
		if (time < 0) 
		{
			// Stop the level timer and null it out.
			// Note that timers need to nulled out if they're going to be restarted and reused.
			levelTimer.stop();
			levelTimer = null;
			
			// Dispose of the listener attached to the plane sprite.
			planeSignalConnection.dispose();
			
			// Show the game over screen.
			ShowGameOverScreen();
		} 
		// If we still have time remaining.
		else 
		{
			// Set the timer text.
			timeText.text = "Time: " + time;
		}
	}
	
	private static function OnClickPlane(event:PointerEvent):Void 
	{
		// Increment the score, and then set the score text.
		score++;
		scoreText.text = "Score: " + score;
		
		// Slowly scale up the plane sprite by a 100th of the score.
		planeSprite.scaleX.animateBy(score * .01, .25);
		planeSprite.scaleY.animateBy(score * .01, .25);
		
		// Play the tap sound effect.
		tapSound.play();
	}
	
	private static function OnPlayAgain(event:PointerEvent):Void
	{
		// Change back to the game screen.
		ShowGameScreen();
	}
}

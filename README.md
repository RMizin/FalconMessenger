
<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Title.png" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/TitleDesc.png" />
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/DOnAppStore.png" alt="App Store" /></a>
</p> 

<br>
<br>
![teamwork-flip](https://github.com/davidtheclark/gifs/blob/master/teamwork-flip.gif)
		

<p align="center"> 
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/FeaturesTitle.png" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Features1.png" width="288"/>
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Features2.png" width="288" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Features3.png" width="288" />
</p> 

<br>
<br>

<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/UITitle.png" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/IPhoneScreensUI.png" />
<img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/IPadScreensUI.png" />
</p> 

<br>
<br>

<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/SomeFeaturesInAction.png" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/BlackList.png"  width="288"/>
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/TypingIndicator.png" width="288" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Themes.png" width="288" />
</p>
<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Shared.png"  width="288"/>
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/ChatLog.png" width="288" />
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/GroupChats.png" width="288" />
</p>
	
<br>
<br>

<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/HowTouRunTitle.png" />
</p> 

1. Open the FalconMessenger.xcworkspace in Xcode.
2. Change the Bundle Identifier to match your domain.
3. Go to Firebase and create new project.
4. Select "Add Firebase to your iOS app" option, type the bundle Identifier & click continue.
5. Download "GoogleService-Info.plist" file and add to the project. Make sure file name is "GoogleService-Info.plist".
6. Enable reCaptcha:<br>
	6.1. Go to your GoogleService-Info.plist;<br>
	6.2. Find the key “REVERSED_CLIENT_ID” and copy its value;<br>
	6.3. Go to Project/targets/info/URLTypes;<br>
	6.4. Paste the Value to URL schemes field;<br>
	6.5. Select “Editor” in the “Role“ field. <br>
7. Go to Firebase Console, select your project, choose "Authentication" from left menu
8. Select "SIGN-IN METHOD" and enable "Phone" option.
9. Add Firebase storage rules: 

		service firebase.storage {
		  match /b/{bucket}/o {
		    match /{allPaths=**} {
		      allow read, write;
		    }
		  }
		}
		
10. Add Firebase Realtime Database Rules:

		{ 
		  "rules": {
		    ".read": "auth != null",
		    ".write": "auth != null",


		     "users": {
			".indexOn": "phoneNumber",
			"$user_id": {
			  // grants write access to the owner of this user account
			  // whose uid must exactly match the key ($user_id)
			  ".write": "$user_id === auth.uid"

			}
		    }
		  }   
		}

Note before next step:<i> if you don't have cocoapods installed on your computer, you have to install it first. You can do it by opening the terminal and running "sudo gem install cocoapods" (without quotation marks), then do the step №8. If you already have cocoapods installed, ignore this note.</i>

11. Open the terminal, navigate to project folder and run "pod update" (without quotation marks).

12. Install Firebase Cloud Functions. 
<b><br> Important Note: Cloud functions a responsible for Sending Group messages and fetching Falcon Users. So it's quite important for you to configure everything poperly.</b>
	<br>Step-by-Step guide is availible here: https://firebase.google.com/docs/functions/
	<br>Video Guide: https://www.youtube.com/watch?v=DYfP-UIKxH0
	
13. Copy and Paste Cloud functions from provided [Index.js](https://github.com/RMizin/FalconMessenger/blob/master/CloudFunctions.js) file to your own Index.js file.
14. Change in your index.js file DatabeseURL: to Yours

		admin.initializeApp ({
		    credential: admin.credential.applicationDefault(),
		    databaseURL: 'https://your-Databse-URL.firebaseio.com'
		});

14. Run "Firebase Delpoy" in the terminal from your cloud Functions Directory to configure Cloud Functions.

15. Configuring Reporting and Blacklisting//todo
16. If you do not have paid Apple Developer Account , you might also see this error: "Your development team, "Name", does not support the Push Notifications capability". 
	<br> To fix this, go to Project->Targets->FalconMessenger->Capabilities and Deselect Push Notifications option
	//todo
	
	
Any unexpected errors? falconmessenger.help@gmail.com

<br>
<br>

<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/CompatibilityTitle.png" />
<img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/Compatibility.png" />
</p> 

<br>
<br>

<p align="center">
 <img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/LicenseTitle.png" />
<a target="_blank" href="https://github.com/RMizin/FalconMessenger/blob/master/LICENSE"><img src="https://github.com/RMizin/Falcon/blob/master/Screenshots/License.png" alt="LICENSE.md" /></a>
</p> 

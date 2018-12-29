
<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Title.png?token=ASVYwnRnfMFJiXEBdpwj0039RvI5x5T5ks5cL0FXwA%3D%3D" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/TitleDesc.png?token=ASVYwjn3bpxTi0bVUorBhkdFmVp8YMUSks5cL0F-wA%3D%3D" />
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/DOnAppStore.png?token=ASVYwm02WeVAXy0c0YBVOQ6vBXJxk2kTks5cL0GtwA%3D%3D" alt="App Store" /></a>
</p> 

<br>
<br>

<p align="center"> 
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/FeaturesTitle.png?token=ASVYwg-PUYSChmbL2cCHccg5Ct6aofSIks5cL0ILwA%3D%3D" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Features1.png?token=ASVYwmy0HRhGQ6EFobEi5nv-JUAI2U0pks5cL0K0wA%3D%3D"  width="288"/>
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Features2.png?token=ASVYwsn1m04j42LDpMZTKSEoaEmzhVZUks5cL0LRwA%3D%3D" width="288" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Features3.png?token=ASVYwsGVVlne2s8SXXOySPmYK6FkApW4ks5cL0LZwA%3D%3D" width="288" />
</p> 

<br>
<br>

<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/UITitle.png?token=ASVYwkoI5uQfblXJp2iaPuXO09Le9Gshks5cL0OQwA%3D%3D" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/IPhoneScreensUI.png?token=ASVYwpdYcvUxoPGR9yVWVyDzGWMZNEm6ks5cL0PYwA%3D%3D" />
<img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/IPadScreensUI.png?token=ASVYwtwgyYkC_N42DM9R6XOOygl8pcSbks5cL0PlwA%3D%3D" />
</p> 

<br>
<br>

<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/SomeFeaturesInAction.png?token=ASVYwmPY0ukxXopVJIEvgWCFoUROIgTWks5cL0WowA%3D%3D" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/BlackList.png?token=ASVYwlHGtzy6hV7Bh2r9sgQ3leVqLhclks5cL0ZFwA%3D%3D"  width="288"/>
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/TypingIndicator.png?token=ASVYwhUHgZStuTpokL72DYsPhHQt9pgnks5cL0Y5wA%3D%3D" width="288" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Themes.png?token=ASVYwiGb3J_i8i18Znru5yPatbRi5PToks5cL0YuwA%3D%3D" width="288" />
</p>
<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Shared.png?token=ASVYwpY_QxlJ3JGiuKwQDuT1TrIBJ52Cks5cL0ZzwA%3D%3D"  width="288"/>
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/ChatLog.png?token=ASVYwk68p2h73zLOH1zi1xtEDx5KilIIks5cL0aGwA%3D%3D" width="288" />
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/GroupChats.png?token=ASVYwpxjnXSsPUK3MwcP9jtGbr44-3hQks5cL0adwA%3D%3D" width="288" />
</p>
	
<br>
<br>

<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/HowTouRunTitle.png?token=ASVYwlzQH1rXZfIGx09f9uGYMSbx8ziFks5cL0SFwA%3D%3D" />
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
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/CompatibilityTitle.png?token=ASVYwhrOwi60a631WfFgfodfY-J0JNyDks5cL0cQwA%3D%3D" />
<img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/Compatibility.png?token=ASVYwhZaj4Qy2pifJ5nc_kxLi6lAI2oiks5cL0cUwA%3D%3D" />
</p> 

<br>
<br>

<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/LicenseTitle.png?token=ASVYwndXHjWYb578DXiMgfuyO4xEQgVKks5cL0cswA%3D%3D" />
<a target="_blank" href="https://github.com/RMizin/FalconMessenger/blob/master/LICENSE"><img src="https://raw.githubusercontent.com/RMizin/Falcon/master/Screenshots/License.png?token=ASVYwmVSy_ogS4wYYhzs5OjIt5btLSh6ks5cL0cqwA%3D%3D" alt="LICENSE.md" /></a>
</p> 


<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/gitTitle.png" />
</p> 

<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://perfectradiousa.files.wordpress.com/2016/09/itunes-app-store-logo.png"  width="350" alt="App Store" /></a>


<br>[] Обновить скрины
<br>[]Cделать маленький хедер вместо большого
<br>[]Cделать список фич в стиле презентации эппл
<br>[]Сделать побольше скринов
<br>[]Может быть сделать гифку

## Features

CLOUD-BASED: You won't lose any of your data when you change your mobile phone or reinstall the app. All you need is to re-authenticate with your phone number.

SYNCED: Your messages sync seamlessly across any number of your devices.

GROUP CHATS: Create group chats, and have fun together with your friends, family or even enemies.

NIGHT MODE: Falcon messenger has a beautiful pure black night mode, which looks especially amazing on iPhone X.

PERSONAL CLOUD STORAGE: You can store text, photos, videos and voice messages in the cloud, by sending them to your personal storage.

SIMPLE AUTHENTICATION PROCESS: No emails and passwords anymore. Authenticate with your phone number and start using Falcon Messenger within a minute.

BIOMETRICS SUPPORT: Keep your conversations away from unwanted eyes by using your Touch ID, Face ID or Passcode to unlock Falcon Messenger.

## User Interface
### Day color theme
<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8LightWelcome.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8LightContacts.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8LightChats.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8LightGroupChat.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8LightSettings.png" width="171"/>
</p>

### Night color theme
<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8DarkWelcome.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8DarkContacts.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8DarkChats.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8DarkGroupChat.png" width="171"/>
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/5.8DarkSettings.png" width="171"/>
</p> 


## How to run the app

Follow these steps:

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

14. Run "Firebase Delpoy" in the terminal from your cloud Functions Directory to configure Cloud Functions.

15. Configuring Reporting and Blacklisting//todo
16. If you do not have paid Apple Developer Account , you might also see this error: "Your development team, "Name", does not support the Push Notifications capability". 
	<br> To fix this, go to Project->Targets->FalconMessenger->Capabilities and Deselect Push Notifications option
	//todo
	
Any unexpected errors? falconmessenger.help@gmail.com

## Compatibility
Falcon Messenger is written in Swift 4.2 and requires iOS 10.0 or later.


## License
This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/RMizin/FalconMessenger/blob/master/LICENSE) file for details

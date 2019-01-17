
<p align="center">
 <img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/gitTitle.png" />
</p> 

<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://perfectradiousa.files.wordpress.com/2016/09/itunes-app-store-logo.png"  width="350" alt="App Store" /></a>

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
Follow these simple steps:

1. Open the Pigeon-project.xcworkspace in Xcode.
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
		    ".read": true,
		    ".write": "auth != null",

		    "users": {
		      ".indexOn": "phoneNumber"
		    }
		  }   
		}

Note before last step:<i> if you don't have cocoapods installed on your computer, you have to install it first. You can do it by opening the terminal and running "sudo gem install cocoapods" (without quotation marks), then do the step №8. If you already have cocoapods installed, ignore this note.</i>

11. Open the terminal, navigate to project folder and run "pod update" (without quotation marks).


## Compatibility
Falcon Messenger is written in Swift 4 and requires iOS 10.0 or later.


## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](https://github.com/RMizin/FalconMessenger/blob/master/LICENSE) file for details

Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license. Copyright and license notices must be preserved. Contributors provide an express grant of patent rights..

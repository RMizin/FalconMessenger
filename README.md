
<p align="center"> 
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/Title.png" alt="App Store"/></a>	
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/TitleDesc.png" alt="App Store"/></a>	
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/DOnAppStore.png" alt="App Store"/></a>
</p> 

<br>
<br>

<p align="center"> 
 <a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/FeaturesTitle.png" alt="App Store"/></a>
</p> 

<b>CLOUD-BASED:</b> You won't lose any of your data when you change your mobile phone or reinstall the app. All you need is to re-authenticate with your phone number.

<b>SYNCED:</b> Your messages sync seamlessly across any number of your devices.

<b>GROUP CHATS:</b> Create group chats, and have fun together with your friends, family or even enemies.

<b>NIGHT MODE:</b> Falcon messenger has a beautiful pure black night mode, which looks especially amazing on iPhone X.

<b>PERSONAL CLOUD STORAGE:</b> You can store text, photos, videos and voice messages in the cloud, by sending them to your personal storage.

<b>SIMPLE AUTHENTICATION PROCESS:</b> No emails and passwords anymore. Authenticate with your phone number and start using Falcon Messenger within a minute.

<b>BIOMETRICS SUPPORT:</b> Keep your conversations away from unwanted eyes by using your Touch ID, Face ID or Passcode to unlock Falcon Messenger.

<br>
<br>

<p align="center"> 
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/SomeFeaturesInAction.png" alt="App Store"/></a>	
<img src="https://github.com/RMizin/FalconMessenger/blob/master/Screenshots/auth.gif" width="288px">
<img src="https://github.com/RMizin/FalconMessenger/blob/master/Screenshots/faceID.gif" width="288px">
<img src="https://github.com/RMizin/FalconMessenger/blob/master/Screenshots/actions.gif" width="288px">
<img src="https://github.com/RMizin/FalconMessenger/blob/master/Screenshots/themes.gif" width="288px">
<img src="https://github.com/RMizin/FalconMessenger/blob/master/Screenshots/send.gif" width="288px">
<img src="https://github.com/RMizin/FalconMessenger/blob/master/Screenshots/typing.gif" width="288px">
</p> 

<br>
<br>

<p align="center">
 <a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/UITitle.png" alt="App Store"/></a>
 <a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/DarkUI.png" alt="App Store"/></a>
 <a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/LightUI.png" alt="App Store"/></a>
</p> 

<br>
<br>

<p align="center">
 <a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/HowTouRunTitle.png" alt="App Store"/></a>
</p> 

<b>Follow these simple steps:</b><br>

<b>1.</b> Open the Pigeon-project.xcworkspace in Xcode.<br>
<b>2.</b> Change the Bundle Identifier to match your domain.<br>
<b>3.</b> Go to Firebase and create new project.<br>
<b>4.</b> Select "Add Firebase to your iOS app" option, type the bundle Identifier & click continue.<br>
<b>5.</b> Download "GoogleService-Info.plist" file and add to the project. Make sure file name is "GoogleService-Info.plist".<br>
<b>6.</b> Enable reCaptcha:<br>
	<pre><b>6.1.</b> Go to your GoogleService-Info.plist;<br>
	<b>6.2.</b> Find the key “REVERSED_CLIENT_ID” and copy its value;<br>
	<b>6.3.</b> Go to Project/targets/info/URLTypes;<br>
	<b>6.4.</b> Paste the Value to URL schemes field;<br>
	<b>6.5.</b> Select “Editor” in the “Role“ field. <br></pre>
<b>7.</b> Go to Firebase Console, select your project, choose "Authentication" from left menu.<br>
<b>8.</b> Select "SIGN-IN METHOD" and enable "Phone" option.<br>
<b>9.</b> Add Firebase storage rules: 

		service firebase.storage {
		  match /b/{bucket}/o {
		    match /{allPaths=**} {
		      allow read, write;
		    }
		  }
		}
		
<b>10.</b> Add Firebase Realtime Database Rules:

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

<b>11.</b> Open the terminal, navigate to project folder and run "pod update" (without quotation marks).

<br>
<br>

<p align="center">
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/CompatibilityTitle.png" alt="App Store"/></a>
<a target="_blank" href="https://itunes.apple.com/app/id1313765714"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/Compatibility.png" alt="App Store"/></a>
</p> 

<br>
<br>

<p align="center">
 <a target="_blank" href="https://github.com/RMizin/FalconMessenger/blob/master/LICENSE"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/LicenseTitle.png" alt="LICENSE.md"/></a>
<a target="_blank" href="https://github.com/RMizin/FalconMessenger/blob/master/LICENSE"><img src="https://raw.githubusercontent.com/RMizin/FalconMessenger/master/Screenshots/License.png" alt="LICENSE.md"/></a>
</p> 

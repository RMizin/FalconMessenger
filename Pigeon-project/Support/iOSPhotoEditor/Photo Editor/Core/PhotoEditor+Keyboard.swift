//
//  PhotoEditor+Keyboard.swift
//  Pods
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import UIKit

extension PhotoEditorViewController {
    
    func keyboardDidShow(notification: NSNotification) {
//      
//        if isTyping {
//          
//          
//          
//        }
    }
  
  
  func keyboardWillShow(notification: NSNotification) {
   // isTyping = false
   // doneButton.isHidden = true
   // hideToolbar(hide: false)
    colorPickerView.isHidden = false
     doneButton.isHidden = false
     hideToolbar(hide: true)
      removeGestures(view: textView)
    
  }
  
    func keyboardWillHide(notification: NSNotification) {
        isTyping = false
        doneButton.isHidden = true
        hideToolbar(hide: false)
        addGestures(view: textView)
      
      
    }
    
    func keyboardWillChangeFrame(_ notification: NSNotification) {
      
        if let userInfo = notification.userInfo {
          let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
          let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
         
          if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
            self.colorPickerViewBottomConstraint?.constant = 0.0
          } else {
            self.colorPickerViewBottomConstraint?.constant = endFrame?.size.height ?? 0.0
          }
          UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: { self.view.layoutIfNeeded() }, completion: nil)

        }
    }

}

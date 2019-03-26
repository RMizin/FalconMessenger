//
//  INSPhotosViewControllerDataSource.swift
//  INSPhotoViewer
//
//  Created by Michal Zaborowski on 28.02.2016.
//  Copyright © 2016 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this library except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation

public struct INSPhotosDataSource {
    private(set) var photos: [INSPhotoViewable] = []
    
    public var numberOfPhotos: Int {
        return photos.count
    }
    
    public func photoAtIndex(_ index: Int) -> INSPhotoViewable? {
        if (index < photos.count && index >= 0) {
            return photos[index];
        }
        return nil
    }
    
    public func indexOfPhoto(_ photo: INSPhotoViewable) -> Int? {
			return photos.firstIndex(where: { $0 === photo})
    }

    public func containsPhoto(_ photo: INSPhotoViewable) -> Bool {
        return indexOfPhoto(photo) != nil
    }
    
    public mutating func deletePhoto(_ photo: INSPhotoViewable){
        if let index = self.indexOfPhoto(photo){
            photos.remove(at: index)
        }
    }
    
    public subscript(index: Int) -> INSPhotoViewable? {
        get {
            return photoAtIndex(index)
        }
    }
}

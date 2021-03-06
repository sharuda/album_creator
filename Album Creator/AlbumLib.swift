//
//  AlbumLib.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/4/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit
import FirebaseStorage
import Firebase
import Kingfisher
import SwiftyJSON

func updateDatabaseWithName(root: String, name: String, databaseRef: DatabaseReference, id: String) {
    //        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
//    var childUpdates = [String : [String : String]]()
    var newDataRef = databaseRef.child("\(root)/\(id)")
    var post = [String: String]()
    
    if root == "pictures" {
        newDataRef = databaseRef.child("\(root)/\(id)/\(name)")
        post = [Constants.PictureFields.name: name,
                Constants.PictureFields.pathToImage: "\(root)/\(id)/\(name)"]
//        childUpdates = ["\(root)/\(id)/\(name)": post]
    } else if root == "albums" {
        post = [Constants.AlbumFields.name: name]
//        childUpdates = ["\(root)/\(id)": post]
    } else if root == "users" {
        post = [Constants.UserFields.name: name,
                Constants.UserFields.id: id]
//        childUpdates = ["\(root)/\(id)": post]
    }
    
    newDataRef.updateChildValues(post)
}

func updateDatabaseWithPost(root: String, post: [String:String], databaseRef: DatabaseReference, id: String) {
    //        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
//    var childUpdates = [String : [String : String]]()
    let newDataRef = databaseRef.child("\(root)/\(id)")
    
    newDataRef.updateChildValues(post)
}

func updateDatabaseUserAndAlbum(userID: String, albumID: String, databaseRef: DatabaseReference) {
    //        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
    // add album to user's list of albums
    var root = Constants.FIRDatabaseRoots.users
//    var childUpdates = [String : Bool]()
    var newDataRef = databaseRef.child("\(root)/\(userID)/albums")
    var childUpdates = [albumID: true]
    newDataRef.updateChildValues(childUpdates)
    
    
    // add user to album's list of users
    root = Constants.FIRDatabaseRoots.albums
    newDataRef = databaseRef.child("\(root)/\(albumID)/users")
    childUpdates = [userID: true]
    newDataRef.updateChildValues(childUpdates)
}


func setCellImageView(cell: UICollectionViewCell, snapshotJSON: JSON, storageRef: StorageReference) {
    
    if let imageCell = cell as? AlbumsCollectionViewCell {
        imageCell.albumImageView.kf.indicatorType = .activity
        let picturePath = snapshotJSON[Constants.AlbumFields.thumbnailURL].string
        if picturePath == nil {
            fatalError(#function)
        }
        let imageRef = storageRef.child(picturePath!)
        imageRef.downloadURL { (URL, error) -> Void in
            
            if let error = error {
                print("\(#function):: error = \(error.localizedDescription)")
            } else {
                print("\(#function):: successfully grabbed url = \(URL?.absoluteString as Optional)")
                imageCell.albumImageView.kf.setImage(with: URL!)
            }
        }
    } else if let imageCell = cell as? PicturesCollectionViewCell {
        imageCell.pictureImageView.kf.indicatorType = .activity
        let picturePath = snapshotJSON[Constants.PictureFields.pathToImage].string
        let imageRef = storageRef.child(picturePath!)
        imageRef.downloadURL { (URL, error) -> Void in
            
            if let error = error {
                print("\(#function):: error = \(error.localizedDescription)")
            } else {
                print("\(#function):: successfully grabbed url = \(URL?.absoluteString as Optional)")
                imageCell.pictureImageView.kf.setImage(with: URL!, placeholder: nil)
            }
        }
    }

}


/// Takes an image URL and returns a UIImage?
func downloadImage(url: String) -> UIImage? {
    
    var downloadedImage: UIImage?
    
    if url.hasPrefix(Constants.FirebaseFields.urlPrefix) {
        let storageRef = Storage.storage().reference()
        // Create a reference to the file you want to download
        let imageRef = storageRef.child(url)
        // Fetch the download URL
        imageRef.downloadURL(completion: { (URL, error) in
            if (error != nil) {
                // Handle any errors
                print("\(#function):: Error downloading: \(error)")
            } else {
                print("\(#function):: downloading firebase storage image")
                
//                downloadedImage = kf_setImageWithURL(URL!, placeholderImage: nil)
//                if let downloadURL = NSURL(string: (URL?.absoluteString)!), data = NSURLSession NSData(contentsOfURL: downloadURL) {
//                    downloadedImage = UIImage.init(data: data)
//                }
            }
        })
    } else if let nonFirebaseURL = URL(string: url), let data = try? Data(contentsOf: nonFirebaseURL) {
        downloadedImage = UIImage.init(data: data)
    }
    
    return downloadedImage
}

func getDownloadURL (pathToImage: String, storageRef: StorageReference) -> URL? {
    
    var downloadURL: URL?
    
    let imageRef = storageRef.child(pathToImage)
    imageRef.downloadURL { (URL, error) -> Void in
        
        if let error = error {
            print("\(#function):: error = \(error.localizedDescription)")
            downloadURL = nil
        } else {
            print("\(#function):: successfully grabbed url = \(URL?.absoluteString)")
            downloadURL = URL
        }
    }
//    while(!urlSet) {
////        print("waiting da heck..")
//        // wait for url to get set
//    }
    return downloadURL
}

func albumAddedToUser(snapshot: DataSnapshot) {
    
}

func albumRemovedFromUser(snapshot: DataSnapshot) {
    print("\(#function):: Album was removed from user - \(snapshot)")
}

func imageType(imgData : Data) -> String
{
    var c = [UInt8](repeating: 0, count: 1)
    (imgData as NSData).getBytes(&c, length: 1)
    
    let ext : String
    
    switch (c[0]) {
    case 0xFF:
        
        ext = "jpg"
        
    case 0x89:
        
        ext = "png"
    case 0x47:
        
        ext = "gif"
    case 0x49, 0x4D :
        ext = "tiff"
    default:
        ext = "" //unknown
    }
    
    return ext
}

func stringUpToChar(origString: String, delimitingChar: Character) -> String {
    let chars = origString.characters
    if let idx = chars.index(of: delimitingChar) {
        return String(chars.prefix(upTo: idx))
    }
    return origString
}


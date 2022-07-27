//
//  PhotosManager.swift
//  SwiftyYTDL
//
//  Created by Danylo Kostyshyn on 25.07.2022.
//

import Foundation
import Photos

struct PhotosManager {
    
    private static let photoAlbumName = "SwiftyYTDL"
    
    private static func requestAuthorization() -> PHAuthorizationStatus {
        var authStatus = PHAuthorizationStatus.notDetermined
        let sem = DispatchSemaphore(value: 0)
        PHPhotoLibrary.requestAuthorization { status in
            authStatus = status
            sem.signal()
        }
        sem.wait()
        return authStatus
    }
    
    private static func fetchAssetCollection() throws -> PHAssetCollection {
        let status = requestAuthorization()
        switch status {
        case .denied, .notDetermined:
            throw "Failed to access Photo library"
        default: break
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", Self.photoAlbumName)

        // Find and return album if exist
        func fetchExistingCollection() -> PHAssetCollection? {
            PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: fetchOptions
            ).firstObject
        }
        
        if let collection = fetchExistingCollection() {
            return collection
        }

        // Create album
        var error: Error?
        let sem = DispatchSemaphore(value: 0)
        PHPhotoLibrary.shared().performChanges({
            _ = PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(withTitle: Self.photoAlbumName)
        }) { _, err in
            defer { sem.signal() }
            error = err
        }
        sem.wait()
        
        if let error = error {
            throw error
        }

        // Re-fetch
        if let collection = fetchExistingCollection() {
            return collection
        }
        
        throw "Failed to create an album"
    }
    
    // MARK: -
    
    static func saveToPhotos(at fileUrl: URL) throws {
        let collection = try fetchAssetCollection()
        
        var error: Error?

        let sem = DispatchSemaphore(value: 0)
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest
                .creationRequestForAssetFromVideo(atFileURL: fileUrl)!
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: collection)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
        }) { _, err in
            defer { sem.signal() }
            error = err
        }
        sem.wait()
        
        if let error = error {
            throw error
        }

        try FileManager.default.removeItem(at: fileUrl)
    }
    
}

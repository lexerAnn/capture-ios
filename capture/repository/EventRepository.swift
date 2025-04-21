//
//  EventRepository.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

class EventRepository {
    private let TAG = "EventRepository"
    
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    private let storage = Storage.storage()
    private let imageRepository: ImageRepository
    
    init(imageRepository: ImageRepository = ImageRepository()) {
        self.imageRepository = imageRepository
    }
    
    /**
     * Create a new event in Firestore with Firebase Storage image storage
     * @param event The event data to save
     * @param backgroundImage UIImage of the background image to upload
     */
    func createEvent(_ event: EventModel, backgroundImage: UIImage?, completion: @escaping (Result<EventModel, Error>) -> Void) {
        // Step 1: Get current user ID
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "EventRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        // Step 2: Create event with user ID
        var newEvent = event
        let eventData = event.toDict()
        
        // Step 3: If we have an image, upload it first
        if let image = backgroundImage {
            imageRepository.uploadEventBackgroundImage(eventId: event.id, image: image) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    // Update event with image URL
                    var updatedEventData = eventData
                    updatedEventData["background_image_url"] = imageUrl
                    updatedEventData["creator_id"] = userId
                    
                    // Now save to Firestore
                    self?.firestore.collection(EventModel.COLLECTION_NAME).document(event.id).setData(updatedEventData) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        // Create updated event model with the image URL and creator ID
                        let updatedEvent = EventModel(
                            id: event.id,
                            eventName: event.eventName,
                            title: event.title,
                            subtitle: event.subtitle,
                            buttonText: event.buttonText,
                            backgroundImageUrl: imageUrl,
                            creatorId: userId,
                            status: event.status,
                            endDate: event.endDate,
                            createdAt: event.createdAt,
                            revealPhotosTiming: event.revealPhotosTiming,
                            photosPerPerson: event.photosPerPerson,
                            maxGuests: event.maxGuests,
                            galleryAccess: event.galleryAccess,
                            participants: event.participants
                        )
                        
                        completion(.success(updatedEvent))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            // No image, just save the event directly
            var updatedEventData = eventData
            updatedEventData["creator_id"] = userId
            
            firestore.collection(EventModel.COLLECTION_NAME).document(event.id).setData(updatedEventData) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Create updated event model with the creator ID
                let updatedEvent = EventModel(
                    id: event.id,
                    eventName: event.eventName,
                    title: event.title,
                    subtitle: event.subtitle,
                    buttonText: event.buttonText,
                    backgroundImageUrl: "",
                    creatorId: userId,
                    status: event.status,
                    endDate: event.endDate,
                    createdAt: event.createdAt,
                    revealPhotosTiming: event.revealPhotosTiming,
                    photosPerPerson: event.photosPerPerson,
                    maxGuests: event.maxGuests,
                    galleryAccess: event.galleryAccess,
                    participants: event.participants
                )
                
                completion(.success(updatedEvent))
            }
        }
    }
    
    /**
     * Update an event's image and return the new image URL
     * @param eventId ID of the event to update
     * @param image UIImage of the new image
     * @return Result containing the new image URL or an error
     */
    func updateEventImage(eventId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        imageRepository.uploadEventBackgroundImage(eventId: eventId, image: image) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                // Update the event with the new image URL
                self?.firestore.collection(EventModel.COLLECTION_NAME).document(eventId).updateData([
                    "background_image_url": imageUrl
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(imageUrl))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Get events hosted by the current user
     */
    func getHostedEvents(completion: @escaping ([EventModel]) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion([])
            return
        }
        
        firestore.collection(EventModel.COLLECTION_NAME)
            .whereField("creator_id", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching hosted events: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let events = documents.compactMap { EventModel.fromDocument($0) }
                completion(events)
            }
    }
    
    /**
     * Get events where the user is a participant
     */
    func getParticipatingEvents(completion: @escaping ([EventModel]) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion([])
            return
        }
        
        firestore.collection(EventModel.COLLECTION_NAME)
            .whereField("participants", arrayContains: userId)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching participating events: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let events = documents.compactMap { EventModel.fromDocument($0) }
                completion(events)
            }
    }
    
    /**
     * Get a single event by ID
     */
    func getEventById(eventId: String, completion: @escaping (Result<EventModel, Error>) -> Void) {
        firestore.collection(EventModel.COLLECTION_NAME).document(eventId).getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = documentSnapshot, 
                  let event = EventModel.fromDocument(document) else {
                let error = NSError(domain: "EventRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
                completion(.failure(error))
                return
            }
            
            completion(.success(event))
        }
    }
    
    /**
     * Update an existing event
     */
    func updateEvent(_ event: EventModel, completion: @escaping (Result<EventModel, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            let error = NSError(domain: "EventRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }
        
        if event.creatorId != userId {
            let error = NSError(domain: "EventRepository", code: 403, userInfo: [NSLocalizedDescriptionKey: "Not authorized to update this event"])
            completion(.failure(error))
            return
        }
        
        firestore.collection(EventModel.COLLECTION_NAME).document(event.id).updateData(event.toDict()) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(event))
        }
    }
    
    /**
     * Add a participant to an event
     */
    func addParticipant(eventId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        firestore.collection(EventModel.COLLECTION_NAME).document(eventId).updateData([
            "participants": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /**
     * End an event (update status to ended)
     */
    func endEvent(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            let error = NSError(domain: "EventRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }
        
        // First get the event to check the creator
        getEventById(eventId: eventId) { [weak self] result in
            switch result {
            case .success(let event):
                if event.creatorId != userId {
                    let error = NSError(domain: "EventRepository", code: 403, userInfo: [NSLocalizedDescriptionKey: "Not authorized to end this event"])
                    completion(.failure(error))
                    return
                }
                
                // Update the event status
                self?.firestore.collection(EventModel.COLLECTION_NAME).document(eventId).updateData([
                    "status": "ended"
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(()))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// Image Repository class for handling image uploads
class ImageRepository {
    private let storage = Storage.storage()
    
    /**
     * Upload an event background image to Firebase Storage
     * @param eventId ID of the event
     * @param image UIImage to upload
     * @return Result containing the image URL or an error
     */
    func uploadEventBackgroundImage(eventId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "ImageRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])
            completion(.failure(error))
            return
        }
        
        let storageRef = storage.reference()
        let eventImagesRef = storageRef.child("event_images")
        let imageRef = eventImagesRef.child("\(eventId)_\(UUID().uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    let error = NSError(domain: "ImageRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
}

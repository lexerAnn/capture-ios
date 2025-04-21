import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

// This repository handles all Firestore operations for events
class EventRepository {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // Create a new event document in Firestore
    func createEvent(_ event: EventModel, backgroundImage: UIImage?, completion: @escaping (Result<EventModel, Error>) -> Void) {
        // First, get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "EventRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Create a mutable copy of event with the current user as creator
        // Since EventModel has immutable properties, we need to create a new instance
        let eventWithCreator = EventModel(
            id: event.id,
            eventName: event.eventName,
            title: event.title,
            subtitle: event.subtitle,
            buttonText: event.buttonText,
            backgroundImageUrl: event.backgroundImageUrl,
            creatorId: userId, // Set current user as creator
            status: event.status,
            endDate: event.endDate,
            createdAt: event.createdAt,
            revealPhotosTiming: event.revealPhotosTiming,
            photosPerPerson: event.photosPerPerson,
            maxGuests: event.maxGuests,
            galleryAccess: event.galleryAccess,
            participants: event.participants
        )
        
        // If there's an image, upload it first, then create the event
        if let image = backgroundImage {
            uploadEventImage(eventId: event.id, image: image) { result in
                switch result {
                case .success(let imageUrl):
                    // Create another copy of the event with the image URL
                    let eventWithImage = EventModel(
                        id: eventWithCreator.id,
                        eventName: eventWithCreator.eventName,
                        title: eventWithCreator.title,
                        subtitle: eventWithCreator.subtitle,
                        buttonText: eventWithCreator.buttonText,
                        backgroundImageUrl: imageUrl,
                        creatorId: eventWithCreator.creatorId,
                        status: eventWithCreator.status,
                        endDate: eventWithCreator.endDate,
                        createdAt: eventWithCreator.createdAt,
                        revealPhotosTiming: eventWithCreator.revealPhotosTiming,
                        photosPerPerson: eventWithCreator.photosPerPerson,
                        maxGuests: eventWithCreator.maxGuests,
                        galleryAccess: eventWithCreator.galleryAccess,
                        participants: eventWithCreator.participants
                    )
                    
                    // Continue with event creation
                    self.saveEventToFirestore(eventWithImage, completion: completion)
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            // No image, just create the event
            saveEventToFirestore(eventWithCreator, completion: completion)
        }
    }
    
    // Helper method to save event to Firestore
    private func saveEventToFirestore(_ event: EventModel, completion: @escaping (Result<EventModel, Error>) -> Void) {
        let eventRef = db.collection(EventModel.COLLECTION_NAME).document(event.id)
        
        eventRef.setData(event.toDict()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(event))
            }
        }
    }
    
    // Upload an image to Firebase Storage
    func uploadEventImage(eventId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "EventRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not process image"])))
            return
        }
        
        let storageRef = storage.reference().child("event_backgrounds/\(eventId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "EventRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown error uploading image"])))
                }
            }
        }
    }
    
    // Update an event's image
    func updateEventImage(eventId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Reuse the upload method
        uploadEventImage(eventId: eventId, image: image, completion: completion)
    }
    
    // Update an existing event
    func updateEvent(_ event: EventModel, completion: @escaping (Result<Void, Error>) -> Void) {
        let eventRef = db.collection(EventModel.COLLECTION_NAME).document(event.id)
        
        eventRef.updateData(event.toDict()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Get all events where the current user is the creator
    func getHostedEvents(completion: @escaping ([EventModel]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection(EventModel.COLLECTION_NAME)
            .whereField("creator_id", isEqualTo: userId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let events = documents.compactMap { EventModel.fromDocument($0) }
                completion(events)
            }
    }
    
    // Get all events where the current user is a participant
    func getParticipatingEvents(completion: @escaping ([EventModel]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection(EventModel.COLLECTION_NAME)
            .whereField("participants", arrayContains: userId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let events = documents.compactMap { EventModel.fromDocument($0) }
                completion(events)
            }
    }
    
    // Get a single event by ID
    func getEvent(eventId: String, completion: @escaping (Result<EventModel, Error>) -> Void) {
        let eventRef = db.collection(EventModel.COLLECTION_NAME).document(eventId)
        
        eventRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists, let event = EventModel.fromDocument(document) else {
                completion(.failure(NSError(domain: "EventRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])))
                return
            }
            
            completion(.success(event))
        }
    }
}

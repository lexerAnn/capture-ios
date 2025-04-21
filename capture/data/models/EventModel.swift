//
//  EventModel.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import Foundation
import FirebaseFirestore

struct EventModel: Identifiable {
    static let COLLECTION_NAME = "events"
    
    let id: String
    let eventName: String
    let title: String
    let subtitle: String
    let buttonText: String
    let backgroundImageUrl: String
    let creatorId: String
    let status: String
    let endDate: Timestamp?
    let createdAt: Timestamp
    let revealPhotosTiming: String
    let photosPerPerson: Int
    let maxGuests: Int
    let galleryAccess: Bool
    let participants: [String]
    
    // Convert to dictionary for Firestore
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "event_name": eventName,
            "title": title,
            "subtitle": subtitle,
            "button_text": buttonText,
            "background_image_url": backgroundImageUrl,
            "creator_id": creatorId,
            "status": status,
            "end_date": endDate as Any,
            "created_at": createdAt,
            "reveal_photos_timing": revealPhotosTiming,
            "photos_per_person": photosPerPerson,
            "max_guests": maxGuests,
            "gallery_access": galleryAccess,
            "participants": participants
        ]
    }
    
    // Create from Firestore document
    static func fromDocument(_ document: DocumentSnapshot) -> EventModel? {
        guard let data = document.data() else { return nil }
        
        return EventModel(
            id: document.documentID,
            eventName: data["event_name"] as? String ?? "",
            title: data["title"] as? String ?? "",
            subtitle: data["subtitle"] as? String ?? "",
            buttonText: data["button_text"] as? String ?? "",
            backgroundImageUrl: data["background_image_url"] as? String ?? "",
            creatorId: data["creator_id"] as? String ?? "",
            status: data["status"] as? String ?? "active",
            endDate: data["end_date"] as? Timestamp,
            createdAt: data["created_at"] as? Timestamp ?? Timestamp(date: Date()),
            revealPhotosTiming: data["reveal_photos_timing"] as? String ?? "Immediately",
            photosPerPerson: data["photos_per_person"] as? Int ?? 10,
            maxGuests: data["max_guests"] as? Int ?? 10,
            galleryAccess: data["gallery_access"] as? Bool ?? true,
            participants: data["participants"] as? [String] ?? []
        )
    }
    
    // Constructor with default values for optional fields
    init(
        id: String,
        eventName: String,
        title: String,
        subtitle: String,
        buttonText: String,
        backgroundImageUrl: String,
        creatorId: String,
        status: String = "active",
        endDate: Timestamp? = nil,
        createdAt: Timestamp = Timestamp(date: Date()),
        revealPhotosTiming: String = "Immediately",
        photosPerPerson: Int = 10,
        maxGuests: Int = 10,
        galleryAccess: Bool = true,
        participants: [String] = []
    ) {
        self.id = id
        self.eventName = eventName
        self.title = title
        self.subtitle = subtitle
        self.buttonText = buttonText
        self.backgroundImageUrl = backgroundImageUrl
        self.creatorId = creatorId
        self.status = status
        self.endDate = endDate
        self.createdAt = createdAt
        self.revealPhotosTiming = revealPhotosTiming
        self.photosPerPerson = photosPerPerson
        self.maxGuests = maxGuests
        self.galleryAccess = galleryAccess
        self.participants = participants
    }
}

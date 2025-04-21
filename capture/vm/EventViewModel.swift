import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class EventViewModel: ObservableObject {
    private let TAG = "EventViewModel"
    private let eventRepository: EventRepository
    
    // Event creation/update state
    @Published var eventCreationState: EventCreationState = .idle
    
    // Loaded event for editing
    @Published var loadedEvent: EventModel?
    
    // Event data
    private var eventName: String = "My Event"
    private var eventTitle: String = "Take a Photo!"
    private var eventSubtitle: String = ""
    private var buttonText: String = "Take Photos"
    private var backgroundImage: UIImage? = nil
    private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    private var revealPhotosTiming: String = "Immediately"
    private var photosPerPerson: Int = 10
    private var maxGuests: Int = 10
    private var galleryAccess: Bool = true
    
    // Keep background image URL when editing
    private var existingBackgroundImageUrl: String = ""
    
    // Published collections for hosted and participating events
    @Published var hostedEvents: [EventModel] = []
    @Published var participatingEvents: [EventModel] = []
    
    init(eventRepository: EventRepository = EventRepository()) {
        self.eventRepository = eventRepository
        loadEvents()
    }
    
    // Load events from repository
    func loadEvents() {
        print("Loading events from repository")
        eventRepository.getHostedEvents { [weak self] events in
            DispatchQueue.main.async {
                self?.hostedEvents = events
                print("Loaded \(events.count) hosted events")
            }
        }
        
        eventRepository.getParticipatingEvents { [weak self] events in
            DispatchQueue.main.async {
                self?.participatingEvents = events
                print("Loaded \(events.count) participating events")
            }
        }
    }
    
    /**
     * Populate the ViewModel with data from an existing EventModel
     * Used when receiving an event directly
     */
    func populateFromEvent(event: EventModel) {
        // Store event in Published property
        loadedEvent = event
        
        // Update all view model fields
        eventName = event.eventName
        eventTitle = event.title
        eventSubtitle = event.subtitle
        buttonText = event.buttonText
        existingBackgroundImageUrl = event.backgroundImageUrl
        
        // Update end date if available
        if let timestamp = event.endDate {
            endDate = timestamp.dateValue()
        }
        
        revealPhotosTiming = event.revealPhotosTiming
        photosPerPerson = event.photosPerPerson
        maxGuests = event.maxGuests
        galleryAccess = event.galleryAccess
        
        eventCreationState = .idle
    }
    
    // Load an existing event by ID
    func loadEvent(event: EventModel) {
        populateFromEvent(event: event)
    }
    
    // Create a new event
    func createEvent() {
        eventCreationState = .loading
        
        // Create event model
        let event = EventModel(
            id: UUID().uuidString,
            eventName: eventName,
            title: eventTitle,
            subtitle: eventSubtitle,
            buttonText: buttonText,
            backgroundImageUrl: "",
            creatorId: "",
            status: "active",
            endDate: Timestamp(date: endDate),
            createdAt: Timestamp(date: Date()),
            revealPhotosTiming: revealPhotosTiming,
            photosPerPerson: photosPerPerson,
            maxGuests: maxGuests,
            galleryAccess: galleryAccess,
            participants: []
        )
        
        eventRepository.createEvent(event, backgroundImage: backgroundImage) { [weak self] result in
            switch result {
            case .success(let createdEvent):
                DispatchQueue.main.async {
                    self?.eventCreationState = .success
                    self?.loadEvents()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.eventCreationState = .error(message: error.localizedDescription)
                }
            }
        }
    }
    
    // Update an existing event
    func updateEvent(eventId: String) {
        print("updateEvent called with ID: \(eventId)")
        eventCreationState = .loading
        
        guard let currentEvent = loadedEvent else {
            eventCreationState = .error(message: "Event not found")
            return
        }
        
        // Set initial background image URL from existing event
        var updatedBackgroundImageUrl = existingBackgroundImageUrl
        
        // If there's a new image, upload it first
        if let newImage = backgroundImage {
            print("Uploading new image for event")
            eventRepository.updateEventImage(eventId: eventId, image: newImage) { [weak self] result in
                switch result {
                case .success(let newImageUrl):
                    print("Image uploaded successfully: \(newImageUrl)")
                    updatedBackgroundImageUrl = newImageUrl
                    self?.continueEventUpdate(
                        currentEvent: currentEvent,
                        eventId: eventId,
                        updatedBackgroundImageUrl: updatedBackgroundImageUrl
                    )
                case .failure(let error):
                    print("Image upload failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.eventCreationState = .error(message: error.localizedDescription)
                    }
                }
            }
        } else {
            // No new image, just update the event
            print("No new image, continuing with update")
            continueEventUpdate(
                currentEvent: currentEvent,
                eventId: eventId,
                updatedBackgroundImageUrl: updatedBackgroundImageUrl
            )
        }
    }
    
    // Helper function to continue event update after potential image upload
    private func continueEventUpdate(currentEvent: EventModel, eventId: String, updatedBackgroundImageUrl: String) {
        print("Continuing event update with ID: \(eventId)")
        // Create updated event with all changed fields
        let updatedEvent = EventModel(
            id: currentEvent.id,
            eventName: eventName,
            title: eventTitle,
            subtitle: eventSubtitle,
            buttonText: buttonText,
            backgroundImageUrl: updatedBackgroundImageUrl,
            creatorId: currentEvent.creatorId,
            status: currentEvent.status,
            endDate: Timestamp(date: endDate),
            createdAt: currentEvent.createdAt,
            revealPhotosTiming: revealPhotosTiming,
            photosPerPerson: photosPerPerson,
            maxGuests: maxGuests,
            galleryAccess: galleryAccess,
            participants: currentEvent.participants
        )
        
        // Update the event in Firestore
        print("Sending updated event to repository")
        eventRepository.updateEvent(updatedEvent) { [weak self] result in
            switch result {
            case .success:
                print("Event updated successfully")
                DispatchQueue.main.async {
                    self?.eventCreationState = .success
                    self?.loadEvents()
                }
            case .failure(let error):
                print("Event update failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.eventCreationState = .error(message: error.localizedDescription)
                }
            }
        }
    }
    
    // Update event properties
    func updateEventName(_ name: String) {
        eventName = name
    }
    
    func updateEventTitle(_ title: String) {
        eventTitle = title
    }
    
    func updateEventSubtitle(_ subtitle: String) {
        eventSubtitle = subtitle
    }
    
    func updateButtonText(_ text: String) {
        buttonText = text
    }
    
    func updateBackgroundImage(_ image: UIImage) {
        backgroundImage = image
    }
    
    func updateEndDate(_ date: Date) {
        endDate = date
    }
    
    func updateRevealPhotosTiming(_ timing: String) {
        revealPhotosTiming = timing
    }
    
    func updatePhotosPerPerson(_ count: Int) {
        photosPerPerson = count
    }
    
    func updateMaxGuests(_ count: Int) {
        maxGuests = count
    }
    
    func updateGalleryAccess(_ enabled: Bool) {
        galleryAccess = enabled
    }
    
    // Event creation/update state
    enum EventCreationState: Equatable {
        case idle
        case loading
        case success
        case error(message: String)
        
        // Custom implementation of Equatable because of associated value
        static func == (lhs: EventCreationState, rhs: EventCreationState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.success, .success):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
}

import SwiftUI
import FirebaseFirestore

struct EventDetailsScreen: View {
    let eventName: String
    @StateObject private var viewModel = EventViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // Navigation state
    @State private var navigateToNextScreen = false
    
    // Photo picker state
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    // Editor states
    @State private var showingTitleEditor = false
    @State private var showingSubtitleEditor = false
    @State private var showingButtonEditor = false
    @State private var showingDatePicker = false
    
    // Temporary edit states
    @State private var tempTitle = "Hi"
    @State private var tempSubtitle = ""
    @State private var tempButtonText = "Take Photos →"
    
    // Picker options
    let revealOptions = ["Immediately", "1 hour after", "12 hours after", "24 hours after", "48 hours after"]
    let photosOptions = [5, 10, 15, 20, 30, 50]
    let maxGuestsOptions = [5, 10, 20, 30, 50, 100]
    
    // Fixed dimensions for preview card
    private let previewCardHeight: CGFloat = 450
    private let previewCardWidth: CGFloat = 240
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM d • h:mma zzz"
        return formatter
    }()
    
    init(eventName: String) {
        self.eventName = eventName
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Preview section
                    previewSection
                    
                    // Settings section
                    settingsSection
                    
                    // Continue button
                    continueButton
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 5)
        }
        .navigationBarTitle("Event Details", displayMode: .inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
                .onDisappear {
                    // Update preview when image is selected
                    if inputImage != nil {
                        viewModel.updateBackgroundImage(inputImage!)
                    }
                }
        }
        .alert("Edit Title", isPresented: $showingTitleEditor) {
            TextField("Title", text: $tempTitle)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                viewModel.updateEventTitle(tempTitle)
                if var updatedEvent = viewModel.loadedEvent {
                    updatedEvent.title = tempTitle
                    viewModel.populateFromEvent(event: updatedEvent)
                }
            }
        }
        .alert("Edit Subtitle", isPresented: $showingSubtitleEditor) {
            TextField("Subtitle", text: $tempSubtitle)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                viewModel.updateEventSubtitle(tempSubtitle)
                if var updatedEvent = viewModel.loadedEvent {
                    updatedEvent.subtitle = tempSubtitle
                    viewModel.populateFromEvent(event: updatedEvent)
                }
            }
        }
        .alert("Edit Button Text", isPresented: $showingButtonEditor) {
            TextField("Button Text", text: $tempButtonText)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                viewModel.updateButtonText(tempButtonText)
                if var updatedEvent = viewModel.loadedEvent {
                    updatedEvent.buttonText = tempButtonText
                    viewModel.populateFromEvent(event: updatedEvent)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .onAppear {
            initializeEvent()
        }
        // Add navigation link for after event creation
        .background(
            NavigationLink(destination: Text("Event Created Successfully!"), isActive: $navigateToNextScreen) {
                EmptyView()
            }
        )
        // Add a listener for event creation state
        // Monitor event creation state manually since EventCreationState doesn't conform to Equatable
        .onReceive(viewModel.$eventCreationState) { newState in
            handleEventCreationStateChange(newState)
        }
    }
    
    // MARK: - Subviews
    
    private var previewSection: some View {
        VStack(spacing: 15) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(alignment: .top) {
                Spacer(minLength: 20)
                
                // Preview Card
                previewCard
                    .frame(width: previewCardWidth, height: previewCardHeight)
                
                Spacer()
                
                // Edit Buttons
                editButtons
                    .frame(width: 70)
                    .padding(.trailing, 5)
            }
        }
        .padding(.top, 10)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal, 0)
    }
    
    private var previewCard: some View {
        ZStack(alignment: .center) {
            // Fixed background regardless of image
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: previewCardWidth, height: previewCardHeight)
            
            // Image if available
            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: previewCardWidth, height: previewCardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Semi-transparent overlay for better text visibility
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .frame(width: previewCardWidth, height: previewCardHeight)
            
            // Content overlay
            VStack(spacing: 12) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text(viewModel.loadedEvent?.title ?? "Hi")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    if !(viewModel.loadedEvent?.subtitle ?? "").isEmpty {
                        Text(viewModel.loadedEvent?.subtitle ?? "")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text(dateFormatter.string(from: viewModel.loadedEvent?.endDate?.dateValue() ?? Date()).components(separatedBy: " • ")[0])
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {}) {
                        Text(viewModel.loadedEvent?.buttonText ?? "Take Photos →")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: previewCardWidth - 50, height: 56)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(28)
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(width: previewCardWidth)
        }
        .frame(width: previewCardWidth, height: previewCardHeight)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var editButtons: some View {
        VStack(spacing: 24) {
            editButton("Photo", systemName: "photo.fill") {
                showingImagePicker = true
            }
            editButton("Title", systemName: "textformat.alt") {
                tempTitle = viewModel.loadedEvent?.title ?? "Hi"  // Initialize with current value
                showingTitleEditor = true
            }
            editButton("Text", systemName: "text.quote") {
                tempSubtitle = viewModel.loadedEvent?.subtitle ?? ""  // Initialize with current value
                showingSubtitleEditor = true
            }
            editButton("Button", systemName: "rectangle.and.pencil.and.ellipsis") {
                tempButtonText = viewModel.loadedEvent?.buttonText ?? "Take Photos →"  // Initialize with current value
                showingButtonEditor = true
            }
        }
        .padding(.top, 16)
    }
    
    private func editButton(_ label: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: systemName)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            VStack(spacing: 0) {
                settingRow("Ending", value: dateFormatter.string(from: viewModel.loadedEvent?.endDate?.dateValue() ?? Date())) {
                    showingDatePicker = true
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                menuSettingRow("Reveal Photo", value: viewModel.loadedEvent?.revealPhotosTiming ?? "12 hours after", options: revealOptions) { newValue in
                    viewModel.updateRevealPhotosTiming(newValue)
                    
                    // Create a new instance with updated values instead of modifying the existing one
                    if let event = viewModel.loadedEvent {
                        let updatedEvent = EventModel(
                            id: event.id,
                            eventName: event.eventName,
                            title: event.title,
                            subtitle: event.subtitle,
                            buttonText: event.buttonText,
                            backgroundImageUrl: event.backgroundImageUrl,
                            creatorId: event.creatorId,
                            status: event.status,
                            endDate: event.endDate,
                            createdAt: event.createdAt,
                            revealPhotosTiming: newValue,
                            photosPerPerson: event.photosPerPerson,
                            maxGuests: event.maxGuests,
                            galleryAccess: event.galleryAccess,
                            participants: event.participants
                        )
                        viewModel.populateFromEvent(event: updatedEvent)
                    }
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                menuSettingRow("Photos per Person", value: "\(viewModel.loadedEvent?.photosPerPerson ?? 10) Photos", options: photosOptions.map { "\($0) Photos" }) { newValue in
                    if let intValue = Int(newValue.components(separatedBy: " ")[0]) {
                        viewModel.updatePhotosPerPerson(intValue)
                        
                        // Create a new instance with updated values
                        if let event = viewModel.loadedEvent {
                            let updatedEvent = EventModel(
                                id: event.id,
                                eventName: event.eventName,
                                title: event.title,
                                subtitle: event.subtitle,
                                buttonText: event.buttonText,
                                backgroundImageUrl: event.backgroundImageUrl,
                                creatorId: event.creatorId,
                                status: event.status,
                                endDate: event.endDate,
                                createdAt: event.createdAt,
                                revealPhotosTiming: event.revealPhotosTiming,
                                photosPerPerson: intValue,
                                maxGuests: event.maxGuests,
                                galleryAccess: event.galleryAccess,
                                participants: event.participants
                            )
                            viewModel.populateFromEvent(event: updatedEvent)
                        }
                    }
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                HStack {
                    menuSettingRow("Number of participants", value: "Up to \(viewModel.loadedEvent?.maxGuests ?? 10) guests", options: maxGuestsOptions.map { "Up to \($0) guests" }) { newValue in
                        if let intValue = Int(newValue.components(separatedBy: " ")[2]) {
                            viewModel.updateMaxGuests(intValue)
                            
                            // Create a new instance with updated values
                            if let event = viewModel.loadedEvent {
                                let updatedEvent = EventModel(
                                    id: event.id,
                                    eventName: event.eventName,
                                    title: event.title,
                                    subtitle: event.subtitle,
                                    buttonText: event.buttonText,
                                    backgroundImageUrl: event.backgroundImageUrl,
                                    creatorId: event.creatorId,
                                    status: event.status,
                                    endDate: event.endDate,
                                    createdAt: event.createdAt,
                                    revealPhotosTiming: event.revealPhotosTiming,
                                    photosPerPerson: event.photosPerPerson,
                                    maxGuests: intValue,
                                    galleryAccess: event.galleryAccess,
                                    participants: event.participants
                                )
                                viewModel.populateFromEvent(event: updatedEvent)
                            }
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6).opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func settingRow(_ label: String, value: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Button(action: action) {
                HStack {
                    Text(value)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private func menuSettingRow(_ label: String, value: String, options: [String], action: @escaping (String) -> Void) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        action(option)
                    }
                }
            } label: {
                HStack {
                    Text(value)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private var continueButton: some View {
        Button(action: createEvent) {
            if viewModel.eventCreationState == .loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            } else {
                Text(inputImage != nil ? "Continue →" : "Add a Photo to Continue →")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(inputImage != nil ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .disabled(inputImage == nil || viewModel.eventCreationState == .loading)
        .padding(.horizontal)
    }
    
    private var datePickerSheet: some View {
        VStack {
            Text("Select End Date & Time")
                .font(.headline)
                .padding(.top)
            
            DatePicker(
                "Select end date",
                selection: Binding(
                    get: { viewModel.loadedEvent?.endDate?.dateValue() ?? Date() },
                    set: { newDate in
                        viewModel.updateEndDate(newDate)
                        
                        // Create a new instance with updated end date
                        if let event = viewModel.loadedEvent {
                            let updatedEvent = EventModel(
                                id: event.id,
                                eventName: event.eventName,
                                title: event.title,
                                subtitle: event.subtitle,
                                buttonText: event.buttonText,
                                backgroundImageUrl: event.backgroundImageUrl,
                                creatorId: event.creatorId,
                                status: event.status,
                                endDate: Timestamp(date: newDate),
                                createdAt: event.createdAt,
                                revealPhotosTiming: event.revealPhotosTiming,
                                photosPerPerson: event.photosPerPerson,
                                maxGuests: event.maxGuests,
                                galleryAccess: event.galleryAccess,
                                participants: event.participants
                            )
                            viewModel.populateFromEvent(event: updatedEvent)
                        }
                    }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            
            Button("Done") {
                showingDatePicker = false
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 200)
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
    
    // MARK: - Methods
    
    private func initializeEvent() {
        let event = EventModel(
            id: UUID().uuidString,
            eventName: eventName,
            title: "Hi",
            subtitle: "",
            buttonText: "Take Photos →",
            backgroundImageUrl: "",
            creatorId: "",
            status: "active",
            endDate: Timestamp(date: Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)),
            createdAt: Timestamp(date: Date()),
            revealPhotosTiming: "12 hours after",
            photosPerPerson: 10,
            maxGuests: 10,
            galleryAccess: true,
            participants: []
        )
        viewModel.populateFromEvent(event: event)
        
        // Also update temp values for manual editing
        tempTitle = "Hi"
        tempSubtitle = ""
        tempButtonText = "Take Photos →"
    }
    
    private func createEvent() {
        // Ensure we're updating the ViewModel with all the latest values
        viewModel.updateEventName(eventName)
        viewModel.updateEventTitle(viewModel.loadedEvent?.title ?? tempTitle)
        viewModel.updateEventSubtitle(viewModel.loadedEvent?.subtitle ?? tempSubtitle)
        viewModel.updateButtonText(viewModel.loadedEvent?.buttonText ?? tempButtonText)
        
        if let image = inputImage {
            viewModel.updateBackgroundImage(image)
        }
        
        // Create the event and observe state changes
        viewModel.createEvent()
    }
    
    // Handle state changes from the viewModel
    private func handleEventCreationStateChange(_ state: EventViewModel.EventCreationState) {
        switch state {
        case .success:
            // Navigate to next screen or dismiss this one
            navigateToNextScreen = true
        case .error(let message):
            // Could add an alert here to display the error
            print("Error creating event: \(message)")
        case .idle, .loading:
            // No action needed for these states
            break
        }
    }
}

// ImagePicker implementation
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EventDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailsScreen(eventName: "Birthday Party")
    }
}
